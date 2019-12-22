#!/usr/bin/perl
#
# SmoothWall CGIs
#
# This code is distributed under the terms of the GPL

# sites file format
# Description,Parser,ENABLE,Site

use lib "/usr/lib/smoothwall";
use header qw( :standard );
use smoothd qw( message );
use smoothtype qw(:standard);
use strict;
use warnings;

my (%blocksetssettings, %cgiparams, %selected, %checked, @service);
#my $filename = "${swroot}/mod/blocksets/settings";
my $filename = "${swroot}/mod/blocksets/sites";

my $refresh = '';
my $errormessage = '';
my $infomessage = '';

#$cgiparams{'ENABLED'} = 'off';
#&readhash("${swroot}/mod/blocksets/settings", \%cgiparams);
#$blocksetssettings{'ENABLED'} = 'off';
#&readhash("${swroot}/mod/blocksets/settings", \%blocksetssettings);

&showhttpheaders();

$cgiparams{'ACTION'} = '';

# ENABLED is from settings
# ENABLE  is from/for sites file
$cgiparams{'ENABLED'} = 'on';
$cgiparams{'ENABLE'} = 'off';
$cgiparams{'DESCRIP'} = '';
$cgiparams{'PARSER'} = '';
$cgiparams{'SITE'} = '';

$cgiparams{'COLUMN'} = 1;
$cgiparams{'ORDER'} = $tr{'log ascending'};

&getcgihash(\%cgiparams);
#&readhash("${swroot}/mod/blocksets/sites", \%cgiparams);

if ($ENV{'QUERY_STRING'} && $cgiparams{'ACTION'} eq "" ) {
	my @temp = split(',',$ENV{'QUERY_STRING'});
	$cgiparams{'ORDER'}  = $temp[1] if ( defined $temp[ 1 ] and $temp[ 1 ] ne "" );
	$cgiparams{'COLUMN'} = $temp[0] if ( defined $temp[ 0 ] and $temp[ 0 ] ne "" );
}

if ($cgiparams{'ACTION'} eq $tr{'add'}) {
	$errormessage .= $tr{'invalid discrip'} ."<br />\n" unless($cgiparams{'DESCRIP'} =~ /^([a-zA-Z 0-9]*)$/);
	$errormessage .= $tr{'invalid parser'} ."<br />" unless ($cgiparams{'PARSER'} =~ /^(white|local|ipdeny|hosts|domains)$/);
	$errormessage .= $tr{'invalid comment'} ."<br />\n" unless ( &validcomment( $cgiparams{'SITE'} ) );

	unless ($errormessage) {
		open(FILE,">>$filename") or die 'Unable to open config file.';
		flock FILE, 2;
		print FILE "$cgiparams{'DESCRIP'},$cgiparams{'PARSER'},$cgiparams{'ENABLE'},$cgiparams{'SITE'}\n";
		close(FILE);

		$cgiparams{'ENABLE'} = 'on';
		$cgiparams{'DESCRIP'} = '';
		$cgiparams{'PARSER'} = '';
		$cgiparams{'SITE'} = '';

		$cgiparams{'COLUMN'} = 1;
		$cgiparams{'ORDER'} = $tr{'log ascending'};
		&log($tr{'site added to blockset'});
		
		my $success = message('blocksets');
		$infomessage .= "$success<br />\n" if ($success);
		$errormessage .= "blocksets ".$tr{'smoothd failure'}."<br />" unless ($success);
	}
}

if ($cgiparams{'ACTION'} eq $tr{'remove'} || $cgiparams{'ACTION'} eq $tr{'edit'}) {
	open(FILE, "$filename") or die 'Unable to open config file.';
	my @current = <FILE>;
	close(FILE);

	my $count = 0;
	my $id = 0;
	my $line;
	foreach $line (@current) {
		$id++;
		$count++ if (($cgiparams{$id}) && $cgiparams{$id} eq "on");
	}
	$errormessage .= $tr{'nothing selected'} ."<br />\n" if ($count == 0);
	$errormessage .= $tr{'you can only select one item to edit'} ."<br />\n" if ($count > 1 && $cgiparams{'ACTION'} eq $tr{'edit'});

	unless ($errormessage) {
		open(FILE, ">$filename") or die 'Unable to open config file.';
		flock FILE, 2;
		my $id = 0;
		foreach $line (@current) {
			$id++;
			unless (($cgiparams{$id}) && $cgiparams{$id} eq "on") {
				print FILE "$line";
			}
			elsif ($cgiparams{'ACTION'} eq $tr{'edit'}) {
				chomp($line);
				my @temp = split(/\,/,$line);
				$cgiparams{'DESCRIP'} = $temp[0];
				$cgiparams{'PARSER'} = $temp[1];
				$cgiparams{'ENABLE'} = $temp[2];
				$cgiparams{'SITE'} = $temp[3] || '';
			}
		}
		close(FILE);
		&log($tr{'site removed from blockset'});

		my $success = message('blocksets');
		$infomessage .= "$success<br />\n" if ($success);
		$errormessage .= "blocksets ".$tr{'smoothd failure'} ."<br />\n" unless ($success);
	}
}

$cgiparams{'ENABLE'} = 'on' if ($cgiparams{'ACTION'} eq '');

$checked{'ENABLE'}{'off'} = '';
$checked{'ENABLE'}{'on'} = '';  
$checked{'ENABLE'}{$cgiparams{'ENABLE'}} = 'CHECKED';

&openpage($tr{'blockset configuration'}, 1, $refresh, 'services');

&openbigbox('100%', 'LEFT');

&alertbox($errormessage, "", $infomessage);

print "<form method='POST' action='?'><div>\n";

&openbox($tr{'enabledc'});

print <<END
<table style='width: 100%; border: none; margin-left:auto; margin-right:auto'>
<tr>
	<td style='width:40%;' class='base'>$tr{'enabable blocksets'}</td>
       <td><input type='checkbox' name='ENABLED' value='on'></td>
	<td style='width:50%; text-align:center;'><input type='SUBMIT' name='ACTION' value='$tr{'add'}'></td>
</tr>
</table>
END
;
&closebox();

&openbox($tr{'add a site'});

print <<END
<table style='width: 100%; border: none; margin-left:auto; margin-right:auto'>
<tr>
	<td class='base'>$tr{'descriptionc'}</td>
	<td><input type='text' name='DESCRIP' value='$cgiparams{'DESCRIP'}' id='descrip' 
		@{[jsvalidregex('descrip','^[a-zA-Z0-9\.,\(\)@$!\%\^\&\*=\+_ ]*$')]}></td>
	<td class='base'>$tr{'parserc'}</td>
	<td><input type='text' name='PARSER' value='$cgiparams{'PARSER'}' id='parser' 
		@{[jsvalidregex('parser','^[a-zA-Z0-9\.,\(\)@$!\%\^\&\*=\+_ ]*$')]}></td>
</tr>
<tr>
	<td class='base'>$tr{'sitec'}</td>
	<td colspan='3'><input type='text' style='width: 84%;' name='SITE' id='comment' 
		@{[jsvalidcomment('comment')]} value='$cgiparams{'SITE'}'></td>
</tr>
</table>
<table style='width: 100%; border: none; margin-left:auto; margin-right:auto'>
<tr>
	<td style='width:40%;' class='base'>$tr{'enabledc'}</td>
       <td><input type='checkbox' name='ENABLE' value='on' $checked{'ENABLE'}{'on'}></td>
	<td style='width:50%; text-align:center;'><input type='SUBMIT' name='ACTION' value='$tr{'add'}'></td>
</tr>
</table>
END
;
&closebox();

&openbox($tr{'current sites'});

my %render_settings =
(
	'url'     => "/mods/blocksets/cgi-bin/blocksets.cgi?[%COL%],[%ORD%]",
	'columns' => 
	[
		{ 
			column => '1',
			title  => "$tr{'descriptionc'}",
			size   => 5,
			#sort   => \&ipcompare,
		},
		{
			column => '2',
			title  => "$tr{'parserc'}",
			size   => 5,
			#sort   => 'cmp'
		},
		{ 
			column => '4',
			title => "$tr{'sitec'}",
			align   => 'left',
		},
		{
			column => '3',
			title  => "$tr{'enabledtitle'}",
			rotate => 60,
			tr     => 'onoff',
			align  => 'center',
		},
		{
			title  => "$tr{'mark'}", 
			rotate => 60,
			mark   => ' ',
		},

	]
);

&displaytable($filename, \%render_settings, $cgiparams{'ORDER'}, $cgiparams{'COLUMN'} );

print <<END
<table class='blank'>
<tr>
	<td style='width: 30%; text-align:center;'><input type='submit' name='ACTION' value='$tr{'remove'}'></td>
	<td style='width: 44%; text-align:center;'><input type='submit' name='ACTION' value='$tr{'restart'}'></td>
	<td style='width: 50%; text-align:center;'><input type='submit' name='ACTION' value='$tr{'edit'}'></td>
</tr>
</table>
END
;
&closebox();

print "</div></form>\n";

&alertbox('add','add');
&closebigbox();
&closepage();
