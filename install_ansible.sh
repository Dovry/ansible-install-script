#!/bin/sh
set -e # exit if a command fails
set -u # exit if a referenced variable is not declared

red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

PACKAGES="software-properties-common python-pip curl python-dev libkrb5-dev gcc"
LOC="/etc/ansible"
FOLDERS="facts files inventory playbooks plugins roles inventory/group_vars inventory/host_vars"
FILES="inventory/hosts hosts ansible.cfg"
# Set this to the URL of your custom ansible.cfg file
CFG="https://raw.githubusercontent.com/ansible/ansible/devel/examples/ansible.cfg"

if [ "$(whoami)" != 'root' ]; 
then
  printf "${green}~~~\n${red}This script must be run as root\n${green}~~~${reset}\n"
  exit 1
fi

printf "\n~~ Ansible Install Script ~~\n"
sleep 1
printf "\nPreparing system\n"
sleep 1

printf "\nUpdating apt cache\n"
apt-get update > /dev/null 2>&1

printf "\nInstalling required packages. This may take a while\n"
apt-get install -y $PACKAGES  > /dev/null 2>&1

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

if cut -d: -f1 /etc/group | grep ansible > /dev/null 2>&1;
 then
  printf "\nAnsible group exists, continuing...\n"
 else
  printf "\nAdding group \"ansible\"\n" 
  groupadd ansible
fi

printf "\nCreate any missing directories\n"
for dir in $FOLDERS;
do
 mkdir -p $LOC/$dir
done

printf "\nCreate any missing files\n"
for file in $FILES;
do
 touch $LOC/$file
done

if [ ! -f $LOC/ansible.cfg.template ];
then
 # Does not overwrite existing ansible.cfg
 curl $CFG -o $LOC/ansible.cfg.template > /dev/null 2>&1
else
 printf "\nTemplate already exists, skipping...\n"
fi

printf "\nSetting Ansible permissions\n"
chmod -R 774 $LOC
chown -R root:ansible $LOC
chmod g+s $LOC

printf "\n\nDone\nYou can now start using Ansible, enjoy.\n"