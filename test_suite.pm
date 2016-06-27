use strict;
use warnings;
use Module::Load;
use Test::More;

load "test_venetian2";
use test_VenetianBlindController;
use test_VenetianMasterController;

test_venetian2();
test_VenetianBlindController();
test_VenetianMasterController();

print "Done.\n";
done_testing();

1;