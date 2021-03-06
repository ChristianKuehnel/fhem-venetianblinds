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
    test_Set_questionsmark();
	test_define();
	test_update_calendar();
	test_update_twilight();
	test_update_weather();
	test_wind_alarm();
	test_stop_all();
    test_automatic_all();
	test_define_errors();
	
	done_testing();	
}

test_VenetianMasterController();

##############################################################################################


sub test_Set_questionsmark{
    note( "test case: ".(caller(0))[3] );   
    main::reset_mocks();
    my $hash = {}; 
    my $a = ["irgendwas","?"];
    my $h = {};

    my $answer = VenetianBlinds::VenetianMasterController::Set($hash,$a,$h);

    ok(defined $answer,$answer);
    ok($answer =~ /automatic:noArg/);
    ok($answer =~ /stop:noArg/);
        
}

sub test_define{
    note( (caller(0))[3] ); 
    main::reset_mocks();
	
    my $hash = {};
    my $a = {};
    my $h = {
    "twilight" => "TWILIGHT",
    "weather" => "WEATHER",
    "wind_speed_threshold" => 50,
    };
	my $answer = VenetianBlinds::VenetianMasterController::Define($hash,$a,$h);
	
	is($answer,undef);
	is($hash->{twilight},"TWILIGHT");
    is($hash->{weather},"WEATHER");
    is($hash->{wind_speed_threshold},50);	
}

sub test_define_errors{
    note( (caller(0))[3] ); 
    main::reset_mocks();
	
    my $hash = {};
    my $a = {};
    my $h = {};
	
	my $answer = VenetianBlinds::VenetianMasterController::Define($hash,$a,$h);
	is($answer,"Mandatory argument 'twilight=<name>' is missing or undefined");
	
	$h->{twilight} = "some_name";
	$answer = VenetianBlinds::VenetianMasterController::Define($hash,$a,$h);
	is($answer,"Mandatory argument 'weather=<name>' is missing or undefined");
	
	$h->{weather} = "some_name";
	$answer = VenetianBlinds::VenetianMasterController::Define($hash,$a,$h);
	is($answer,"Mandatory argument 'wind_speed_threshold=<value>' is missing or undefined");
	
	$h->{wind_speed_threshold} = "60";
	$answer = VenetianBlinds::VenetianMasterController::Define($hash,$a,$h);
	is($answer,undef);
}

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

sub test_wind_alarm{
	note( (caller(0))[3] );	
	main::reset_mocks();
	main::set_fhem_mock("list .* type",
		"shady1   VenetianBlindController");
	my $hash = {
		"NAME" => "NervousNick",
		"wind_speed_threshold" => 50,
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
	
	VenetianBlinds::VenetianMasterController::Set($hash,["stopper","stop"]);
    is(scalar @{get_fhem_history()},3,join(", ",@{get_fhem_history()}));        
}

sub test_automatic_all{
    note( (caller(0))[3] ); 
    main::reset_mocks();
    my $hash = {
        "NAME" => "stopper",
    };
    main::set_fhem_mock("list .* type",
        "shady1   VenetianBlindController\nshady2   VenetianBlindController");
    main::set_fhem_mock("set shady1 automatic");
    main::set_fhem_mock("set shady2 automatic");
    
    VenetianBlinds::VenetianMasterController::Set($hash,["stopper","automatic"]);
    is(scalar @{get_fhem_history()},3,join(", ",@{get_fhem_history()}));        
}

1;
