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

STARTTIME=$(date +%s)
# system agnostic packages
PKGS="gcc curl sshpass" 
# yum agnostic packages
YUM="python2-pip kernel-devel gcc-c++ libxslt-devel libffi-devel openssl-devel" 
# CentOS 8
DNF="redhat-rpm-config" 
# apt agnostic packages
APT="software-properties-common python-pip python-dev libkrb5-dev"
# py agnostic packages
PYPKGS="pywinrm py"
UBU_PYPKGS="pykerberos pygssapi requests-kerberos"
CENT_PYPKGS=""
LOC="/etc/ansible"
ANSI_FOLDERS="facts files inventory playbooks plugins roles inventory/group_vars inventory/host_vars"
FILES="/etc/ansible/inventory/hosts /etc/ansible/hosts /etc/ansible/ansible.cfg"

# Exit if not run as root
if [ "$(whoami)" != 'root' ]; 
  then
    printf "\nThis script must be run as root\n"
    exit 1
fi

# Check which OS script is being run on. Exits if it's not supported
if [ "$(cat /etc/*release | grep -P "^ID=(\w+|\"\w+\")" | sed 's/"//g' | sed 's/ID=//g')" = "ubuntu" ];
  then
    OS="ubuntu"
    if [ "$(cat /etc/*release | grep -P "^VERSION_ID=" | sed 's/VERSION_ID=//g' | sed 's/"//g')" = "18.04" ]; 
      then
        VER="18.04"
      elif [ "$(cat /etc/*release | grep -P "^VERSION_ID=" | sed 's/VERSION_ID=//g' | sed 's/"//g')" = "16.04" ]; 
        then
          VER="16.04"
      else
        printf "\nOS not supported\n"
        exit 1
    fi
    printf "\nUbuntu %s " "$VER"
    printf "detected, configuring...\n"
    sleep 2
  elif [ "$(cat /etc/*release | grep -P "^ID=(\w+|\"\w+\")" | sed 's/"//g' | sed 's/ID=//g')" = "centos" ];
  then
    OS="centos"
    if [ "$(cat /etc/*release | grep -P "^VERSION_ID=" | sed 's/VERSION_ID=//g' | sed 's/"//g')" = "8" ];
      then
        VER="8"
      elif [ "$(cat /etc/*release | grep -P "^VERSION_ID=" | sed 's/VERSION_ID=//g' | sed 's/"//g')" = "7" ];
        then
          VER="7"
      else
        printf "\nOS not supported\n"
        exit 1
    fi
    printf "\nCentOS %s " "$VER"
    printf "detected, configuring...\n"
    sleep 2
  else
    printf "OS not supported\n"
    exit 1
fi

# Update cache // install epel-release
printf "\n~~~ Ansible Installation script for %s " "$OS $VER"
printf "~~~\n"
if [ "$OS" = "ubuntu" ]; then
  sleep 1
  printf "\nPreparing system\n"
  sleep 1
  printf "\nUpdating apt cache\n"
  apt-get update > /dev/null 2>&1
  elif [ "$OS" = "centos" ]; then
    sleep 1
    printf "\nPreparing system\n"
    sleep 1
    printf "\nInstalling epel-release\n"
    yum install -y epel-release > /dev/null 2>&1
fi

# Install requirements with package manager
printf "\nInstalling required packages. This may take a while\n"
if [ "$OS" = "ubuntu" ]; then
  apt-get install -y $APT > /dev/null 2>&1
  elif [ "$OS" = "centos" ]; then
    if [ "$VER" = "8" ]; then
      dnf install -y $YUM $DNF $PKGS > /dev/null 2>&1    
    elif [ "$VER" = "7" ]; then
      yum install -y $YUM $PKGS > /dev/null 2>&1
    fi
fi

# Add & remove PPA + update cache
if [ "$OS" = "ubuntu" ]; then
  printf "\nRemoving any old Ansible PPAs\n"
  add-apt-repository -ry ppa:ansible/ansible > /dev/null 2>&1
  
  printf "\nAdding Ansible PPA\n"
  add-apt-repository -y ppa:ansible/ansible > /dev/null 2>&1
  
  printf "\nUpdating apt cache\n"
  apt-get update > /dev/null 2>&1
fi

# Install Ansible
printf "\nInstalling Ansible\n"
if [ "$OS" = "ubuntu" ]; then
    apt-get install -y ansible > /dev/null 2>&1
  elif [ "$OS" = "centos" ]; then
    if [ "$VER" = "8" ]; then
      pip2 install ansible > /dev/null 2>&1
    elif [ "$VER" = "7" ]; then
      yum install -y ansible > /dev/null 2>&1
    fi
fi

# Install python pip packages
printf "\nInstalling python modules. This may take a while\n"
if [ "$OS" = "ubuntu" ]; then
    pip install --upgrade $PYPKGS $UBU_PYPKGS > /dev/null 2>&1
  elif [ "$OS" = "centos" ]; then
    if [ "$VER" = "8" ]; then
      pip2 install --upgrade $PYPKGS $CENT_PYPKGS > /dev/null 2>&1
    elif [ "$VER" = "7" ]; then
      pip install --upgrade $PYPKGS $CENT_PYPKGS > /dev/null 2>&1
    fi
fi

# Create missing directories
printf "\nCreate any missing directories\n"
for DIR in $ANSI_FOLDERS;
  do
   mkdir -p "$LOC"/"$DIR"
done

# Create missing files
printf "\nCreate any missing files\n"
for FILE in $FILES;
  do
   touch $FILE
done

# Make sure ansible.cfg exists under /etc/ansible
if [ -z "$CFG" ]
  then
    printf "\nNo ansible.cfg specified, skipping...\n"
  else
    printf "\nBacking up current ansible.cfg\n"
    BACKUP=$(date '+%Y_%m_%d_%H_%M_%S')
    cp "$LOC"/ansible.cfg "$LOC"/ansible.cfg_"$BACKUP".bak
    sleep 1
    printf "\nFetching specified ansible.cfg\n"
    sleep 1
    curl "$CFG" -o "$LOC"/ansible.cfg > /dev/null 2>&1
fi

# Download Ansible Galaxy roles if specified
if [ -z "$GALAXY" ];
  then
    printf "\nNo galaxy roles set, skipping...\n"
    sleep 1
  else
    printf "\nFetching galaxy roles\n"
    ansible-galaxy --roles-path "$LOC"/roles install "$GALAXY" > /dev/null 2>&1
fi

# Download Ansible roles from git if specified
if [ -z "$GIT" ]; then
    printf "\nNo git roles set, skipping...\n"
    sleep 1
  elif [ "$OS" = "ubuntu" ]; then
    for ROLE in $GIT;
      do
        printf "\nInstalling git\n"
        apt install -y git > /dev/null 2>&1
        printf "\nFetching roles from git\n"
        git clone "$ROLE" "$LOC"/roles > /dev/null 2>&1
      done
  elif [ "$OS" = "centos" ]; then
    for ROLE in $GIT;
      do
        printf "\nInstalling git\n"
        yum install -y git > /dev/null 2>&1
        printf "\nFetching roles from git\n"
        git clone "$ROLE" "$LOC"/roles > /dev/null 2>&1
      done
fi

# Make sure group 'ansible' exists
if cut -d: -f1 /etc/group | grep ansible > /dev/null 2>&1;
  then
   printf "\nAnsible group exists, continuing...\n"
  else
   printf "\nAdding group \"ansible\"\n" 
   groupadd ansible
fi

# Create any users, and add them to group 'ansible' if specified
if [ -z "$USERS" ]
  then
   printf "\nNo users specified, skipping...\n"
  else
    for USER in $USERS;
      do
        useradd "$USER" > /dev/null 2>&1
        printf "\nUser %s" $USER
        printf "created\n"
        usermod -aG ansible "$USER"
    done
fi

# Set the correct Read Write Execute rights on /etc/ansible
printf "\nSetting Ansible permissions\n"
chmod -R 774 "$LOC"
chown -R root:ansible "$LOC"
chmod g+s "$LOC"

# Print run time in seconds
ENDTIME=$(date +%s)
printf "\nFinished in %s" "$((ENDTIME-STARTTIME))" 
printf " seconds.\n\n"

ANSI_VER=$(ansible --version | head -n 1 | awk '{print $2}')

# Exit message upon successfully running the script
printf "Ansible version %s " "$ANSI_VER"
printf "installed."
if [ -z "$GALAXY" -o -z "$GIT" ]; then
  printf "\n\nDownload some roles to get started\n\n"
else
  printf " Enjoy\n\n"
fi
