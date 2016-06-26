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
use DateTime;


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

sub update_calendar($){
	my ($hash) = @_;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    # Note: months start at 0 = January
    $mon +=1;
    my $current = main::ReadingsVal($hash->{name}, "month", undef);    
	if ($mon != $current){
		main::readingsSingleUpdate($hash,"month",$mon,1);		
	}
	#TODO: do the update exactly at midnight
	main::InternalTimer(main::gettimeofday()+24*60*60, "VenetianMasterController::update_calendar", $hash, 1);        
	return undef;
}

1;
