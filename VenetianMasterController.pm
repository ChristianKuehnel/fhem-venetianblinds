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

# Map the condition codes from yahoo to cloudiness index, 
# makes it easier to implement thresholds as higher number indicates more clouds
# https://de.wikipedia.org/wiki/Bew%C3%B6lkung#Einteilung_des_Flugwetterdienstes
my $yahoo_code_map = {
	#TODO: add mapping for more codes	
	26 => 5, # cloudy
    28 => 6, # mostly cloudy (day)
    30 => 3, # partly cloudy (day)
    32 => 1, # sunny 
    34 => 2, # fair (day)
    36 => 0, # hot
};


sub Define($$$){
	my ($hash,$a,$h) = @_;
	$hash->{twilight} = $h->{twilight};
	$hash->{weather} = $h->{weather};

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
	} elsif ($devName eq $hash->{weather}){
		update_weather($hash);
	}
	
	foreach my $event (@{$events}) {
	  	$event = "" if(!defined($event));
		main::Log(3,"Event on device $devName: $event");
	}
	return undef;		
}

sub update_twilight($){
	my ($hash) = @_;
	# TODO: reduce number of events: only trigger event if data has changed
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

sub update_weather($){
	my ($hash) = @_;
	my $condition_code = main::ReadingsVal($hash->{weather}, "code", undef);
	my $cloud_index = undef;
	$cloud_index = $yahoo_code_map->{$condition_code};
	if (!defined $cloud_index){
		$cloud_index = 9;
	};
	
	# TODO: reduce number of events: only trigger event if data has changed
	main::readingsBeginUpdate($hash);	
	main::readingsBulkUpdate($hash, "wind_speed",
		main::ReadingsVal($hash->{weather}, "wind_speed", undef) );
	main::readingsBulkUpdate($hash, "cloud_index", $cloud_index);
	main::readingsEndUpdate($hash, 1);
}

1;
