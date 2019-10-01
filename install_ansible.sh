#!/bin/sh
set -e # exit if a command fails
set -u # exit if a referenced variable is not declared

red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`
# echo "${red}red text ${green}green text${reset}"
SPC="software-properties-common"
LOC="/etc/ansible"
FOLDERS="facts files inventory playbooks plugins roles inventory/group_vars inventory/host_vars"

# use != and remove 'NOT' if it must be run as root
if [ "$(whoami)" != 'root' ]; then
  printf "${green}~~~\n${red}This script must be run as root\n${green}~~~${reset}\n"
  exit 1
fi

printf "\n~~ Ansible Install Script ~~\n"
sleep 1
printf "\nPreparing system\n"

printf "\nUpdating apt cache\n"
apt-get update > /dev/null 2>&1

printf "\nInstalling required packages\n"
apt-get install -y $SPC python-pip python-dev libkrb5-dev gcc > /dev/null 2>&1

printf "\nRemoving any old Ansible PPAs\n"
add-apt-repository -ry ppa:ansible/ansible > /dev/null 2>&1

printf "\nAdding Ansible PPA\n"
add-apt-repository -y ppa:ansible/ansible > /dev/null 2>&1

printf "\nUpdating apt cache\n"
apt-get update > /dev/null 2>&1

printf "\nInstalling Ansible\n"
apt-get install -y ansible > /dev/null 2>&1

printf "\nInstalling python modules\n"
pip install pykerberos pywinrm py > /dev/null 2>&1

printf "\nSetting Ansible permissions\n"
chown root:ansible $LOC
chmod g+s $LOC

printf "\nCreate any missing directories\n"
for dir in $FOLDERS;
do
 mkdir -p $LOC/$dir
done

