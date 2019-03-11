#!/bin/bash
#
# Set up apache2 using the ppa of Ondřej Surý.
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

setup_apache () {

	if [ "${APACHE2_INSTALLED}" != "1" ] ; then

		case ${DIST_ID} in
		Ubuntu)
			echo
			echo "#######################################################################################"
			echo "#"
			echo "# Install apache2 from the ppa of Ondřej Surý."
			echo "#"
			echo "#######################################################################################"
			echo

			ask_to_continue

			apt-add-repository -y ppa:ondrej/apache2
			apt-get update

			apt-get dist-upgrade -y
			;;
		Debian)
			echo
			echo "#######################################################################################"
			echo "#"
			echo "# Configure apache2."
			echo "#"
			echo "#######################################################################################"
			echo

			ask_to_continue

			case ${DIST_RELEASE} in
			8.*)
				apt-get remove libapache2-mod-python -y
				a2dismod php5
				systemctl restart apache2
				;;
			9.*)
				apt-get remove libapache2-mod-python -y
				systemctl restart apache2
				;;
			*)
				;;
			esac
		esac

		apt-get install apache2-doc -y

		/bin/rm -f /etc/apache2/mods-enabled/status.conf

		a2disconf apache2-doc
		systemctl reload apache2

		touch ${STAMP_DIR}/apache2_installed
	else
		echo
		echo "#######################################################################################"
		echo "#"
		echo "# INFO: Apache already setup, skipping..."
		echo "#"
		echo "#######################################################################################"
		echo
	fi

}
