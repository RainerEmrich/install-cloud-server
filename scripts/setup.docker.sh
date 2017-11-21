#!/bin/bash
#
# Set up docker ce.
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

setup_docker () {

	if [ "${DOCKER_INSTALLED}" != "1" ] ; then

		echo
		echo "#######################################################################################"
		echo "#"
		echo "# Install Docker (docker-ce) from the docker.com repository."
		echo "#"
		echo "#######################################################################################"
		echo

		ask_to_continue

		apt-get update

		apt-get install curl apt-transport-https ca-certificates software-properties-common -y

		case ${DIST_ID} in
		Ubuntu)
			apt-get install linux-image-extra-virtual -y
			;;
		Debian)
			apt-get install gnupg2 -y
			;;
		*)
			;;
		esac
	
		curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | apt-key add -

		add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") $(lsb_release -cs) stable"

		apt-get update
		apt-get -y install docker-ce

		docker run hello-world

		touch ${STAMP_DIR}/docker_installed
	else
		echo
		echo "#######################################################################################"
		echo "#"
		echo "# INFO: Docker installed already, skipping..."
		echo "#"
		echo "#######################################################################################"
		echo
	fi

}
