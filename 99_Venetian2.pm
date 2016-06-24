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
use Switch;
use experimental "smartmatch";

use venetianblinds::VenetianMasterController;
use venetianblinds::VenetianRoomController;
use venetianblinds::VenetianBlindController;

my %valid_types = (
	"master" =>"VenetianMasterController",
	"room" => "VenetianRoomController",
	"blind" => "VenetianBlindController",
	);

sub Venetian_Initialize($) {
    my ($hash) = @_;
    $hash->{DefFn}      = 'Venetian_Define';
    #$hash->{UndefFn}    = 'Venetian_Undef';
    $hash->{SetFn}      = 'Venetian_Set';
    #$hash->{GetFn}      = 'Venetian_Get';
    #$hash->{AttrFn}     = 'Venetian_Attr';
    #$hash->{ReadFn}     = 'Venetian_Read';    
    #$hash->{NotifyFn}     = 'Venetian_Notify';
    $hash->{parseParams} = 1;
    return undef;
}

sub Venetian_Define($$$) {
    my ($hash, $a, $h) = @_;	
	$hash->{type} = $valid_types{$h->{type}};
	if (!defined $hash->{type}) {
		return "Type $hash->{type} is not supported!";
	}

	return vbc_call("Define",$hash, $a, $h);
}

sub Venetian_Set($$$) {	
	my ( $hash, $a,$h ) = @_;
	my $result = undef;
	return vbc_call("Set",$hash, $a, $h);
}

sub vbc_call($$$$){
	my ($func,$hash,$a,$h) = @_;
	$func = "$hash->{type}::$func";
	my $result;
	{
		no strict 'refs';
		$result = &$func($hash, $a, $h);
	}
	return $result;	
}

1;
