#!/bin/bash
# Sets permissions of the Nextcloud instance for updating

ncpath='my_ncpath'

if [ ! -f "${ncpath}/config/config.php" ] ; then
	echo "ERROR: Configuration file ${ncpath}/config/config.php not found!"
	exit 0
fi

ncdatapath=`grep datadirectory ${ncpath}/config/config.php | cut -d "'" -f 4`
htuser='www-data'
htgroup='www-data'

chown -R ${htuser}:${htgroup} ${ncpath}
chown -R ${htuser}:${htgroup} ${ncdatapath}
