### LinuxToolScripts
# Some useful scripts (mainly Bash) and commands for different purposes

Repository for collection of scripts/commands for general purposes in linux post-installation and usage

Nowaday, we have:

- **configure_linux_distro.sh** : This scripts try to easily complete and post-configure a linux fresh installation of different distributions, with missing but needed packages, alias and all-day useful commands. Distros currently working are: Debian-based (Debian, Ubuntu, Mint, ...), RH-Based (CentOS, RedHat, Fedora, ..) and Archlinux. SuSE Linux will be added soon ...
- **clone_user.sh** : You can clone a system user (only Linux PAM authentication users) with another name and uid, but replicating all the groups and authorizations of original user. Only a new password for the new user will be requested.
- **killuser** : You can kill all processes of a specified system username.
