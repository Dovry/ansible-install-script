[![Build Status](https://travis-ci.org/Dovry/ansible-install-script.svg?branch=master)](https://travis-ci.org/Dovry/ansible-install-script)

# Ansible convenience script

## Install Ansible with a shell script

### Now supports pip and containers!

### Tested and works:

* Ubuntu 18.04
* Ubuntu 16.04

* Centos 8
* Centos 7

### Untested, but might work

* Ubuntu 16.10
* Ubuntu 18.10
* Ubuntu 19.04
* Ubuntu 19.10

## How to use this script

```shell
git clone git@git.evry.cloud:cloudascore-ansible-roles/ansible_sh.git
cd ansible_sh
chmod +x ansible_convenience_script.sh
sudo ./ansible_convenience_script.sh
```

**Arguments**:

```bash
-h, --help     Shows this help menu
-p,            Install Ansible via python pip
-x,            Force normal installation in a container
```

**Optional** variables:

```sh
# Set this to the URL of your custom ansible.cfg file
CFG=""
# Space seperated list of git roles
GIT=""
# Space seperated list of ansible-galaxy roles
GALAXY=""
# Space seperated list of users to add to the 'ansible' group
USERS=""
``` 

### Step by step walkthrough

1. Checks for OS and Version, exits if not supported
1. Prepares system
      * **Ubuntu**
         * Updates apt cache
      * **CentOS**
         * Installs epel-release
1. Installs required packages, includes:
    * python-pip
    * curl
    * misc. other dependencies for each OS
1. **Ubuntu**
      * Removes old Ansible PPAs if there are any
      * Re-adds the latest Ansible PPA
1. Installs Ansible
1. Installs missing Python modules (space seperated list in variables)
1. Creates **missing** directories under /etc/ansible
    * roles
    * inventory
    * playbooks
    * etc.
1. Creates **missing** files, includes:
    * /etc/ansible/inventory/hosts
    * /etc/ansible/hosts
    * /etc/ansible/ansible.cfg
1. **[if specified]** Downloads  an ansible.cfg, backs up the old one with a unique name
1. **[if specified]** Downloads any Galaxy roles
1. **[if specified]** Downloads any Git roles
1. Creates (if missing) group 'ansible'
1. Creates and adds any users **[if specified]** to group 'ansible'
1. Sets the correct permissions to /etc/ansible for group 'ansible'
1. prints Ansible version, and **Done** when it's done
