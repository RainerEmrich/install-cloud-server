#!/bin/bash
#
# Set up nextcloud.
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

setup_nextcloud () {

	if [ "${NEXTCLOUD_INSTALLED}" != "1" ] ; then

		echo
		echo "#######################################################################################"
		echo "#"
		echo "# Install nextcloud using the configuration in file"
		echo "# ${CONFIG_DIR}/nextcloud.sh"
		echo "#"
		echo "# Site domain: ${MY_NEXTCLOUD_DOMAIN}"
		echo "# DocumentRoot: ${MY_NEXTCLOUD_DR}"
		echo "# Data directory: ${MY_NEXTCLOUD_DATA_DIR}"
		echo "# MySQL Database: ${MY_DATABASE_NAME}"
		echo "# Nextcloud Admin user: ${MY_NC_ADMIN_NAME}"
		echo "# Nextcloud version: ${MY_NEXTCLOUD_VERSION}"
		echo "#"
		echo "#######################################################################################"
		echo

		ask_to_continue

		echo
		echo "#######################################################################################"
		echo "#"
		echo "# INFO: Creating database, and database user for nextcloud."
		echo "#"
		echo "#######################################################################################"
		echo

		mysql --defaults-extra-file=/etc/mysql/debian.cnf -Bse "create database ${MY_DATABASE_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
		mysql --defaults-extra-file=/etc/mysql/debian.cnf -Bse "create user '${MY_DATABASE_NAME}'@'localhost' identified by '${MY_DATABASE_PASSWD}';"
		mysql --defaults-extra-file=/etc/mysql/debian.cnf -Bse "grant all privileges on ${MY_DATABASE_NAME}.* to '${MY_DATABASE_NAME}'@'localhost';"
		mysql --defaults-extra-file=/etc/mysql/debian.cnf -Bse "flush privileges;"

		echo
		echo "#######################################################################################"
		echo "#"
		echo "# INFO: Creating DocumentRoot and Data directories for nextcloud."
		echo "#"
		echo "#######################################################################################"
		echo

		mkdir -p $(dirname ${MY_NEXTCLOUD_DR})
		mkdir -p ${MY_NEXTCLOUD_DATA_DIR}
		chown www-data:www-data ${MY_NEXTCLOUD_DATA_DIR}
		chmod o-rwx ${MY_NEXTCLOUD_DATA_DIR}

		echo
		echo "#######################################################################################"
		echo "#"
		echo "# INFO: Fetching nextcloud ${MY_NEXTCLOUD_VERSION}"
		echo "#       from https://download.nextcloud.com/server/releases/ for releases"
		echo "#       or"
		echo "#       from https://download.nextcloud.com/server/prereleases/ for release candidates."
		echo "#"
		echo "#######################################################################################"
		echo

		case ${MY_NEXTCLOUD_VERSION} in
		*daily*)
			wget https://download.nextcloud.com/server/daily/nextcloud-${MY_NEXTCLOUD_VERSION}.tar.bz2
			;;
		*RC*)
			wget https://download.nextcloud.com/server/prereleases/nextcloud-${MY_NEXTCLOUD_VERSION}.tar.bz2
			;;
		*)
			wget https://download.nextcloud.com/server/releases/nextcloud-${MY_NEXTCLOUD_VERSION}.tar.bz2
			;;
		esac

		tar -C $(dirname ${MY_NEXTCLOUD_DR}) -xf nextcloud-${MY_NEXTCLOUD_VERSION}.tar.bz2
		/bin/rm -f nextcloud-${MY_NEXTCLOUD_VERSION}.tar.bz2
		chown -R www-data:www-data ${MY_NEXTCLOUD_DR}
		chmod -R o-rwx ${MY_NEXTCLOUD_DR}

		echo
		echo "#######################################################################################"
		echo "#"
		echo "# INFO: Setup apache configuration for nextcloud."
		echo "#"
		echo "#######################################################################################"
		echo

		/bin/cp -a ${DATA_DIR}/etc/apache2/sites-available/999-mycloud-mydomain-tld-le-ssl.conf /etc/apache2/sites-available/
		/bin/cp -a /etc/apache2/sites-available/999-mycloud-mydomain-tld-le-ssl.conf /etc/apache2/sites-available/${MY_NEXTCLOUD_SITE_CONFIG}.conf

		sed --in-place "s/ServerAdmin webmaster@localhost/ServerAdmin ${MY_NEXTCLOUD_SA}/" /etc/apache2/sites-available/${MY_NEXTCLOUD_SITE_CONFIG}.conf
		sed --in-place "s/myhost.mydomain.tld/${MY_NEXTCLOUD_DOMAIN}/g" /etc/apache2/sites-available/${MY_NEXTCLOUD_SITE_CONFIG}.conf
		sed --in-place "s#my_document_root#${MY_NEXTCLOUD_DR}#g" /etc/apache2/sites-available/${MY_NEXTCLOUD_SITE_CONFIG}.conf

		case ${DIST_ID} in
		Debian)
			sed --in-place "s/Protocols h2/# Protocols h2/" /etc/apache2/sites-available/${MY_NEXTCLOUD_SITE_CONFIG}.conf
			;;
		*)
			;;
		esac

		echo
		echo "#######################################################################################"
		echo "#"
		echo "# INFO: Get let's encrypt certificate for the nextcloud site."
		echo "#"
		echo "#######################################################################################"
		echo

		echo "letsencrypt --apache --non-interactive --agree-tos --hsts --uir --email ${MY_EMAIL} --rsa-key-size ${MY_KEY_SIZE} -d ${MY_NEXTCLOUD_DOMAIN}" >~/Dokumentation/letsencrypt/${MY_NEXTCLOUD_DOMAIN}.txt
		letsencrypt --apache --non-interactive --agree-tos --hsts --uir --email ${MY_EMAIL} --rsa-key-size ${MY_KEY_SIZE} -d ${MY_NEXTCLOUD_DOMAIN}

		echo
		echo "#######################################################################################"
		echo "#"
		echo "# INFO: Creating scripts to set strong permissions and to set permissions for upgrade."
		echo "#"
		echo "# ~/bin/${_MY_NEXTCLOUD_DOMAIN_}-safe.sh"
		echo "# ~/bin/${_MY_NEXTCLOUD_DOMAIN_}-upgrade.sh"
		echo "#"
		echo "#######################################################################################"
		echo

		/bin/cp -a ${DATA_DIR}/root/bin/nc_template-safe.sh ~/bin/${_MY_NEXTCLOUD_DOMAIN_}-safe.sh
		sed --in-place "s#my_ncpath#${MY_NEXTCLOUD_DR}#" ~/bin/${_MY_NEXTCLOUD_DOMAIN_}-safe.sh
		/bin/cp -a ${DATA_DIR}/root/bin/nc_template-upgrade.sh ~/bin/${_MY_NEXTCLOUD_DOMAIN_}-upgrade.sh
		sed --in-place "s#my_ncpath#${MY_NEXTCLOUD_DR}#" ~/bin/${_MY_NEXTCLOUD_DOMAIN_}-upgrade.sh

		a2ensite ${MY_NEXTCLOUD_SITE_CONFIG}
		systemctl reload apache2

		cd ${MY_NEXTCLOUD_DR}

		sudo -u www-data php7.1 occ maintenance:install --database "mysql" \
			--database-name "${MY_DATABASE_NAME}" --database-user "${MY_DATABASE_NAME}" --database-pass "${MY_DATABASE_PASSWD}" \
			--admin-user "${MY_NC_ADMIN_NAME}" --admin-pass "${MY_NC_ADMIN_PASSWD}" --data-dir "${MY_NEXTCLOUD_DATA_DIR}"

		~/bin/${_MY_NEXTCLOUD_DOMAIN_}-safe.sh

		MY_NEXTCLOUD_HOSTNAME="$(echo "${MY_NEXTCLOUD_DOMAIN}" | cut -d "." -f 1)"

		grep -v ');' ${MY_NEXTCLOUD_DR}/config/config.php >${MY_NEXTCLOUD_DR}/config/config.php.tmp
		echo "  'memcache.local' => '\\OC\\Memcache\\APCu'," >>${MY_NEXTCLOUD_DR}/config/config.php.tmp
		echo "  'memcache.distributed' => '\\OC\\Memcache\\Redis'," >>${MY_NEXTCLOUD_DR}/config/config.php.tmp
		echo "  'memcache.locking' => '\\OC\\Memcache\\Redis'," >>${MY_NEXTCLOUD_DR}/config/config.php.tmp
		echo "  'redis' =>" >>${MY_NEXTCLOUD_DR}/config/config.php.tmp
		echo "  array (" >>${MY_NEXTCLOUD_DR}/config/config.php.tmp
		echo "    'host' => '/var/run/redis/redis.sock'," >>${MY_NEXTCLOUD_DR}/config/config.php.tmp
		echo "    'port' => 0," >>${MY_NEXTCLOUD_DR}/config/config.php.tmp
		echo "    'timeout' => 0," >>${MY_NEXTCLOUD_DR}/config/config.php.tmp
		echo "    'dbindex' => ${MY_REDIS_DB_NUMBER}," >>${MY_NEXTCLOUD_DR}/config/config.php.tmp
		echo "  )," >>${MY_NEXTCLOUD_DR}/config/config.php.tmp
		echo "  'filelocking.enabled' => true," >>${MY_NEXTCLOUD_DR}/config/config.php.tmp
		echo "  'appstore.experimental.enabled' => 'true'," >>${MY_NEXTCLOUD_DR}/config/config.php.tmp
		echo "  'updater.server.url' => 'https://updates.nextcloud.org/updater_server/'," >>${MY_NEXTCLOUD_DR}/config/config.php.tmp
		echo "  'updater.release.channel' => 'stable'," >>${MY_NEXTCLOUD_DR}/config/config.php.tmp
		echo "  'mail_smtpmode' => 'smtp'," >>${MY_NEXTCLOUD_DR}/config/config.php.tmp
		echo "  'mail_from_address' => '${MY_NEXTCLOUD_HOSTNAME}'," >>${MY_NEXTCLOUD_DR}/config/config.php.tmp
		echo "  'mail_domain' => '${MY_NEXTCLOUD_DOMAIN}'," >>${MY_NEXTCLOUD_DR}/config/config.php.tmp
		echo "  'mail_smtphost' => 'localhost'," >>${MY_NEXTCLOUD_DR}/config/config.php.tmp
		echo "  'mail_smtpport' => '25'," >>${MY_NEXTCLOUD_DR}/config/config.php.tmp
		echo "  'enable_previews' => true," >>${MY_NEXTCLOUD_DR}/config/config.php.tmp
		echo "  'preview_max_x' => 1024," >>${MY_NEXTCLOUD_DR}/config/config.php.tmp
		echo "  'preview_max_y' => 1024," >>${MY_NEXTCLOUD_DR}/config/config.php.tmp
		echo "  'preview_max_scale_factor' => 8," >>${MY_NEXTCLOUD_DR}/config/config.php.tmp
		echo "  'trashbin_retention_obligation' => 'auto'," >>${MY_NEXTCLOUD_DR}/config/config.php.tmp
		echo "  'maintenance' => false," >>${MY_NEXTCLOUD_DR}/config/config.php.tmp
		echo "  'theme' => ''," >>${MY_NEXTCLOUD_DR}/config/config.php.tmp
		echo "  'loglevel' => 2," >>${MY_NEXTCLOUD_DR}/config/config.php.tmp
		echo ");" >>${MY_NEXTCLOUD_DR}/config/config.php.tmp

		sed --in-place "s#    0 => 'localhost',#    0 => '${MY_NEXTCLOUD_DOMAIN}',#" ${MY_NEXTCLOUD_DR}/config/config.php.tmp
		sed --in-place "s#  'overwrite.cli.url' => 'http://localhost',#  'overwrite.cli.url' => 'https://${MY_NEXTCLOUD_DOMAIN}',#" ${MY_NEXTCLOUD_DR}/config/config.php.tmp

		chown www-data:www-data ${MY_NEXTCLOUD_DR}/config/config.php.tmp
		chmod 640 ${MY_NEXTCLOUD_DR}/config/config.php.tmp
		/bin/mv -f ${MY_NEXTCLOUD_DR}/config/config.php.tmp ${MY_NEXTCLOUD_DR}/config/config.php

		sed --in-place 's/# Require all granted/Require all granted/' /etc/apache2/sites-available/${MY_NEXTCLOUD_SITE_CONFIG}.conf
		systemctl reload apache2

		cd ${START_DIR}

		echo
		echo "#######################################################################################"
		echo "#"
		echo "# INFO: Install nextcloud cronjob, please change to cron in the nextcloud admin page."
		echo "#"
		echo "#######################################################################################"
		echo

		( echo "# Edit this file to introduce tasks to be run by cron." ; \
		  echo "#" ; \
		  echo "# Each task to run has to be defined through a single line" ; \
		  echo "# indicating with different fields when the task will be run" ; \
		  echo "# and what command to run for the task" ; \
		  echo "#" ; \
		  echo "# To define the time you can provide concrete values for" ; \
		  echo "# minute (m), hour (h), day of month (dom), month (mon)," ; \
		  echo "# and day of week (dow) or use '*' in these fields (for 'any').#" ; \
		  echo "# Notice that tasks will be started based on the cron's system" ; \
		  echo "# daemon's notion of time and timezones." ; \
		  echo "#" ; \
		  echo "# Output of the crontab jobs (including errors) is sent through" ; \
		  echo "# email to the user the crontab file belongs to (unless redirected)." ; \
		  echo "#" ; \
		  echo "# For example, you can run a backup of all your user accounts" ; \
		  echo "# at 5 a.m every week with:" ; \
		  echo "# 0 5 * * 1 tar -zcf /var/backups/home.tgz /home/" ; \
		  echo "#" ; \
		  echo "# For more information see the manual pages of crontab(5) and cron(8)" ; \
		  echo "#" ; \
		  echo "# m h  dom mon dow   command" ; \
		  echo "0,15,30,45  *  *  *  * php7.1 -f ${MY_NEXTCLOUD_DR}/cron.php >/dev/null 2>&1") | crontab -u www-data -

		touch ${STAMP_DIR}/nextcloud_installed

		echo
		echo "#######################################################################################"
		echo "#"
		echo "# INFO: Nextcloud installation finished."
		echo "#"
		echo "#######################################################################################"
		echo
	else
		echo
		echo "#######################################################################################"
		echo "#"
		echo "# INFO: Nextcloud installed already, skipping..."
		echo "#"
		echo "#######################################################################################"
		echo
	fi

}
