##############################################
#
# This is open source software licensed unter the Apache License 2.0
# http://www.apache.org/licenses/LICENSE-2.0
#
##############################################

package VenetianBlindController;

use v5.10.1;
use strict;
use warnings;
use experimental "smartmatch";


my $scenes = {
	"open" => {
        "blind" => 99,
        "slat" => 99,   
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

sub Define{
	my ($hash,$a,$h) = @_;
	$hash->{master_controller} = $h->{master};
	$hash->{device} = $h->{device};
	my ($azstart,$azend) = split(/-/, $h->{azimuth});
	$hash->{azimuth_start} = $azstart;
	$hash->{azimuth_end} = $azend;
	my ($evstart,$evend) = split(/-/, $h->{elevation});
	$hash->{elevation_start} = $evstart;
	$hash->{elevation_end} = $evend;	
	return;
}

sub Set{
	my ( $hash, $a,$h ) = @_;
	my $cmd = $a->[1];
	if ( $cmd eq "?" ){
		return "automatic:noArg"
	} elsif ($cmd eq "automatic") {
		$hash->{automatic} = 1;
		update_automatic($hash);
	} elsif ($cmd ~~ keys %{$hash->{scenes}}) {
		$hash->{automatic} = 0;
		set_scene($hash,$cmd);
	} elsif ($cmd eq "scenes") {
		delete $hash->{scences};
	} else {
		return "unknown command $cmd";
	}
	return; 
}


sub Notify{
	my ($hash, $devName, $events) = @_;	
	if ($devName eq $hash->{master_controller}){
		update_automatic($hash);
	}
	return;
}

sub update_automatic{
	#TODO: get sun and wind params from Master Controller
	#TODO: decide what to do
	# if ($hash->{automatic})
	#   set_secene (...)
}

sub set_scene{
	my ($hash,$scene) = @_;
	#TODO:get secene config
	#TODO:move blinds
}

1;
