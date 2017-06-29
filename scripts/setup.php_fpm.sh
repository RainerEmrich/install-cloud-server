#!/bin/bash
#
# Set up php-fpm to have the chance to use different php versions.
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

setup_php_fpm () {

	if [ "${PHP_FPM_INSTALLED}" != "1" ] ; then

		echo
		echo "#######################################################################################"
		echo "#"
		echo "# Install and enable php7.0-fpm and php7.1-fpm."
		echo "#"
		echo "# The php-fpm status and ping pages are available for the admin host or local at:"
		echo "# https://${MY_FQDN}/fpm-status?html&full"
		echo "# https://${MY_FQDN}/fpm-ping"
		echo "#"
		echo "#######################################################################################"
		echo

		ask_to_continue

		apt-get update
		apt-get install php7.0-fpm php7.1-fpm

		PACKAGES=""
		for PACKAGE in $(dpkg -l | grep php7.0 | awk '{print $2}' | sed 's/7.0/7.1/') ; do PACKAGES="${PACKAGES} ${PACKAGE}"; done
		apt-get install ${PACKAGES} -y

		patch /etc/php/7.0/fpm/php.ini ${PATCH_DIR}/etc.php.7.0.fpm.php.ini.patch
		patch /etc/php/7.1/fpm/php.ini ${PATCH_DIR}/etc.php.7.1.fpm.php.ini.patch
		patch /etc/php/7.0/fpm/pool.d/www.conf ${PATCH_DIR}/etc.php.7.0.fpm.pool.d.www.conf.patch
		patch /etc/php/7.1/fpm/pool.d/www.conf ${PATCH_DIR}/etc.php.7.1.fpm.pool.d.www.conf.patch

		systemctl restart php7.0-fpm
		systemctl restart php7.1-fpm

		a2dismod php7.0 php7.1 mpm_prefork
		a2enmod proxy_fcgi setenvif mpm_event

		if [ -f /etc/apache2/mods-enabled/proxy_fcgi.conf ] ; then /bin/rm /etc/apache2/mods-enabled/proxy_fcgi.conf; fi

		patch /etc/apache2/conf-available/php7.0-fpm.conf ${PATCH_DIR}/etc.apache2.conf-available.php7.0-fpm.conf.patch
		patch /etc/apache2/conf-available/php7.1-fpm.conf ${PATCH_DIR}/etc.apache2.conf-available.php7.1-fpm.conf.patch

		sed --in-place 's/#Include \/etc\/apache2\/conf-available\/php7.1-fpm/Include \/etc\/apache2\/conf-available\/php7.1-fpm/' /etc/apache2/sites-available/${MY_SITE_CONFIG}.conf

		systemctl restart apache2

		touch ${STAMP_DIR}/php_fpm_installed
	else
		echo
		echo "#######################################################################################"
		echo "#"
		echo "# INFO: php-fpm installed already, skipping..."
		echo "#"
		echo "#######################################################################################"
		echo
	fi

}
