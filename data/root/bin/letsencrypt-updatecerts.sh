#!/bin/bash

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

/root/bin/letsencrypt-preupdatehook.sh
 
letsencrypt renew -c /etc/letsencrypt/cli.ini

/root/bin/letsencrypt-postupdatehook.sh
