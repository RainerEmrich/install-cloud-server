#!/bin/bash
#
# Set up redis server.
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

setup_redis () {

	if [ "${REDIS_INSTALLED}" != "1" ] ; then

		echo
		echo "#######################################################################################"
		echo "#"
		echo "# Install the redis server and set the necessary system variables."
		echo "#"
		echo "# /sys/kernel/mm/transparent_hugepage/enabled = never"
		echo "# vm.overcommit_memory = 1"
		echo "# net.core.somaxconn = 1024"
		echo "#"
		echo "#######################################################################################"
		echo

		ask_to_continue

		case ${DIST_ID} in
		Debian)
			wget -qO- https://www.dotdeb.org/dotdeb.gpg | apt-key add -
			echo "deb http://packages.dotdeb.org ${DIST_CODENAME} all" >/etc/apt/sources.list.d/dotdeb.list
			echo "deb-src http://packages.dotdeb.org ${DIST_CODENAME} all" >>/etc/apt/sources.list.d/dotdeb.list
			apt-get update
			;;
		Ubuntu)
			add-apt-repository ppa:chris-lea/redis-server -y
			apt-get update
			;;
		*)
			;;
		esac

		apt-get install redis-server redis-tools -y

		systemctl stop redis

		patch /etc/redis/redis.conf ${PATCH_DIR}/etc.redis.redis.conf.patch

		echo '[Unit]' >/etc/systemd/system/disable-transparent-huge-pages.service
		echo 'Description=Disable Transparent Huge Pages' >>/etc/systemd/system/disable-transparent-huge-pages.service
		echo '' >>/etc/systemd/system/disable-transparent-huge-pages.service
		echo '[Service]' >>/etc/systemd/system/disable-transparent-huge-pages.service
		echo 'Type=oneshot' >>/etc/systemd/system/disable-transparent-huge-pages.service
		echo 'ExecStart=/bin/sh -c "/bin/echo "never" | tee /sys/kernel/mm/transparent_hugepage/enabled"' >>/etc/systemd/system/disable-transparent-huge-pages.service
		echo '' >>/etc/systemd/system/disable-transparent-huge-pages.service
		echo '[Install]' >>/etc/systemd/system/disable-transparent-huge-pages.service
		echo 'WantedBy=redis-server.service' >>/etc/systemd/system/disable-transparent-huge-pages.service

		systemctl daemon-reload
		systemctl enable disable-transparent-huge-pages.service

		sysctl vm.overcommit_memory=1
		sysctl net.core.somaxconn=1024
		echo "#" >>/etc/sysctl.conf
		echo "# Enable memory overcommit" >>/etc/sysctl.conf
		echo "vm.overcommit_memory = 1" >>/etc/sysctl.conf
		echo "#" >>/etc/sysctl.conf
		echo "# The maximum number of sockets connections.  Default is 128." >>/etc/sysctl.conf
		echo "net.core.somaxconn = 1024" >>/etc/sysctl.conf

		/bin/cp -a ${DATA_DIR}/etc/systemd/system/redis-server.service.d /etc/systemd/system/
		systemctl daemon-reload

		usermod -aG redis www-data

		systemctl start redis

		touch ${STAMP_DIR}/redis_installed
	else
		echo
		echo "#######################################################################################"
		echo "#"
		echo "# INFO: Redis server installed already, skipping..."
		echo "#"
		echo "#######################################################################################"
		echo
	fi

}
