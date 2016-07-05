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
use Test::MockModule;
 
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
	test_update_automatic_off();
	test_update_automatic_down();
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

sub test_update_automatic_off {
	my $newScene = undef;
	my $master = "YourGrace";
	
    my $module = Test::MockModule->new('VenetianBlindController');
    $module->mock('set_scene', sub { 
		my ($hash,$scene,$force) = @_;
        $newScene = $scene; });
	my $hash = {
		"device" => "shadow",
		"master_controller" => $master,
		"automatic" => 0,
	};
	add_reading($master, "sun_elevation", 40);
	add_reading($master, "sun_azimuth", 60);
	add_reading($master, "wind_speed", 5);
	add_reading($master, "wind_alarm", "");
	add_reading($master, "cloud_index", 1);
	add_reading($master, "month", 7);
  	VenetianBlindController::update_automatic($hash);              
}

sub test_update_automatic_down {
	my $newScene = undef;
	my $master = "YourGrace";
	
    my $module = Test::MockModule->new('VenetianBlindController');
    $module->mock('set_scene', sub { 
		my ($hash,$scene,$force) = @_;
        $newScene = $scene; 
	  	$hash->{scene}=$newScene;          
    });
	my $hash = {
		"device" => "shadow",
		"master_controller" => $master,
		"automatic" => 1,
		"could_index_threshold" => 4,
		"azimuth_start" => 10,
		"azimuth_end" => 90,
		"elevation_start" => 5,
		"elevation_end" => 80,
		"month_start" => 5,
		"month_end" => 10,
		"scene" => undef,
	};
	add_reading($master, "sun_elevation", 40);
	add_reading($master, "sun_azimuth", 50);
	add_reading($master, "wind_speed", 5);
	add_reading($master, "wind_alarm", 0);
	add_reading($master, "cloud_index", 4);
	add_reading($master, "month", 3);
  	VenetianBlindController::update_automatic($hash,0);
  	is($newScene,undef);          

	$newScene = undef;
	add_reading($master, "month", 7);
  	VenetianBlindController::update_automatic($hash,0);
  	is($newScene,"shaded");          

	$newScene = undef;
	add_reading($master, "cloud_index", 7);
  	VenetianBlindController::update_automatic($hash,0);
  	is($newScene,"open");          
	add_reading($master, "cloud_index", 5);
	
	$newScene = undef;
	$hash->{scene} = "closed";
	add_reading($master, "sun_elevation", 3);
  	VenetianBlindController::update_automatic($hash,0);
  	is($newScene,"open");          	

	$newScene = undef;
	add_reading($master, "sun_elevation", 100);
  	VenetianBlindController::update_automatic($hash,1);
  	is($newScene,"open");          	
	add_reading($master, "sun_elevation", 50);

	$newScene = undef;
	add_reading($master, "cloud_index", 5);
  	VenetianBlindController::update_automatic($hash,1);
  	is($newScene,"open");          
	add_reading($master, "cloud_index", 2);

	$newScene = undef;
	add_reading($master, "sun_azimuth", 3);
  	VenetianBlindController::update_automatic($hash,1);
  	is($newScene,"open");          

	$newScene = undef;
	add_reading($master, "sun_azimuth", 120);
  	VenetianBlindController::update_automatic($hash,1);
  	is($newScene,"open");          
	add_reading($master, "sun_azimuth", 60);

	$newScene = undef;
	VenetianBlindController::update_automatic($hash,0);
  	is($newScene,"shaded");          

	#repeast same command -> do not move anything
	$newScene = undef;
	VenetianBlindController::update_automatic($hash,0);
  	is($hash->{scene},"shaded");          
  	is($newScene,undef);          

	$newScene = undef;
	add_reading($master, "wind_alarm", 1);
	VenetianBlindController::update_automatic($hash,0);
  	is($newScene,undef);          
	add_reading($master, "wind_alarm", 0);

	$newScene = undef;
	$hash->{automatic} = 0;
	VenetianBlindController::update_automatic($hash,0);
  	is($newScene,undef);          
	$hash->{automatic} = 1;


}

1;