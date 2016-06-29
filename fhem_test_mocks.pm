##############################################
# 
# This is open source software licensed unter the Apache License 2.0 
# http://www.apache.org/licenses/LICENSE-2.0
#
##############################################

use strict;
use warnings;
use experimental "smartmatch";

package main;


# general ################################
my %readings = ();
my %fhem_list = ();
my @fhem_expected_list = ();
my @timer_list = ();

sub reset_mocks(){
	%readings = ();
	%fhem_list = ();
	@timer_list = ();
	@fhem_expected_list = ();
}


# Logging ################################

sub Log{
print "Log: $_[0] , $_[1] \n"; 
}


# fhem command ##########################
sub fhem{
    my ($cmd) = @_;
    ok($cmd ~~ @fhem_expected_list, "fhem $cmd");
    return $fhem_list{$cmd};  
}

sub set_fhem_mock{
	my ($cmd, $return_value) = @_;
	$fhem_list{$cmd} = $return_value;
	push(@fhem_expected_list,$cmd);
}

# Timer ###############################

sub InternalTimer{
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


sub get_timer_list(){
	return @timer_list;
};

# Readings ###############################################

sub ReadingsVal {
    my ($device,$reading,$default) = @_;
    my $value = $readings{$device}{$reading}{value};
    #print "readings $device, $reading, $value \n";
    ok(defined $value,"ReadingsVal $device:$reading");
    return $value;
}

sub ReadingsAge {
    my ($device,$reading,$default) = @_;
    my $time = $readings{$device}{$reading}{timestamp};
    #print "readings $device, $reading, $value \n";
    ok(defined $time,"ReadingsAge $device:$reading");
    return time-$time;
}

sub add_reading{
	my ($device,$reading,$value) = @_;
	add_reading_time($device,$reading,$value,time());
}

sub add_reading_time{
	my ($device,$reading,$value,$timestamp) = @_;
	$readings{$device}{$reading}{value} = $value;
	$readings{$device}{$reading}{timestamp} = $timestamp;
}

sub readingsSingleUpdate{
	my ($hash,$reading,$value,$trigger) = @_;
	my $device = $hash->{name};
	ok(defined $device);
	add_reading($device, $reading, $value);
	print("update reading: $device - $reading = '$value'\n");		
}		


sub readingsBeginUpdate($){
	#not sure how to mock this...
}

sub readingsEndUpdate($){
	#not sure how to mock this...
}

sub readingsBulkUpdate($$$){
	my ($hash, $reading, $value) = @_;
	my $device = $hash->{name};
	ok(defined $device);
	add_reading($device, $reading, $value);
}
1;

