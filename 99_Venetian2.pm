##############################################
#
# This is open source software licensed unter the Apache License 2.0
# http://www.apache.org/licenses/LICENSE-2.0
#
##############################################

use v5.10.1;
use strict;
use warnings;
use POSIX;
use experimental "smartmatch";


use venetianblinds::VenetianMasterController;
use venetianblinds::VenetianRoomController;
use venetianblinds::VenetianBlindController;

package main;

my %valid_types = (
	"master" =>"VenetianMasterController",
	"room" => "VenetianRoomController",
	"blind" => "VenetianBlindController",
	);

sub Venetian_Initialize {
    my ($hash) = @_;
    $hash->{DefFn}      = 'Venetian_Define';
    #$hash->{UndefFn}    = 'Venetian_Undef';
    $hash->{SetFn}      = 'Venetian_Set';
    #$hash->{GetFn}      = 'Venetian_Get';
    #$hash->{AttrFn}     = 'Venetian_Attr';
    #$hash->{ReadFn}     = 'Venetian_Read';    
    $hash->{NotifyFn}     = 'Venetian_Notify';
    $hash->{parseParams} = 1;
    return;
}

sub Venetian_Define {
    my ($hash, $a, $h) = @_;	
	$hash->{type} = $valid_types{$h->{type}};
	if (!defined $hash->{type}) {
		return "Type $hash->{type} is not supported!";
	}

	return vbc_call("Define",$hash, $a, $h);
}

sub Venetian_Set {	
	my ( $hash, $a,$h ) = @_;
	my $result = undef;
	return vbc_call("Set",$hash, $a, $h);
}


sub Venetian_Notify {	
    my ($own_hash, $dev_hash) = @_;
    my $ownName = $own_hash->{NAME}; # own name / hash	
	return "" if(IsDisabled($ownName)); # Return without any further action if the module is disabled
	
    my $devName = $dev_hash->{NAME}; # Device that created the events
    my $events = main::deviceEvents($dev_hash,0);
    return if( !$events );
    
	return vbc_call("Notify",$own_hash, $devName, $events);
}

sub vbc_call{
	my ($func,$hash,$a,$h) = @_;
	$func = "$hash->{type}::$func";
	my $result;
	{
		## no critic (ProhibitNoStrict)
		no strict 'refs';
		$result = &$func($hash, $a, $h);
		## use critic
	}
	return $result;	
}

1;
