#!/bin/bash
#
# Set up hostname, private network, sshd config and ssh keys.
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

setup_hostname_network_ssh () {

	if [ "${UPGRADE_DONE}" != "1" ] ; then
		echo
		echo "#######################################################################################"
		echo "#"
		echo "# First we update the installed software and install the required patch package."
		echo "#"
		echo "#######################################################################################"
		echo

		ask_to_continue

		apt-get update
		apt-get upgrade -y
		apt-get dist-upgrade -y
		apt-get autoremove --purge -y
		apt-get install patch patchutils

		touch ${STAMP_DIR}/upgrade_done
	fi

	echo
	echo "#######################################################################################"
	echo "#"
	echo "# Setup hostname, private network and ssh configuration."
	echo "#"
	echo "#######################################################################################"

	if [ "${CURRENT_FQDN}" != "${MY_FQDN}" ] ; then
		echo
		echo "#######################################################################################"
		echo "#"
		echo "# Setup the hostname according to the configuration file"
		echo "# ${CONFIG_DIR}/hostname.sh"
		echo "#"
		echo "# hostname: ${MY_HOSTNAME}"
		echo "# dnsdomainname: ${MY_DOMAIN}"
		echo "# FQDN: ${MY_FQDN}"
		echo "#"
		echo "#######################################################################################"
		echo

		ask_to_continue

		hostnamectl set-hostname ${MY_FQDN}

		sed --in-place "s/127.0.1.1 .*/127.0.1.1       $MY_FQDN $MY_HOSTNAME/" /etc/hosts
		echo "${MY_GLOBAL_IP}   ${MY_FQDN}" >>/etc/hosts

		echo "${MY_FQDN}" >/etc/mailname

		/bin/cp ${DATA_DIR}/root/.toprc ~/
		echo "alias rm='rm -i'" >~/.bash_aliases
		echo "alias cp='cp -i'" >>~/.bash_aliases
		echo "alias mv='mv -i'" >>~/.bash_aliases
		echo "alias ln='ln -i'" >>~/.bash_aliases

		mkdir -p ~/bin

		touch ${STAMP_DIR}/hostname_set
	else
		echo
		echo "#######################################################################################"
		echo "#"
		echo "# INFO: Host has the right hostname setup already, skipping..."
		echo "#"
		echo "#######################################################################################"
		echo
	fi

	if [ "${NETWORK_SET}" != "1" ] ; then
		echo
		echo "#######################################################################################"
		echo "#"
		echo "# Setup a private network interface according to the configuration file"
		echo "# ${CONFIG_DIR}/network.sh"
		echo "#"

		if [ "${SETUP_PRIVATE_NETWORK}" == "1" ] ; then

			if [ "${MY_PRIVATE_NETWORK_NAME}" == "" ] ; then
				MY_PRIVATE_NETWORK_NAME="${MY_HOSTNAME}-priv"
			fi

			echo "# The following configuration will be used:"
			echo "# Device: ${MY_PRIVATE_NETWORK_DEVICE}"
			echo "# IP: ${MY_PRIVATE_NETWORK_IP}"
			echo "# NETMASK: ${MY_PRIVATE_NETWORK_MASK}"
			echo "# NAME: ${MY_PRIVATE_NETWORK_NAME}"
			echo "#"
			echo "#######################################################################################"
			echo

			ask_to_continue

			if [ "${AVAILABLE_NETWORK_DEVICE}" == "" ] ; then
				echo
				echo "#######################################################################################"
				echo "#"
				echo "# ERROR: No network device available."
				echo "#"
				echo "#        Exiting..."
				echo "#"
				echo "#######################################################################################"
				echo

				exit
			elif [ "${AVAILABLE_NETWORK_DEVICE}" != "${MY_PRIVATE_NETWORK_DEVICE}" ] ; then
				echo
				echo "#######################################################################################"
				echo "#"
				echo "# ERROR: Available network device ${AVAILABLE_NETWORK_DEVICE} differs from configured network device ${MY_PRIVATE_NETWORK_DEVICE}."
				echo "#"
				echo "#        Exiting..."
				echo "#"
				echo "#######################################################################################"
				echo

				exit
			else
				case ${DIST_ID} in
				Debian)
					case ${DIST_RELEASE} in
					8.*)
						echo "# The private network interface" >/etc/network/interfaces.d/${MY_PRIVATE_NETWORK_DEVICE}.cfg
						echo "auto ${MY_PRIVATE_NETWORK_DEVICE}" >>/etc/network/interfaces.d/${MY_PRIVATE_NETWORK_DEVICE}.cfg
						echo "iface ${MY_PRIVATE_NETWORK_DEVICE} inet static" >>/etc/network/interfaces.d/${MY_PRIVATE_NETWORK_DEVICE}.cfg
						echo "address ${MY_PRIVATE_NETWORK_IP}" >>/etc/network/interfaces.d/${MY_PRIVATE_NETWORK_DEVICE}.cfg
						echo "netmask ${MY_PRIVATE_NETWORK_MASK}" >>/etc/network/interfaces.d/${MY_PRIVATE_NETWORK_DEVICE}.cfg
						;;
					esac
					;;
				*)
					echo "" >>/etc/network/interfaces
					echo "# The private network interface" >>/etc/network/interfaces
					echo "auto ${MY_PRIVATE_NETWORK_DEVICE}" >>/etc/network/interfaces
					echo "iface ${MY_PRIVATE_NETWORK_DEVICE} inet static" >>/etc/network/interfaces
					echo "address ${MY_PRIVATE_NETWORK_IP}" >>/etc/network/interfaces
					echo "netmask ${MY_PRIVATE_NETWORK_MASK}" >>/etc/network/interfaces
					;;
				esac

				echo "" >>/etc/hosts
				echo "${MY_PRIVATE_NETWORK_IP}   ${MY_PRIVATE_NETWORK_NAME}" >>/etc/hosts
			fi

		else

			echo "# INFO: Setup of a private network, not requested in the configuration, skipping..."
			echo "#"
			echo "#######################################################################################"
			echo

			ask_to_continue

		fi

		touch ${STAMP_DIR}/network_set
	else
		echo
		echo "#######################################################################################"
		echo "#"
		echo "# INFO: Private network interface already setup, skipping..."
		echo "#"
		echo "#######################################################################################"
		echo
	fi

	if [ "${HOSTS_SET}" != "1" ] ; then

		echo
		echo "#######################################################################################"
		echo "#"
		echo "# Additional entries for the /etc/hosts file may be put in the file"
		echo "# ${CONFIG_DIR}/etc.hosts.part"
		echo "# This file will be appended to /etc/hosts"
		echo "#"
		echo "# Current content of ${CONFIG_DIR}/etc.hosts.part:"
		echo "#"
		cat ${CONFIG_DIR}/etc.hosts.part
		echo "#"
		echo "#######################################################################################"
		echo

		ask_to_continue

		cat ${CONFIG_DIR}/etc.hosts.part >>/etc/hosts

		touch ${STAMP_DIR}/hosts_set
	else
		echo
		echo "#######################################################################################"
		echo "#"
		echo "# INFO: /etc/hosts already setup, skipping..."
		echo "#"
		echo "#######################################################################################"
		echo
	fi

	if [ "${SSH_SET}" != "1" ] ; then

		if [ ! -f "${CONFIG_DIR}/ssh/authorized_keys" ] ; then

			echo
			echo "#######################################################################################"
			echo "#"
			echo "# ERROR: ${CONFIG_DIR}/ssh/authorized_keys not found!"
			echo "#"
			echo "#        If we would continue now, you wouldn't be able to logon to the system again."
			echo "#"
			echo "# Put your public ed25519 ssh key(s) in the file ${CONFIG_DIR}/ssh/authorized_keys"
			echo "# Pregenerated ssh key(s) for the account at your new host put in the directory"
			echo "# ${CONFIG_DIR}/ssh/ too."
			echo "# The content of the directory will be copied to your .ssh directory."
			echo "#"
			echo "#######################################################################################"
			echo

			exit

		else

			echo
			echo "#######################################################################################"
			echo "#"
			echo "# Important: SSH will be setup to allow publickey authentication only!!!"
			echo "#"
			echo "# Put your public ed25519 ssh key(s) in the file ${CONFIG_DIR}/ssh/authorized_keys"
			echo "# Pregenerated ssh key(s) for the account at your new host put in the directory"
			echo "# ${CONFIG_DIR}/ssh/ too."
			echo "# Current content of ${CONFIG_DIR}/ssh/authorized_keys:"
			echo "#"
			cat ${CONFIG_DIR}/ssh/authorized_keys
			echo "#"
			echo "# Please check carefully."
			echo "#"
			echo "#######################################################################################"
			echo

			ask_to_continue

			mkdir -p ~/.ssh
			chmod 700 ~/.ssh
			/bin/cp ${CONFIG_DIR}/ssh/* ~/.ssh/
			chmod 600 ~/.ssh/*
			test -f ~/.ssh/*.pub && chmod 644 ~/.ssh/*.pub

			patch /etc/ssh/sshd_config ${PATCH_DIR}/etc.ssh.sshd_config.patch

			touch ${STAMP_DIR}/ssh_set

			echo
			echo "#######################################################################################"
			echo "#"
			echo "# Now we reboot the system forcing all changes to take effect."
			echo "#"
			echo "#######################################################################################"
			echo

			ask_to_continue

			reboot
		fi
	else
		echo
		echo "#######################################################################################"
		echo "#"
		echo "# INFO: SSH configuration already setup, skipping..."
		echo "#"
		echo "#######################################################################################"
		echo
	fi

}
