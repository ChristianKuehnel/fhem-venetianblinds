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

sub send_to_all_in_room{
    my ($cmd,$room) = @_;
    foreach my $device (find_devices_in_room($room)) {
        main::fhem("set $device $cmd");         
    }
}

sub find_devices_in_room {
    my ($my_room) = @_;
    my @result = ();
    foreach my $device (find_devices()){
    	my $rooms = main::AttrVal($device,"room",undef);
    	foreach my $room (split(/,/, $rooms)){
    		if ($my_room eq $room){
    			push(@result,$device);
    		}
    	}
    }	
    return @result;
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