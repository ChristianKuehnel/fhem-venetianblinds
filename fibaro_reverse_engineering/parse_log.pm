#!/usr/bin/perl -w

use strict;
use warnings;

sub main() {
	my $filename = 'fhem-2016-06.log';
	open(my $fh, '<:encoding(UTF-8)', $filename)
	  or die "Could not open file '$filename' $!";
	 
	while (my $row = <$fh>) {
	  chomp $row;
	  process($row);
	}
}

sub process($){
	my ($row) = @_;
	$row =~ /ZWDongle_0 dispatch (.*)/;
	if (defined $1) {
		process_dispatch($1);
	}
}


sub process_dispatch($){
	my ($message) = @_;
	my $hex2 = "[0-9a-f]{2}";
	my $hex4 = "[0-9a-f]{4}";
	if ($message eq "011301" ){
		print "probably ACK ($message)\n";
	} elsif ( $message =~ /^000400($hex2)0891010f260303($hex2)($hex2)$/) {
		print "position $1: ".hex($2)." - ".hex($3)." ($message)\n";
	} elsif ($message =~/^000400($hex2)0631050422($hex4)$/){
		print "power $1: ".(hex($2)/10)."W ($message)\n";
	} elsif ($message =~ /^0013($hex2)00($hex4)$/) {
		print "counter ".hex($1)." - ".hex($2)." ($message)\n";
	} else {
		print "-- UNKNOWN: \"$message\"\n";
		
	}
}

exit main();