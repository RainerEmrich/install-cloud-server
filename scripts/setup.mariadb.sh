#!/bin/bash
#
# Set up MariaDB 10.1 from mariadb.org using the netcologne mirror.
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

setup_mariadb () {

	if [ "${MARIADB_INSTALLED}" != "1" ] ; then

		echo
		echo "#######################################################################################"
		echo "#"
		echo "# Replace Mysql Server with MariaDB Server 10.1."
		echo "#"
		echo "# Important notice: All mysql databases will be deleted!"
		echo "#"
		echo "# After installation we secure the MariaDB Server, you have to provide a secure"
		echo "# password for the mysql root user."
		echo "#"
		echo "# To finish the installation we reboot the system!"
		echo "#"
		echo "#######################################################################################"
		echo

		ask_to_continue

		export MARIADB_SOURCE="$(grep -R "http://mirror.netcologne.de/mariadb/repo/10.1/ubuntu xenial main" /etc/apt/ -l)"

		if [ "${MARIADB_SOURCE}" == "" ] ; then
			echo
			echo "#######################################################################################"
			echo "#"
			echo "# Add MariaDB repository."
			echo "#"
			echo "#######################################################################################"
			echo

			apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
			add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://mirror.netcologne.de/mariadb/repo/10.1/ubuntu xenial main'

			apt-get update
		fi

		if [ "${MYSQL_INSTALLED}" == "1" ] ; then
			echo
			echo "#######################################################################################"
			echo "#"
			echo "# Remove MySQL server."
			echo "#"
			echo "#######################################################################################"
			echo

			apt-get remove --purge mysql-client-${MYSQL_VERSION} mysql-client-core-${MYSQL_VERSION} mysql-server mysql-server-${MYSQL_VERSION} mysql-server-core-${MYSQL_VERSION} -y

			/bin/rm -rf /etc/mysql/* /var/lib/mysql/*

			apt-get autoremove --purge -y
		fi

		echo
		echo "#######################################################################################"
		echo "#"
		echo "# Install MariaDB server."
		echo "#"
		echo "#"
		echo "#"
		echo "#######################################################################################"
		echo

		apt-get install mariadb-server mysql-common dbconfig-common dbconfig-mysql -y

		apt-get autoremove --purge -y

		# Set BINLOG FORMAT = ROW
		patch /etc/mysql/my.cnf ${PATCH_DIR}/etc.mysql.my.cnf.patch
		# Set default character  set to utf8
		patch /etc/mysql/conf.d/mariadb.cnf ${PATCH_DIR}/etc.mysql.conf.d.mariadb.conf.patch

		systemctl restart mysql

		sleep 5

		mysql_secure_installation

		systemctl stop apparmor
		systemctl disable apparmor

		touch ${STAMP_DIR}/apparmor_disabled

		echo
		echo "#######################################################################################"
		echo "#"
		echo "# INFO: Rebooting..."
		echo "#"
		echo "#######################################################################################"
		echo

		reboot

	else
		echo
		echo "#######################################################################################"
		echo "#"
		echo "# INFO: MariaDB Server installed already, skipping..."
		echo "#"
		echo "#######################################################################################"
		echo
	fi

	if [ "${APPARMOR_DISABLED}" == "1" ] ; then
		systemctl enable apparmor
		systemctl start apparmor
		/bin/rm ${STAMP_DIR}/apparmor_disabled
	fi

}
