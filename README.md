# install-cloud-server

Script collection to setup an 1&amp;1 cloud server with ubuntu 16.04.
Installs and sets up all required packages for nextcloud.
Finally installs nextcloud.

Optionally installs libreoffice online.

## Requirements

The scripts collection is tested for an 1&amp;1 cloud server, ubuntu 16.04,
64-bit, standard installation. 

1. For the scripts to work, you have to setup such a server as descripted in my blog at https://blog.emrich-ebersheim.de/2016/09/05/11-cloud-server-unter-ubuntu-16-04-1-lts-teil-1-server-erstellen/ (in german). For testing purposes a Cloud Server S incl. one public IP is sufficient.
2. You have to point a DNS Entry for the host itself and a DNS Entry for the nexcloud instance to the public IP you've got.
3. If you want to install libreoffice online you need a third DNS Entry for the online office.

It's recommended to use subdomains of the same domain for online office and nextcloud, for example:
office.mydomain.tld and cloud.mydomain.tld. 

## Functions

* Update the system
* Set system hostname and domain
* Setup a privat netwerk interface [optional]
* Append host entries to /etc/hosts [optional]
* Configure sshd for publickey authentication
* Copy authorized_keys to ~/.ssh/
* Copy pregenerated ssh host keys to ~/.ssh/
* Setup 1&amp;1 Backup Manager [optional]
* Install some basic software packages
* Setup redis
* Replace MySQL with MariaDB 10.1
* Setup apache2
* Setup letsencrypt
* Setup postfix using tls
* Setup docker
* Setup munin
* Setup phpmyadmin
* Setup php7.0-fpm
* Install nextcloud prerequisites (including the necessary php 7.0 modules)
* Install nextcloud
* Install libreoffice online [optional, seperate script]

## Configuration

Before you start, you have to customize the configuration!

### Most Important:

Please copy a file authorized_keys containing your ed25519 public key(s) into
the directory config/ssh.
If you want to use pregenerated ssh keys for the account at your new host, please
copy the keys into the directory config/ssh too.

### Hostname

Please copy the file config/hostname.sh.example to config/hostname.sh and adjust
the variables MY_HOSTNAME and MY_DOMAIN to the actual values.

### Private network

Please copy the file config/network.sh.example to config/network.sh and adjust
to your needs. If you don't use a private network, set the variable SETUP_PRIVATE_NETWORK
to "0", that's sufficient.

### /etc/hosts

Please copy the file config/etc.hosts.part.example to config/etc.hosts.part and
replace the conent with your host entries. This is especially usefull if you have
a private network. 

### apache and letsencrypt

Please copy the file config/letsencrypt.sh.example to config/letsencrypt.sh and adjust
to your needs. The variable ADMINHOST defines the FQDN or an IPv4 address of an administration
host. The access to the Apache webserver server-status, server-info, apache2-doc, phpinfo
and phpmyadmin pages will be restrictet to local and the administration host.

### postfix

Please copy the file config/postfix.sh.example to config/postfix.sh and adjust to your
needs.

### nextcloud

Please copy the file config/nextcloud.sh.example to nextcloud.sh and adjust to your needs.

### libreoffice online (optional), seperate script install-lool.sh

Please copy the file config/lool.sh.example to config/lool.sh and adjust to your needs.
If you want to use this functionality, you have to build a libreoffice online package,
see https://github.com/RainerEmrich/build-lool.
The built package has to be copied to the packages directory.


## Execution
