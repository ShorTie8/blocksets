# SmoothWall Express "Types" Module
#
# This code is distributed under the terms of the GPL
#
# (c) 2004-2007 SmoothWall Ltd

package smoothtype;
require Exporter;
@ISA = qw(Exporter);

use header qw(:standard);

# define the Exportlists.

@EXPORT       = qw();
@EXPORT_OK    = qw( validdiscription validparser validsite);

%EXPORT_TAGS  = (
	standard   => [@EXPORT_OK],
	);

sub jsvaliddiscription
{
	my ( $id, $blank ) = @_;
	$blank = 'false' if ( not defined $blank or $blank ne "true" );
	my $ret = &script("validdiscription('$id','$blank')");
	push @_validation_items, "validdiscription('$id','$blank')";
	return $ret;
}

sub jsvalidparser
{
	my ( $id, $blank ) = @_;
	$blank = 'false' if ( not defined $blank or $blank ne "true" );
	my $ret = &script("validparser('$id','$blank')");
	push @_validation_items, "validparser('$id','$blank')" ;
	return $ret;
}

sub jsvalidsite
{
	my ( $id, $blank ) = @_;
	$blank = 'false' if ( not defined $blank or $blank ne "true" );
	my $ret = &script("validsite('$id', $blank)");
	push @_validation_items, "validsite('$id',$blank)" ;
	return $ret;
}

1;
