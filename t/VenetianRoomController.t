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

use VenetianBlinds::VenetianRoomController ;

use lib "t"; 
use fhem_test_mocks;

##############################################################################################
sub test_suite {
    test_Set_questionsmark();	
    test_Set_scene();   
    
	done_testing();
}

test_suite();

##############################################################################################

sub test_Set_questionsmark{
    note( "test case: ".(caller(0))[3] );   
    main::reset_mocks();
    my $hash = {}; 
    my $a = ["irgendwas","?"];
    my $h = {};

    my $answer = VenetianBlinds::VenetianRoomController::Set($hash,$a,$h);

    ok(defined $answer,$answer);
    ok($answer =~ /automatic:noArg/);
    ok($answer =~ /shaded:noArg/);
    	
}

sub test_Set_scene {
    note( "test case: ".(caller(0))[3] );   
    main::reset_mocks();
    my $hash = {
    	"NAME" => "roomy",
    }; 
    my $a = ["irgendwas","open"];
    my $h = {};
    my $module = Test::MockModule->new('VenetianBlinds::Shared');
    $module->mock(find_devices => sub{ return qw(dev1 dev2 dev3) });
    
    set_attr("roomy","room","kitchen,living");
    set_attr("dev1","room","here,kitchen");
    set_attr("dev2","room","living,other");
    set_attr("dev3","room","somewhere");
    
    set_fhem_mock("set dev1 open");
    set_fhem_mock("set dev2 open");
    VenetianBlinds::VenetianRoomController::Set($hash,$a,$h);
    is(scalar @{get_fhem_history()},2,join(", ",@{get_fhem_history()}));        
	
}   


1;