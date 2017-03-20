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

## Configuration

Before you start, you have to customize the configuration.
