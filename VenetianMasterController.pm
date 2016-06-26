##############################################
#
# This is open source software licensed unter the Apache License 2.0
# http://www.apache.org/licenses/LICENSE-2.0
#
##############################################

package VenetianMasterController;
use v5.10.1;
use strict;
use warnings;

sub Define($$$){
	my ($hash,$a,$h) = @_;
	$hash->{twilight} = $h->{twilight};

	return undef;
}

sub Set($$$){
	my ($hash,$a,$h) = @_;

	return undef;
}


sub Notify($$$){
	my ($hash, $devName, $events) = @_;
	if ($devName eq $hash->{twilight}) {
		update_twilight($hash);
	}
	
	
	foreach my $event (@{$events}) {
	  	$event = "" if(!defined($event));
		main::Log(3,"Event on device $devName: $event");
	}
	return undef;		
}

sub update_twilight($){
	my ($hash) = @_;
	main::readingsBeginUpdate($hash);
	main::readingsBulkUpdate($hash, "sun_elevation",
		main::ReadingsVal($hash->{twilight}, "elevation", undef) );
	main::readingsBulkUpdate($hash, "sun_azimuth",
		main::ReadingsVal($hash->{twilight}, "azimuth", undef) );
	main::readingsEndUpdate($hash, 1);
}


1;
