#!/usr/bin/perl -w

##############################################
#
# This is open source software licensed unter the Apache License 2.0
# http://www.apache.org/licenses/LICENSE-2.0
#
##############################################

use strict;
use warnings;
use Module::Load;
use v5.10.1;
use experimental "smartmatch";
use Test::More;
use Time::HiRes "gettimeofday";
 
use VenetianBlindController;

##############################################################################################
sub main() {
	test_Define();
	test_Set_questionsmark();

	done_testing();
}

exit main();

##############################################################################################
sub test_Define() {
	my $hash = {}; 
	my $a = [];
	my $h = {
		"master" => "mymaster",
		"device" => "mydevice",
	};
	VenetianBlindController::Define($hash,$a,$h);
	is($hash->{master_controller},"mymaster");
	is($hash->{device},"mydevice");
}

sub test_Set_questionsmark() {
	my $hash = {}; 
	my $a = ["irgendwas","?"];
	my $h = {};
	my $answer = VenetianBlindController::Set($hash,$a,$h);
	ok(defined $answer);
}
