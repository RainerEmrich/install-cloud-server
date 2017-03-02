#!/bin/bash
#
# Get current configuration.
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

get_config () {

	. ${CONFIG_DIR}/hostname.sh
	. ${CONFIG_DIR}/network.sh
	. ${CONFIG_DIR}/letsencrypt.sh
	. ${CONFIG_DIR}/postfix.sh
	. ${CONFIG_DIR}/nextcloud.sh
	. ${CONFIG_DIR}/lool.sh

	export CURRENT_HOSTNAME="$(hostname -s)"
	export CURRENT_FQDN="$(hostname)"
	export MY_GLOBAL_IP="$(ip addr show up scope global | grep inet | grep ${MY_GLOBAL_INTERFACE} | cut -d " " -f 6 | cut -d "/" -f 1)"
	export AVAILABLE_NETWORK_DEVICE="$(ip link show | grep DOWN | cut -d " " -f 2 | cut -d ":" -f 1)"

	export MARIADB_INSTALLED=$(test ! -z "$(dpkg -l | grep "mariadb-server")" && echo "1")
	export MYSQL_INSTALLED=$(test ! -z "$(dpkg -l | grep "mysql-server")" && echo "1")
	if [ "${MYSQL_INSTALLED}" == "1" ] ; then export MYSQL_VERSION="$(dpkg -l | grep mysql-server-core- | cut -d " " -f 3 | cut -d "-" -f 4)"; fi

	export UPGRADE_DONE=$(test -f "${STAMP_DIR}/upgrade_done" && echo "1")
	export HOSTNAME_SET=$(test -f "${STAMP_DIR}/hostname_set" && echo "1")
	export NETWORK_SET=$(test -f "${STAMP_DIR}/network_set" && echo "1")
	export HOSTS_SET=$(test -f "${STAMP_DIR}/hosts_set" && echo "1")
	export SSH_SET=$(test -f "${STAMP_DIR}/ssh_set" && echo "1")
	export BM_SET=$(test -f "${STAMP_DIR}/bm_set" && echo "1")
	export BASE_INSTALLED=$(test -f "${STAMP_DIR}/base_installed" && echo "1")
	export REDIS_INSTALLED=$(test -f "${STAMP_DIR}/redis_installed" && echo "1")
	export APPARMOR_DISABLED=$(test -f "${STAMP_DIR}/apparmor_disabled" && echo "1")
	export APACHE2_INSTALLED=$(test -f "${STAMP_DIR}/apache2_installed" && echo "1")
	export LETSENCRYPT_INSTALLED=$(test -f "${STAMP_DIR}/letsencrypt_installed" && echo "1")
	export POSTFIX_SETUP=$(test -f "${STAMP_DIR}/postfix_setup" && echo "1")
	export DOCKER_INSTALLED=$(test -f "${STAMP_DIR}/docker_installed" && echo "1")
	export MUNIN_INSTALLED=$(test -f "${STAMP_DIR}/munin_installed" && echo "1")
	export PHPMYADMIN_INSTALLED=$(test -f "${STAMP_DIR}/phpmyadmin_installed" && echo "1")
	export PHP_FPM_INSTALLED=$(test -f "${STAMP_DIR}/php_fpm_installed" && echo "1")
	export NEXTCLOUD_PREREQUISITES_INSTALLED=$(test -f "${STAMP_DIR}/nextcloud_prerequisites_installed" && echo "1")
	export NEXTCLOUD_INSTALLED=$(test -f "${STAMP_DIR}/nextcloud_installed" && echo "1")
	export LOOL_INSTALLED=$(test -f "${STAMP_DIR}/lool_installed" && echo "1")
	if [ "${LOOL_INSTALLED}" == "1" ] ; then export LOOL_LAST="$(cat ${STAMP_DIR}/lool_installed)" ; fi

}
