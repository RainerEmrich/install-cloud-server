#!/bin/bash
#
# Test the OS Release and bail out if not supported.
#
# Copyright 2017 Rainer Emrich, <rainer@emrich-ebersheim.de>
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

test_os_release () {

	case ${DIST_ID} in
	Ubuntu)
		case ${DIST_RELEASE} in
		16.04)
			SUPPORTED="1"
			;;
		*)
			SUPPORTED="0"
			;;
		esac
		;;
	Debian)
		case ${DIST_RELEASE} in
		8.*)
			SUPPORTED="1"
			;;
		*)
			SUPPORTED="0"
			;;
		esac
		;;
	*)
		SUPPORTED="0"
		;;
	esac

	echo
	echo "#######################################################################################"
	echo "#"
	echo "# Your Operating System is: ${DIST_ID} ${DIST_RELEASE} ${DIST_CODENAME}"
	echo "#"

	if [ "${SUPPORTED}" == "1" ] ; then
		echo "#######################################################################################"
		echo
	else
		echo "# ERROR: This Operating System is not supported!"
		echo "#"
		echo "#        At the moment the following systems are supported."
		echo "#"
		echo "#        Ubuntu 16.04.* xenial"
		echo "#        Debian 8.* jessie"
		echo "#"
		echo "#######################################################################################"
		echo

		exit
	fi

}
