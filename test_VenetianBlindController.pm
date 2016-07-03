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
 
use VenetianBlindController;

package main;

##############################################################################################
sub test_VenetianBlindController() {
	test_Define();
	test_Set_questionsmark();
	test_move_blinds_no_movement();
	test_move_blinds_up_no_slats();
	test_move_both();
	test_wind_alarm_vbc();
	test_set_scene();
}

##############################################################################################
sub test_Define {
	my $hash = {}; 
	my $a = [];
	my $h = {
		"master" => "mymaster",
		"device" => "mydevice",
		"elevation" => "10-90",
		"azimuth" => "80-190",
		"months" => "5-10",
	};
	VenetianBlindController::Define($hash,$a,$h);
	is($hash->{master_controller},"mymaster");
	is($hash->{device},"mydevice");
	is($hash->{azimuth_start},80);
	is($hash->{azimuth_end},190);
	is($hash->{elevation_start},10);
	is($hash->{elevation_end},90);
}

sub test_Set_questionsmark {
	my $hash = {}; 
	my $a = ["irgendwas","?"];
	my $h = {};
	my $answer = VenetianBlindController::Set($hash,$a,$h);
	ok(defined $answer);
}

sub test_move_blinds_no_movement {
	main::reset_mocks();
	my $hash = {
		"device" => "shadow"
	}; 
	set_fhem_mock("get shadow position","Blind 97 Slat 30");
	add_reading("shadow","position","Blind 97 Slat 30");
	VenetianBlindController::move_blinds($hash,99,undef);	
	ok(!defined $hash->{queue});
}

sub test_move_blinds_up_no_slats {
	main::reset_mocks();
	my $hash = {
		"device" => "shadow"
	};
	set_fhem_mock("get shadow position","Blind 0 Slat 30");
	add_reading("shadow","position","Blind 0 Slat 30");
	add_reading("shadow","power","0W");
	set_fhem_mock("set shadow positionBlinds 99",undef);
	VenetianBlindController::move_blinds($hash,99,undef);	
	ok(!defined $hash->{queue});
	is(scalar @{get_fhem_history()},2);
}


sub test_move_both {
	main::reset_mocks();
	my $hash = {
		"device" => "shadow"
	};
	set_fhem_mock("get shadow position","Blind 0 Slat 30");
	add_reading("shadow","position","Blind 0 Slat 30");
	add_reading("shadow","power","90 W");
	set_fhem_mock("set shadow positionBlinds 50",undef);
	VenetianBlindController::move_blinds($hash,50,50);	
	ok(defined $hash->{queue});
	is(scalar @{get_fhem_history()},2);

	reset_fhem_history();	
	add_reading("shadow","power","90 W");
	trigger_timer();
	ok(defined $hash->{queue});
	is(scalar @{get_fhem_history()},0);
	
	reset_fhem_history();	
	add_reading("shadow","power","0 W");
	set_fhem_mock("set shadow positionSlat 50",undef);
	trigger_timer();
	ok(!defined $hash->{queue});	
}

sub test_wind_alarm_vbc {
	main::reset_mocks();
	my $hash = {
		"device" => "shadow"
	};
	add_reading("shadow","position","Blind 0 Slat 30");
	add_reading("shadow","power","0 W");
	set_fhem_mock("get shadow position","Blind 0 Slat 30");
	set_fhem_mock("set shadow positionBlinds 99",undef);
	VenetianBlindController::wind_alarm($hash);
	is(scalar @{get_fhem_history()},2);	
}

sub test_set_scene {
	main::reset_mocks();
	my $hash = {
		"device" => "shadow"
	};
	add_reading("shadow","position","Blind 0 Slat 30");
	add_reading("shadow","power","0 W");
	set_fhem_mock("get shadow position","Blind 0 Slat 30");
	set_fhem_mock("set shadow positionBlinds 99",undef);
	VenetianBlindController::set_scene($hash,"open");
	is(scalar @{get_fhem_history()},2,join(", ",@{get_fhem_history()}));	

	
}

1;