#!/bin/bash
#
# This script installs libreoffice online.
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

export START_DIR="$(pwd)"
export MYSELF="$(readlink -f "$0")"
export MYSELF_QUOTED="$(echo "${MYSELF}" | sed 's/\//\\\//g' -)"
export BASE_DIR="$(dirname "${MYSELF}")"
export ARCHIVES_DIR="${BASE_DIR}/archives"
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

ONLINE_VERSION=$(echo $LOOL_VERSION | sed "s/.*online-//" | cut -d . -f1-3)

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

	if [ -f ${PKG_DIR}/${LOOL_VERSION}-required-packages.txt ] ; then
		dpkg -l | grep "ii  " | cut -d " " -f 3 | cut -d ":" -f 1 >available-packages.tmp

		PACKAGES=""
		for PACKAGE in $(cat ${PKG_DIR}/${LOOL_VERSION}-required-packages.txt) ; do
			if [ "$(grep "${PACKAGE}" available-packages.tmp)" == "" ] ; then
				PACKAGES="${PACKAGES} ${PACKAGE}"
			fi
		done

		/bin/rm available-packages.tmp

		if [ "${PACKAGES}" != "" ] ; then
			apt-get install ${PACKAGES} -y
		fi

		apt-get autoremove --purge -y
	fi

	echo
	echo "#######################################################################################"
	echo "#"
	echo "# INFO: Installing lool."
	echo "#"
	echo "#######################################################################################"
	echo

	mkdir -p ${LOOL_PREFIX}
	tar -C ${LOOL_PREFIX} -xf ${PKG_DIR}/${LOOL_VERSION}.tar.xz

	if [ -d ${LOOL_PREFIX}/etc/loolwsd ] ; then
		LOOL_DISTRO="loolwsd"
		LOOL_NAME="loolwsd"
		LOOL_USER="lool"
	elif [ -d ${LOOL_PREFIX}/etc/coolwsd ] ; then
		LOOL_DISTRO="coolwsd"
		LOOL_NAME="coolwsd"
		LOOL_USER="cool"
	else
		LOOL_DISTRO="libreoffice-online"
		LOOL_NAME="loolwsd"
		LOOL_USER="lool"
	fi

	echo
	echo "#######################################################################################"
	echo "#"
	echo "# INFO: Add user and group lool/cool."
	echo "#"
	echo "#######################################################################################"
	echo

	groupadd -f ${LOOL_USER}
	useradd --gid ${LOOL_USER} --groups sudo --home-dir /opt/lool --no-create-home --shell /usr/sbin/nologin ${LOOL_USER}

	if [ -f ${LOOL_PREFIX}/bin/coolforkit ] ; then
		/sbin/setcap cap_fowner,cap_chown,cap_mknod,cap_sys_chroot=ep ${LOOL_PREFIX}/bin/coolforkit
	elif [ -f ${LOOL_PREFIX}/bin/loolforkit ] ; then
		/sbin/setcap cap_fowner,cap_chown,cap_mknod,cap_sys_chroot=ep ${LOOL_PREFIX}/bin/loolforkit
	fi
	if [ -f ${LOOL_PREFIX}/bin/coolmount ] ; then
		/sbin/setcap cap_sys_admin=ep ${LOOL_PREFIX}/bin/coolmount
	elif [ -f ${LOOL_PREFIX}/bin/loolmount ] ; then
		/sbin/setcap cap_sys_admin=ep ${LOOL_PREFIX}/bin/loolmount
	fi

	OFFICE_PATH="$(find ${LOOL_PREFIX}/lib -maxdepth 1 -type d -name "*office*")"
	if [ -f ${LOOL_PREFIX}/bin/coolwsd-systemplate-setup ] ; then
		${LOOL_PREFIX}/bin/coolwsd-systemplate-setup ${LOOL_PREFIX}/var/systemplate ${OFFICE_PATH}
	elif [ -f ${LOOL_PREFIX}/bin/loolwsd-systemplate-setup ] ; then
		${LOOL_PREFIX}/bin/loolwsd-systemplate-setup ${LOOL_PREFIX}/var/systemplate ${OFFICE_PATH}
	fi
	case ${ONLINE_VERSION} in
	cp-6.4.0*)
		/bin/rm -f ${LOOL_PREFIX}/var/systemplate/etc/resolv.conf
		/bin/ln -s /etc/resolv.conf ${LOOL_PREFIX}/var/systemplate/etc/
		;;
	esac

	mkdir -p ${LOOL_PREFIX}/var/tmp
	mkdir -p ${LOOL_PREFIX}/var/log/${LOOL_NAME}
	mkdir -p ${LOOL_PREFIX}/var/jails
	mkdir -p ${LOOL_PREFIX}/var/cache/${LOOL_DISTRO}

	chown ${LOOL_USER}:${LOOL_USER} ${LOOL_PREFIX}/var/tmp
	chown ${LOOL_USER}:${LOOL_USER} ${LOOL_PREFIX}/var/log/${LOOL_NAME}
	chown ${LOOL_USER}:${LOOL_USER} ${LOOL_PREFIX}/var/jails
	chown ${LOOL_USER}:${LOOL_USER} ${LOOL_PREFIX}/var/cache/${LOOL_DISTRO}

	/bin/cp ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/${LOOL_NAME}.xml ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/${LOOL_NAME}.xml.dist

	csplit ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/${LOOL_NAME}.xml '/            <host desc="Regex pattern of hostname to allow or deny." allow="true">10/'

	MY_NEXTCLOUD_DOMAIN_QUOTED="$(echo ${MY_NEXTCLOUD_DOMAIN} | sed 's/\./\\\./g')"
	MY_GLOBAL_IP_QUOTED="$(dig +short ${MY_NEXTCLOUD_DOMAIN} | sed 's/\./\\\./g')"

	echo '            <host desc="Regex pattern of hostname to allow or deny." allow="true">'$MY_NEXTCLOUD_DOMAIN_QUOTED'</host>' >>xx00
	echo '            <host desc="Regex pattern of hostname to allow or deny." allow="true">'$MY_GLOBAL_IP_QUOTED'</host>' >>xx00

	for lool_client in $LOOL_CLIENTS; do
		my_lool_client_domain_quoted="$(echo ${lool_client} | sed 's/\./\\\./g')"
		echo '            <host desc="Regex pattern of hostname to allow or deny." allow="true">'$my_lool_client_domain_quoted'</host>' >>xx00
	done

	cat xx00 xx01 >${LOOL_PREFIX}/etc/${LOOL_DISTRO}/${LOOL_NAME}.xml
	/bin/rm xx00 xx01

	chown root:${LOOL_USER} ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/*
	chmod o-r ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/*

	sed --in-place "s#\"systemplate\"></sys_template_path>#\"systemplate\">../var/systemplate</sys_template_path>#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/${LOOL_NAME}.xml
	sed --in-place "s#\"></lo_template_path>#\">${OFFICE_PATH}</lo_template_path>#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/${LOOL_NAME}.xml
	sed --in-place "s#\"jails\"></child_root_path>#\"jails\">../var/jails</child_root_path>#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/${LOOL_NAME}.xml
	sed --in-place "s#default=\"loleaflet/../\"></file_server_root_path>#default=\"loleaflet/../\">../var/www/loleaflet/../</file_server_root_path>#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/${LOOL_NAME}.xml
	sed --in-place "s#default=\"browser/../\"></file_server_root_path>#default=\"browser/../\">../var/www/browser/../</file_server_root_path>#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/${LOOL_NAME}.xml
	sed --in-place "s#<file enable=\"false\">#<file enable=\"true\">#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/${LOOL_NAME}.xml
	sed --in-place "s#\"true\">/tmp/looltrace.gz</path>#\"true\">${LOOL_PREFIX}/var/tmp/looltrace.gz</path>#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/${LOOL_NAME}.xml
	sed --in-place "s#/etc/${LOOL_NAME}/cert.pem#${LOOL_PREFIX}/etc/${LOOL_DISTRO}/cert.pem#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/${LOOL_NAME}.xml
	sed --in-place "s#/etc/${LOOL_NAME}/key.pem#${LOOL_PREFIX}/etc/${LOOL_DISTRO}/key.pem#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/${LOOL_NAME}.xml
	sed --in-place "s#/etc/${LOOL_NAME}/ca-chain.cert.pem#${LOOL_PREFIX}/etc/${LOOL_DISTRO}/ca-chain.cert.pem#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/${LOOL_NAME}.xml
	sed --in-place "s#>0</max_file_size>#>${LO_DOC_SIZE}</max_file_size>#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/${LOOL_NAME}.xml
	sed --in-place "s#></username>#>${LOOL_ADMIN_NAME}</username>#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/${LOOL_NAME}.xml
	sed --in-place "s#></password>#>${LOOL_ADMIN_PASSWD}</password>#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/${LOOL_NAME}.xml
	sed --in-place "s#type=\"uint\">0</limit_virt_mem_kb>#type=\"uint\">${LO_MAX_VIRT_SIZE}</limit_virt_mem_kb>#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/${LOOL_NAME}.xml
	sed --in-place "s#type=\"uint\">0</limit_data_mem_kb>#type=\"uint\">${LO_MAX_DATA_SEG_SIZE}</limit_data_mem_kb>#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/${LOOL_NAME}.xml
	sed --in-place "s#type=\"uint\">8000</limit_stack_mem_kb>#type=\"uint\">${LO_MAX_STACK_SIZE}</limit_stack_mem_kb>#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/${LOOL_NAME}.xml
	sed --in-place "s#type=\"uint\">0</limit_file_size_mb>#type=\"uint\">${LO_MAX_FILE_SIZE}</limit_file_size_mb>#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/${LOOL_NAME}.xml
	sed --in-place "s#type=\"uint\">0</limit_num_open_files>#type=\"uint\">${LO_MAX_FILE_NUM}</limit_num_open_files>#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/${LOOL_NAME}.xml

	openssl genrsa -out ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/key.pem 4096
	chown root:${LOOL_USER} ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/key.pem
	chmod 640 ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/key.pem

	openssl req -out ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/cert.csr -key ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/key.pem -new -sha256 -nodes -subj "/C=DE/OU=${LOOL_DOMAIN}/CN=${LOOL_DOMAIN}/emailAddress=${LOOL_SA}"
	openssl x509 -req -days 3650 -in ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/cert.csr -signkey ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/key.pem -out ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/cert.pem
	openssl x509 -req -days 3650 -in ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/cert.csr -signkey ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/key.pem -out ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/ca-chain.cert.pem
	ssh-keygen -t rsa -N "" -m PEM -f "${LOOL_PREFIX}/etc/${LOOL_DISTRO}/proof_key"

	chown root:${LOOL_USER} ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/cert.csr
	chown root:${LOOL_USER} ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/cert.pem
	chown root:${LOOL_USER} ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/ca-chain.cert.pem
	chown root:${LOOL_USER} ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/proof_key

	chmod 644 ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/cert.csr
	chmod 644 ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/cert.pem
	chmod 644 ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/ca-chain.cert.pem
	chmod 640 ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/proof_key

	echo
	echo "#######################################################################################"
	echo "#"
	echo "# INFO: Create, enable and start loolwsd service."
	echo "#"
	echo "#######################################################################################"
	echo

	case ${DIST_ID} in
	Ubuntu)
		case ${DIST_RELEASE} in
		18.04)
			echo "# loolwsd default configuration" >/etc/ld.so.conf.d/loolwsd.conf
			echo "${LOOL_PREFIX}/lib" >>/etc/ld.so.conf.d/loolwsd.conf
			ldconfig
			;;
		esac
		;;
	esac

	echo "[Unit]" >/lib/systemd/system/loolwsd.service
	echo "Description=Collabora Online Office Service" >>/lib/systemd/system/loolwsd.service
	echo "After=network.target" >>/lib/systemd/system/loolwsd.service
	echo "" >>/lib/systemd/system/loolwsd.service
	echo "[Service]" >>/lib/systemd/system/loolwsd.service
	echo "Type=simple" >>/lib/systemd/system/loolwsd.service
	echo "User=${LOOL_USER}" >>/lib/systemd/system/loolwsd.service
	echo "ExecStart=${LOOL_PREFIX}/bin/${LOOL_NAME}" >>/lib/systemd/system/loolwsd.service
	echo "" >>/lib/systemd/system/loolwsd.service
	echo "[Install]" >>/lib/systemd/system/loolwsd.service
	echo "WantedBy=multi-user.target" >>/lib/systemd/system/loolwsd.service

	systemctl daemon-reload
	systemctl enable loolwsd
	systemctl start loolwsd

	echo
	echo "#######################################################################################"
	echo "#"
	echo "# INFO: Create temporary apache2 site configuration for libreoffice online."
	echo "#"
	echo "#######################################################################################"
	echo

	/bin/cp -a ${DATA_DIR}/etc/apache2/sites-available/998-myoffice-mydomain-tld.conf /etc/apache2/sites-available/${LOOL_SITE_CONFIG}.conf

	sed --in-place "s/ServerAdmin webmaster@localhost/ServerAdmin ${LOOL_SA}/" /etc/apache2/sites-available/${LOOL_SITE_CONFIG}.conf
	sed --in-place "s/myhost.mydomain.tld/${LOOL_DOMAIN}/g" /etc/apache2/sites-available/${LOOL_SITE_CONFIG}.conf

	a2ensite ${LOOL_SITE_CONFIG}
	systemctl reload apache2

	echo
	echo "#######################################################################################"
	echo "#"
	echo "# INFO: Get a Let's Encrypt Certificate."
	echo "#"
	echo "#######################################################################################"
	echo

	echo "letsencrypt --authenticator webroot --webroot-path /var/www/html --installer apache --non-interactive --agree-tos --hsts --uir --email ${MY_EMAIL} --rsa-key-size ${MY_KEY_SIZE} -d ${LOOL_DOMAIN}" >~/Dokumentation/letsencrypt/${LOOL_DOMAIN}.txt
	letsencrypt --authenticator webroot --webroot-path /var/www/html --installer apache --non-interactive --agree-tos --hsts --uir --email ${MY_EMAIL} --rsa-key-size ${MY_KEY_SIZE} -d ${LOOL_DOMAIN}

	echo
	echo "#######################################################################################"
	echo "#"
	echo "# INFO: Create final apache2 site configuration for libreoffice online."
	echo "#"
	echo "#######################################################################################"
	echo

	a2dissite ${LOOL_SITE_CONFIG}
	systemctl reload apache2
	/bin/rm /etc/apache2/sites-available/${LOOL_SITE_CONFIG}*

	if [ -f ${LOOL_PREFIX}/etc/apache2/conf-available/${LOOL_NAME}.conf ] ; then
		sed --in-place "s/http:/https:/g"  ${LOOL_PREFIX}/etc/apache2/conf-available/${LOOL_NAME}.conf
		sed --in-place "s/ws:/wss:/g"  ${LOOL_PREFIX}/etc/apache2/conf-available/${LOOL_NAME}.conf

		/bin/cp -a ${DATA_DIR}/etc/apache2/sites-available/997-myoffice-mydomain-tld-le-ssl.conf /etc/apache2/sites-available/${LOOL_SITE_CONFIG}.conf
	else
		/bin/cp -a ${DATA_DIR}/etc/apache2/sites-available/999-myoffice-mydomain-tld-le-ssl.conf /etc/apache2/sites-available/${LOOL_SITE_CONFIG}.conf
	fi

	sed --in-place "s/ServerAdmin webmaster@localhost/ServerAdmin ${LOOL_SA}/" /etc/apache2/sites-available/${LOOL_SITE_CONFIG}.conf
	sed --in-place "s/myhost.mydomain.tld/${LOOL_DOMAIN}/g" /etc/apache2/sites-available/${LOOL_SITE_CONFIG}.conf
	sed --in-place "s#Include /opt/lool/etc/apache2/conf-available/.*#Include /opt/lool/etc/apache2/conf-available/${LOOL_NAME}.conf#" /etc/apache2/sites-available/${LOOL_SITE_CONFIG}.conf

	case ${DIST_ID} in
	Debian)
		sed --in-place "s/Protocols h2/# Protocols h2/" /etc/apache2/sites-available/${LOOL_SITE_CONFIG}.conf
		;;
	*)
		;;
	esac

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

	if [ -f ${PKG_DIR}/${LOOL_VERSION}-required-packages.txt ] ; then
		dpkg -l | grep "ii  " | cut -d " " -f 3 | cut -d ":" -f 1 >available-packages.tmp

		PACKAGES=""
		for PACKAGE in $(cat ${PKG_DIR}/${LOOL_VERSION}-required-packages.txt) ; do
			if [ "$(grep "${PACKAGE}" available-packages.tmp)" == "" ] ; then
				PACKAGES="${PACKAGES} ${PACKAGE}"
			fi
		done

		/bin/rm available-packages.tmp

		if [ "${PACKAGES}" != "" ] ; then
			apt-get install ${PACKAGES} -y
		fi

		apt-get autoremove --purge -y
	fi

	mkdir -p ${LOOL_PREFIX}
	tar -C ${LOOL_PREFIX} -xf ${PKG_DIR}/${LOOL_VERSION}.tar.xz

	if [ -d ${LOOL_PREFIX}/etc/loolwsd ] ; then
		LOOL_DISTRO="loolwsd"
		LOOL_NAME="loolwsd"
		LOOL_USER="lool"
	elif [ -d ${LOOL_PREFIX}/etc/coolwsd ] ; then
		LOOL_DISTRO="coolwsd"
		LOOL_NAME="coolwsd"
		LOOL_USER="cool"
	else
		LOOL_DISTRO="libreoffice-online"
		LOOL_NAME="loolwsd"
		LOOL_USER="lool"
	fi
	if [ -d ${BACKUP_PATH}/etc/loolwsd ] ; then
		BACKUP_LOOL_DISTRO="loolwsd"
	elif [ -d ${BACKUP_PATH}/etc/coolwsd ] ; then
		BACKUP_LOOL_DISTRO="coolwsd"
	else
		BACKUP_LOOL_DISTRO="libreoffice-online"
	fi

	if getent passwd lool > /dev/null 2>&1; then
		LOOL_OLD_USER="lool"
	else
		LOOL_OLD_USER="cool"
	fi

	if [ "${LOOL_USER}" != "${LOOL_OLD_USER}" ] ; then
		usermod -l ${LOOL_USER} ${LOOL_OLD_USER}
		groupmod -n ${LOOL_USER} ${LOOL_OLD_USER}
		sed --in-place "s#User=.*#User=${LOOL_USER}#" /lib/systemd/system/loolwsd.service
		sed --in-place "s#ExecStart=.*#ExecStart=/opt/lool/bin/${LOOL_NAME}#" /lib/systemd/system/loolwsd.service
		systemctl daemon-reload
	fi

	if [ -f ${LOOL_PREFIX}/bin/coolforkit ] ; then
		/sbin/setcap cap_fowner,cap_chown,cap_mknod,cap_sys_chroot=ep ${LOOL_PREFIX}/bin/coolforkit
	elif [ -f ${LOOL_PREFIX}/bin/loolforkit ] ; then
		/sbin/setcap cap_fowner,cap_chown,cap_mknod,cap_sys_chroot=ep ${LOOL_PREFIX}/bin/loolforkit
	fi
	if [ -f ${LOOL_PREFIX}/bin/coolmount ] ; then
		/sbin/setcap cap_sys_admin=ep ${LOOL_PREFIX}/bin/coolmount
	elif [ -f ${LOOL_PREFIX}/bin/loolmount ] ; then
		/sbin/setcap cap_sys_admin=ep ${LOOL_PREFIX}/bin/loolmount
	fi

	OFFICE_PATH="$(find ${LOOL_PREFIX}/lib -maxdepth 1 -type d -name "*office*")"
	BACKUP_OFFICE_PATH="${LOOL_PREFIX}/lib/$(basename $(find ${BACKUP_PATH}/lib -maxdepth 1 -type d -name "*office*"))"
	if [ -f ${LOOL_PREFIX}/bin/coolwsd-systemplate-setup ] ; then
		${LOOL_PREFIX}/bin/coolwsd-systemplate-setup ${LOOL_PREFIX}/var/systemplate ${OFFICE_PATH}
	elif [ -f ${LOOL_PREFIX}/bin/loolwsd-systemplate-setup ] ; then
		${LOOL_PREFIX}/bin/loolwsd-systemplate-setup ${LOOL_PREFIX}/var/systemplate ${OFFICE_PATH}
	fi
	case ${ONLINE_VERSION} in
	cp-6.4.0*)
		/bin/rm -f ${LOOL_PREFIX}/var/systemplate/etc/resolv.conf
		/bin/ln -s /etc/resolv.conf ${LOOL_PREFIX}/var/systemplate/etc/
		;;
	esac

	mkdir -p ${LOOL_PREFIX}/var/tmp
	mkdir -p ${LOOL_PREFIX}/var/log/${LOOL_NAME}
	mkdir -p ${LOOL_PREFIX}/var/jails
	mkdir -p ${LOOL_PREFIX}/var/cache/${LOOL_DISTRO}

	chown ${LOOL_USER}:${LOOL_USER} ${LOOL_PREFIX}/var/tmp
	chown ${LOOL_USER}:${LOOL_USER} ${LOOL_PREFIX}/var/log/${LOOL_NAME}
	chown ${LOOL_USER}:${LOOL_USER} ${LOOL_PREFIX}/var/jails
	chown ${LOOL_USER}:${LOOL_USER} ${LOOL_PREFIX}/var/cache/${LOOL_DISTRO}

	/bin/rm -f ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/*.pem
	/bin/cp -af ${BACKUP_PATH}/etc/${BACKUP_LOOL_DISTRO}/*.pem ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/
	if [ -f ${BACKUP_PATH}/etc/${BACKUP_LOOL_DISTRO}/proof_key ] ; then
		/bin/cp -af ${BACKUP_PATH}/etc/${BACKUP_LOOL_DISTRO}/proof_key* ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/
	else
		ssh-keygen -t rsa -N "" -m PEM -f "${LOOL_PREFIX}/etc/${LOOL_DISTRO}/proof_key"
		chown root:${LOOL_USER} ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/proof_key
		chmod 640 ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/proof_key
	fi
	/bin/cp ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/${LOOL_NAME}.xml ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/${LOOL_NAME}.xml.dist

	csplit ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/${LOOL_NAME}.xml '/            <host desc="Regex pattern of hostname to allow or deny." allow="true">10/'

	MY_NEXTCLOUD_DOMAIN_QUOTED="$(echo ${MY_NEXTCLOUD_DOMAIN} | sed 's/\./\\\./g')"
	MY_GLOBAL_IP_QUOTED="$(dig +short ${MY_NEXTCLOUD_DOMAIN} | sed 's/\./\\\./g')"

	echo '            <host desc="Regex pattern of hostname to allow or deny." allow="true">'$MY_NEXTCLOUD_DOMAIN_QUOTED'</host>' >>xx00
	echo '            <host desc="Regex pattern of hostname to allow or deny." allow="true">'$MY_GLOBAL_IP_QUOTED'</host>' >>xx00

	for lool_client in $LOOL_CLIENTS; do
		my_lool_client_domain_quoted="$(echo ${lool_client} | sed 's/\./\\\./g')"
		echo '            <host desc="Regex pattern of hostname to allow or deny." allow="true">'$my_lool_client_domain_quoted'</host>' >>xx00
	done

	cat xx00 xx01 >${LOOL_PREFIX}/etc/${LOOL_DISTRO}/${LOOL_NAME}.xml
	/bin/rm xx00 xx01

	chown root:${LOOL_USER} ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/*
	chmod o-r ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/*

	sed --in-place "s#\"systemplate\"></sys_template_path>#\"systemplate\">../var/systemplate</sys_template_path>#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/${LOOL_NAME}.xml
	sed --in-place "s#\"></lo_template_path>#\">${OFFICE_PATH}</lo_template_path>#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/${LOOL_NAME}.xml
	sed --in-place "s#\"jails\"></child_root_path>#\"jails\">../var/jails</child_root_path>#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/${LOOL_NAME}.xml
	sed --in-place "s#default=\"loleaflet/../\"></file_server_root_path>#default=\"loleaflet/../\">../var/www/loleaflet/../</file_server_root_path>#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/${LOOL_NAME}.xml
	sed --in-place "s#default=\"browser/../\"></file_server_root_path>#default=\"browser/../\">../var/www/browser/../</file_server_root_path>#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/${LOOL_NAME}.xml
	sed --in-place "s#<file enable=\"false\">#<file enable=\"true\">#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/${LOOL_NAME}.xml
	sed --in-place "s#\"true\">/tmp/looltrace.gz</path>#\"true\">${LOOL_PREFIX}/var/tmp/looltrace.gz</path>#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/${LOOL_NAME}.xml
	sed --in-place "s#/etc/${LOOL_NAME}/cert.pem#${LOOL_PREFIX}/etc/${LOOL_DISTRO}/cert.pem#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/${LOOL_NAME}.xml
	sed --in-place "s#/etc/${LOOL_NAME}/key.pem#${LOOL_PREFIX}/etc/${LOOL_DISTRO}/key.pem#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/${LOOL_NAME}.xml
	sed --in-place "s#/etc/${LOOL_NAME}/ca-chain.cert.pem#${LOOL_PREFIX}/etc/${LOOL_DISTRO}/ca-chain.cert.pem#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/${LOOL_NAME}.xml
	sed --in-place "s#>0</max_file_size>#>${LO_DOC_SIZE}</max_file_size>#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/${LOOL_NAME}.xml
	sed --in-place "s#></username>#>${LOOL_ADMIN_NAME}</username>#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/${LOOL_NAME}.xml
	sed --in-place "s#></password>#>${LOOL_ADMIN_PASSWD}</password>#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/${LOOL_NAME}.xml
	sed --in-place "s#type=\"uint\">0</limit_virt_mem_kb>#type=\"uint\">${LO_MAX_VIRT_SIZE}</limit_virt_mem_kb>#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/${LOOL_NAME}.xml
	sed --in-place "s#type=\"uint\">0</limit_data_mem_kb>#type=\"uint\">${LO_MAX_DATA_SEG_SIZE}</limit_data_mem_kb>#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/${LOOL_NAME}.xml
	sed --in-place "s#type=\"uint\">8000</limit_stack_mem_kb>#type=\"uint\">${LO_MAX_STACK_SIZE}</limit_stack_mem_kb>#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/${LOOL_NAME}.xml
	sed --in-place "s#type=\"uint\">0</limit_file_size_mb>#type=\"uint\">${LO_MAX_FILE_SIZE}</limit_file_size_mb>#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/${LOOL_NAME}.xml
	sed --in-place "s#type=\"uint\">0</limit_num_open_files>#type=\"uint\">${LO_MAX_FILE_NUM}</limit_num_open_files>#" ${LOOL_PREFIX}/etc/${LOOL_DISTRO}/${LOOL_NAME}.xml

	case ${DIST_ID} in
	Ubuntu)
		case ${DIST_RELEASE} in
		18.04)
			echo "# loolwsd default configuration" >/etc/ld.so.conf.d/loolwsd.conf
			echo "${LOOL_PREFIX}/lib" >>/etc/ld.so.conf.d/loolwsd.conf
			ldconfig
			;;
		esac
		;;
	esac

	systemctl start loolwsd

	echo
	echo "#######################################################################################"
	echo "#"
	echo "# INFO: Update apache2 site configuration for libreoffice online."
	echo "#"
	echo "#######################################################################################"
	echo

	/bin/rm /etc/apache2/sites-available/${LOOL_SITE_CONFIG}*

	if [ -f ${LOOL_PREFIX}/etc/apache2/conf-available/${LOOL_NAME}.conf ] ; then
		sed --in-place "s/http:/https:/g"  ${LOOL_PREFIX}/etc/apache2/conf-available/${LOOL_NAME}.conf
		sed --in-place "s/ws:/wss:/g"  ${LOOL_PREFIX}/etc/apache2/conf-available/${LOOL_NAME}.conf

		/bin/cp -a ${DATA_DIR}/etc/apache2/sites-available/997-myoffice-mydomain-tld-le-ssl.conf /etc/apache2/sites-available/${LOOL_SITE_CONFIG}.conf
	else
		/bin/cp -a ${DATA_DIR}/etc/apache2/sites-available/999-myoffice-mydomain-tld-le-ssl.conf /etc/apache2/sites-available/${LOOL_SITE_CONFIG}.conf
	fi

	sed --in-place "s/ServerAdmin webmaster@localhost/ServerAdmin ${LOOL_SA}/" /etc/apache2/sites-available/${LOOL_SITE_CONFIG}.conf
	sed --in-place "s/myhost.mydomain.tld/${LOOL_DOMAIN}/g" /etc/apache2/sites-available/${LOOL_SITE_CONFIG}.conf
	sed --in-place "s#Include /opt/lool/etc/apache2/conf-available/.*#Include /opt/lool/etc/apache2/conf-available/${LOOL_NAME}.conf#" /etc/apache2/sites-available/${LOOL_SITE_CONFIG}.conf

	case ${DIST_ID} in
	Debian)
		sed --in-place "s/Protocols h2/# Protocols h2/" /etc/apache2/sites-available/${LOOL_SITE_CONFIG}.conf
		;;
	*)
		;;
	esac

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

