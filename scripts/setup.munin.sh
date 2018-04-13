#!/bin/bash
#
# Set up munin server monitoring.
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

setup_munin () {

	if [ "${MUNIN_INSTALLED}" != "1" ] ; then

		echo
		echo "#######################################################################################"
		echo "#"
		echo "# Install munin server monitoring."
		echo "#"
		echo "# The monitoring page is available for the admin host or local at:"
		echo "# https://${MY_FQDN}/munin/"
		echo "#"
		echo "#######################################################################################"
		echo

		ask_to_continue

		apt-get install munin munin-doc munin-node time -y

		systemctl stop munin-node
		a2disconf munin
		systemctl reload apache2

		apt-get install libdbd-csv-perl libxml-dom-perl liblog-dispatch-perl libipc-shareable-perl libio-socket-ssl-perl \
				libnet-ssleay-perl libcrypt-des-perl libdigest-hmac-perl acpi libcrypt-ssleay-perl libdbd-pg-perl \
				liblwp-useragent-determined-perl libtext-csv-xs-perl libwww-perl libxml-simple-perl logtail ruby \
				libnet-netmask-perl libnet-telnet-perl libxml-parser-perl libcache-cache-perl libdbd-mysql-perl \
				libnet-dns-perl libgssapi-perl libdbi-test-perl libmldbm-perl libnet-daemon-perl libmojolicious-perl \
				libauthen-ntlm-perl -y

		patch /etc/munin/apache24.conf ${PATCH_DIR}/etc.munin.apache24.conf.patch
		sed --in-place "s/localhost.localdomain/${MY_FQDN}/g" /etc/munin/munin.conf
		echo "[docker_*]" >/etc/munin/plugin-conf.d/docker
		echo "user root" >>/etc/munin/plugin-conf.d/docker
		patch /etc/munin/plugin-conf.d/munin-node ${PATCH_DIR}/etc.munin.plugin-conf.d.munin-node.patch
		sed --in-place "s/myhost.mydomain.tld/${MY_FQDN}/g" /etc/munin/plugin-conf.d/munin-node

		case ${DIST_ID} in
		Debian)
			case ${DIST_RELEASE} in
			8.*)
				MUNIN_PASSWD="$(grep password /etc/mysql/debian.cnf | head -n 1 | cut -d " " -f 3)"
				sed --in-place "/env.mysqluser debian-sys-maint/aenv.mysqlpassword ${MUNIN_PASSWD}" /etc/munin/plugin-conf.d/munin-node

				chmod 600 /etc/munin/plugin-conf.d/munin-node
				;;
			9.*)
				sed --in-place "/env.mysqluser/d" /etc/munin/plugin-conf.d/munin-node

				chmod 600 /etc/munin/plugin-conf.d/munin-node
				;;
			*)
				;;
			esac
			;;
		*)
			;;
		esac

		munin-node-configure --shell | sh -x
		/bin/ln -s /usr/share/munin/plugins/proc /etc/munin/plugins/proc
		/bin/ln -s /usr/share/munin/plugins/http_loadtime /etc/munin/plugins/http_loadtime
		/bin/rm -f /etc/munin/plugins/mysql_innodb_insert_buf
		/bin/rm -f /etc/munin/plugins/mysql_innodb_io_pend
		/bin/rm -f /etc/munin/plugins/mysql_replication
		/bin/rm -f /etc/munin/plugins/ntp_*.*.*.*

		systemctl start munin-node

		sed --in-place 's/#Include \/etc\/apache2\/conf-available\/munin/Include \/etc\/apache2\/conf-available\/munin/' /etc/apache2/sites-available/${MY_SITE_CONFIG}.conf

		systemctl restart apache2

		touch ${STAMP_DIR}/munin_installed
	else
		echo
		echo "#######################################################################################"
		echo "#"
		echo "# INFO: Munin server monitoring installed already, skipping..."
		echo "#"
		echo "#######################################################################################"
		echo
	fi

}
