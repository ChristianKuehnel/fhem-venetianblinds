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
use VenetianBlinds::Shared;

use lib "t"; 
use fhem_test_mocks;


##############################################################################################
sub test_Shared {
    test_find_devices();
    test_send_to_all();
    test_find_devices_in_room();
    test_send_to_all_in_room();
    
    done_testing(); 
}

test_Shared();


##############################################################################################

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
    
    my @device_list = VenetianBlinds::Shared::find_devices();
    is(scalar @device_list,5);
    ok("vbc.ku.fenster" ~~ @device_list);
    ok("vbc.sz.west_fenster" ~~ @device_list);
    ok("vbc.wz.sued_fenster" ~~ @device_list);
    
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
    set_fhem_mock("set vbc.ku.fenster test",undef);
    set_fhem_mock("set vbc.sz.west_fenster test",undef);
    set_fhem_mock("set vbc.wz.sued_fenster test",undef);
    VenetianBlinds::Shared::send_to_all("test");
    is(scalar( @{get_fhem_history()} ),4);
}


sub test_find_devices_in_room{
    note( (caller(0))[3] ); 
    main::reset_mocks();
    my $module = Test::MockModule->new('VenetianBlinds::Shared');
    $module->mock(find_devices => sub{ return qw(dev1 dev2 dev3 dev4 dev5)} );

    set_attr("dev1","room","kitchen");
    set_attr("dev2","room","bathroom");
    set_attr("dev3","room","kitchen,somethingelse");
    set_attr("dev4","room","daroom,kitchen,moreroom");
    set_attr("dev5","room","daroom,kitchen");
    my @device_list = VenetianBlinds::Shared::find_devices_in_room("kitchen");
    is(scalar @device_list,4, join(" ",@device_list));
    ok("dev1" ~~ @device_list);
    ok("dev3" ~~ @device_list);
    ok("dev4" ~~ @device_list);
    ok("dev5" ~~ @device_list);
}

sub test_send_to_all_in_room {
    note( (caller(0))[3] ); 
    main::reset_mocks();
    main::set_fhem_mock("list .* type",
        q{
vbc.ku.fenster           VenetianBlindController
vbc.sz.west_fenster      VenetianBlindController
        });

    set_attr("vbc.ku.fenster","room","kitchen");
    set_attr("vbc.sz.west_fenster","room","bathroom");
    main::set_fhem_mock("set vbc.ku.fenster test");
    VenetianBlinds::Shared::send_to_all_in_room("kitchen","test");
	
}

1;