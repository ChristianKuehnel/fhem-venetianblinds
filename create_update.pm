#!/usr/bin/perl

use warnings;
use strict;
use File::Basename;
use File::Spec::Functions 'catfile';
use File::Find;
use Date::Format;
use File::Copy;
 use File::Path "make_path";

my $update_root = catfile(dirname($0),"update");
my $fhem_root = catfile($update_root,"FHEM");
my $output_file = catfile($update_root,"control_venetian.txt");
my $source_root = catfile(dirname($0),"lib");

print("source root directory: $source_root\n");
print("update root directory: $update_root\n");

copy(   catfile($source_root, "Venetian.pm"),
        catfile($fhem_root  , "99_Venetian.pm"));

if (!-d catfile($fhem_root,"lib/VenetianBlinds")){
	make_path(catfile($fhem_root,"lib/VenetianBlinds"));
}

for my $file ( glob(catfile($source_root,"VenetianBlinds/*.pm")) ) {
	copy($file, catfile($fhem_root,"lib/VenetianBlinds"));
};

my @dirs = ();
my @files= ();

sub wanted(){
	if (-d $File::Find::name){
        push @dirs, $File::Find::name;
	} else {
        push @files, $File::Find::name;
	}
}


find(\&wanted,$fhem_root);

open(my $fh, ">", $output_file) or die "Could not open file '$output_file' $!";

foreach my $dir (sort(@dirs)) {
	print $fh "DIR $dir\n";
}

foreach my $file (sort(@files)){
	my @stat = stat($file);
	my $date = time2str("%Y-%m-%d_%H:%M:%S", $stat[9]);
	my $size = $stat[7];
	print $fh "UPD $date $size $file\n";
	
}

close($fh);