#!/bin/bash
#
# Set up MariaDB 10.2 from mariadb.org using the netcologne mirror.
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

setup_mariadb () {

	if [ "${MARIADB_INSTALLED}" != "1" ] ; then

		echo
		echo "#######################################################################################"
		echo "#"
		echo "# Replace Mysql Server with MariaDB Server 10.2."
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

		export MARIADB_SOURCE="$(grep -R "http://mirror.netcologne.de/mariadb/repo/10.2/${DIST_NAME} ${DIST_CODENAME} main" /etc/apt/ -l)"

		if [ "${MARIADB_SOURCE}" == "" ] ; then
			echo
			echo "#######################################################################################"
			echo "#"
			echo "# Add MariaDB repository."
			echo "#"
			echo "#######################################################################################"
			echo

			case ${DIST_ID} in
			Ubuntu)
				case ${DIST_RELEASE} in
				16.04)
					apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
					;;
				*)
					;;
				esac
				;;
			Debian)
				case ${DIST_RELEASE} in
				8.*)
					apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xCBCB082A1BB943DB
					;;
				9.*)
					apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
					;;
				*)
					;;
				esac
				;;
			*)
				;;
			esac
			add-apt-repository "deb [arch=amd64,i386,ppc64el] http://mirror.netcologne.de/mariadb/repo/10.2/${DIST_NAME} ${DIST_CODENAME} main"

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
		echo "#######################################################################################"
		echo

		apt-get install mariadb-server mysql-common dbconfig-common dbconfig-mysql -y

		apt-get autoremove --purge -y

		# Set BINLOG FORMAT = ROW, innodb_large_prefix = 1, innodb_file_format = barracuda
		patch /etc/mysql/my.cnf ${PATCH_DIR}/etc.mysql.my.cnf.patch
		# Set default character  set to utf8
		patch /etc/mysql/conf.d/mariadb.cnf ${PATCH_DIR}/etc.mysql.conf.d.mariadb.conf.patch

		# Set  transaction isolation to READ COMMITTED
		echo "MYSQLD_OPTS=--transaction-isolation=READ-COMMITTED" >/etc/mysql/env.cnf
		echo "[Service]" >/etc/systemd/system/mariadb.service.d/environment.conf
		echo "EnvironmentFile=/etc/mysql/env.cnf" >>/etc/systemd/system/mariadb.service.d/environment.conf
		systemctl daemon-reload

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

	elif [ "${MARIADB_VERSION}" != "10.2" ] ; then

		echo
		echo "#######################################################################################"
		echo "#"
		echo "# Update MariaDB server."
		echo "#"
		echo "#######################################################################################"
		echo

		ask_to_continue

		export MARIADB_SOURCE="$(grep -R "http://mirror.netcologne.de/mariadb/repo/10.2/${DIST_NAME} ${DIST_CODENAME} main" /etc/apt/ -l)"

		if [ "${MARIADB_SOURCE}" == "" ] ; then
			echo
			echo "#######################################################################################"
			echo "#"
			echo "# Add MariaDB repository."
			echo "#"
			echo "#######################################################################################"
			echo

			case ${DIST_ID} in
			Ubuntu)
				case ${DIST_RELEASE} in
				16.04)
					apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
					;;
				*)
					;;
				esac
				;;
			Debian)
				case ${DIST_RELEASE} in
				8.*)
					apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xCBCB082A1BB943DB
					;;
				9.*)
					apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
					systemctl stop mysql.service
					mysqld_safe --skip-grant-tables &
					sleep 2
					mysql -u root --execute="use mysql; update user set plugin='mysql_native_password'; flush privileges;"
					kill -KILL $(pgrep mysql)
					/bin/rm /etc/mysql/my.cnf /etc/alternatives/my.cnf
					;;
				*)
					;;
				esac
				;;
			*)
				;;
			esac
			add-apt-repository "deb [arch=amd64,i386,ppc64el] http://mirror.netcologne.de/mariadb/repo/10.2/${DIST_NAME} ${DIST_CODENAME} main"

			apt-get update
	
			apt-get dist-upgrade -y

			# Set BINLOG FORMAT = ROW, innodb_large_prefix = 1, innodb_file_format = barracuda
			patch /etc/mysql/my.cnf ${PATCH_DIR}/etc.mysql.my.cnf.patch
			# Set default character  set to utf8
			patch /etc/mysql/conf.d/mariadb.cnf ${PATCH_DIR}/etc.mysql.conf.d.mariadb.conf.patch

			# Set  transaction isolation to READ COMMITTED
			if [ ! -f /etc/mysql/env.cnf ] ; then echo "MYSQLD_OPTS=--transaction-isolation=READ-COMMITTED" >/etc/mysql/env.cnf ; fi
			if [ ! -f /etc/systemd/system/mariadb.service.d/environment.conf ] ; then
				echo "[Service]" >/etc/systemd/system/mariadb.service.d/environment.conf
				echo "EnvironmentFile=/etc/mysql/env.cnf" >>/etc/systemd/system/mariadb.service.d/environment.conf
			fi

			systemctl daemon-reload

			case ${DIST_ID} in
			Debian)
				case ${DIST_RELEASE} in
				9.*)
					read -sp "Please enter the password for the mysql root user: " MY_PASSWD
					echo
					sed --in-place "s/password =/password = ${MY_PASSWD}/g" /etc/mysql/debian.cnf
					;;
				*)
					;;
				esac
				;;
			*)
				;;
			esac

			systemctl restart mysql

			sleep 5

			mysql_secure_installation
		fi

	else
		echo
		echo "#######################################################################################"
		echo "#"
		echo "# INFO: MariaDB Server 10.2 installed already, skipping..."
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
