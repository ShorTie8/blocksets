#/bin/bash
#
# deactivate mod
# delete symlinks .. :(~

. /etc/rc.d/inc.rc-functions

echo -e "${BOUL}  DeActivate mod ${INFO}"
rm /var/smoothwall/mods/blocksets
echo -e "${NO}"

echo -e "${BOUL}  DeCreate sbin link ${INFO}"
rm /usr/sbin/blockset
echo -e "${NO}"

