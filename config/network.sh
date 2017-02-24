#!/bin/bash
#
# If you have a private network defined, you may give here the necessary
# information to set up the interface automatically.
#
# If you want to setup a private network interface, set this to "1", "" otherwise.

SETUP_PRIVATE_NETWORK="1"

#
# Define IP and network mask for your private network.
#

MY_PRIVATE_NETWORK_IP="10.0.1.3"
MY_PRIVATE_NETWORK_MASK="255.255.255.0"

#
# MY_PRIVATE_NETWORK_NAME defines an entry in the /etc/hosts file,
# defaults to "${MY_HOSTNAME}-priv".
#
MY_PRIVATE_NETWORK_NAME=""

#
# Change the device only if necessary.
#

MY_PRIVATE_NETWORK_DEVICE="ens224"

#
# Don't edit below!
#

export SETUP_PRIVATE_NETWORK MY_PRIVATE_NETWORK_IP MY_PRIVATE_NETWORK_MASK MY_PRIVATE_NETWORK_NAME MY_PRIVATE_NETWORK_DEVICE
