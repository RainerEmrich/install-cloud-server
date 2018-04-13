#!/bin/bash
#
# Show some information about the script.
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

show_info () {

	echo "#######################################################################################"
	echo "#                                                                                     #"
	echo "# This script sets up and configures an 1&1 cloud server for the use with nextcloud.  #"
	echo "#                                                                                     #"
	echo "# The script is tested on an 1&1 Cloud Server S with the following configuration:     #"
	echo "#                                                                                     #"
	echo "# 1&1 Cloud Server S                                                                  #"
	echo "# CPU: 1 vcore                                                                        #"
	echo "# RAM: 0.5 GB                                                                         #"
	echo "# SSD: 30 GB                                                                          #"
	echo "#                                                                                     #"
	echo "# OS: Ubuntu 16.04 64-bit Standard Installation                                       #"
	echo "# OS: Debian 8 64-bit Standard Installation                                           #"
	echo "# OS: Debian 9 64-bit Standard Installation                                           #"
	echo "#                                                                                     #"
	echo "# Networking devices:                                                                 #"
	echo "# ens192: public network, ipv4 address assigned,                                      #"
	echo "#         DNS entry configured on the ISP site,                                       #"
	echo "#         reverse DNS entry configured in the cloud panel                             #"
	echo "# ens224: private network, assigned to a private network                              #"
	echo "#                                                                                     #"
	echo "# Firewall Policy: Linux                                                              #"
	echo "#                                                                                     #"
	echo "# Note: On Debian 8 the network devices are eth0 and eth1.                            #"
	echo "#                                                                                     #"
	echo "#######################################################################################"
	echo

}
