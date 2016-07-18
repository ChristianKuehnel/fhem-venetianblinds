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

use VenetianBlinds::VenetianBlindController ;

use lib "t"; 
use fhem_test_mocks;

##############################################################################################
sub test_VenetianBlindController {
	test_Define();
	test_Set_questionsmark();
	test_move_blinds_no_movement();
	test_move_blinds_up_no_slats();
	test_move_both();
	test_wind_alarm_vbc();
	test_set_scene();
	test_update_automatic_off();
	test_update_automatic_down();
	test_stop();
	
	done_testing();
}

test_VenetianBlindController();

##############################################################################################
sub test_Define {
	note( "test case: ".(caller(0))[3] );	
	my $hash = {}; 
	my $a = [];
	my $h = {
		"master" => "mymaster",
		"device" => "mydevice",
		"elevation" => "10-90",
		"azimuth" => "80-190",
		"months" => "5-10",
	};
	VenetianBlinds::VenetianBlindController::Define($hash,$a,$h);
	is($hash->{master_controller},"mymaster");
	is($hash->{device},"mydevice");
	is($hash->{azimuth_start},80);
	is($hash->{azimuth_end},190);
	is($hash->{elevation_start},10);
	is($hash->{elevation_end},90);
}

sub test_Set_questionsmark {
	note( "test case: ".(caller(0))[3] );	
	my $hash = {}; 
	my $a = ["irgendwas","?"];
	my $h = {};
	my $answer = VenetianBlinds::VenetianBlindController::Set($hash,$a,$h);
	ok(defined $answer);
}

sub test_move_blinds_no_movement {
	note( "test case: ".(caller(0))[3] );	
	main::reset_mocks();
	my $hash = {
		"NAME" => "mover",
		"device" => "shadow"
	}; 
	set_fhem_mock("get shadow position","Blind 97 Slat 30");
	add_reading("shadow","position","Blind 97 Slat 30");
	add_reading("mover","count_commands","0");
	VenetianBlinds::VenetianBlindController::move_blinds($hash,99,undef);	
	ok(!defined $hash->{queue});
	is(main::ReadingsVal("mover","count_commands",undef),0);
}

sub test_move_blinds_up_no_slats {
	note( "test case: ".(caller(0))[3] );	
	main::reset_mocks();
	my $hash = {
		"NAME" => "mover",
		"device" => "shadow"
	};
	set_fhem_mock("get shadow position","Blind 0 Slat 30");
	add_reading("shadow","position","Blind 0 Slat 30");
	add_reading("shadow","power","0W");
	add_reading("mover","command_count","0");
	set_fhem_mock("set shadow positionBlinds 99",undef);

	VenetianBlinds::VenetianBlindController::move_blinds($hash,99,undef);	

	ok(!defined $hash->{queue});
	is(scalar @{get_fhem_history()},2);
	is(main::ReadingsVal("mover","command_count",undef),1);
}


sub test_move_both {
	note( "test case: ".(caller(0))[3] );	
	main::reset_mocks();
	my $hash = {
		"NAME" => "mover",
		"device" => "shadow"
	};
	set_fhem_mock("get shadow position","Blind 0 Slat 30");
	add_reading("shadow","position","Blind 0 Slat 30");
	add_reading("shadow","power","90 W");
	set_fhem_mock("set shadow positionBlinds 50",undef);
	add_reading("mover","command_count","0");
	VenetianBlinds::VenetianBlindController::move_blinds($hash,50,50);	
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
	is(main::ReadingsVal("mover","command_count",undef),2);
}

sub test_wind_alarm_vbc {
	note( "test case: ".(caller(0))[3] );	
	main::reset_mocks();
	my $hash = {
		"NAME" => "some_random_name",
		"device" => "shadow"
	};
	add_reading("shadow","position","Blind 0 Slat 30");
	add_reading("shadow","power","0 W");
	set_fhem_mock("get shadow position","Blind 0 Slat 30");
	set_fhem_mock("set shadow positionBlinds 99",undef);
	VenetianBlinds::VenetianBlindController::wind_alarm($hash);
	is(scalar @{get_fhem_history()},2);	
}

sub test_set_scene {
	note( "test case: ".(caller(0))[3] );	
	main::reset_mocks();
	my $hash = {
		"device" => "shadow",
		"NAME" => "my_name",
	};
	add_reading("shadow","position","Blind 0 Slat 30");
	add_reading("shadow","power","0 W");
	add_reading($hash->{NAME},"scene","closed");
	add_reading($hash->{NAME},"automatic",1);
	
	set_fhem_mock("get shadow position","Blind 0 Slat 30");
	set_fhem_mock("set shadow positionBlinds 99",undef);

	VenetianBlinds::VenetianBlindController::set_scene($hash,"open");

	is(scalar @{get_fhem_history()},2,join(", ",@{get_fhem_history()}));		
	is(main::ReadingsVal("my_name","command_count",undef),1);
}

sub test_update_automatic_off {
	note( "test case: ".(caller(0))[3] );	
	main::reset_mocks();
	my $newScene = undef;
	my $master = "YourGrace";
	
    my $module = Test::MockModule->new('VenetianBlinds::VenetianBlindController');
    $module->mock(set_scene => sub { 
		my ($hash,$scene,$force) = @_;
        $newScene = $scene; });
	my $hash = {
		"device" => "test_update_automatic_off",
		"master_controller" => $master,
		"NAME" => "vbc",
	};
	add_reading($master, "sun_elevation", 40);
	add_reading($master, "sun_azimuth", 60);
	add_reading($master, "wind_speed", 5);
	add_reading($master, "wind_alarm", undef);
	add_reading($master, "cloud_index", 1);
	add_reading($master, "month", 7);
	add_reading($hash->{NAME}, "automatic", 0);
  	VenetianBlinds::VenetianBlindController::update_automatic($hash,0);              
}

sub test_update_automatic_down {
	note( "test case: ".(caller(0))[3] );	
	main::reset_mocks();
	my $newScene = undef;
	my $master = "YourGrace";
	
    my $module = Test::MockModule->new('VenetianBlinds::VenetianBlindController');
    $module->mock(set_scene => sub { 
		my ($hash,$scene,$force) = @_;
        $newScene = $scene; 
	  	add_reading("its_me","scene",$newScene);          
	});
	
	my $hash = {
		"NAME" => "its_me",
		"device" => "shadow2",
		"master_controller" => $master,
		"could_index_threshold" => 4,
		"azimuth_start" => 10,
		"azimuth_end" => 90,
		"elevation_start" => 5,
		"elevation_end" => 80,
		"month_start" => 5,
		"month_end" => 10,
	};
	add_reading($master, "sun_elevation", 40);
	add_reading($master, "sun_azimuth", 50);
	add_reading($master, "wind_speed", 5);
	add_reading($master, "wind_alarm", 0);
	add_reading($master, "cloud_index", 4);
	add_reading($master, "month", 3);
	add_reading($hash->{NAME}, "automatic", 1);
	add_reading($hash->{NAME}, "scene", "closed");
  	VenetianBlinds::VenetianBlindController::update_automatic($hash,0);
  	is($newScene,undef);          

	$newScene = undef;
	add_reading($master, "month", 7);
  	VenetianBlinds::VenetianBlindController::update_automatic($hash,0);
  	is($newScene,"shaded");          

	$newScene = undef;
	add_reading($master, "cloud_index", 7);
  	VenetianBlinds::VenetianBlindController::update_automatic($hash,0);
  	is($newScene,"open");          
	add_reading($master, "cloud_index", 5);
	
	$newScene = undef;
	add_reading($hash->{NAME},"scene","closed");
	add_reading($master, "sun_elevation", 3);
  	VenetianBlinds::VenetianBlindController::update_automatic($hash,0);
  	is($newScene,"open");          	

	$newScene = undef;
	add_reading($master, "sun_elevation", 100);
  	VenetianBlinds::VenetianBlindController::update_automatic($hash,1);
  	is($newScene,"open");          	
	add_reading($master, "sun_elevation", 50);

	$newScene = undef;
	add_reading($master, "cloud_index", 5);
  	VenetianBlinds::VenetianBlindController::update_automatic($hash,1);
  	is($newScene,"open");          
	add_reading($master, "cloud_index", 2);

	$newScene = undef;
	add_reading($master, "sun_azimuth", 3);
  	VenetianBlinds::VenetianBlindController::update_automatic($hash,1);
  	is($newScene,"open");          

	$newScene = undef;
	add_reading($master, "sun_azimuth", 120);
  	VenetianBlinds::VenetianBlindController::update_automatic($hash,1);
  	is($newScene,"open");          
	add_reading($master, "sun_azimuth", 60);

	$newScene = undef;
	VenetianBlinds::VenetianBlindController::update_automatic($hash,0);
  	is($newScene,"shaded");          

	#repeast same command -> do not move anything
	$newScene = undef;
	VenetianBlinds::VenetianBlindController::update_automatic($hash,0);
  	is(ReadingsVal($hash->{NAME},"scene",undef),"shaded");          
  	is($newScene,undef);          

	$newScene = undef;
	add_reading($master, "wind_alarm", 1);
	VenetianBlinds::VenetianBlindController::update_automatic($hash,0);
  	is($newScene,undef);          
	add_reading($master, "wind_alarm", 0);

	$newScene = undef;
	add_reading($hash->{NAME}, "automatic", 0);
	VenetianBlinds::VenetianBlindController::update_automatic($hash,0);
  	is($newScene,undef);          
	add_reading($hash->{NAME}, "automatic", 1);
}

sub test_stop {
	note( "test stop: ".(caller(0))[3] );	
	main::reset_mocks();
	my $hash = {
		"NAME" => "its_me",
		"device" => "shadow2",
		"queue" => "some command",
	};
	set_fhem_mock("set shadow2 stop",undef);

	VenetianBlinds::VenetianBlindController::stop($hash);
	ok(!defined $hash->{queue});
	is(main::ReadingsVal("its_me","command_count",undef),1);
	
}

1;