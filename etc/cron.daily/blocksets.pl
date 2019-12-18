#! /usr/bin/perl

# sites file format
# Description,Parser,ENABLED,Site

use Sys::Syslog;
use Data::Dumper;

my (@BLOCKLIST, @BLOCKFUNC);
my %SEEN;

# dispatch table so we cannot execute random user-supplied functions
my %parsers = (
		'white' => \&parse_white,
		'local' => \&parse_local,
		'ipdeny' => \&parse_ipdeny,
		'hosts' => \&parse_hosts,
	      );

# Open syslog
&openlog("blocksets", "", "user");

$settingsFile = "/var/smoothwall/mods/blocksets/sites";

# Ensure settings file exists
if (! -f $settingsFile)
{
  open(SETTINGS, ">$settingsFile");
  close(SETTINGS);
}

# Create the replacement sets
  # blockSet Net
  # In case a previous run orphaned it
  system ("/usr/sbin/ipset -F blockSetNetReplace 2>/dev/null");
  system ("/usr/sbin/ipset -X blockSetNetReplace 2>/dev/null");
  # Create the set
  system("/usr/sbin/ipset -N blockSetNetReplace nethash");

  # blockSet Host
  # In case a previous run orphaned it
  system ("/usr/sbin/ipset -F blockSetHostReplace 2>/dev/null");
  system ("/usr/sbin/ipset -X blockSetHostReplace 2>/dev/null");
  # Create the set
  system("/usr/sbin/ipset -N blockSetHostReplace iphash");

  # whiteSet Net
  # In case a previous run orphaned it
  system ("/usr/sbin/ipset -F whiteSetNetReplace 2>/dev/null");
  system ("/usr/sbin/ipset -X whiteSetNetReplace 2>/dev/null");
  # Create the set
  system ("/usr/sbin/ipset -N whiteSetNetReplace nethash");

  # whiteSet Host
  # In case a previous run orphaned it
  system ("/usr/sbin/ipset -F whiteSetHostReplace 2>/dev/null");
  system ("/usr/sbin/ipset -X whiteSetHostReplace 2>/dev/null");
  # Create the set
  system ("/usr/sbin/ipset -N whiteSetHostReplace iphash");


# Prepare ipset to 'restore'
open (IPSET, "|/usr/sbin/ipset restore");

# Do the local whitelist first to skip processing such entries when found.
$parsers{"white"}->();

# Fetch each block list, erase the HTML, comments and blank lines,
#   and add to the respective replacement set.
open SETTINGS, "<$settingsFile";
while (<SETTINGS>)
{
  chomp;
  next if ($_ eq "");
  next if ($_ =~ /^#/);
  my ($name, $parser, $enable, $url) = split(/\,/, $_);
  print "    Processing $name\n";
  $parsers{$parser}->($name, $enable, $url);
}
# Do the local blacklist last
$parsers{"local"}->();
close(SETTINGS);

close(IPSET);

# For debugging
system ("/usr/sbin/ipset save blockSetNetReplace -file /var/smoothwall/mods/blocksets/blockSetNetReplace");
system ("/usr/sbin/ipset save blockSetHostReplace -file /var/smoothwall/mods/blocksets/blockSetHostReplace");
system ("/usr/sbin/ipset save whiteSetNetReplace -file /var/smoothwall/mods/blocksets/whiteSetNetReplace");
system ("/usr/sbin/ipset save whiteSetHostReplace -file /var/smoothwall/mods/blocksets/whiteSetHostReplace");

# Exchange the set's names and delete the 'now old' set

foreach $setType ("Net","Host")
{
  system ("/usr/sbin/ipset -W blockSet${setType} blockSet${setType}Replace");
  system ("/usr/sbin/ipset -F blockSet${setType}Replace");
  system ("/usr/sbin/ipset -X blockSet${setType}Replace");
  system ("/usr/sbin/ipset -W whiteSet${setType} whiteSet${setType}Replace");
  system ("/usr/sbin/ipset -F whiteSet${setType}Replace");
  system ("/usr/sbin/ipset -X whiteSet${setType}Replace");
}

open SET, "ipset list blockSetNet | egrep '^[0-9]' | wc -l |";
$netBlockEntries = <SET>;
chomp $netBlockEntries;
close SET;
open SET, "ipset list blockSetHost | egrep '^[0-9]' | wc -l |";
$hostBlockEntries = <SET>;
chomp $hostBlockEntries;
close SET;
open SET, "ipset list whiteSetNet | egrep '^[0-9]' | wc -l |";
$netWhiteEntries = <SET>;
chomp $netWhiteEntries;
close SET;
open SET, "ipset list whiteSetHost | egrep '^[0-9]' | wc -l |";
$hostWhiteEntries = <SET>;
chomp $hostWhiteEntries;
close SET;
# gives error: Redundant argument in sprintf at /usr/lib/perl5/5.22.4/aarch64-linux-thread-multi/Sys/Syslog.pm line 423.
#syslog("info", "$netBlockEntries blocked nets, $hostBlockEntries blocked hosts", "$netWhiteEntries allowed nets, $hostWhiteEntries allowed hosts");

# Close syslog
&closelog();

#print STDERR Dumper \%SEEN;

# Finished
exit 0;

# Parse ipdeny blocklists
#
# Fetch the block list, skip the HTML, comments and blank lines,
#   and add to the respective replacement set.

sub parse_ipdeny() {
  my ($NAME,$ENABLE,$URL) = @_;

  my $error = 0;
  # No name?
  if ($NAME eq "")
  {
    syslog("info", "parse_ipdeny: no NAME");
    $error = 1;
  }
  # No URL?
  if ($URL eq "")
  {
    syslog("info", "parse_ipdeny: no URL");
    $error = 1;
  }
  # Can't proceed?
  if ($error == 1) { return; }

  # Enabled ??
  if ($ENABLE ne "on") { 
    print "      $NAME is Not Enabled\n";
    return;
  }

  # Log the operation
  syslog("info", "process $NAME");

  my $populating = 0;

  # Get and process each list
  open (LIST, "wget -O - '${URL}' 2>/dev/null |");
  while (<LIST>)
  {
    chomp;
    # Skip comments
    if ($_ =~ /^#/) { next; }
    if ($_ =~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\/[0-9]+$/ && $SEEN{$_} != 1) {
      print IPSET "add blockSetNetReplace $_\n";
    }
    elsif ($_ =~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/ && $SEEN{$_} != 1) {
      print IPSET "add blockSetHostReplace $_\n";
    }
    $SEEN{$_} = 1;
  }
  close(LIST);
  print "      Done Processing $NAME\n";
}



# Process local blocklist
#
# Skip any comments and blank lines, and add to the respective replacement set.

sub parse_local() {
  my $local_blocklist = "/var/smoothwall/mods/blocksets/local.blocklist";

  my $populating = 0;

  if (-e $local_blocklist) {
    # Log the operation
    syslog("info", "process local blocklist");

    # Get and process the local list only if the file exists
    open (LIST, $local_blocklist);
    while (<LIST>)
    {
      # Skip comments
      chomp;
      next if ($_ =~ /^#/);
      next if ($_ eq "");
      if ($_ =~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\/[0-9]+$/ && $SEEN{$_} != 1) {
        print IPSET "add blockSetNetReplace $_\n";
      }
      elsif ($_ =~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/ && $SEEN{$_} != 1) {
        print IPSET "add blockSetHostReplace $_\n";
      }
      $SEEN{$_} = 1;
    }
    close(LIST);
  }
}



# Process local whitelist
#
# Skip any comments and blank lines, and add to the respective replacement set.

sub parse_white() {
  my $local_whitelist = "/var/smoothwall/mods/blocksets/local.whitelist";

  my $populating = 0;

  if (-e $local_whitelist) {
    # Log the operation
    syslog("info", "process local whitelist");

    # Get and process the local list only if the file exists
    open (LIST, $local_whitelist);
    while (<LIST>)
    {
      # Skip comments
      chomp;
      next if ($_ =~ /^#/);
      next if ($_ eq "");
      if ($_ =~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\/[0-9]+$/ && $SEEN{$_} != 1) {
        print IPSET "add whiteSetNetReplace $_\n";
      }
      elsif ($_ =~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/ && $SEEN{$_} != 1) {
        print IPSET "add whiteSetHostReplace $_\n";
      }
      # Whitelist by marking the host/net 'seen'
      $SEEN{$_} = 1;
    }
    close(LIST);
  }
}



# Parse ipdeny blocklists
#
# Fetch the block list, skip the HTML, comments and blank lines,
#   and add to the respective replacement set.

sub parse_hosts() {
  my ($NAME,$ENABLE,$URL) = @_;

  my $error = 0;
  # No name?
  if ($NAME eq "")
  {
    syslog("info", "parse_hosts: no NAME");
    $error = 1;
  }
  # No URL?
  if ($URL eq "")
  {
    syslog("info", "parse_hosts: no URL");
    $error = 1;
  }
  # Can't proceed?
  if ($error == 1) { return; }

  # Enabled ??
  if ($ENABLE ne "on") { 
    print "      $NAME is Not Enabled\n";
    return;
  }

  # Log the operation
  syslog("info", "process $NAME");

  my $populating = 0;

  # Get and process each list
  open (LIST, "wget -O - '${URL}' 2>/dev/null |");
  while (<LIST>)
  {
    chomp;
    # Skip comments
    next if ($_ =~ /^#/);
    next if ($_ eq "");
    print IPSET "add blockSetHostReplace $_\n";
#    if ($_ =~ /^[a-zA-Z0-9\,\(\)@$!\%\^\&\*=\+_ ]*$/ && $SEEN{$_} != 1) {
#      print IPSET "add blockSetHostReplace $_\n";
#    }
#    elsif ($_ =~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/ && $SEEN{$_} != 1) {
#      print IPSET "add blockSetHostReplace $_\n";
#    }
    print "adding  blockSetHostReplace  $_\n";
    $SEEN{$_} = 1;
  }
  close(LIST);
}


