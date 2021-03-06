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

use_ok("Venetian");


##############################################################################################
sub test_venetian2(){
	test_Set();
	test_Define_valid();
	test_Define_invalid_type();
	
	done_testing();
}

test_venetian2();

##############################################################################################
sub test_Set() {
	my $hash = {
		"type" => "VenetianBlindController",
	}; 
	my $a = ["somename","?"];
	my $h = {};
	my $answer = Venetian_Set($hash,$a,$h);
	ok($answer =~ /automatic:noArg/);	
}

sub test_Define_valid {
	my $hash = {}; 
	my $a = [];
	my $h = {"type"=>"room"};

	my $answer = Venetian_Define($hash,$a,$h);
	is($answer,undef);
}

sub test_Define_invalid_type {
	my $hash = {}; 
	my $a = [];
	my $h = {"type"=>"xxx"};

	my $answer = Venetian_Define($hash,$a,$h);
	is($answer,"Type xxx is not supported!");
}

1;