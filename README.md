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
* Install nextcloud prerequisites (php 7.0)
* Install nextcloud
* Install libreoffice online [optional, seperate script]

## Configuration

Before you start, you have to customize the configuration.
