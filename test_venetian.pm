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
 
load "99_Rolladensteuerung.pm";
##############################################################################################
my %readings = ();
my @fhem_list = ();
my @timer_list = ();

sub ReadingsVal($$$) {
    my ($device,$reading,$default) = @_;
    my $value = $readings{$device}{$reading};
    #print "readings $device, $reading, $value \n";
    ok(defined $value,"ReadingsVal $device:$reading");
    return $value;
}

sub Log($$){
print "Log: $_[0] , $_[1] \n"; 
}

sub fhem($){
    my ($cmd) = @_;
    push(@fhem_list, $cmd);
}

sub InternalTimer($$$$){
	my ($time,$func,$param,$init) = @_;
	push(@timer_list, {
		"timer" => $time,
		"func" => $func,
		"param" => $param,
		"init" => $init,	
	});
	ok(scalar @timer_list > 0);
}

sub trigger_timer(){
	my $timer = undef;
	ok(scalar @timer_list > 0);
	my @oldtimers = @timer_list;
	@timer_list = ();
	foreach $timer (@oldtimers){
	    no strict "refs";
	    &{$timer->{func}}($timer->{param});
	    use strict "refs";	}
}

##############################################################################################
sub main() {
	test_Set();
	test_get_position();
	test_get_power();
	test_process_queue();
	test_Set_nochange();
	
	done_testing();
}

exit main();

sub cleanup() {
	%readings = ();
	@fhem_list = ();
	@timer_list = ();
}

##############################################################################################
sub test_Set() {
	cleanup();
	my $hash = {}; 
	my @cmd = split / /, "rolladen move west offen";
	$readings{"wz.west_fenster"}{position} = "Blind 1 Slat 50";
	$readings{"wz.west_fenster"}{power} = "0.0 W";
	$hash->{"side_west"} = "irgendwas";
	@fhem_list = ();

	is(Rolladensteuerung_Set($hash,@cmd), undef);
	ok("set wz.west_fenster positionBlinds 99" ~~ @fhem_list) ;
	ok("get wz.west_fenster position" ~~ @fhem_list) ;
	is(scalar(@fhem_list),2);
	is($hash->{"side_west"},"offen");
	@fhem_list = ();

	$readings{"wz.west_fenster"}{position} = "Blind 99 Slat 50";
	trigger_timer();
	ok("get wz.west_fenster position" ~~ @fhem_list) ;
	ok("set wz.west_fenster positionSlat 99" ~~ @fhem_list);
	is(scalar(@fhem_list),2);
	print "$_\n" for @fhem_list;
}

##############################################################################################
sub test_Set_nochange() {
	cleanup();
	my $hash = {}; 
	my @cmd = split / /, "rolladen move west offen";
	$readings{"wz.west_fenster"}{position} = "Blind 1 Slat 50";
	$readings{"wz.west_fenster"}{power} = "0.0 W";
	$hash->{"side_west"} = "offen";
	@fhem_list = ();

	is(Rolladensteuerung_Set($hash,@cmd), undef);
	is(scalar(@fhem_list),0);
	is($hash->{"side_west"},"offen");
}

##############################################################################################
sub test_process_queue() {
	cleanup();	
	my $hash = {};
	my $device = "das_ding";
	
	$readings{$device}{power} = "83.9 W";
	$readings{$device}{position} = "Blind 99 Slat 99";

	Rolladensteuerung::add_command($hash,$device,0,0);
	is(scalar( keys %{ $hash->{queue}}),1);
	
	Rolladensteuerung::process_command_queue($hash);
	is(scalar @fhem_list,0);
	is(scalar( keys %{$hash->{queue}}),1);

	trigger_timer();
	is(scalar @fhem_list,0);
	is(scalar( keys %{$hash->{queue}}),1);

	$readings{$device}{power} = "0.0 W";
	trigger_timer();
	ok("set $device positionBlinds 0" ~~@fhem_list);
	is(scalar @fhem_list, 2);
	is(scalar( keys %{$hash->{queue}}),1);
	
	@fhem_list = ();
	$readings{$device}{position} = "Blind 3 Slat 99";
	trigger_timer();
	ok("set $device positionSlat 0" ~~@fhem_list);
	is(scalar @fhem_list, 2);
	ok("get $device position" ~~ @fhem_list) ;
	is(scalar( keys %{$hash->{queue}}),1);
}

##############################################################################################
sub test_get_position(){
	cleanup();	
	my $hash = {};
	my $device = "da_hinten";
	$readings{$device}{position} = "Blind 1 Slat 50";
	my ($blinds,$slats) = Rolladensteuerung::get_position($device);
	is($blinds,1);
	is($slats,50);
	
}

##############################################################################################
sub test_get_power(){
	cleanup();	
	my $hash = {};
	my $device = "das_ding";
	$readings{$device}{power} = "90.2 W";
	is(Rolladensteuerung::get_power($device), 90.2);
	
}
