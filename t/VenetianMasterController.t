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
 
use VenetianBlinds::VenetianMasterController;

use lib "t"; 
use fhem_test_mocks;

#package main;

##############################################################################################
sub test_VenetianMasterController {
	test_update_calendar();
	test_update_twilight();
	test_update_weather();
	test_find_devices();
	test_wind_alarm();
	test_stop_all();
	test_send_to_all();
	
	done_testing();	
}

test_VenetianMasterController();

##############################################################################################

sub test_update_calendar{
	note( (caller(0))[3] );	
	main::reset_mocks();
	main::add_reading("myname","month","0");
	my $hash = {
		"NAME" => "myname",
	};
	my $result = VenetianBlinds::VenetianMasterController::update_calendar($hash);
	ok(!defined $result);
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    # Note: months start at 0 = January
	is(ReadingsVal("myname", "month", undef) ,$mon+1);
	is(scalar get_timer_list(),1);
}

sub test_update_twilight{
	note( (caller(0))[3] );	
	main::reset_mocks();
	my $hash = {
		"NAME" => "RogerRabbit",
		"twilight" => "the_twilight",
	};
	add_reading("the_twilight", "elevation", 27 );
	add_reading("the_twilight", "azimuth", 199 );
	
	my $result = VenetianBlinds::VenetianMasterController::update_twilight($hash);
	ok(!defined $result);
	is(ReadingsVal("RogerRabbit", "sun_elevation", undef), 27);
	is(ReadingsVal("RogerRabbit", "sun_azimuth", undef) ,199);
	
}

sub test_update_weather{
	note( (caller(0))[3] );	
	main::reset_mocks();
	my $hash = {
		"NAME" => "JollyJumper",
		"weather" => "some_weather",
	};

	add_reading("some_weather", "code", 26 );
	add_reading("some_weather", "wind_speed", 15 );
	my $result = VenetianBlinds::VenetianMasterController::update_weather($hash);
	ok(!defined $result);
	is(ReadingsVal("JollyJumper", "wind_speed", undef), 15);
	is(ReadingsVal("JollyJumper", "cloud_index", undef) ,5);

	# try some unmapped weather code
	add_reading("some_weather", "code", 3 );
	$result = VenetianBlinds::VenetianMasterController::update_weather($hash);
	ok(!defined $result);
	is(ReadingsVal("JollyJumper", "cloud_index", undef) ,9);
}

sub test_find_devices{
	note( (caller(0))[3] );	
	main::reset_mocks();
	main::set_fhem_mock("list .* type",
		q{
vbc.ku.fenster           VenetianBlindController
vbc.sz.west_fenster      VenetianBlindController
vbc.wz.sued_fenster      VenetianBlindController
vbc.wz.sued_tuer         VenetianBlindController
vbc.wz.west_fenster      VenetianBlindController
		});
	
	my @device_list = VenetianBlinds::VenetianMasterController::find_devices();
	is(scalar @device_list,5);
	ok("vbc.ku.fenster" ~~ @device_list);
	ok("vbc.sz.west_fenster" ~~ @device_list);
	ok("vbc.wz.sued_fenster" ~~ @device_list);
	
}

sub test_wind_alarm{
	note( (caller(0))[3] );	
	main::reset_mocks();
	main::set_fhem_mock("list .* type",
		"shady1   VenetianBlindController");
	my $hash = {
		"NAME" => "NervousNick",
	};
	add_reading("NervousNick", "wind_speed", 10 );
	add_reading("NervousNick", "wind_alarm", 0 );
	
	my $result = VenetianBlinds::VenetianMasterController::check_wind_alarm($hash);
	ok(!defined $result);
	is(ReadingsVal("NervousNick", "wind_alarm", undef) ,0);
	
	add_reading("NervousNick", "wind_speed", 51 );
	main::set_fhem_mock("set shady1 wind_alarm", undef);
	
	$result = VenetianBlinds::VenetianMasterController::check_wind_alarm($hash);
	ok(!defined $result);
	is(ReadingsVal("NervousNick", "wind_alarm", undef) ,1);
	
	add_reading_time("NervousNick", "wind_speed", 49, time()-700 );
	$result = VenetianBlinds::VenetianMasterController::check_wind_alarm($hash);
	ok(!defined $result);
	is(ReadingsVal("NervousNick", "wind_alarm", undef) ,0);
	
}

sub test_stop_all{
	note( (caller(0))[3] );	
	main::reset_mocks();
	my $hash = {
		"NAME" => "stopper",
	};
	main::set_fhem_mock("list .* type",
		"shady1   VenetianBlindController\nshady2   VenetianBlindController");
	main::set_fhem_mock("set shady1 stop");
	main::set_fhem_mock("set shady2 stop");
	
	VenetianBlinds::VenetianMasterController::stop_all($hash);
}

sub test_send_to_all {
    note( (caller(0))[3] ); 
    main::reset_mocks();
    main::set_fhem_mock("list .* type",
        q{
vbc.ku.fenster           VenetianBlindController
vbc.sz.west_fenster      VenetianBlindController
vbc.wz.sued_fenster      VenetianBlindController
        });
    set_fhem_mock("set vbc.ku.fenster stop",undef);
    set_fhem_mock("set vbc.sz.west_fenster stop",undef);
    set_fhem_mock("set vbc.wz.sued_fenster stop",undef);
    VenetianBlinds::VenetianMasterController::stop_all("test");
    is(scalar( @{get_fhem_history()} ),4);
}

1;
