##############################################
# 
# This is open source software licensed unter the Apache License 2.0 
# http://www.apache.org/licenses/LICENSE-2.0
#
##############################################



use v5.10.1;
use strict;
use warnings;
use POSIX;
use Switch;

package Rolladensteuerung;

my %config = (
    "sides" => {
        "sued" => {
            "blinds" => ["wz.sued_fenster","wz.sued_tuer"],
            "start_azimuth" => 90,
            "end_azimuth" => 230,
            "min_elevation" => 8,
        },
        "west" => {
            "blinds" => ["wz.west_fenster","ku.tuer","sz.west_fenster"],
            "start_azimuth" => 180,
            "end_azimuth" => 300,
            "min_elevation" => 15,
        }
    },
    "scenes" => {
        "offen" => {
            "positionBlinds" => 99,
            "positionSlat" => 99,   
        },
        "geschlossen" => {
            "positionBlinds" => 0,
            "positionSlat" => 0,   
        },
        "schattiert" => {
            "positionBlinds" => 0,
            "positionSlat" => 50,   
        },
        "stark_schattiert" => {
            "positionBlinds" => 0,
            "positionSlat" => 30,   
        },
    },
    "calendar" => {
        "first_month" => 5,
        "last_month" => 9,
    },
    "condition_codes_sun" => {
        26 => 1,
        28 => 1,
        30 => 1,
        32 => 1,
        34 => 1,
        36 => 1,
    },
    "power_threshold" => 10,
    "blinds_threshold" => 5,
    "slats_threshold" => 5,
);

sub Log($$) {
    my ($n,$text) = @_;
    main::Log($n, "Rolladensteuerung: $text");

}

sub update($$){
    my ($hash,$force) = @_;
    Log 5, "triggering update";
    update_calendar($hash,$force);
    update_wind($hash,$force);
    update_sun_intensity($hash,$force);
    update_sun_position($hash,$force);

    update_state($hash,$force);
    controller($hash,$force);
}


sub update_calendar($$) {
    my ($hash,$force) = @_;
    
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);    
    if (!$config{calendar}{first_month} or !$config{calendar}{last_month}){
        Log(3,"error in calendar configuration!");
    }
    # Note: months start at 0 = January
    my $new_state = ($config{calendar}{first_month} <= $mon+1 and 
                    $mon+1 <= $config{calendar}{last_month});
    if (!$new_state) { $new_state = 0 }
    set_state($hash,"calendar_state",$new_state,$force);
}

sub get_state($$) {
    my ($hash,$reading) = @_;
    return main::ReadingsVal($hash->{NAME},$reading,undef);
}

sub set_state($$$$) {
    my ($hash,$reading,$value,$force) = @_;
    my $old_value = get_state($hash,$reading);
    # it seems to be normal to update every time...
    #if ($force or !(defined $old_value) or $value != $old_value) {
    #    Log 2, "updated $reading to $value";
        main::readingsSingleUpdate($hash,$reading,$value,1);
    #}
    update_state($hash,$force);
}


sub update_state($$){
    my ($hash,$force) = @_;
    
    my $calendar_state = get_state($hash,"calendar_state");
    my $wind_state = get_state($hash,"wind_state");
    my $sun_intensity = get_state($hash,"sun_intensity");
    my $automatic = get_state($hash, "automatic");

    my $new_state = "auto:$automatic cal:$calendar_state wind:$wind_state sun:$sun_intensity";

    my $key = undef;
    my $value = undef;
    my $side = undef;
    foreach $side (keys %{ $config{sides} }) {
        $value = get_state($hash,"sun_position_$side");
        $new_state .= " $side:$value"; 
    } 

    if ($force or $new_state ne $hash->{STATE}) {
        $hash->{STATE} = $new_state;
    }
}

sub update_wind($$){
    my ($hash,$force) = @_;
    
    my $wind = main::ReadingsVal("Wetter", "wind", undef);
    my $new_state = ($wind >=50);
    if (!$new_state) { $new_state = 0 }
    set_state($hash,"wind_state",$new_state,$force);
}

sub update_sun_intensity($$){
    my ($hash,$force) = @_;
    
    my $condition_code = main::ReadingsVal("Wetter", "code", undef);
   
    my $new_state = (exists $config{condition_codes_sun}{$condition_code}); 
    if (!$new_state) { $new_state = 0; }
    set_state($hash,"sun_intensity",$new_state,$force);
}

sub update_sun_position($$){
    my ($hash,$force) = @_;
    
    my $azimuth = main::ReadingsVal("sonnenstand", "azimuth", undef);
    my $elevation = main::ReadingsVal("sonnenstand", "elevation", undef);
    my $side = undef;
   
    foreach $side (keys  %{ $config{sides}}) {
        my $new_state = ( 
            $config{sides}{$side}{start_azimuth} < $azimuth and
            $config{sides}{$side}{end_azimuth} > $azimuth and
            $config{sides}{$side}{min_elevation} < $elevation);
        if (!$new_state) { $new_state = 0 }
        set_state($hash,"sun_position_$side",$new_state,$force);
    } 
}

sub controller($$) {
    my ($hash,$force) = @_;

    if (get_state($hash,"wind_state") != 0) {
        reposition_all($hash,"offen",1);
    } elsif (get_state($hash, "automatic") and get_state($hash,"calendar_state") ) {
        my $sun_position = undef;
        my $side = undef;
        my $sun_intensity = get_state($hash,"sun_intensity"); 
        foreach $side (keys  %{$config{sides}}) {
            $sun_position = get_state($hash,"sun_position_$side");
            if ($sun_position and $sun_intensity ) {
                reposition_side($hash, $side, "stark_schattiert", $force);
            } else {
                reposition_side($hash, $side, "offen", $force);
            }
        }    
    }
}

sub reposition_all($$$) {
    my ($hash,$new_position,$force) = @_;
    
    my $side = undef;
    foreach $side (keys  %{$config{sides}}) {
        reposition_side($hash, $side, $new_position,$force);
    }
}

sub reposition_side($$$$) {
    my ($hash, $side, $new_scene,$force) = @_;
    
    # only send data if position has changed
    if (!$force and $hash->{"side_$side"} eq $new_scene){
    	return undef;
    }
    
    my $device = undef;
    my @devices = @{$config{sides}{$side}{blinds}};
    my $blinds = $config{scenes}{$new_scene}{positionBlinds};
    my $slats = $config{scenes}{$new_scene}{positionSlat};
    
    foreach $device (@devices) {
    	if ( get_power($device) > $config{power_threshold} ) {
            stop_device($hash,$device);
        } 
        add_command($hash,$device,$blinds,$slats);
    }
    $hash->{"side_$side"} = $new_scene;
    process_command_queue($hash);
}

sub add_command($$$$){
	my ($hash,$device,$blinds,$slats) = @_;
	
	$hash->{queue}{$device}{blinds}= $blinds;
	$hash->{queue}{$device}{slats}= $slats;
}

sub remove_device_from_queue($$){
    my ($hash,$device) = @_;
    delete $hash->{queue}{$device};
}

sub process_command_queue($){
	my ($hash) = @_;
	my @queue = keys %{$hash->{queue}};
	for ( my $d=0 ; $d < scalar(@queue); $d++ ){
		my $device = $queue[$d];
		my $completed = process_device($hash,$device);
		if ($completed){
            remove_device_from_queue($hash,$device);
		}
	}
	if (scalar(keys %{$hash->{queue}}) > 0){
		main::InternalTimer(main::gettimeofday()+1, "Rolladensteuerung::process_command_queue", $hash, 1);        
	}
}

sub process_device($$){
	my ($hash,$device) = @_;
	my $blinds = $hash->{queue}{$device}{blinds};
	my $slats = $hash->{queue}{$device}{slats};
	if ( get_power($device) <= $config{power_threshold} ) {
		my ($old_blinds,$old_slats) = get_position($device);
        if ((!defined $old_blinds) or (!defined $old_slats)) {
            return 0;
        }
        if (abs($old_blinds - $blinds) > $config{blinds_threshold}) {
            Log 3, "process_device $device blinds $old_blinds -> $blinds";
            main::fhem("set $device positionBlinds $blinds"); 
        } elsif ($blinds < 95 and abs($old_slats - $slats) > $config{slats_threshold}) {    
            Log 3, "process_device $device slats $old_slats -> $slats";
            main::fhem("set $device positionSlat $slats");
        } else {
            return 1;
        }
	} else {
        Log 5, "process_device $device waiting for movement to be completed";
    }
	return 0;
}

sub stop_all($){
    my ($hash) = @_;
    
    my $side = undef;
    my $device = undef;
    my @devices = undef;
    foreach $side (keys  %{$config{sides}}) {
        @devices = @{$config{sides}{$side}{blinds}};
        foreach $device (@devices) {
            stop_device($hash,$device);
        }
    }
}

sub stop_device($$){
    my ($hash, $device) = @_;
    remove_device_from_queue($hash,$device);
    main::fhem("set $device stop");
}

sub get_power($){
	my ($device) = @_;
    my $power_reading = main::ReadingsVal($device, "power", undef);
    $power_reading =~ /([\d\.]+)\WW/;
    return $1;
}

sub get_position($){
	my ($device) = @_;
    main::fhem("get $device position");
    my $position = main::ReadingsVal($device, "position", undef);
    $position =~ /Blind (\d+) Slat (\d+)/;
    if (!defined $1 or !defined $2){
        Log 1, "Error: could not get position of device $device: $position";
    }
	return ($1,$2);
}
##############################
package main;

sub Rolladensteuerung_Initialize($) {
    my ($hash) = @_;
    $hash->{DefFn}      = 'Rolladensteuerung_Define';
    #$hash->{UndefFn}    = 'Rolladensteuerung_Undef';
    $hash->{SetFn}      = 'Rolladensteuerung_Set';
    #$hash->{GetFn}      = 'Rolladensteuerung_Get';
    #$hash->{AttrFn}     = 'Rolladensteuerung_Attr';
    #$hash->{ReadFn}     = 'Rolladensteuerung_Read';    
    $hash->{NotifyFn}     = 'Rolladensteuerung_Notify';
    
    return undef;
}

sub Rolladensteuerung_Define($$) {
    my ($hash, $def) = @_;
    $hash->{STATE} = "defined";
    $hash->{sun_state} = {};
    InternalTimer(gettimeofday()+30,"Rolladensteuerung::update",$hash,0);
    return undef;
}

sub Rolladensteuerung_Set($@) {
    my ($hash,@args) = @_;
       
    my $name = shift @args;
    my $cmd=shift @args;
    switch ($cmd) {
        case "update" { Rolladensteuerung::update($hash,0); }
        case "force_update" { Rolladensteuerung::update($hash,1); }
        case "move" { 
            my $side = shift @args;
            my $position = shift @args;
            Rolladensteuerung::reposition_side($hash,$side,$position,1);
        }
        case "automatic" {
			my $automatic = shift @args;
			Rolladensteuerung::set_state($hash,"automatic", $automatic,0);
            Rolladensteuerung::update($hash,0);
        }
        case "stop" {
            Rolladensteuerung::stop_all($hash);
        }
        case "tv_mode" {
			Rolladensteuerung::set_state($hash,"automatic", 0,0);
            Rolladensteuerung::reposition_side($hash,"sued","geschlossen",1);
            Rolladensteuerung::reposition_side($hash,"west","geschlossen",1);
        }
        case "?" { return "update:noArg force_update:noArg move automatic:0,1 stop:noArg tv_mode:noArg";}
        else { return "Unknown command $cmd"; }
    }
    return undef;
}

sub Rolladensteuerung_Notify($$){
    my ($hash, $dev_hash) = @_;
    my $ownName = $hash->{NAME}; # own name / hash
    return "" if(IsDisabled($ownName)); # Return without any further action if the module is disabled

    my $devName = $dev_hash->{NAME}; # Device that created the events

    switch ($devName) {
        #case "$ownName" { Rolladensteuerung::controller($hash,0); }
        case "Wetter" {  Rolladensteuerung::update($hash,0); }
        case "sonnenstand" { Rolladensteuerung::update($hash,0); }
    }
}

1;
