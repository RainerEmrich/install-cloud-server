#!/bin/bash
#
# Set up postfix with ssl
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

setup_postfix () {

	if [ "${POSTFIX_SETUP}" != "1" ] ; then

		echo
		echo "#######################################################################################"
		echo "#"
		echo "# Set an e-mail redirection for the root user."
		echo "# Change postfix configuration to use tls and a smtp relay."
		echo "# See configuration in file"
		echo "# ${CONFIG_DIR}/postfix.sh"
		echo "#"
		echo "# E-mail address for redirection: ${MY_MAIL_REDIRECT}"
		echo "# Relayhost: ${MY_MAIL_RELAY}"
		echo "# Relayhost port: ${MY_MAIL_RELAY_PORT}"
		echo "# Relayhost user: ${MY_MAIL_RELAY_USER}"
		echo "# Relayhost passwd: ${MY_MAIL_RELAY_PASSWD}"
		echo "#"
		echo "#######################################################################################"
		echo

		ask_to_continue

		echo "${MY_MAIL_RELAY} ${MY_MAIL_RELAY_USER}:${MY_MAIL_RELAY_PASSWD}" >/etc/postfix/sasl_passwd
		postmap /etc/postfix/sasl_passwd

		case ${DIST_ID} in
		Debian)
			case ${DIST_RELEASE} in
			8.*)
				sed --in-place "/html_directory/d" /etc/postfix/main.cf
				echo "inet_protocols = all" >>/etc/postfix/main.cf
				;;
			9.*)
				sed --in-place "/html_directory/d" /etc/postfix/main.cf
				;;
			*)
				;;
			esac
			;;
		*)
			;;
		esac

		patch /etc/postfix/main.cf ${PATCH_DIR}/etc.postfix.main.cf.patch
		sed --in-place "s/myhostname = localhost.localdomain/myhostname = ${MY_FQDN}/" /etc/postfix/main.cf
		sed --in-place "s/myhost.mydomain.tld/${MY_FQDN}/g" /etc/postfix/main.cf
		sed --in-place "s/relayhost =/relayhost = ${MY_MAIL_RELAY}/" /etc/postfix/main.cf

		echo "root:          ${MY_MAIL_REDIRECT}" >>/etc/aliases
		newaliases

		systemctl restart postfix

		sed --in-place 's/\/\/Unattended-Upgrade::Mail /Unattended-Upgrade::Mail /' /etc/apt/apt.conf.d/50unattended-upgrades

		touch ${STAMP_DIR}/postfix_setup
	else
		echo
		echo "#######################################################################################"
		echo "#"
		echo "# INFO: Postfix is setup already, skipping..."
		echo "#"
		echo "#######################################################################################"
		echo
	fi

}
