#!/bin/bash
ncpath='my_ncpath'

if [ ! -f "${ncpath}/config/config.php" ] ; then
	echo "ERROR: Configuration file ${ncpath}/config/config.php not found!"
	exit 0
fi

ncdatapath=`grep datadirectory ${ncpath}/config/config.php | cut -d "'" -f 4`
htuser='www-data'
htgroup='www-data'
rootuser='root'

printf "Creating possible missing Directories\n"
mkdir -p $ncdatapath
mkdir -p $ncpath/updater

printf "chmod Files and Directories\n"
find ${ncpath} -type f -print0 | xargs -0 chmod 0640
find ${ncpath} -type d -print0 | xargs -0 chmod 0750
find ${ncdatapath} -type f -print0 | xargs -0 chmod 0640
find ${ncdatapath} -type d -print0 | xargs -0 chmod 0750

printf "chown Directories\n"
chown -R ${rootuser}:${htgroup} ${ncpath}
chown -R ${htuser}:${htgroup} ${ncpath}/apps/
chown -R ${htuser}:${htgroup} ${ncpath}/config/
chown -R ${htuser}:${htgroup} ${ncdatapath}/
chown -R ${htuser}:${htgroup} ${ncpath}/themes/
chown -R ${htuser}:${htgroup} ${ncpath}/updater/

chmod ug+x ${ncpath}/occ

printf "chmod/chown .htaccess\n"
if [ -f ${ncpath}/.htaccess ]
 then
  chmod 0644 ${ncpath}/.htaccess
  chown ${rootuser}:${htgroup} ${ncpath}/.htaccess
fi
if [ -f ${ncdatapath}/.htaccess ]
 then
  chmod 0644 ${ncdatapath}/.htaccess
  chown ${rootuser}:${htgroup} ${ncdatapath}/.htaccess
fi
