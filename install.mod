#/bin/bash
#
# Creates symlinks and sets file permissions for blocksets

# load our functions {echolog} & colors
. /etc/rc.d/inc.rc-functions

chown -v nobody:nobody sites
chown -v nobody:nobody settings
chown -v nobody:nobody local.blocklist
chown -v nobody:nobody local.whitelist

chmod -v 644 sites
chmod -v 644 settings
chmod -v 644 local.blocklist
chmod -v 644 local.whitelist

chown -v -R nobody:nobody httpd
chmod -v 755 httpd/cgi-bin/blocksets.cgi
chmod -v 644 httpd/html/help/blocksets.cgi.html.en

chown -v -R root:root usr
chmod -v 644 usr/lib/smoothwall/header.pm
chmod -v 644 usr/lib/smoothwall/smoothtype.pm
chmod -v 644 usr/lib/smoothwall/langs/alertboxes.en.pl
chmod -v 644 usr/lib/smoothwall/langs/en.pl
chmod -v 644 usr/lib/smoothwall/langs/glossary.en.pl
chmod -v 644 usr/lib/smoothwall/menu/3000_Networking/8000_blocksets.list
chmod -v 755 usr/sbin/blockset

#chown -v -R 500:squid etc ??
chown -v -R root:root etc
chmod -v 755 etc/cron.daily/blocksets.pl
chmod -v 755 etc/rc.d/01rc.firewall.down
chmod -v 755 etc/rc.d/90rc.firewall.up

echo -e "${BOUL}  Activate mod ${DONE}"
cd /var/smoothwall/mods
ln -svf ../mods-available/blocksets blocksets
echo -e "${NO}"

echo -e "${BOUL}  Create sbin link ${INFO}"
cd /usr/sbin
ln -sfv /var/smoothwall/mods/blocksets/usr/sbin/blockset blockset
echo -e "${NO}"

cd /var/smoothwall
chown -v nobody:nobody mods-available
cd mods-available
chown -v nobody:nobody blocksets

