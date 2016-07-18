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

sub Define{
    my ($hash,$a,$h) = @_;
    $hash->{master_controller} = $h->{master};

}


1;
