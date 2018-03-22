#!/bin/bash
#
# This script sets up a cloud server with Ubuntu 16.04 or Debian 8.
# Installs and sets up all required packages for nextcloud.
# Finally installs nextcloud.
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

export START_DIR="$(pwd)"
export MYSELF="$(readlink -f "$0")"
export MYSELF_QUOTED="$(echo "${MYSELF}" | sed 's/\//\\\//g' -)"
export BASE_DIR="$(dirname "${MYSELF}")"
export ARCHIVES_DIR="${BASE_DIR}/archives"
export BM_DIR="${BASE_DIR}/backupmanager"
export CONFIG_DIR="${BASE_DIR}/config"
export DATA_DIR="${BASE_DIR}/data"
export PKG_DIR="${BASE_DIR}/packages"
export PATCH_DIR="${BASE_DIR}/patches"
export SCRIPT_DIR="${BASE_DIR}/scripts"
export STAMP_DIR="${BASE_DIR}/stamps"

if [ ! -d ${STAMP_DIR} ] ; then mkdir -p ${STAMP_DIR}; fi

. ${SCRIPT_DIR}/setup.functions.sh


get_os_release
test_os_release


get_config
show_info
ask_to_continue


if [[ "${CURRENT_FQDN}" != "localhost.localdomain" && "${CURRENT_FQDN}" != "${MY_FQDN}" ]] ; then

	echo
	echo "#######################################################################################"
	echo "#"
	echo "# ERROR: A hostname is already set and differs from the one in the configuration."
	echo "#        See ${CONFIG_DIR}/hostname.sh"
	echo "#"
	echo "#        Wrong host exiting..."
	echo "#"
	echo "#######################################################################################"
	exit

else

	if [ "$(grep "\.bash_aliases" ~/.bashrc)" == "" ] ; then
		echo "if [ -f ~/.bash_aliases ]; then" >>~/.bashrc
		echo "    . ~/.bash_aliases" >>~/.bashrc
		echo "fi" >>~/.bashrc
	fi

	test -z "$(grep "${MYSELF}" ~/.bashrc)" && echo "${MYSELF}" >>~/.bashrc

	setup_hostname_network_ssh
	setup_backupmanager
	setup_software

	test ! -z "$(grep "${MYSELF}" ~/.bashrc)" && sed --in-place "/${MYSELF_QUOTED}/d" ~/.bashrc

	echo
	echo "#######################################################################################"
	echo "#"
	echo "# INFO: Script finished!"
	echo "#"
	echo "#######################################################################################"
	echo

fi
