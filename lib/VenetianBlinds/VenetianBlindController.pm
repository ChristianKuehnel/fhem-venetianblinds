##############################################
#
# This is open source software licensed unter the Apache License 2.0
# http://www.apache.org/licenses/LICENSE-2.0
#
##############################################
package VenetianBlinds::VenetianBlindController;

use v5.10.1;
use strict;
use warnings;
use experimental "smartmatch";
use VenetianBlinds::Shared "scenes";


# constants ########################

use constant blind_threshold =>  5; #percentage points
use constant slat_threshold  =>  5; #percentage points
use constant power_threshold => 10; #watts

# FHEM commands ########################

sub Define{
	#TODO: check if $device and $master really exist
	my ($hash,$a,$h) = @_;

	if (!defined $h->{master}) {
		return "Mandatory argument 'master=<name>' is missing or undefined";
	}
	$hash->{master_controller} = $h->{master};

	if (!defined $h->{device}) {
		return "Mandatory argument 'device=<name>' is missing or undefined";
	}
	$hash->{device} = $h->{device};
	
	if (!defined $h->{could_index_threshold}) {
		return "Mandatory argument 'could_index_threshold=<value>' is missing or undefined";
	}	
	$hash->{could_index_threshold} = $h->{could_index_threshold};

	if (!defined $h->{azimuth} ) {
		return "Mandatory argument 'azimuth=<start>-<end>' is missing or undefined";
	}	
	my ($azstart,$azend) = split(/-/, $h->{azimuth});
	$hash->{azimuth_start} = $azstart;
	$hash->{azimuth_end} = $azend;

	if (!defined $h->{elevation}) {
		return "Mandatory argument 'elevation=<start>-<end>' is missing or undefined";
	}
	my ($evstart,$evend) = split(/-/, $h->{elevation});
	$hash->{elevation_start} = $evstart;
	$hash->{elevation_end} = $evend;

	if (!defined $h->{months} ) {
		return "Mandatory argument 'months=<start>-<end>' is missing or undefined";
	}	$hash->{azimuth_start} = $azstart;
	my ($monstart,$monend) = split(/-/, $h->{months});
	$hash->{month_start} = $monstart;
	$hash->{month_end} = $monend;

	return;
}

sub Set{
	my ( $hash, $a,$h ) = @_;
	my $cmd = $a->[1];
	my @scene_list = keys %{&scenes};
	if ( $cmd eq "?" ){
		my $result = "automatic:noArg wind_alarm:noArg stop:noArg";
		foreach my $scene (@scene_list){
			$result .= " $scene:noArg";
		}
		return $result;
	} elsif ($cmd eq "automatic") {
		main::readingsSingleUpdate($hash,"automatic",1,1);		
		update_automatic($hash,1);
    } elsif ($cmd ~~ @scene_list) {
		main::readingsSingleUpdate($hash,"automatic",0,1);		
		set_scene($hash, $cmd, 0);
	} elsif ($cmd eq "scenes") {
		delete $hash->{scences};
	} elsif ($cmd eq "wind_alarm") {
		wind_alarm($hash);
	} elsif ($cmd eq "stop") {
		stop($hash);
	} else {
		return "unknown command $cmd";
	}
	return; 
}


sub Notify{
	my ($hash, $devName, $events) = @_;	
    if ($devName eq $hash->{master_controller}){
		update_automatic($hash,0);
	} elsif ($devName eq $hash->{device}) {
		update_STATE($hash);
	}
	return;
}


# logic for blind control #####################
sub update_automatic{
	my ($hash,$force) = @_;
    my $master = $hash->{master_controller};
	my $sun_elevation = main::ReadingsVal($master, "sun_elevation", undef);
	my $sun_azimuth = main::ReadingsVal($master, "sun_azimuth", undef);
	my $wind_speed = main::ReadingsVal($master, "wind_speed", undef);
	my $wind_alarm = main::ReadingsVal($master, "wind_alarm", undef);
	my $cloud_index = main::ReadingsVal($master, "cloud_index", undef);
	my $month = main::ReadingsVal($master, "month", undef);
	my $automatic = main::ReadingsVal($hash->{NAME}, "automatic", undef);
	my $old_scene = main::ReadingsVal($hash->{NAME}, "scene", undef);
	my $mechanical_switches = main::ReadingsVal($hash->{device}, "reportedState", undef);
	
	# reasons to not work in automatic mode
	if ($wind_alarm  
		or !$automatic
		or $month < $hash->{month_start} 
		or $month > $hash->{month_end} 	
		or $mechanical_switches eq "setOn"
		or $mechanical_switches eq "setOff" ){ 
			return;
        main::Log(3,"Automatic inactive on $hash->{NAME}"); 
	}
	
	my $new_scene = undef;
	if ($hash->{elevation_start} <= $sun_elevation and 
		$sun_elevation <= $hash->{elevation_end} and
		$hash->{azimuth_start} <= $sun_azimuth and
		$sun_azimuth <= $hash->{azimuth_end} and
		$cloud_index <= $hash->{could_index_threshold}) {
		$new_scene ="shaded";
	} else {
		$new_scene = "open";
	}
	
	if ($force or !($new_scene eq $old_scene)) {
		set_scene($hash,$new_scene,0);
	} else {
        main::Log(5,"Scene has not changed on $hash->{NAME}, not moving blinds");
    }
}

# move the blinds ##########################
sub set_scene{
	my ($hash,$scene,$force) = @_;
	my $automatic = main::ReadingsVal($hash->{NAME}, "automatic", undef);
	my $old_scene = main::ReadingsVal($hash->{NAME}, "scene", undef);

	if (!defined &scenes->{$scene}){
		main::Log(1, "undefined scene &scenes->{$scene}");
	} else {
		main::readingsSingleUpdate($hash,"scene",$scene,1);		
        main::Log(3,"moving blinds $hash->{device} to scene $scene.");
        move_blinds($hash, &scenes->{$scene}{blind}, &scenes->{$scene}{slat});	
	}
	update_STATE($hash);
}

sub update_STATE {
    my ($hash) = @_;
    my $automatic = main::ReadingsVal($hash->{NAME}, "automatic", undef);
    my $scene = main::ReadingsVal($hash->{NAME}, "scene", undef);
	my $mechanical_switches = main::ReadingsVal($hash->{device}, "reportedState", undef);

	if ($mechanical_switches eq "setOn") {
        $hash->{STATE} = "mechanical: Up";				
	} elsif ( $mechanical_switches eq "setOff") {
        $hash->{STATE} = "mechanical: Down";						
	} elsif ($automatic) {
        $hash->{STATE} = "automatic: $scene";
    } else {
        $hash->{STATE} = "manual: $scene";
    }
}

sub move_blinds{
	my ($hash, $blind, $slat)= @_;
	my ($current_blind, $current_slat) = get_position($hash);
	if ( defined $blind and
		abs($blind-$current_blind) > &blind_threshold ){
		main::fhem("set $hash->{device} positionBlinds $blind");
		count_commands($hash);
	}
	if ( defined $slat and 
	    abs($slat - $current_slat) > &slat_threshold ){
		main::fhem("set $hash->{device} positionSlat $slat");
	}
}

sub wind_alarm{
	my ($hash) = @_;
	move_blinds($hash,99,undef);
}

sub stop {
	my ($hash) = @_;
	main::fhem("set $hash->{device} stop");	
	count_commands($hash);
	delete $hash->{queue};
}

sub count_commands{
	my ($hash) = @_;
    my $count = main::ReadingsVal($hash->{NAME}, "command_count", 0) +1;
	main::readingsSingleUpdate($hash,"command_count",$count,0);		
}


# wrappers around readings #############################
sub get_power{
	my ($hash) = @_;
    main::fhem("get $hash->{device} smStatus", undef);
    my $power_reading = main::ReadingsVal($hash->{device}, "power", undef);   
    $power_reading =~ /([\d\.]+)\WW/;
    if (!defined $1){
    	main::Log(1,"Error reading power level of $hash->{device}:'$power_reading'");
    }
    return $1;
}

sub get_position{
	my ($hash) = @_;
    main::fhem("get $hash->{device} position");
    my $device=$hash->{device};
    #TODO: do we really need a ReadingsVal or does the "get position" also deliver that result?
    my $position = main::ReadingsVal($device, "position", undef);
    $position =~ /Blind (\d+) Slat (\d+)/;
    if (!defined $1 or !defined $2){
        main::Log( 1, "Error: could not get position of device $hash->{device}: $position");
    }
	return ($1,$2);
}

1; # end module
