# ansible_sh

## Install Ansible on Ubuntu with a shell script

## How to use this script

```shell
git clone git@git.evry.cloud:cloudascore-ansible-roles/ansible_sh.git
cd ansible_sh
sh install_ansible.sh
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

1. Installs required packages, includes:
    * python-pip
    * curl
    * misc. other dependencies
1. Removes old Ansible PPAs if there are any
1. Re-adds the latest Ansible PPA
1. Installs Ansible
1. Installs missing Python modules, includes:
    * pywinrm (for ansible against windows)
    * pykerberos
    * py
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
1. **[if specified]** Downloads any Git roles
1. **[if specified]** Downloads any Galaxy roles
1. Creates an 'ansible' group and gives that group RWX against /etc/ansible
1. Sets the correct permissions to /etc/ansible
1. prints **Done** when it's done
