#!/bin/bash
#
# Source the scripts to set up the functions
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

. ${SCRIPT_DIR}/get.os.release.sh
. ${SCRIPT_DIR}/test.os.release.sh
. ${SCRIPT_DIR}/get.config.sh
. ${SCRIPT_DIR}/show.info.sh
. ${SCRIPT_DIR}/ask.to.continue.sh
. ${SCRIPT_DIR}/pause.sh
. ${SCRIPT_DIR}/setup.hostname.network.ssh.sh
. ${SCRIPT_DIR}/setup.backupmanager.sh
. ${SCRIPT_DIR}/setup.software.sh
. ${SCRIPT_DIR}/setup.base.software.sh
. ${SCRIPT_DIR}/setup.redis.sh
. ${SCRIPT_DIR}/setup.mariadb.sh
. ${SCRIPT_DIR}/setup.apache.sh
. ${SCRIPT_DIR}/setup.letsencrypt.sh
. ${SCRIPT_DIR}/setup.postfix.sh
. ${SCRIPT_DIR}/setup.docker.sh
. ${SCRIPT_DIR}/setup.munin.sh
. ${SCRIPT_DIR}/setup.phpmyadmin.sh
. ${SCRIPT_DIR}/setup.php_fpm.sh
. ${SCRIPT_DIR}/setup.nextcloud.prerequisites.sh
. ${SCRIPT_DIR}/setup.nextcloud.sh
