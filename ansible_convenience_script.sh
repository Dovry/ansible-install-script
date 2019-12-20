#!/bin/sh
# POSIX
set -e # exit if a command fails
set -u # exit if a referenced variable is not declared
STARTTIME=$(date +%s) # start function for script runtime

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

# Ansible files and folders
 LOC="/etc/ansible"
 ANSI_FOLDERS="facts files inventory playbooks plugins roles inventory/group_vars inventory/host_vars"
 FILES="$LOC/inventory/hosts $LOC/hosts $LOC/ansible.cfg"

# Package manager dependencies
 PKGS="gcc curl sshpass"
 YUM="python2-pip kernel-devel gcc-c++ libxslt-devel libffi-devel openssl-devel"
 DNF="redhat-rpm-config"
 APT="software-properties-common python-pip python-dev libkrb5-dev"

# Container dependencies
 PIP_ANSI="ansible"
 C_CENT="sudo which initscripts"
 C_CENT8="python3 python3-pip hostname"
 C_CENT7="deltarpm python-pip"
 C_UBU="locales software-properties-common python-setuptools sudo wget rsyslog systemd systemd-cron sudo iproute2"
 C_UBU18="apt-utils"
 C_UBU16="python-software-properties"

# Install systemd function
 SYSD () { 
  (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i = systemd-tmpfiles-setup.service ] || rm -f $i; done);
  rm -f /lib/systemd/system/multi-user.target.wants/*;
  rm -f /etc/systemd/system/*.wants/*;
  rm -f /lib/systemd/system/local-fs.target.wants/*;
  rm -f /lib/systemd/system/sockets.target.wants/*udev*;
  rm -f /lib/systemd/system/sockets.target.wants/*initctl*;
  rm -f /lib/systemd/system/basic.target.wants/*;
  rm -f /lib/systemd/system/anaconda.target.wants/*;
 }

# Help menu
 HELP () {
  printf "Options:"
  printf "\nTHESE ARE CASE SENSITIVE"
  printf "\n"
  printf "\n  -c,         Specify a url to an ansible.cfg file to download"
  printf "\n  -f,         Force normal installation in a container"
  printf "\n  -g,         Git roles to download"
  printf "\n  -G,         Galaxy roles to download"
  printf "\n  -h, -H,     Shows this help menu"
  printf "\n  -p,         Install Ansible via python pip"
  printf "\n  -u,         Creates, or adds existing users to the group 'ansible'"
  printf "\n\n"
  exit 0
 }

# Check for distribution
 OS="$(sed -n '/^ID=/p' /etc/*release | sed 's/ID=//g;s/"//g')"
# Check for distribution version
 VER="$(sed -n '/VERSION_ID=/p' /etc/*release | sed 's/VERSION_ID=//g;s/"//g')"

# Exit if not run as root
 if [ "$(whoami)" != 'root' ]; then
  printf "\nThis script must be run with sudo or as root\n"
  exit 1
 fi

# Check if running in container
 INODE_NUM=$(stat / | awk '/Inode/ {print $4}')
 if [ "$INODE_NUM" -gt '2' ]; then
  PIP=true
 else
  PIP=""
 fi

# Options
 while getopts 'c:fhHg:G:pu:' option; do
  case $option in
   c) CFG="$OPTARG" ;;         # ansible.cfg to use, has a default
   f) PIP=false ;;             # force package manager install (defaults to pip in container)
   h) HELP ;;                  # shows the help menu
   H) HELP ;;                  # shows the help menu
   g) GIT="$OPTARG" ;;         # git roles
   G) GALAXY="$OPTARG" ;;      # galaxy roles to download
   p) PIP=true ;;              # pip install
   u) USERS="$OPTARG" ;;       # users to add to ansible group
   *) ;;
  esac
 done

# Check which OS script is being run on. Exits if it's not supported
 while :; do
  case "$OS" in
   ubuntu|centos)
    while :; do
     case "$VER" in
      18.*|16.*|8|7)
       printf "\n%s %s detected\n\nconfigured " "$OS" "$VER"
        if [ "$PIP" = true ]; then
         printf "for pip installation\n"
        else
         printf "for package manager installation\n"
        fi
        break;;
     esac
    done
   break;;
    *)
     printf "\n%s %s is not supported\n" "$OS" "$VER"
     exit 0
   ;;
  esac
 done

# Update cache // install epel-release
 while :; do
  case "$OS" in
   ubuntu)
    printf "\nupdating apt cache\n"
    apt-get update > /dev/null 2>&1
   break;;
   centos)
    printf "\nInstalling epel-release\n"
    yum install -y epel-release > /dev/null 2>&1
   break;;
  esac
 done

# Package manager installation
 if [ "$PIP" != true ]; then
  printf "\nInstalling required packages. This may take a while\n"
  while :; do
   case "$OS" in
    ubuntu)
     apt-get install -y $APT > /dev/null 2>&1
     printf "\nRemoving any old Ansible PPAs\n"
     add-apt-repository -ry ppa:ansible/ansible > /dev/null 2>&1
     printf "\nAdding Ansible PPA\n"
     add-apt-repository -y ppa:ansible/ansible > /dev/null 2>&1
     printf "\nUpdating apt cache\n"
     apt-get update > /dev/null 2>&1
     break;;
    centos)
     while :; do
      case "$VER" in
       8)
        dnf install -y $YUM $DNF $PKGS > /dev/null 2>&1
       break;;
       7)
        yum install -y $YUM $PKGS > /dev/null 2>&1
       break;;
      esac
     done
    break;;
   esac
  done

  printf "\nInstalling Ansible\n"
  while :; do
   case "$OS" in
    ubuntu)
     apt-get install --reinstall -y ansible > /dev/null 2>&1
    break;;
    centos)
     while :; do
      case "$VER" in
       8)
        pip2 install --upgrade --force-reinstall ansible > /dev/null 2>&1
       break;;
       7)
        yum install -y ansible > /dev/null 2>&1
       break;;
      esac
     done
    break;;
   esac
  done
 fi

# Pip installation
 if [ "$PIP" = true ]; then
  printf '\nInstalling and setting up python-pip Ansible\n'
  while :; do
   case "$OS" in
    ubuntu)
     while :; do
      case "$VER" in
       18.*)
        # Prepare image for Ansible install
        apt-get -y --no-install-recommends install $C_UBU $C_UBU18
        locale-gen en_US.UTF-8
        sed -i 's/^\($ModLoad imklog\)/#\1/' /etc/rsyslog.conf
        # Download and install pip
        wget -O /tmp/get-pip.py https://bootstrap.pypa.io/get-pip.py
        python /tmp/get-pip.py
        # Install Ansible
        pip install --disable-pip-version-check --upgrade --force-reinstall $PIP_ANSI
        # Cleanup
        rm -Rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man /root/.cache/pip/ /tmp/get-pip.py
        find / -name '*.pyc' -delete
        find / -name '*__pycache__*' -delete
       break;;
       16.*)
        # Prepare image for Ansible install
        apt-get -y --no-install-recommends install $C_UBU $C_UBU16
        locale-gen en_US.UTF-8
        sed -i 's/^\($ModLoad imklog\)/#\1/' /etc/rsyslog.conf
        # Download and install pip
        wget -O /tmp/get-pip.py https://bootstrap.pypa.io/get-pip.py
        python /tmp/get-pip.py
        # Install Ansible
        pip install --disable-pip-version-check --upgrade --force-reinstall $PIP_ANSI
        # Cleanup
        rm -Rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man /tmp/get-pip.py
        find / -name '*.pyc' -delete
        find / -name '*__pycache__*' -delete
        apt-get clean
       break;;
      esac
     done
    break;;
    centos)
     while :; do
      case "$VER" in
       8)
        yum makecache --timer
        yum -y install $C_CENT
        yum -y update
        yum -y install $C_CENT8
        yum clean all
        # If container, install Systemd
        if [ "$INODE_NUM" -gt '2' ]; then
          printf "\nInstalling SystemD\n"
          SYSD
        fi
        # Install Ansible
        pip3 install $PIP_ANSI
        # Disable requiretty
        sed -i -e 's/^\(Defaults\s*requiretty\)/#--- \1/' /etc/sudoers
       break;;
       7)
        yum makecache fast
        yum -y install $C_CENT7
        yum -y update
        yum -y install $C_CENT
        yum clean all
        # If container, install Systemd
        if [ "$INODE_NUM" -gt '2' ]; then
        printf "\nInstalling SystemD\n"
        SYSD
        fi
        # Install Ansible
        pip install ansible
        # Disable requiretty
        sed -i -e 's/^\(Defaults\s*requiretty\)/#--- \1/' /etc/sudoers
       break;;
      esac
     done
    break;;
   esac
  done
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
    touch "$FILE"
 done

# If the host is a container, modify ansible to run against localhost
 if [ "$PIP" = true ] && [ "$INODE_NUM" -gt '2' ] ; then
   printf "[local]\nlocalhost ansible_connection=local" > /etc/ansible/hosts
 fi

# Make sure ansible.cfg exists under /etc/ansible
 if [ -z "$CFG" ]
  then
   printf "\nNo ansible.cfg specified, skipping...\n"
  else
   printf "\nBacking up current ansible.cfg\n"
   BACKUP=$(date '+%Y_%m_%d_%H_%M_%S')
   cp "$LOC"/ansible.cfg "$LOC"/ansible.cfg_"$BACKUP".bak
   printf "\nFetching specified ansible.cfg\n"
   curl "$CFG" -o "$LOC"/ansible.cfg > /dev/null 2>&1
 fi

# Download Ansible Galaxy roles if specified
 if [ -z "$GALAXY" ];
  then
   printf "\nNo galaxy roles set, skipping...\n"
  else
   printf "\nFetching galaxy roles\n"
   ansible-galaxy --roles-path "$LOC"/roles install "$GALAXY" > /dev/null 2>&1
 fi

# Download Ansible roles from git if specified
 if [ -z "$GIT" ]; then
  printf "\nNo git roles set, skipping\n"
 else
  while :; do
   case "$OS" in
    ubuntu)
     printf "\nInstalling git\n"
     apt-get install -y git > /dev/null 2>&1
     printf "\nFetching roles from git\n"
     git clone "$ROLE" "$LOC"/roles > /dev/null 2>&1
     break;;
    centos)
     printf "\nInstalling git\n"
     yum install -y git > /dev/null 2>&1
     printf "\nFetching roles from git\n"
     git clone "$ROLE" "$LOC"/roles > /dev/null 2>&1
     break;;
   esac
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

# Create any specified users
 if [ -z "$USERS" ]; then
  printf "\nNo users specified, skipping...\n"
 else
  for USER in $USERS;
   do
    if ! grep -q "$USER" /etc/passwd; then
     useradd "$USER" > /dev/null 2>&1
     printf "\nUser %s created" "$USER"
     usermod -aG ansible "$USER"
    else
     usermod -aG ansible "$USER"
    fi
   done
 fi

# Set the correct Read Write Execute rights on /etc/ansible
 printf "\nSetting Ansible permissions\n"
 chmod -R 774 "$LOC"
 chown -R root:ansible "$LOC"
 chmod g+s "$LOC"

# Print script runtime
 ENDTIME=$(date +%s)
 printf "\nFinished in %s seconds\n" "$((ENDTIME-STARTTIME))"

# Exit message on successfull run
 if [ -z "$GALAXY" ] && [ -z "$GIT" ]; then
  printf "\nDownload some roles to get started\n"
 else
  printf "\nEnjoy\n"
 fi

# Print out Ansible version
 ANSI_VER=$(ansible --version | head -n 1 | awk '{print $2}')
 printf "\nAnsible version %s is installed\n\n" "$ANSI_VER"