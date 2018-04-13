#!/bin/bash
#
# Set up the base software
#
# Copyright (C) 2017-2018 Rainer Emrich, <rainer@emrich-ebersheim.de>
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

setup_base_software () {

	if [ "${BASE_INSTALLED}" != "1" ] ; then

		echo
		echo "#######################################################################################"
		echo "#"
		echo "# Installing some basic sopftware packages:"
		echo "#"
		echo "# software-properties-common"
		echo "# update-notifier-common"
		echo "# apt-show-versions"
		echo "# dnsutils"
		echo "# bsd-mailx"
		echo "# git"
		echo "# man-db"
		echo "# manpages"
		echo "# vim"
		echo "# vim-doc"
		echo "# vim-scripts"
		echo "# haveged"
		echo "# jq"
		echo "#"
		echo "#######################################################################################"
		echo

		ask_to_continue

		apt-get update
		apt-get install software-properties-common bzip2 -y

		case ${DIST_ID} in
		Ubuntu)
			apt-get install update-notifier-common -y
			/usr/lib/update-notifier/update-motd-updates-available --force
			;;
		Debian)
			case ${DIST_RELEASE} in
			9.*)
				apt-get install unattended-upgrades apt-listchanges dirmngr -y
				dpkg-reconfigure -plow unattended-upgrades
				;;
			*)
				;;
			esac
			;;
		*)
			;;
		esac

		apt-get install apt-show-versions dnsutils bsd-mailx git -y

		apt-get install man-db manpages -y

		apt-get install vim vim-doc vim-scripts -y

		apt-get install haveged -y

		apt-get install jq -y

		touch ${STAMP_DIR}/base_installed

	else
		echo
		echo "#######################################################################################"
		echo "#"
		echo "# INFO: Base software installed already, skipping...."
		echo "#"
		echo "#######################################################################################"
		echo
	fi
}
