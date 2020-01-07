# Ansible convenience script

![Build Status](https://github.com/dovry/ansible-install-script/workflows/CI/badge.svg)

## Install Ansible with a shell script

### Now supports pip installation and containers

### Tested and works

* [![Build Status](https://travis-ci.com/dovry/docker_ubuntu18_ansible.svg?branch=master)](https://travis-ci.com/dovry/docker_ubuntu18_ansible) [Ubuntu 18.04](https://github.com/dovry/docker_ubuntu18_ansible)
* [![Build Status](https://travis-ci.com/dovry/docker_ubuntu16_ansible.svg?branch=master)](https://travis-ci.com/dovry/docker_ubuntu16_ansible) [Ubuntu 16.04](https://github.com/dovry/docker_ubuntu16_ansible)
* [![Build Status](https://travis-ci.com/dovry/docker_centos8_ansible.svg?branch=master)](https://travis-ci.com/dovry/docker_centos8_ansible) [Centos 8](https://github.com/dovry/docker_centos8_ansible)
* [![Build Status](https://travis-ci.com/dovry/docker_centos7_ansible.svg?branch=master)](https://travis-ci.com/dovry/docker_centos7_ansible) [Centos 7](https://github.com/dovry/docker_centos7_ansible)

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
Options:

  -c,         Specify a url to an ansible.cfg file to download
  -g,         Git role to download
  -G,         Galaxy role to download
  -h, -H,     Shows this help menu
  -l,         Location where Ansible files are placed, default is /etc/ansible
  -p,         Force pip installation
  -P,         Force package manager installation
  -u,         Creates, or adds an existing user to the group 'ansible'
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

examples are included at the top of the script
