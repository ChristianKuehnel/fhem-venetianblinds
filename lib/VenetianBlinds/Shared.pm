##############################################
#
# This is open source software licensed unter the Apache License 2.0
# http://www.apache.org/licenses/LICENSE-2.0
#
##############################################

package VenetianBlinds::Shared;
use v5.14;
use strict;
use warnings;
use experimental "smartmatch";


sub send_to_all{
    my ($cmd) = @_;
    foreach my $device (find_devices()) {
        main::fhem("set $device $cmd");         
    }
}

sub find_devices{
    my $devstr = main::fhem("list .* type");
    my @result = ();
    foreach my $device (split /\n/, $devstr) {
        $device =~ s/^\s+|\s+$//g; # trim white spaces
        if( length($device) > 0){ 
            $device =~ /^(\S+)\s+(\S+)$/;
            my $devname = $1;
            my $model = $2;
            if ($model eq "VenetianBlindController"){
                push(@result,$devname);
            }
        }
    }
    return @result;
    
}


1;