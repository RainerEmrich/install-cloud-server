#!/bin/bash
#
# This script installs libreoffice online.
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

export START_DIR="$(pwd)"
export MYSELF="$(readlink -f "$0")"
export MYSELF_QUOTED="$(echo "${MYSELF}" | sed 's/\//\\\//g' -)"
export BASE_DIR="$(dirname "${MYSELF}")"
export ARCHIVES_DIR="${BASE_DIR}/Narchives"
export BM_DIR="${BASE_DIR}/backupmanager"
export CONFIG_DIR="${BASE_DIR}/config"
export DATA_DIR="${BASE_DIR}/data"
export PKG_DIR="${BASE_DIR}/packages"
export PATCH_DIR="${BASE_DIR}/patches"
export SCRIPT_DIR="${BASE_DIR}/scripts"
export STAMP_DIR="${BASE_DIR}/stamps"

if [ ! -d ${STAMP_DIR} ] ; then mkdir -p ${STAMP_DIR}; fi

. ${SCRIPT_DIR}/setup.functions.sh


get_os_release
test_os_release


get_config


echo
echo "#######################################################################################"
echo "#"
echo "# This script installs and configures libreoffice online according to the"
echo "# configuration given in ${CONFIG_DIR}/lool.sh"
echo "#"
echo "# Installing ${LOOL_VERSION}.tar.xz"
echo "#"
echo "#######################################################################################"
echo

ask_to_continue


if [ ! -f ${PKG_DIR}/${LOOL_VERSION}.tar.xz ] ; then
	echo
	echo "#######################################################################################"
	echo "#"
	echo "# ERROR: libreoffice online package not found."
	echo "#        ${PKG_DIR}/${LOOL_VERSION}.tar.xz missing."
	echo "#"
	echo "# Exiting..."
	echo "#"
	echo "#######################################################################################"
	echo

	exit
fi


if [ "${LOOL_INSTALLED}" != "1" ] ; then

	echo
	echo "#######################################################################################"
	echo "#"
	echo "# INFO: Installing required packages."
	echo "#"
	echo "#######################################################################################"
	echo

	apt-get install libiodbc2 libcunit1 python-polib python3-polib -y
	apt-get autoremove --purge -y

	echo
	echo "#######################################################################################"
	echo "#"
	echo "# INFO: Add user and group lool."
	echo "#"
	echo "#######################################################################################"
	echo

	groupadd -f lool
	useradd --gid lool --groups sudo --home-dir /opt/lool --no-create-home --shell /bin/false lool

	echo
	echo "#######################################################################################"
	echo "#"
	echo "# INFO: Installing lool."
	echo "#"
	echo "#######################################################################################"
	echo

	mkdir -p ${LOOL_PREFIX}
	tar -C ${LOOL_PREFIX} -xf ${PKG_DIR}/${LOOL_VERSION}.tar.xz
	/sbin/setcap cap_fowner,cap_mknod,cap_sys_chroot=ep ${LOOL_PREFIX}/bin/loolforkit
	/sbin/setcap cap_sys_admin=ep ${LOOL_PREFIX}/bin/loolmount

	LOOL_DISTRO="$(ls -1 ${LOOL_PREFIX}/etc)"
	OFFICE_PATH="$(find ${LOOL_PREFIX}/lib -maxdepth 1 -type d -name "*office*")"
	${LOOL_PREFIX}/bin/loolwsd-systemplate-setup ${LOOL_PREFIX}/var/systemplate ${OFFICE_PATH}

	mkdir -p ${LOOL_PREFIX}/var/tmp
	mkdir -p ${LOOL_PREFIX}/var/log/loolwsd
	mkdir -p ${LOOL_PREFIX}/var/jails
	mkdir -p ${LOOL_PREFIX}/var/cache/${LOOL_DISTRO}

	chown lool:lool ${LOOL_PREFIX}/var/tmp
	chown lool:lool ${LOOL_PREFIX}/var/log/loolwsd
	chown lool:lool ${LOOL_PREFIX}/var/jails
	chown lool:lool ${LOOL_PREFIX}/var/cache/${LOOL_DISTRO}

	chown root:lool ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/*
	chmod o-r ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/*

	patch ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/loolwsd.xml ${PATCH_DIR}/opt.lool.etc.loolwsd.loowsd.xml.patch

	sed --in-place "s#\"systemplate\"></sys_template_path>#\"systemplate\">../var/systemplate</sys_template_path>#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/loolwsd.xml
	sed --in-place "s#\"></lo_template_path>#\">${OFFICE_PATH}</lo_template_path>#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/loolwsd.xml
	sed --in-place "s#\"jails\"></child_root_path>#\"jails\">../var/jails</child_root_path>#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/loolwsd.xml
	sed --in-place "s#default=\"loleaflet/../\"></file_server_root_path>#default=\"loleaflet/../\">../var/www/loleaflet/../</file_server_root_path>#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/loolwsd.xml
	sed --in-place "s#<file enable=\"false\">#<file enable=\"true\">#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/loolwsd.xml
	sed --in-place "s#\"true\">/tmp/looltrace.gz</path>#\"true\">${LOOL_PREFIX}/var/tmp/looltrace.gz</path>#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/loolwsd.xml
	sed --in-place "s#/etc/loolwsd/cert.pem#${LOOL_PREFIX}/etc/${LOOL_DISTRO}/cert.pem#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/loolwsd.xml
	sed --in-place "s#/etc/loolwsd/key.pem#${LOOL_PREFIX}/etc/${LOOL_DISTRO}/key.pem#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/loolwsd.xml
	sed --in-place "s#/etc/loolwsd/ca-chain.cert.pem#${LOOL_PREFIX}/etc/${LOOL_DISTRO}/ca-chain.cert.pem#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/loolwsd.xml
	sed --in-place "s#>0</max_file_size>#>${LO_DOC_SIZE}</max_file_size>#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/loolwsd.xml
	sed --in-place "s#></username>#>${LOOL_ADMIN_NAME}</username>#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/loolwsd.xml
	sed --in-place "s#></password>#>${LOOL_ADMIN_PASSWD}</password>#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/loolwsd.xml

	MY_NEXTCLOUD_DOMAIN_QUOTED="$(echo ${MY_NEXTCLOUD_DOMAIN} | sed 's/\./\\\\\\\./g')"
	MY_GLOBAL_IP_QUOTED="$(dig +short ${MY_NEXTCLOUD_DOMAIN} | sed 's/\./\\\\\\\./g')"

	sed --in-place "s#mycloud\\\.mydomain\\\.tld#${MY_NEXTCLOUD_DOMAIN_QUOTED}#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/loolwsd.xml
	sed --in-place "s#my_global_ipv4#${MY_GLOBAL_IP_QUOTED}#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/loolwsd.xml

	echo
	echo "#######################################################################################"
	echo "#"
	echo "# INFO: Create, enable and start loolwsd service."
	echo "#"
	echo "#######################################################################################"
	echo

	echo "[Unit]" >/lib/systemd/system/loolwsd.service
	echo "Description=Collabora Online Office Service" >>/lib/systemd/system/loolwsd.service
	echo "After=network.target" >>/lib/systemd/system/loolwsd.service
	echo "" >>/lib/systemd/system/loolwsd.service
	echo "[Service]" >>/lib/systemd/system/loolwsd.service
	echo "Type=simple" >>/lib/systemd/system/loolwsd.service
	echo "User=lool" >>/lib/systemd/system/loolwsd.service
	echo "ExecStart=${LOOL_PREFIX}/bin/loolwsd" >>/lib/systemd/system/loolwsd.service
	echo "" >>/lib/systemd/system/loolwsd.service
	echo "[Install]" >>/lib/systemd/system/loolwsd.service
	echo "WantedBy=multi-user.target" >>/lib/systemd/system/loolwsd.service

	systemctl daemon-reload
	systemctl enable loolwsd
	systemctl start loolwsd

	echo
	echo "#######################################################################################"
	echo "#"
	echo "# INFO: Create apache2 site configuration for libreoffice online."
	echo "#"
	echo "#######################################################################################"
	echo

	/bin/cp -a ${DATA_DIR}/etc/apache2/sites-available/999-myoffice-mydomain-tld-le-ssl.conf /etc/apache2/sites-available/
	/bin/cp -a /etc/apache2/sites-available/999-myoffice-mydomain-tld-le-ssl.conf /etc/apache2/sites-available/${LOOL_SITE_CONFIG}.conf

	sed --in-place "s/ServerAdmin webmaster@localhost/ServerAdmin ${LOOL_SA}/" /etc/apache2/sites-available/${LOOL_SITE_CONFIG}.conf
	sed --in-place "s/myhost.mydomain.tld/${LOOL_DOMAIN}/g" /etc/apache2/sites-available/${LOOL_SITE_CONFIG}.conf

	echo
	echo "#######################################################################################"
	echo "#"
	echo "# INFO: Get a Let's Encrypt Certificate."
	echo "#"
	echo "#######################################################################################"
	echo

	echo "letsencrypt --apache --non-interactive --agree-tos --hsts --uir --email ${MY_EMAIL} --rsa-key-size ${MY_KEY_SIZE} -d ${LOOL_DOMAIN}" >~/Dokumentation/letsencrypt/${LOOL_DOMAIN}.txt
	letsencrypt --apache --non-interactive --agree-tos --hsts --uir --email ${MY_EMAIL} --rsa-key-size ${MY_KEY_SIZE} -d ${LOOL_DOMAIN}

	echo
	echo "#######################################################################################"
	echo "#"
	echo "# INFO: Enable libreoffice online site, enable proxy modules and restart apache2."
	echo "#"
	echo "#######################################################################################"
	echo

	a2ensite ${LOOL_SITE_CONFIG}
	a2enmod proxy_http proxy_wstunnel
	systemctl restart apache2

	echo "${LOOL_VERSION}" >${STAMP_DIR}/lool_installed

elif [ "${LOOL_VERSION}" != "${LOOL_LAST}" ] ; then

	BACKUP_DATE="$(date +%F-%H-%M-%S)"
	BACKUP_PATH="${LOOL_PREFIX}.backup.${BACKUP_DATE}"

	echo
	echo "#######################################################################################"
	echo "#"
	echo "# INFO: Updating the libreoffice online installation."
	echo "#"
	echo "#       The directory ${LOOL_PREFIX} containing the libreoffice online version"
	echo "#       ${LOOL_LAST}"
	echo "#       is moved to ${BACKUP_PATH}."
	echo "#"
	echo "#######################################################################################"
	echo

	a2dissite ${LOOL_SITE_CONFIG}
	systemctl reload apache2
	systemctl stop loolwsd

	/bin/mv -f ${LOOL_PREFIX} ${BACKUP_PATH}

	mkdir -p ${LOOL_PREFIX}
	tar -C ${LOOL_PREFIX} -xf ${PKG_DIR}/${LOOL_VERSION}.tar.*
	/sbin/setcap cap_fowner,cap_mknod,cap_sys_chroot=ep ${LOOL_PREFIX}/bin/loolforkit
	/sbin/setcap cap_sys_admin=ep ${LOOL_PREFIX}/bin/loolmount

	LOOL_DISTRO="$(ls -1 ${LOOL_PREFIX}/etc)"
	BACKUP_LOOL_DISTRO="$(ls -1 ${BACKUP_PATH}/etc)"
	OFFICE_PATH="$(find ${LOOL_PREFIX}/lib -maxdepth 1 -type d -name "*office*")"
	BACKUP_OFFICE_PATH="${LOOL_PREFIX}/lib/$(basename $(find ${BACKUP_PATH}/lib -maxdepth 1 -type d -name "*office*"))"
	${LOOL_PREFIX}/bin/loolwsd-systemplate-setup ${LOOL_PREFIX}/var/systemplate ${OFFICE_PATH}

	mkdir -p ${LOOL_PREFIX}/var/tmp
	mkdir -p ${LOOL_PREFIX}/var/log/loolwsd
	mkdir -p ${LOOL_PREFIX}/var/jails
	mkdir -p ${LOOL_PREFIX}/var/cache/${LOOL_DISTRO}

	chown lool:lool ${LOOL_PREFIX}/var/tmp
	chown lool:lool ${LOOL_PREFIX}/var/log/loolwsd
	chown lool:lool ${LOOL_PREFIX}/var/jails
	chown lool:lool ${LOOL_PREFIX}/var/cache/${LOOL_DISTRO}

	/bin/rm -f ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/*.pem
	/bin/mv ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/loolwsd.xml ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/loolwsd.xml.dist
	/bin/cp -af ${BACKUP_PATH}/etc/${BACKUP_LOOL_DISTRO}/* ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/

	chown root:lool ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/*
	chmod o-r ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/*

	sed --in-place "s#${LOOL_PREFIX}/var/cache/${BACKUP_LOOL_DISTRO}#${LOOL_PREFIX}/var/cache/${LOOL_DISTRO}#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/loolwsd.xml
	sed --in-place "s#\">${BACKUP_OFFICE_PATH}</lo_template_path>#\">${OFFICE_PATH}</lo_template_path>#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/loolwsd.xml
	sed --in-place "s#${LOOL_PREFIX}/etc/${BACKUP_LOOL_DISTRO}/cert.pem#${LOOL_PREFIX}/etc/${LOOL_DISTRO}/cert.pem#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/loolwsd.xml
	sed --in-place "s#${LOOL_PREFIX}/etc/${BACKUP_LOOL_DISTRO}/key.pem#${LOOL_PREFIX}/etc/${LOOL_DISTRO}/key.pem#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/loolwsd.xml
	sed --in-place "s#${LOOL_PREFIX}/etc/${BACKUP_LOOL_DISTRO}/ca-chain.cert.pem#${LOOL_PREFIX}/etc/${LOOL_DISTRO}/ca-chain.cert.pem#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/loolwsd.xml

	systemctl start loolwsd
	a2ensite ${LOOL_SITE_CONFIG}
	systemctl reload apache2

	echo "${LOOL_VERSION}" >${STAMP_DIR}/lool_installed

fi


echo
echo "#######################################################################################"
echo "#"
echo "# INFO: Script finished!"
echo "#"
echo "#######################################################################################"
echo

