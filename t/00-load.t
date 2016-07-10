#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 4;

BEGIN {
    use_ok( 'Venetian' ) || print "Bail out!\n";
    use_ok( 'VenetianBlinds::VenetianBlindController' ) || print "Bail out!\n";
    use_ok( 'VenetianBlinds::VenetianRoomController' ) || print "Bail out!\n";
    use_ok( 'VenetianBlinds::VenetianMasterController' ) || print "Bail out!\n";
}
