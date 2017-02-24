#!/bin/bash
#
# Define e-mail and rsa key size for letsencrypt.
#

MY_EMAIL="me@mydomain.tld"
MY_KEY_SIZE="4096"

#
# Define ServerAdmin e-mail.
#

WEBMASTER_EMAIL="webmaster@mydomain.tld"

#
# Define an admin host IPv4 or hostname. Apache server-status, server-info,
# apache2-doc, phpinfo and phpmyadmin will only be available to this host or local.
#

ADMINHOST="myadminhost.myotherdomain.tld"

#
# Don't edit below!
#

_MY_FQDN_="$(echo "${MY_FQDN}" | sed 's/\./-/g' -)"
MY_SITE_CONFIG="001-${_MY_FQDN_}-le-ssl"

export MY_EMAIL MY_KEY_SIZE WEBMASTER_EMAIL ADMINHOST MY_SITE_CONFIG
