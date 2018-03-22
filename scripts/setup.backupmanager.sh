#!/bin/bash
#
# Set up the 1&1 backupmanager
#
# Copyright 2017,2018 Rainer Emrich, <rainer@emrich-ebersheim.de>
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

setup_backupmanager () {

	if [[ ! -d "/opt/1UND1EU" && "${BM_SET}" != "1" ]] ; then

		echo
		echo "#######################################################################################"
		echo "#"
		echo "# Install the 1&1 Backup Manager."
		echo "#"
		echo "# Because it's not allowed to redistribute the 1&1 Backup Manager installer, you have"
		echo "# to grap the installer by yourself."
		echo "# How to get the 1&1 Backup Manager installer may be deduced from the following articel"
		echo "# on my blog."
		echo "# https://blog.emrich-ebersheim.de/2016/09/07/11-cloud-server-unter-ubuntu-16-04-1-lts-teil-3-netzwerk-firewall-backup/"
		echo "# Put the installer in the directory ${BM_DIR}"
		echo "#"
		echo "# If you don't want to install the 1&1 Backup Manager remove all files from the"
		echo "# installer directory ${BM_DIR}"
		echo "#"
		echo "#######################################################################################"
		echo

		ask_to_continue

		if [ -f ${BM_DIR}/1and1-backup-manager*linux-x86_64.run ] ; then
			echo
			echo "#######################################################################################"
			echo "#"
			echo "# During the installation you need the following information:"
			echo "#"
			echo "# Backup account name"
			echo "# Backup account password"
			echo "# Both may be obtained from the cloud panel."
			echo "#"
			echo "# Strong encryption key used for encrypting the backup data."
			echo "#"
			echo "#######################################################################################"
			echo

			ask_to_continue

			${BM_DIR}/1and1-backup-manager*linux-x86_64.run

			/bin/cp ${DATA_DIR}/root/bin/backup.* ~/bin/

			echo "alias backup='~/bin/backup.start.sh'" >>~/.bash_aliases
			echo "alias backup.add='~/bin/backup.add.dir.sh'" >>~/.bash_aliases
			echo "alias backup.err='~/bin/backup.error.fs.list.sh'" >>~/.bash_aliases
			echo "alias backup.schedule='~/bin/backup.schedule.list.sh'" >>~/.bash_aliases
			echo "alias backup.script='~/bin/backup.script.list.sh'" >>~/.bash_aliases
			echo "alias backup.selection='~/bin/backup.selection.list.sh'" >>~/.bash_aliases
			echo "alias backup.session='~/bin/backup.session.list.sh'" >>~/.bash_aliases
			echo "alias backup.session.node='~/bin/backup.session.node.fs.list.sh'" >>~/.bash_aliases
			echo "alias backup.setting='~/bin/backup.setting.list.sh'" >>~/.bash_aliases
			echo "alias backup.status='~/bin/backup.status.list.sh'" >>~/.bash_aliases

			touch ${STAMP_DIR}/bm_set
		else
			echo
			echo "#######################################################################################"
			echo "#"
			echo "# WARNING: No 1&1 Backup Manager installer found!"
			echo "#"
			echo "#          We've searched for ${BM_DIR}/1and1-backup-manager*linux-x86_64.run"
			echo "#"
			echo "# If you don't want to install the 1&1 Backup Manager, please continue now!"
			echo "# Otherwise stop now, copy the 1&1 Backup Manager installer into the directory"
			echo "# ${BM_DIR} and restart the script."
			echo "#"
			echo "#######################################################################################"
			echo

			ask_to_continue

			touch ${STAMP_DIR}/bm_set
		fi

	else
		echo
		echo "#######################################################################################"
		echo "#"
		echo "# INFO: 1&1 Backup Manager already installed or installation not requested, skipping..."
		echo "#"
		echo "#######################################################################################"
		echo
	fi

}
