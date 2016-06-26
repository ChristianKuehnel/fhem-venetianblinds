##############################################
#
# This is open source software licensed unter the Apache License 2.0
# http://www.apache.org/licenses/LICENSE-2.0
#
##############################################

use strict;
use warnings;
use v5.10.1;
use experimental "smartmatch";
use Test::More;
use Time::HiRes "gettimeofday";
 
use VenetianMasterController;
use fhem_test_mocks;

package main;

##############################################################################################
sub test_VenetianMasterController() {
	test_update_calendar();
	test_update_twilight();
	test_update_weather();
}

##############################################################################################

sub test_update_calendar(){
	main::reset_mocks();
	main::add_reading("myname","month","0");
	my $hash = {
		"name" => "myname",
	};
	my $result = VenetianMasterController::update_calendar($hash);
	ok(!defined $result);
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    # Note: months start at 0 = January
	is(ReadingsVal("myname", "month", undef) ,$mon+1);
	is(scalar get_timer_list(),1);
}

sub test_update_twilight(){
	main::reset_mocks();
	my $hash = {
		"name" => "RogerRabbit",
		"twilight" => "the_twilight",
	};
	add_reading("the_twilight", "elevation", 27 );
	add_reading("the_twilight", "azimuth", 199 );
	
	my $result = VenetianMasterController::update_twilight($hash);
	ok(!defined $result);
	is(ReadingsVal("RogerRabbit", "sun_elevation", undef), 27);
	is(ReadingsVal("RogerRabbit", "sun_azimuth", undef) ,199);
	
}

sub test_update_weather(){
	main::reset_mocks();
	my $hash = {
		"name" => "JollyJumper",
		"weather" => "some_weather",
	};

	add_reading("some_weather", "code", 26 );
	add_reading("some_weather", "wind_speed", 15 );
	my $result = VenetianMasterController::update_weather($hash);
	ok(!defined $result);
	is(ReadingsVal("JollyJumper", "wind_speed", undef), 15);
	is(ReadingsVal("JollyJumper", "cloud_index", undef) ,5);

	# try some unmapped weather code
	add_reading("some_weather", "code", 3 );
	$result = VenetianMasterController::update_weather($hash);
	ok(!defined $result);
	is(ReadingsVal("JollyJumper", "cloud_index", undef) ,9);
}



1;