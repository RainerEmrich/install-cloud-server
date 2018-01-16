#!/bin/bash
#
# Set up letsencrypt.
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

setup_letsencrypt () {

	if [ "${LETSENCRYPT_INSTALLED}" != "1" ] ; then

		echo
		echo "#######################################################################################"
		echo "#"
		echo "# Install letsencrypt using the ppa certbot/certbot and get a first certificate,"
		echo "# configure apache2"
		echo "#"
		echo "# Configuration paramter are set in file"
		echo "# ${CONFIG_DIR}/letsencrypt.sh"
		echo "#"
		echo "# E-mail address for letsencrypt: ${MY_EMAIL}"
		echo "# Rsa key size for letsencrypt: ${MY_KEY_SIZE}"
		echo "# Webmaster e-mail for the webpage: ${WEBMASTER_EMAIL}"
		echo "# Admin host for the web server: ${ADMINHOST}"
		echo "#"
		echo "#######################################################################################"
		echo

		ask_to_continue

		case ${DIST_ID} in
		Ubuntu)
			apt-add-repository -y ppa:certbot/certbot

			apt-get update
			apt-get install certbot python-certbot-apache python-certbot-doc python-acme-doc python-cryptography-vectors python-certbot-apache-doc python-openssl-doc -y
			apt-get dist-upgrade -y
			apt-get autoremove --purge -y
			;;
		Debian)
			echo "deb http://ftp.debian.org/debian ${DIST_CODENAME}-backports main" >/etc/apt/sources.list.d/backports.list
			apt-get update
			apt-get install python-certbot-apache -t ${DIST_CODENAME}-backports -y
			apt-get autoremove --purge -y
			;;
		*)
			;;
		esac

		mkdir -p ~/Dokumentation/letsencrypt/
		echo "letsencrypt --authenticator webroot --webroot-path /var/www/html --installer apache --non-interactive --agree-tos --hsts --uir --email ${MY_EMAIL} --rsa-key-size ${MY_KEY_SIZE} -d ${MY_FQDN}" >~/Dokumentation/letsencrypt/${MY_FQDN}.txt

		letsencrypt --authenticator webroot --webroot-path /var/www/html --installer apache --non-interactive --agree-tos --hsts --uir --email ${MY_EMAIL} --rsa-key-size ${MY_KEY_SIZE} -d ${MY_FQDN}

		patch /etc/letsencrypt/options-ssl-apache.conf ${PATCH_DIR}/etc.letsencrypt.options-ssl-apache.conf.patch
		case ${DIST_ID} in
		Debian)
			sed --in-place "s/SSLOpenSSLConfCmd ECDHParameters/# SSLOpenSSLConfCmd ECDHParameters/" /etc/letsencrypt/options-ssl-apache.conf
			sed --in-place "s/SSLOpenSSLConfCmd Curves/# SSLOpenSSLConfCmd Curves/" /etc/letsencrypt/options-ssl-apache.conf
			sed --in-place "s/SSLSessionTickets/# SSLSessionTickets/" /etc/letsencrypt/options-ssl-apache.conf
			;;
		*)
			;;
		esac

		echo "# This is an example of the kind of things you can do in a configuration file." >/etc/letsencrypt/cli.ini
		echo "# All flags used by the client can be configured here. Run Let's Encrypt with" >>/etc/letsencrypt/cli.ini
		echo "# "--help" to learn more about the available options." >>/etc/letsencrypt/cli.ini
		echo "" >>/etc/letsencrypt/cli.ini
		echo "# Use a 4096 bit RSA key instead of 2048" >>/etc/letsencrypt/cli.ini
		echo "rsa-key-size = ${MY_KEY_SIZE}" >>/etc/letsencrypt/cli.ini
		echo "" >>/etc/letsencrypt/cli.ini
		echo "# Uncomment and update to register with the specified e-mail address" >>/etc/letsencrypt/cli.ini
		echo "email = ${MY_EMAIL}" >>/etc/letsencrypt/cli.ini
		echo "" >>/etc/letsencrypt/cli.ini
		echo "# Uncomment and update to generate certificates for the specified" >>/etc/letsencrypt/cli.ini
		echo "# domains." >>/etc/letsencrypt/cli.ini
		echo "# domains = example.com, www.example.com" >>/etc/letsencrypt/cli.ini
		echo "" >>/etc/letsencrypt/cli.ini
		echo "# Uncomment to use a text interface instead of ncurses" >>/etc/letsencrypt/cli.ini
		echo "# text = True" >>/etc/letsencrypt/cli.ini
		echo "" >>/etc/letsencrypt/cli.ini
		echo "# Uncomment to use the standalone authenticator on port 443" >>/etc/letsencrypt/cli.ini
		echo "# authenticator = standalone" >>/etc/letsencrypt/cli.ini
		echo "# standalone-supported-challenges = tls-sni-01" >>/etc/letsencrypt/cli.ini
		echo "" >>/etc/letsencrypt/cli.ini
		echo "# Uncomment to use the webroot authenticator. Replace webroot-path with the" >>/etc/letsencrypt/cli.ini
		echo "# path to the public_html / webroot folder being served by your web server." >>/etc/letsencrypt/cli.ini
		echo "# authenticator = webroot" >>/etc/letsencrypt/cli.ini
		echo "# webroot-path = /usr/share/nginx/html" >>/etc/letsencrypt/cli.ini

		patch /etc/apache2/conf-available/security.conf ${PATCH_DIR}/etc.apache2.conf-available.security.conf.patch
		patch /etc/apache2/conf-available/apache2-doc.conf ${PATCH_DIR}/etc.apache2.conf-available.apache2-doc.conf.patch
		patch /etc/apache2/mods-available/info.conf ${PATCH_DIR}/etc.apache2.mods-available.info.conf.patch
		patch /etc/apache2/mods-available/ssl.conf ${PATCH_DIR}/etc.apache2.mods-available.ssl.conf.patch
		patch /etc/apache2/mods-available/status.conf ${PATCH_DIR}/etc.apache2.mods-available.status.conf.patch
		patch /etc/apache2/sites-available/000-default.conf ${PATCH_DIR}/etc.apache2.sites-available.000-default.conf.patch
		sed --in-place "s/ServerAdmin webmaster@localhost/ServerAdmin ${WEBMASTER_EMAIL}/" /etc/apache2/sites-available/000-default.conf
		/bin/cp -af ${DATA_DIR}/etc/apache2/sites-available/000-default-le-ssl.conf /etc/apache2/sites-available/
		sed --in-place "s/ServerAdmin webmaster@localhost/ServerAdmin ${WEBMASTER_EMAIL}/" /etc/apache2/sites-available/000-default-le-ssl.conf
		sed --in-place "s/myhost.mydomain.tld/${MY_FQDN}/g" /etc/apache2/sites-available/000-default-le-ssl.conf

		a2enmod info rewrite
		case ${DIST_ID} in
		Ubuntu)
			a2enmod http2
			;;
		*)
			;;
		esac
		/bin/rm -f /etc/apache2/mods-enabled/info.conf

		/bin/rm -rf /var/www/html
		tar -C /var/www -xvf ${ARCHIVES_DIR}/html.tar

		/bin/cp -a ${DATA_DIR}/var/www/phpinfo /var/www/
		/bin/cp -a ${DATA_DIR}/etc/apache2/conf-available/phpinfo.conf /etc/apache2/conf-available/

		tar -C /etc/apache2 -xvf ${ARCHIVES_DIR}/misc.tar

		/bin/cp -a ${DATA_DIR}/etc/apache2/sites-available/999-myhost-mydomain-tld-le-ssl.conf /etc/apache2/sites-available/

		/bin/cp -a /etc/apache2/sites-available/999-myhost-mydomain-tld-le-ssl.conf /etc/apache2/sites-available/${MY_SITE_CONFIG}.conf

		sed --in-place "s/ServerAdmin webmaster@localhost/ServerAdmin ${WEBMASTER_EMAIL}/" /etc/apache2/sites-available/${MY_SITE_CONFIG}.conf
		sed --in-place "s/myhost.mydomain.tld/${MY_FQDN}/g" /etc/apache2/sites-available/${MY_SITE_CONFIG}.conf

		a2ensite ${MY_SITE_CONFIG}

		case ${DIST_ID} in
		Debian)
			sed --in-place "s/Protocols h2/# Protocols h2/" /etc/apache2/sites-available/000-default-le-ssl.conf
			sed --in-place "s/Protocols h2/# Protocols h2/" /etc/apache2/sites-available/${MY_SITE_CONFIG}.conf
			;;
		*)
			;;
		esac

		systemctl restart apache2

		/bin/cp ${DATA_DIR}/root/bin/letsencrypt-* ~/bin/
		/bin/cp ${DATA_DIR}/root/bin/setmyhost.sh ~/bin/

		~/bin/setmyhost.sh ${ADMINHOST}

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
		  echo "33 1 * * *      /root/bin/letsencrypt-updatecerts.sh" ; \
		  echo "*/5 * * * *     /root/bin/setmyhost.sh ${ADMINHOST}" ; \
  		  echo "# 11 2 * * *      /root/bin/cronjob-backup.sh >/dev/null") | crontab -

		echo
		echo "#######################################################################################"
		echo "#"
		echo "# INFO: Letsencrypt installation and apache2 configuration finished!"
		echo "#"
		echo "#       The follwing web pages are setup:"
		echo "#"
		echo "#       Public accessible:"
		echo "#       https://${MY_FQDN}/"
		echo "#"
		echo "#       Accessible only local or from admin host ${ADMINHOST}:"
		echo "#       https://${MY_FQDN}/server-info/"
		echo "#       https://${MY_FQDN}/server-status/"
		echo "#       https://${MY_FQDN}/manual/"
		echo "#       https://${MY_FQDN}/phpinfo/"
		echo "#"
		echo "#######################################################################################"
		echo

		pause

		touch ${STAMP_DIR}/letsencrypt_installed
	else
		echo
		echo "#######################################################################################"
		echo "#"
		echo "# INFO: Letsencrypt installed already, skipping..."
		echo "#"
		echo "#######################################################################################"
		echo
	fi

}
