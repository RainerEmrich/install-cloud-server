#!/bin/bash
#
# MySQL databases backup script
# keeps numbackup backups
#
# Copyright (C) 2017-2019 Rainer Emrich, <rainer@emrich-ebersheim.de>
#
# This file is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; see the file LICENSE.  If not see
# <http://www.gnu.org/licenses/>.
#
###################################
# Define number of backups to keep
let numbackup=30

# Define backup directory
BACKUPDIR="/root/database-backup"

# Define configuration file
CONF="/etc/mysql/debian.cnf"

###################################

# Check if configuration file exists
if [ ! -r $CONF ]; then
	echo "ERROR: Can't access configuration file ${CONF}."
	exit
fi

# Check if backup directory exists
if [ ! -d "${BACKUPDIR}" ] ; then
	mkdir -p "${BACKUPDIR}"
fi

# Find the databases to backup
IGNORE="phpmyadmin|mysql|information_schema|performance_schema|test"
DBS="$(mysql --defaults-extra-file=$CONF -Bse 'SHOW DATABASES' | grep -Ev $IGNORE)"

cd ${BACKUPDIR}

STARTTIME=`date +%Y%m%d-%H%M`

for DATABASE in ${DBS} ; do

	# Check if backup directory exists
	if [ ! -d "${DATABASE}" ] ; then
		mkdir -p "${DATABASE}"
	fi

	cd ${DATABASE}

	mysqldump --defaults-extra-file=$CONF --verbose --log-error=${DATABASE}_${STARTTIME}.log --single-transaction ${DATABASE} >${DATABASE}_${STARTTIME}.sql
	xz ${DATABASE}_${STARTTIME}.*

	let numfiles=1;

	for file in `ls -1t ${DATABASE}_*.sql*`; do
		# echo $numfiles
		# echo $file
		if [ $numfiles -gt $numbackup ] ; then
			filebase=`basename ${file} .sql.xz`
			/bin/rm -f ${filebase}.*
		fi
		let numfiles=$numfiles+1
	done

	cd ..

done
