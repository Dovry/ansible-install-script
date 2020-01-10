# Ansible convenience script

![Build Status](https://github.com/dovry/ansible-install-script/workflows/CI/badge.svg)

## Install Ansible with a shell script

### Now supports pip installation and containers

### Tested and works

* ![Build Status](https://github.com/dovry/docker_ubuntu18_ansible/workflows/Basic%20build%20and%20push%20to%20Docker%20hub/badge.svg) - [Ubuntu 18.04](https://github.com/dovry/docker_ubuntu18_ansible)
* ![Build Status](https://github.com/dovry/docker_ubuntu16_ansible/workflows/Basic%20build%20and%20push%20to%20Docker%20hub/badge.svg) - [Ubuntu 16.04](https://github.com/dovry/docker_ubuntu16_ansible)
* ![Build Status](https://github.com/dovry/docker_centos8_ansible/workflows/Basic%20build%20and%20push%20to%20Docker%20hub/badge.svg) - [Centos 8](https://github.com/dovry/docker_centos8_ansible)
* ![Build Status](https://github.com/dovry/docker_centos7_ansible/workflows/Basic%20build%20and%20push%20to%20Docker%20hub/badge.svg) - [Centos 7](https://github.com/dovry/docker_centos7_ansible)

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
# Space seperated pip packages to install
PYPKG=""
```
