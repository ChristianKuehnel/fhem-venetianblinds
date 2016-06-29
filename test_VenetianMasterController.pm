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
	test_find_devices();
	test_wind_alarm();
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

sub test_find_devices{
	main::reset_mocks();
	main::set_fhem_mock("list .* type",
		"shady1   VenetianBlindController\nshady2    VenetianBlindController\nother Some different type of thing");
	
	my @device_list = VenetianMasterController::find_devices();
	is(scalar @device_list,2);
	ok("shady1" ~~ @device_list);
	ok("shady2" ~~ @device_list);
	
}

sub test_wind_alarm{
	main::reset_mocks();
	main::set_fhem_mock("list .* type",
		"shady1   VenetianBlindController");
	my $hash = {
		"name" => "NervousNick",
	};
	add_reading("NervousNick", "wind_speed", 10 );
	add_reading("NervousNick", "wind_alarm", 0 );
	
	my $result = VenetianMasterController::check_wind_alarm($hash);
	ok(!defined $result);
	is(ReadingsVal("NervousNick", "wind_alarm", undef) ,0);
	
	add_reading("NervousNick", "wind_speed", 51 );
	main::set_fhem_mock("set shady1 wind_alarm", undef);
	
	$result = VenetianMasterController::check_wind_alarm($hash);
	ok(!defined $result);
	is(ReadingsVal("NervousNick", "wind_alarm", undef) ,1);
	
	add_reading_time("NervousNick", "wind_speed", 49, time()-700 );
	$result = VenetianMasterController::check_wind_alarm($hash);
	ok(!defined $result);
	is(ReadingsVal("NervousNick", "wind_alarm", undef) ,0);
	
}


1;
