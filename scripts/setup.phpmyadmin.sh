#!/bin/bash
#
# Set up php7.0, php7.1 and php7.2 base and phpmyadmin using the ppas from Ondřej Surý
# and Michal Čihař (nijel).
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

setup_phpmyadmin () {

	if [ "${PHPMYADMIN_INSTALLED}" != "1" ] ; then

		echo
		echo "#######################################################################################"
		echo "#"
		echo "# Install phpmyadmin using the ppa from Michal Čihař (nijel)."
		echo "# Requires the php7.0, php7.1 and php7.2 base from the ppa of Ondřej Surý."
		echo "#"
		echo "# Two scripts phpmyadmin-on.sh and phpmyadmin-off.sh for activating or deactivating"
		echo "# the phpmyadmin page are installed in ~/bin/."
		echo "#"
		echo "# Two scripts phpmyadmin-root-enable.sh and phpmyadmin-root-disable.sh for activating"
		echo "# or deactivating root login on the phpmyadmin page are installed in ~/bin/."
		echo "#"
		echo "# The phpmyadmin page is available for the admin host or local at:"
		echo "# https://${MY_FQDN}/phpmyadmin/"
		echo "#"
		echo "# During phpmyadmin configuration choose to configure database for phpmyadmin with"
		echo "# dbconfig-common. Leave the MySQL application password for phpmyadmin blank."
		echo "# Choose apache2 as web server that should be automatically configured."
		echo "#"
		echo "#######################################################################################"
		echo

		ask_to_continue

		case ${DIST_ID} in
		Ubuntu)
			apt-add-repository ppa:ondrej/php -y
			;;
		Debian)
			case ${DIST_RELEASE} in
			8.* | \
			9.*)
				wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
				echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list
				;;
			*)
				;;
			esac
			;;
		*)
			;;
		esac

		apt-get update

		PACKAGES70=""
		for PACKAGE in $(dpkg -l | grep php7.0 | awk '{print $2}') ; do PACKAGES70="${PACKAGES70} ${PACKAGE}"; done
		PACKAGES71=$(echo ${PACKAGES70} | sed 's/7.0/7.1/g')
		PACKAGES72=$(echo ${PACKAGES71} | sed 's/7.1/7.2/g')
		PACKAGES72=$(echo ${PACKAGES72} | sed 's/php7.2-mcrypt//')
		apt-get install ${PACKAGES70} ${PACKAGES71} ${PACKAGES72} -y

		apt-get dist-upgrade -y

		apt-get install php7.0 php7.0-bz2 php7.0-curl php7.0-gd php7.0-mbstring php7.0-mcrypt php7.0-xml php7.0-zip php7.0-mysql \
				php7.1 php7.1-bz2 php7.1-curl php7.1-gd php7.1-mbstring php7.1-mcrypt php7.1-xml php7.1-zip php7.1-mysql \
				php7.2 php7.2-bz2 php7.2-curl php7.2-gd php7.2-mbstring php7.2-xml php7.2-zip php7.2-mysql -y

		case ${DIST_ID} in
		Ubuntu)
			apt-add-repository ppa:nijel/phpmyadmin -y
			;;
		*)
			;;
		esac
	
		apt-get update
		apt-get install phpmyadmin -y

		a2disconf phpmyadmin
		systemctl restart apache2

		/bin/cp ${DATA_DIR}/root/bin/phpmyadmin-*.sh ~/bin/
		/bin/cp ${DATA_DIR}/root/bin/mysql-backup.sh ~/bin/
		/bin/cp ${DATA_DIR}/root/bin/cronjob-backup.sh ~/bin/

		case ${DIST_ID} in
		Ubuntu)
			patch /etc/phpmyadmin/apache.conf ${PATCH_DIR}/etc.phpmyadmin.apache.conf.patch
			patch /etc/phpmyadmin/config.inc.php ${PATCH_DIR}/etc.phpmyadmin.config.inc.php.patch
			;;
		Debian)
			case ${DIST_RELEASE} in
			8.*)
				patch /etc/phpmyadmin/apache.conf ${PATCH_DIR}/etc.phpmyadmin.apache.conf.patch
				patch /etc/phpmyadmin/config.inc.php ${PATCH_DIR}/etc.phpmyadmin.config.inc.php.debian8.patch
				;;
			9.*)
				patch /etc/phpmyadmin/apache.conf ${PATCH_DIR}/etc.phpmyadmin.apache.conf.patch
				patch /etc/phpmyadmin/config.inc.php ${PATCH_DIR}/etc.phpmyadmin.config.inc.php.debian9.patch
				;;
			*)
				;;
			esac
			;;
		*)
			;;
		esac
	
		sed --in-place 's/#Include \/etc\/apache2\/misc\/my-phpmyadmin/Include \/etc\/apache2\/misc\/my-phpmyadmin/' /etc/apache2/sites-available/${MY_SITE_CONFIG}.conf
		sed --in-place 's/Header always set Content-Security-Policy /# Header always set Content-Security-Policy /g' /etc/apache2/sites-available/${MY_SITE_CONFIG}.conf

		systemctl restart apache2

		touch ${STAMP_DIR}/phpmyadmin_installed
	else
		echo
		echo "#######################################################################################"
		echo "#"
		echo "# INFO: phpmyadmin installed already, skipping..."
		echo "#"
		echo "#######################################################################################"
		echo
	fi

}
