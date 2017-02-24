#!/bin/bash
#
# Utility to set a "Require host" record for apache
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
# You may adopt the following three variables to your needs
configdir="/etc/apache2/misc"
configfile="my-current-admin-host.conf"
comparefile="my-old-admin-host.txt"

#
# My own name
#
myname=$0

#
# define funktion usage
#
usage()
{
	echo "Usage: ${myname} [ options ] <host>"
	echo ""
	echo "Options:"
	echo "         -h, --help     print usage"
	echo "         -v, --verbose  give verbose output"
	echo ""
}

#
# parse arguments
#
dyndnsname=""

for arg in "$@"; do
	case $arg in
		-h|--help)
			usage
			exit 0
		;;
		-v|--verbose)
			verbose="true"
		;;
		-*)
			echo "Error: Unknown option $arg"
			usage
			exit 0
		;;
		*)
			if [ "${dyndnsname}" == "" ] ; then
				dyndnsname=${arg}
			else
				echo "Error: No extra parameter allowed: $arg"
				usage
				exit 0
			fi
		;;
	esac
done

# Check if configdir exists
if [ ! -d "${configdir}" ] ; then
	echo "Error: Configuration directory ${configdir} doesn't exist!"
	exit 2
fi

# Check if comparefile exists
if [ ! -f "${configdir}/${comparefile}" ] ; then
	echo "Warning: File ${configdir}/${comparefile} doesn't exist, creating an empty one"
	touch "${configdir}/${comparefile}"
fi


if [[ ${dyndnsname} =~ [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3} ]] ; then

	myipaddress="${dyndnsname}"

	# Read the old name, stored the last time the name changed.
	myoldhostname=`cat ${configdir}/${comparefile}`

	# Hostname is the IPv4 address
	myhostname=${myipaddress}

	if [ "${myhostname}" != "${myoldhostname}" ] ; then
		echo "Host has changed."
		echo "Given hostname is:        ${dyndnsname}"
		echo "IPv4 address is:          ${myipaddress}"
		echo "The current hostname is:  ${myhostname}"
		echo "The old hostname was:     ${myoldhostname}"
		echo "Writing new configuration file and reloading apache!"

		# Write new configuration file. This file has to be included in the right places.
		echo "Require ip ${myhostname}" >${configdir}/${configfile}

		# Write new current admin host to text file for easy comparison.
		echo "${myhostname}" >${configdir}/${comparefile}

		# Reload apache, suppress normal output.
		systemctl reload apache2
	else
		if [ $2 ] ; then
			if [ $verbose ] ; then
				echo "Host has not changed."
				echo "Given hostname is:        ${dyndnsname}"
				echo "IPv4 address is:          ${myipaddress}"
				echo "The current hostname is:  ${myhostname}"
				echo "The old hostname was:     ${myoldhostname}"
				echo "Nothing to do!"
			fi
		fi
	fi
else

	# Lookup the IP address for dyndnsname.
	myipaddress_tmp=`host -t A ${dyndnsname}`

	# Check for Error!
	case "$myipaddress_tmp" in
		# No Error. We are only interested in the A record. Extract the fourth field it's the IP.
		*"$dyndnsname has address"*)
			myipaddress=`echo $myipaddress_tmp | cut -d " " -f 4`
		;;
		# Error
		*)
			echo "Error: $myipaddress_tmp"
			echo "Restrict to localhost.localdomain"
			myipaddress="127.0.0.1"
		;;
	esac

	# Now we do a reverse lookup.
	myhostname_tmp=`host ${myipaddress}`

	# Check for Error!
	case "$myhostname_tmp" in
		# No Error. Extract the fifth field it's the name.
		*".in-addr.arpa domain name pointer "*)
			myhostname=`echo $myhostname_tmp | cut -d " " -f 5`
		;;
		# Error
		*)
			echo "Error: $myhostname_tmp"
			echo "Restrict to localhost.localdomain"
			myhostname="localhost.localdomain."
		;;
	esac

	# Remove the trailing dot.
	myhostname=`echo ${myhostname%.}`

	# Read the old name, stored the last time the name changed.
	myoldhostname=`cat ${configdir}/${comparefile}`

	if [ "${myhostname}" != "${myoldhostname}" ] ; then
		echo "Host has changed."
		echo "Given hostname is:        ${dyndnsname}"
		echo "IPv4 address is:          ${myipaddress}"
		echo "The current hostname is:  ${myhostname}"
		echo "The old hostname was:     ${myoldhostname}"
		echo "Writing new configuration file and reloading apache!"

		# Write new configuration file. This file has to be included in the right places.
		echo "Require host ${myhostname}" >${configdir}/${configfile}

		# Write new current admin host to text file for easy comparison.
		echo "${myhostname}" >${configdir}/${comparefile}

		# Reload apache, suppress normal output.
		systemctl reload apache2
	else
		if [ $2 ] ; then
			if [ $verbose ] ; then
				echo "Host has not changed."
				echo "Given hostname is:        ${dyndnsname}"
				echo "IPv4 address is:          ${myipaddress}"
				echo "The current hostname is:  ${myhostname}"
				echo "The old hostname was:     ${myoldhostname}"
				echo "Nothing to do!"
			fi
		fi
	fi
fi

exit 0
