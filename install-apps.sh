#!/bin/bash
#
# This script installs nextcloud apps.
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
echo "# This script installs and enables nextcloud apps according to the"
echo "# configuration given in ${CONFIG_DIR}/nextcloud.sh"
echo "#"
echo "#######################################################################################"
echo

ask_to_continue

if [ "${NEXTCLOUD_APPS_INSTALLED}" != "1" ] ; then

	echo
	echo "#######################################################################################"
	echo "#"
	echo "# INFO: Installing nextcloud apps."
	echo "#"
	echo "#######################################################################################"
	echo

	cd ${MY_NEXTCLOUD_DR}/apps/
	curl https://apps.nextcloud.com/api/v1/platform/${MY_NEXTCLOUD_VERSION}/apps.json | jq -r . >apps.store

	for APP in ${MY_NEXTCLOUD_APPS} ; do
		cd ${MY_NEXTCLOUD_DR}/apps/
		if [ -d "${APP}" ] ; then
			echo "${APP} app already installed."
		else
			if [[ "${APP}" == "apporder" && -f "${PKG_DIR}/apporder-master.zip" ]] ; then
				echo "Using ${PKG_DIR}/apporder-master.zip."
				unzip ${PKG_DIR}/apporder-master.zip
				/bin/mv apporder-master apporder
			elif [[ "${APP}" == "contacts" && -f "${PKG_DIR}/nextcloud_contacts_nightly.tar.gz" ]] ; then
				echo "Using ${PKG_DIR}/nextcloud_contacts_nightly.tar.gz."
				tar xvf ${PKG_DIR}/nextcloud_contacts_nightly.tar.gz
			else
				if [ "${APP}" == "gpxpod" ] ; then
					apt-get install gpsbabel gpsbabel-doc -y
					apt-get install python-pip -y
					pip install gpxpy requests SRTM.py
				fi
				APP_DOWNLOAD="$(cat apps.store | jq '.[] | select(.id == "'${APP}'")' | jq '.releases' | jq .[] | jq '.download' | head -1 | cut --delimiter=\" -f2)"
				FILE_NAME="$(basename ${APP_DOWNLOAD})"
				echo "Downloading ${APP} from ${APP_DOWNLOAD}."
				wget ${APP_DOWNLOAD}
				echo "Unpacking ${APP}."
				tar xvf ${FILE_NAME}
				/bin/rm ${FILE_NAME}
				if [ "${APP}" == "gpxpod" ] ; then
					/bin/cp gpxpod/img/gpx.svg ../core/img/filetypes/
				fi
			fi
		fi

		cd ${MY_NEXTCLOUD_DR}
		~/bin/${_MY_NEXTCLOUD_DOMAIN_}-upgrade.sh
		echo "Enabling ${APP}."
		sudo -u www-data php7.1 occ app:enable ${APP}

		if [ "${APP}" == "previewgenerator" ] ; then
			sudo -u www-data php7.1 occ preview:delete_old
			sudo -u www-data php7.1 occ preview:generate-all
			sudo -u www-data php7.1 occ preview:pre-generate
			crontab -u www-data -l >~/crontab.txt
			echo "5,20,35,50  *  *  *  * php7.1 ${MY_NEXTCLOUD_DR}/occ preview:pre-generate" >>~/crontab.txt
			crontab -u www-data ~/crontab.txt
		fi
	done

	cd ${MY_NEXTCLOUD_DR}/apps/
	/bin/rm apps.store
	cd ${MY_NEXTCLOUD_DR}/


	if [ -f "${CONFIG_DIR}/mimetypealiases.json" ] ; then /bin/cp ${CONFIG_DIR}/mimetypealiases.json ${MY_NEXTCLOUD_DR}/config/; fi
	if [ -f "${CONFIG_DIR}/mimetypemapping.json" ] ; then /bin/cp ${CONFIG_DIR}/mimetypemapping.json ${MY_NEXTCLOUD_DR}/config/; fi

	~/bin/${_MY_NEXTCLOUD_DOMAIN_}-upgrade.sh

	sudo -u www-data php7.1 occ maintenance:mimetype:update-js
	sudo -u www-data php7.1 occ files:scan --all

	~/bin/${_MY_NEXTCLOUD_DOMAIN_}-safe.sh

	touch ${STAMP_DIR}/nextcloud_apps_installed
fi


echo
echo "#######################################################################################"
echo "#"
echo "# INFO: Script finished!"
echo "#"
echo "#######################################################################################"
echo
