#!/bin/bash
 
result=$(find /etc/letsencrypt/live/ -type l -mmin -60 )
if [ -n "$result" ]; then
    # Certificates changed
    echo "Some Certificates changed."
    # reload apache2
    echo "Reload Apache2."
    systemctl reload apache2
    # reload postfix
    echo "Reload postfix."
    systemctl reload postfix
fi
