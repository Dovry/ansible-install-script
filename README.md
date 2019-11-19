# Ansible convenience script

[![Build Status](https://travis-ci.org/Dovry/ansible-install-script.svg?branch=master)](https://travis-ci.org/Dovry/ansible-install-script)

## Install Ansible with a shell script

### Now supports pip and containers

### Tested and works

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
