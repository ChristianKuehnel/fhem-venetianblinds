##############################################
#
# This is open source software licensed unter the Apache License 2.0
# http://www.apache.org/licenses/LICENSE-2.0
#
##############################################

use v5.10.1;
use strict;
use warnings;
use experimental "smartmatch";

package VenetianBlinds::VenetianBlindController;


# constants ########################

my $scenes = {
	"open" => {
        "blind" => 99,
        "slat" => undef,   
    },
    "closed" => {
        "blind" => 0,
        "slat" => 0,   
    },
    "see_through" => {
        "blind" => 0,
        "slat" => 50,   
    },
    "shaded" => {
        "blind" => 0,
        "slat" => 30,   
    },
};

my $blind_threshold =  5; #percentage points
my $slat_threshold  =  5; #percentage points
my $power_threshold = 10; #watts

# FHEM commands ########################

sub Define{
	my ($hash,$a,$h) = @_;
	$hash->{master_controller} = $h->{master};
	$hash->{device} = $h->{device};
	$hash->{could_index_threshold} = $h->{could_index_threshold};

	my ($azstart,$azend) = split(/-/, $h->{azimuth});
	$hash->{azimuth_start} = $azstart;
	$hash->{azimuth_end} = $azend;

	my ($evstart,$evend) = split(/-/, $h->{elevation});
	$hash->{elevation_start} = $evstart;
	$hash->{elevation_end} = $evend;

	my ($monstart,$monend) = split(/-/, $h->{months});
	$hash->{month_start} = $monstart;
	$hash->{month_end} = $monend;

	return;
}

sub Set{
	my ( $hash, $a,$h ) = @_;
	my $cmd = $a->[1];
	my @scene_list = keys %{$scenes};
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
	
	# reasons to not work in automatic mode
	if ($wind_alarm  
		or !$automatic
		or $month < $hash->{month_start} 
		or $month > $hash->{month_end} 	){ 
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

	if (!defined $scenes->{$scene}){
		main::Log(1, "undefined scene $scenes->{$scene}");
	} else {
		main::readingsSingleUpdate($hash,"scene",$scene,1);		
        if ($automatic) {
            $hash->{STATE} = "automatic: $scene";
        } else {
            $hash->{STATE} = "manual: $scene";
        }
        main::Log(3,"moving blinds $hash->{device} to scene $scene.");
        move_blinds($hash, $scenes->{$scene}{blind}, $scenes->{$scene}{slat});	
	}
}

sub move_blinds{
	my ($hash, $blind, $slat)= @_;
	my ($current_blind, $current_slat) = get_position($hash);
	if ( defined $blind and
		abs($blind-$current_blind) > $blind_threshold ){
		main::fhem("set $hash->{device} positionBlinds $blind");
	}
	if ( defined $slat and 
		abs($slat-$current_slat) > $slat_threshold and
		$blind < 95 ){
		enqueue_command($hash,"set $hash->{device} positionSlat $slat");
	}
}

sub wind_alarm{
	my ($hash) = @_;
	move_blinds($hash,99,undef);
}

sub stop {
	my ($hash) = @_;
	main::fhem("set $hash->{device} stop");	
	delete $hash->{queue};
}

# queing of commans ######################
sub enqueue_command {
	my ($hash,$cmd) = @_;
	$hash->{queue} = $cmd;
	process_queue($hash);
}

sub process_queue {
	my ($hash) = @_;
	if (!defined $hash->{queue}) { return; };
		
	if (get_power($hash) > $power_threshold) {
		main::InternalTimer(main::gettimeofday()+1, "VenetianBlinds::VenetianBlindController::process_queue", $hash, 1);        
	} else {
		main::fhem($hash->{queue});
		delete $hash->{queue};
	}
}


# wrappers around readings #############################
sub get_power{
	my ($hash) = @_;
    my $power_reading = main::ReadingsVal($hash->{device}, "power", undef);
    $power_reading =~ /([\d\.]+)\WW/;
    return $1;
}

sub get_position{
	my ($hash) = @_;
    main::fhem("get $hash->{device} position");
    my $device=$hash->{device};
    #TODO: do we really need a ReadingsVal or does the "get position" also deliver that result?
    my $position = main::ReadingsVal($device, "position", undef);
    $hash->{position} = $position;
    $position =~ /Blind (\d+) Slat (\d+)/;
    if (!defined $1 or !defined $2){
        main::Log( 1, "Error: could not get position of device $hash->{device}: $position");
    }
	return ($1,$2);
}

1; # end module
