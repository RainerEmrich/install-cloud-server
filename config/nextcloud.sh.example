#!/bin/bash
#
# Define the required data for nextcloud.
#
# Define the domain for nextcloud. The domain must be already assigned to your host.
# The domain has to be different from the hostname.

MY_NEXTCLOUD_DOMAIN="mynextcloud.mydomain.tld"

#
# Define the DocumentRoot for nextcloud. For simplicity the directory should be
# named nextcloud and should be placed in the /var/www directory tree.

MY_NEXTCLOUD_DR="/var/www/mynextcloud/nextcloud"

#
# Define the nextcloud data directory. For simplicity the directory should be
# named data and should be placed in the /var/ncdata directory tree.

MY_NEXTCLOUD_DATA_DIR="/var/ncdata/mynextcloud/data"

#
# Define the ServerAdmin for nextcloud.

MY_NEXTCLOUD_SA="webmaster@mydomain.tld"

#
# Define a name for database and database user and a password

MY_DATABASE_NAME='nc_mycloud'
MY_DATABASE_PASSWD='databasepasswd'

#
# Define an admin user and password

MY_NC_ADMIN_NAME='adminname'
MY_NC_ADMIN_PASSWD='adminpasswd'

#
# Define the redis database number to use.

MY_REDIS_DB_NUMBER="0"

#
# Define nextcloud version
MY_NEXTCLOUD_VERSION="11.0.1"

#
# Define nextcloud apps to enable
MY_NEXTCLOUD_APPS="admin_audit files_accesscontrol files_automatedtagging files_retention templateeditor"

#
# Don't edit below!
#

_MY_NEXTCLOUD_DOMAIN_="$(echo "${MY_NEXTCLOUD_DOMAIN}" | sed 's/\./-/g' -)"
MY_NEXTCLOUD_SITE_CONFIG="101-${_MY_NEXTCLOUD_DOMAIN_}-le-ssl"

export MY_NEXTCLOUD_DOMAIN MY_NEXTCLOUD_DR MY_NEXTCLOUD_DATA_DIR MY_NEXTCLOUD_SA \
	MY_DATABASE_NAME MY_DATABASE_PASSWD MY_NC_ADMIN_NAME MY_NC_ADMIN_PASSWD \
	MY_REDIS_DB_NUMBER MY_NEXTCLOUD_VERSION _MY_NEXTCLOUD_DOMAIN_ MY_NEXTCLOUD_SITE_CONFIG MY_NEXTCLOUD_APPS
