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
It's recommended to download the script collection to a different host. Unpack the
archive there as user root or using sudo and the tar commandline options "-p --no-same-owner".
Adjust the configuration and if you want to use the 1&amp;1 Backup Manager, please
copy the installer into the backupmanager directory, see notes below.
If you want to install libreoffice online, you may copy the libreoffice online package to the
packages directory too. But this may also be done later on, see below.
After finishing the configuration, repackage the whole directory as user root or
using sudo to a tar archive and transfer the archive to your new host using scp.

### Most Important:

Please copy a file authorized_keys containing your ed25519 ssh public key(s) into
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

Transfer the configured script collection archive to your new host. Unpack in your home
directory or to another suitable location.

Before you start the script, you should have some additional info at hand:

Start the script install-server.sh.

1. The first action the script executes, is to check wether we are on an ubuntu 16.04
system. If not  we stop. Then we compare the current hostname to the configured one.
If the current hostname is not "localhost" or the configured one we stop. If the current
hostname is "localhost" we continue execution.
2. We write a startup line for starting the script to ~/.bashrc, so the script is started
again at login.
3. We update the system and install the patchutils, which are required for the script
collection to function.
4. We set hostname and mailname and add some aliases to .bash_aliases.
5. If requested, we setup the private network interface.
6. We append the content of config/etc.hosts.part to /etc/hosts.
7. We configure the ssh daemon to use ed25519 keys and publickey authentication. We copy
the authorized_keys file and existing ssh keys from the config/ssh directory to ~/.ssh/.
8. We reboot the system.
9. At login we resume execution.
10. If the 1&amp;1 Backup Manager installer is available, we install and setup the Backup Manager.
Additionally some scripts for more convenient usage of the Backup Manager are copied to ~/bin/ and
correspondent aliases are added to ~/.bash_aliases.
11. We install some commonly used software: software-properties-common, update-notifier-common,
apt-show-versions, dnsutils, git, man-db, manpages, vim, vim-doc, vim-scripts and haveged.
12. We install and setup redis for use with nextcloud.
13. We replace the default MySQL database server with MariaDB 10.1.
14. We reboot the system a second time.
15. At login we resume execution by installing the apache2 webserver from the ppa of Ondřej Surý.
16. Install letsencrypt, get a first certificate and configure apache2.
17. Setup postfix using tls.
18. Setup docker.
19. Setup munin for server monitoring, only accessible from the administration host.
20. Setup phpmyadmin from the ppa of Michal Čihař (nijel). Acces is restricted to local and the
administration host. Additionally scripts are copied to ~/bin/ for enabling and disabling the phpmyadmin
page completely and to enable or disbale root login for phpmyadmin.
21. Install and configure php7.0-fpm.
22. Install the remaining prerequisites for nextcloud.
23. Install nextcloud.
24. Optionally install libreoffice online using the install-lool.sh script, has to be started manually.
