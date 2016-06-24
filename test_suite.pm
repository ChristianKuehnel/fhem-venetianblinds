use strict;
use warnings;
use Module::Load;
use Test::More;

load "test_venetian2";
use test_VenetianBlindController;

test_venetian2();
test_VenetianBlindController();

print "Done.\n";
done_testing();

1;