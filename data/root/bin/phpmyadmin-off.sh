#!/bin/bash
#
# Utility to disable phpmyadmin
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
# You may adopt the following three variables to your needs
configdir="/etc/apache2/misc"
configfile="my-phpmyadmin.conf"
configfile_off="my-phpmyadmin-off.conf"

# Check if configdir exists
if [ ! -d "${configdir}" ] ; then
	echo "Error: Configuration directory ${configdir} doesn't exist!"
	exit 2
fi

# Check if configfile exists
if [ ! -f "${configdir}/${configfile_off}" ] ; then
	echo "Warning: File ${configdir}/${configfile_off} doesn't exist, creating an empty one"
	touch "${configdir}/${configfile}"
fi

/bin/rm -f ${configdir}/${configfile}
/bin/ln -s "${configdir}/${configfile_off}" "${configdir}/${configfile}"
service apache2 reload

exit 0
