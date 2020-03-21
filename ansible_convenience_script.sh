#!/bin/sh
# POSIX
set -e # exit if a command fails
set -u # exit if a referenced variable is not declared
STARTTIME=$(date +%s) # start function for script runtime

# Set this to the URL of your custom ansible.cfg file, e.g.
# "https://raw.githubusercontent.com/ansible/ansible/devel/examples/ansible.cfg"
CFG=""
# Space seperated list of git roles, e.g.
# "https://github.com/geerlingguy/ansible-role-java.git https://github.com/geerlingguy/ansible-role-nodejs.git"
GIT=""
# Space seperated list of ansible-galaxy roles, e.g.
# "geerlingguy.ntp geerlingguy.nginx"
GALAXY=""
# Space seperated list of users to add to the 'ansible' group, e.g.
# "alice bob charlie diane"
USERS=""

# Ansible files and folders
 LOC="/etc/ansible"
 ANSI_FOLDERS="facts files inventory playbooks plugins roles inventory/group_vars inventory/host_vars"
 FILES="$LOC/inventory/hosts $LOC/hosts $LOC/ansible.cfg"

# Packages
 PKGS="gcc curl sshpass"
 APT="software-properties-common"
 DNF="redhat-rpm-config"
 YUM="python2-pip kernel-devel gcc-c++ libxslt-devel libffi-devel openssl-devel"
 PY3="python3 python3-setuptools"

# Container-specific packages
 ANSIBLE="ansible"
 C_CENT="sudo which initscripts"
 C_CENT8="hostname"
 C_CENT7="deltarpm"
 C_APT="locales sudo wget rsyslog systemd systemd-cron sudo iproute2"
 C_UBU18="apt-utils"
 C_UBU16="python-software-properties libssl-dev"

# Install systemd function - Required to run Ansible against localhost in containers
 SYSD () { 
  (cd /lib/systemd/system/sysinit.target.wants/; \
  for i in *; do [ $i = systemd-tmpfiles-setup.service ] || rm -f $i; done);
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
  printf "\n"
  printf "\n  -c,         Specify a url to an ansible.cfg file to download"
  printf "\n  -g,         Git role to download"
  printf "\n  -G,         Galaxy role to download"
  printf "\n  -h, -H,     Shows this help menu"
  printf "\n  -l,         Location where Ansible files are placed, default is /etc/ansible"
  printf "\n  -p,         Force pip installation"
  printf "\n  -P,         Force package manager installation"
  printf "\n  -u,         Creates, or adds an existing user to the group 'ansible'"
  printf "\n"
  printf "\nTo specify multiple users or roles, surround the string in quotes"
  printf " like so:\n"
  printf "Users:  -u \"user1 user2 user3\" \n"
  printf "Galaxy: -G \"owner.role owner.role2\"\n"
  printf "Git:    -g \"https://github.com/user/role.git https://github.com/someguy/role2.git\""
  printf "\n\n"
  exit 0
 }

# Options
 while getopts 'c:g:G:hHl:pPu:' option; do
  case $option in
   c) CFG="$OPTARG" ;;                               # ansible.cfg to use, has a default
   g) GIT="$OPTARG" ;;                               # git roles
   G) GALAXY="$OPTARG" ;;                            # galaxy roles to download
   h) HELP ;;                                        # shows the help menu
   H) HELP ;;                                        # shows the help menu
   l) LOC="$LOC" ;;                                  # ansible files location
   p) PIP=true; INSTALLATION="pip" ;;                # pip install
   P) PIP=false; INSTALLATION="package manager" ;;   # force package manager install (defaults to pip in container)
   u) USERS="$OPTARG" ;;                             # users to add to ansible group
   *) ;;
  esac
 done

# Exit if not run as root
 [ "$(whoami)" = 'root' ] \
 || printf "\nThis script must be run with elevated privleges!\n\n" \
 || exit 1

# Check if running in container || used mainly for CI processes
# Use flag -x to force normal install in containers, which is useful for testing
INODE_NUM=$(stat / | awk '/Inode/ {print $4}')
[ "$INODE_NUM" -gt '2' ] && PIP="true" || PIP=""

 # Check if git should be installed
 [ -z "$GIT" ] && GIT_PKG="git" || GIT_PKG=""

# Check which OS script is being run on. Exits if it's not supported
 while :; do
  case "$OS" in
   ubuntu|centos)
    while :; do
     case "$VER" in
      18.*|16.*|8|7)
       printf "\n%s %s %s detected\n\nconfigured for %s installation" \
       "$OS" "$VER" "$CONTAINER" "$INSTALLATION"
      break;;
     esac
    done
   break;;
    *)
     printf "\n%s %s %s is not supported\n" "$OS" "$VER" "$CONTAINER"
     exit 0
   ;;
  esac
 done

# Update cache // install epel-release (if not container)
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
     apt-get install -y $APT $PKGS $GIT_PKG > /dev/null 2>&1
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
        dnf install -y $YUM $DNF $PKGS $GIT_PKG $PY3 > /dev/null 2>&1
       break;;
       7)
        yum install -y $YUM $PKGS $GIT_PKG > /dev/null 2>&1
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
     apt-get install --reinstall -y $ANSIBLE > /dev/null 2>&1
    break;;
    centos)
     while :; do
      case "$VER" in
       8)
        # Install pip
        wget -O - https://bootstrap.pypa.io/get-pip.py | python3 -
        pip3 install --upgrade --force-reinstall $ANSIBLE > /dev/null 2>&1
       break;;
       7)
        yum install -y $ANSIBLE > /dev/null 2>&1
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
        # Prepare OS for Ansible install
        apt-get -y --no-install-recommends install \
        $PKGS $APT $C_APT $C_UBU18 $GIT_PKG $PY3

        locale-gen en_US.UTF-8
        sed -i 's/^\($ModLoad imklog\)/#\1/' /etc/rsyslog.conf
        # Install pip
        wget -O - https://bootstrap.pypa.io/get-pip.py | python3 -
        # Install Ansible
        pip3 install --disable-pip-version-check \
        --upgrade \
        --force-reinstall $ANSIBLE
        # Cleanup
        rm -Rf /var/lib/apt/lists/* \
        /usr/share/doc /usr/share/man \
        /root/.cache/pip/

        find / -name '*.pyc' -delete
        find / -name '*__pycache__*' -delete
       break;;
       16.*)
        # Prepare OS for Ansible install
        apt-get -y install $PKGS $APT $C_APT $C_UBU16 $GIT_PKG $PY3
        locale-gen en_US.UTF-8
        sed -i 's/^\($ModLoad imklog\)/#\1/' /etc/rsyslog.conf
        # Install pip
        wget -O - https://bootstrap.pypa.io/get-pip.py | python3 -
        # Install Ansible
        pip3 install --disable-pip-version-check \
        --upgrade \
        --force-reinstall $ANSIBLE
        # Cleanup
        rm -Rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man
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
        yum -y update
        yum -y install $C_CENT $C_CENT8 $PY3 $GIT_PKG
        # Install pip
        wget -O - https://bootstrap.pypa.io/get-pip.py | python3 -
        # If container, install Systemd
        [ "$INODE_NUM" -gt '2' ] && printf "\nInstalling SystemD\n" && SYSD
        # Install Ansible
        pip3 install $ANSIBLE
        # Disable requiretty
        sed -i -e 's/^\(Defaults\s*requiretty\)/#--- \1/' /etc/sudoers
        yum clean all
       break;;
       7)
        yum makecache fast
        yum -y update
        yum -y install $C_CENT $C_CENT7 $GIT_PKG $PY3
        # Install pip
        wget -O - https://bootstrap.pypa.io/get-pip.py | python3 -
        # If container, install Systemd
        [ "$INODE_NUM" -gt '2' ] && printf "\nInstalling SystemD\n" && SYSD
        # Install Ansible
        pip3 install ansible
        # Disable requiretty
        sed -i -e 's/^\(Defaults\s*requiretty\)/#--- \1/' /etc/sudoers
        yum clean all
       break;;
      esac
     done
    break;;
   esac
  done
 fi

# Create missing directories
 printf "\nCreating any missing directories\n"
 for DIR in $ANSI_FOLDERS;
   do
    mkdir -p "$LOC"/"$DIR"
 done

# Create missing files
 printf "\nCreating any missing files\n"
 for FILE in $FILES;
   do
    touch "$FILE"
 done

# If the host is a container, modify ansible to run against localhost
 [ "$PIP" = true ] && [ "$INODE_NUM" -gt '2' ] \
 && printf "\nAdding localhost entry to Ansible hosts file\n" \
 && printf "[local]\nlocalhost ansible_connection=local" > /etc/ansible/hosts

# Make sure ansible.cfg exists under /etc/ansible
 [ -z "$CFG" ] \
 && printf "\nNo ansible.cfg specified, continuing...\n" \
 || printf "\nBacking up current ansible.cfg\n" \
 || BACKUP=$(date '+%Y_%m_%d_%H_%M_%S') \
 || cp "$LOC"/ansible.cfg "$LOC"/ansible.cfg_"$BACKUP".bak \
 || printf "\nDownloading specified ansible.cfg\n" \
 || curl "$CFG" -o "$LOC"/ansible.cfg > /dev/null 2>&1 \

# Download Ansible Galaxy roles if specified
 if [ -z "$GALAXY" ]; then
  printf "\nNo galaxy roles set, continuing...\n"
 else
  printf "\nDownloading the following roles to %s/roles\n" "$LOC"
   for galaxy_role in $GALAXY; do
    ansible-galaxy install --roles-path \
    "$LOC"/roles "$galaxy_role" > /dev/null 2>&1
    printf "\n - %s" "$galaxy_role"
   done
  printf "\n"
 fi

# Download Ansible roles with git if specified
 if [ -z "$GIT" ]; then
  printf "\nNo git roles set, continuing\n"
 else
  printf "\nDownloading the following roles to %s/roles\n" "$LOC"
  cd "$LOC"/roles
   for git_role in $GIT; do
    git clone "$git_role" || true > /dev/null 2>&1 
   done
 fi

# Make sure group 'ansible' exists
 if cut -d: -f1 /etc/group | grep ansible > /dev/null 2>&1;
  then
   printf "\nAnsible group exists, continuing..."
  else
   printf "\nAdding group \"ansible\"\n"
   groupadd ansible
 fi

# Create any specified users
 if [ -z "$USERS" ]; then
  printf "\nNo users specified, continuing..."
 else
  for USER in $USERS; do
    [ ! grep -q "$USER" /etc/passwd ] \
     && useradd "$USER" > /dev/null 2>&1 \
     && usermod -aG ansible "$USER" \
     && printf "\n - %s created" "$USER" \
     || usermod -aG ansible "$USER"
  done
 fi

# Set the correct Read Write Execute permissions on /etc/ansible
 printf "\n\nSetting Ansible permissions on %s\n" "$LOC"
 chmod -R 774 "$LOC"
 chown -R root:ansible "$LOC"
 chmod g+rwxs "$LOC"

# Print script runtime
 ENDTIME=$(date +%s)
 printf "\nFinished in %s seconds\n" "$((ENDTIME-STARTTIME))"

# Print out Ansible version
 ANSI_VER=$(ansible --version | head -n 1 | awk '{print $2}')
 printf "\nAnsible version %s is installed\n" "$ANSI_VER"

# Exit message on successfull run
 [ -z "$GALAXY" ] && [ -z "$GIT" ] \
 && printf "\nDownload some roles to get started\n\n" || printf "\nEnjoy\n\n"