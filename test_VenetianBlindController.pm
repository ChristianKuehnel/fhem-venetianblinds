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
}

##############################################################################################
sub test_Define() {
	my $hash = {}; 
	my $a = [];
	my $h = {
		"master" => "mymaster",
		"device" => "mydevice",
		"elevation" => "10-90",
		"azimuth" => "80-190",
	};
	VenetianBlindController::Define($hash,$a,$h);
	is($hash->{master_controller},"mymaster");
	is($hash->{device},"mydevice");
	is($hash->{azimuth_start},80);
	is($hash->{azimuth_end},190);
	is($hash->{elevation_start},10);
	is($hash->{elevation_end},90);
}

sub test_Set_questionsmark() {
	my $hash = {}; 
	my $a = ["irgendwas","?"];
	my $h = {};
	my $answer = VenetianBlindController::Set($hash,$a,$h);
	ok(defined $answer);
}

1;