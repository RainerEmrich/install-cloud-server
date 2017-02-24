#!/bin/bash
#
# Set up docker engine.
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
		echo "# Install Docker from the dockerproject.org repository."
		echo "# deb https://apt.dockerproject.org/repo/ ubuntu-xenial main"
		echo "#"
		echo "#######################################################################################"
		echo

		ask_to_continue

		apt-get update
		apt-get install curl linux-image-extra-virtual -y
		apt-get install apt-transport-https ca-certificates -y

		curl -fsSL https://yum.dockerproject.org/gpg | sudo apt-key add -
		apt-key fingerprint 58118E89F3A912897C070ADBF76221572C52609D

		add-apt-repository "deb https://apt.dockerproject.org/repo/ ubuntu-xenial main"

		apt-get update
		apt-get -y install docker-engine

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
