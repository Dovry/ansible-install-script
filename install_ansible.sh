#!/bin/sh
set -e # exit if a command fails
set -u # exit if a referenced variable is not declared

red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`
# echo "${red}red text ${green}green text${reset}"
SPC="software-properties-common"

# use != and remove 'NOT' if it must be run as root
if [ "$(whoami)" != 'root' ]; then
  printf "${green}~~~\n${red}This script must be run as root\n${green}~~~${reset}\n"
  exit 1
fi

printf "\n~~ Ansible Install Script ~~\n\nInstalling prerequisites\n"

#apt-get update

if ! dpkg -s $SPC >/dev/null 2>&1;
then
 printf "package '$SPC' is installed ...continuing\n"
else
  printf "package $SPC will be installed"
  apt-get install -y $SPC
fi

# grep -r "ansible" /etc/apt/sources.list*

# apt-add-repository -y ppa:ansible/ansible