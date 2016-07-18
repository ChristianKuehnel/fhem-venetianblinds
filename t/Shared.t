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
    main::set_fhem_mock("list .* type",
        q{
vbc.ku.fenster           VenetianBlindController
vbc.sz.west_fenster      VenetianBlindController
vbc.wz.sued_fenster      VenetianBlindController
vbc.wz.west_fenster      VenetianBlindController
        });

    set_attr("vbc.ku.fenster","room","kitchen");
    set_attr("vbc.sz.west_fenster","room","bathroom");
    set_attr("vbc.wz.sued_fenster","room","kitchen,somethingelse");
    set_attr("vbc.wz.west_fenster","room","daroom,kitchen,moreroom");
    my @device_list = VenetianBlinds::Shared::find_devices_in_room("kitchen");
    is(scalar @device_list,3, join(" ",@device_list));
    ok("vbc.ku.fenster" ~~ @device_list);
    ok("vbc.wz.sued_fenster" ~~ @device_list);
    ok("vbc.wz.west_fenster" ~~ @device_list);
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