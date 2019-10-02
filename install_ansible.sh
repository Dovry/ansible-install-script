#!/bin/sh
# POSIX
set -e # exit if a command fails
set -u # exit if a referenced variable is not declared

# Set this to the URL of your custom ansible.cfg file, e.g.
# CFG="https://raw.githubusercontent.com/ansible/ansible/devel/examples/ansible.cfg"
CFG=""
# Space seperated list of git roles, e.g.
# GIT="https://github.com/geerlingguy/ansible-role-java.git https://github.com/geerlingguy/ansible-role-nodejs.git"
GIT=""
# Space seperated list of ansible-galaxy roles, e.g.
# GALAXY="geerlingguy.docker geerlingguy.apache geerlingguy.nodejs"
GALAXY=""
# Space seperated list of users to add to the 'ansible' group, e.g.
# USERS="alice bob charlie diane"
USERS=""

red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`


STARTTIME=$(date +%s)
PACKAGES="software-properties-common python-pip curl sshpass python-dev libkrb5-dev gcc"
PYPKGS="pywinrm pykerberos py pygssapi requests-kerberos"
LOC="/etc/ansible"
FOLDERS="facts files inventory playbooks plugins roles inventory/group_vars inventory/host_vars"
FILES="inventory/hosts hosts ansible.cfg"

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
apt-get install -y $PACKAGES > /dev/null 2>&1

printf "\nRemoving any old Ansible PPAs\n"
add-apt-repository -ry ppa:ansible/ansible > /dev/null 2>&1

printf "\nAdding Ansible PPA\n"
add-apt-repository -y ppa:ansible/ansible > /dev/null 2>&1

printf "\nUpdating apt cache\n"
apt-get update > /dev/null 2>&1

printf "\nInstalling Ansible\n"
apt-get install -y ansible > /dev/null 2>&1

printf "\nInstalling python modules\n"
pip install $PYPKGS > /dev/null 2>&1

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

if [ -z "$CFG" ]
then
  printf "\nNo ansible.cfg specified, skipping...\n"
else
  printf "\nBacking up current ansible.cfg\n"
  BACKUP=`date '+%Y_%m_%d_%H_%M_%S'`
  cp $LOC/ansible.cfg $LOC/ansible.cfg_$BACKUP.bak
  sleep 1
  printf "\nFetching specified ansible.cfg\n"
  sleep 1
  curl $CFG -o $LOC/ansible.cfg > /dev/null 2>&1
fi  

if [ -z "$GIT" ];
then
  printf "\nNo git roles set, skipping...\n"
  sleep 1
else
  for role in $GIT;
    do
      apt install -y git > /dev/null 2>&1
      printf "\nFetching roles from git\n"
      git clone $role > /dev/null 2>&1
  done
fi

if [ -z "$GALAXY" ];
then
  printf "\nNo galaxy roles set, skipping...\n"
  sleep 1
else
  printf "\nFetching galaxy roles\n"
  ansible-galaxy --roles-path $LOC/roles/ install $GALAXY > /dev/null 2>&1
fi

if cut -d: -f1 /etc/group | grep ansible > /dev/null 2>&1;
 then
  printf "\nAnsible group exists, continuing...\n"
 else
  printf "\nAdding group \"ansible\"\n" 
  groupadd ansible
fi

if [ -z "$USERS" ]
then
 printf "\nNo users specified, skipping...\n"
else
  for user in $USERS;
    do
      useradd $user > /dev/null 2>&1
      printf "\nUser '$user' created\n"
      usermod -aG ansible $user
  done
fi

printf "\nSetting Ansible permissions\n"
chmod -R 774 $LOC
chown -R root:ansible $LOC
chmod g+s $LOC

ENDTIME=$(date +%s)
printf "\nFinished in $((ENDTIME-STARTTIME)) seconds.\n\n"

if [ -z "$GALAXY" ] || [ -z "$GIT"]
then
  printf "You should install some roles to get started\n\n"
else
  printf "You can now start using Ansible. Enjoy\n\n"
fi
