##############################################
# 
# This is open source software licensed unter the Apache License 2.0 
# http://www.apache.org/licenses/LICENSE-2.0
#
##############################################

use strict;
use warnings;

package main;

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

sub reset_mocks(){
	%readings = ();
	@fhem_list = ();
	@timer_list = ();
}

sub add_reading($$$){
	my ($device,$reading,$value) = @_;
	$readings{$device}{$reading} = $value;
}


sub readingsSingleUpdate($$$$){
	my ($hash,$reading,$value,$trigger) = @_;
	my $device = $hash->{name};
	ok(defined $device);
	add_reading($device, $reading, $value);
	print("update reading: $device - $reading = '$value'\n");		
}		

sub get_timer_list(){
	return @timer_list;
};

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

