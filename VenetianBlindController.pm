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
use Switch;
use experimental "smartmatch";

sub Define($$$){
	my ($hash,$a,$h) = @_;
	$hash->{master_controller} = $h->{master};
	$hash->{device} = $h->{device};
	return undef;
}

sub Set($$$){
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
	} else {
		return "unknown command $cmd";
	}
	return undef; 
}

sub update_automatic($){
	#TODO: get sun and wind params from Master Controller
	#TODO: decide what to do
	#TODO: do it
}

sub set_scene($$){
	my ($hash,$scene) = @_;
	#TODO:get secene config
	#TODO:move blinds
}

1;
