# SmoothWall Express "Header" Module
#
# This code is distributed under the terms of the GPL
#
# (c) 2004-2005 SmoothWall Ltd

package header;
require Exporter;
use Data::Dumper;
@ISA = qw(Exporter);

# define the Exportlists.

our @_validation_items;

@EXPORT       = qw();
@EXPORT_OK    = qw( validdiscription validparser validsite);
%EXPORT_TAGS  = (
      standard   => [@EXPORT_OK],
      );

sub validdiscription
{
	$_ = $_[0];

	if (/^[\w\d\.\-,\(\)\@Â£\$!\%\^\&\*=\+_ ]*$/) {
		return 0 if ( length $_ > 16 );
		return 1;
	}
	return 0;
}


sub validparser
{
	$_ = $_[0];

	if (/^[\w\d\.\-,\(\)\@Â£\$!\%\^\&\*=\+_ ]*$/) {
		return 0 if ( length $_ > 16 );
		return 1;
	}
	return 0;
}

sub validsite
{
	$_ = $_[0];

	if (/^[\w\d\.\-,\(\)\@Â£\$!\%\^\&\*=\+_ ]*$/) {
		return 0 if ( length $_ > 188 );
		return 1;
	}
	return 0;
}

1;
