##############################################
#
# This is open source software licensed unter the Apache License 2.0
# http://www.apache.org/licenses/LICENSE-2.0
#
##############################################

package VenetianBlinds::VenetianRoomController;

use v5.10.1;
use strict;
use warnings;
use experimental "smartmatch";
use VenetianBlinds::Shared;


##############################################
sub Define{
    my ($hash,$a,$h) = @_;
}

sub Notify {
    my ($hash, $devName, $events) = @_;
}

sub Set{
    my ($hash,$a,$h) = @_;
    my $cmd = $a->[1];
    my @scene_list = keys %{&VenetianBlinds::Shared::scenes};
    given ($cmd) {
    	when ("?") {
	        my $result = "automatic:noArg stop:noArg"; 
	        foreach my $scene (@scene_list){
	            $result .= " $scene:noArg";
		        }
	        return $result;
        }
        when ("automatic") {
        	VenetianBlinds::Shared::send_to_all_in_my_rooms($hash, "automatic");
        }
        when ("stop"){
            VenetianBlinds::Shared::send_to_all_in_my_rooms($hash, "stop");
        }
        when (@scene_list){
            VenetianBlinds::Shared::send_to_all_in_my_rooms($hash, $cmd);
        }
    }
    return;
}

1;
