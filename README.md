# Medulla installation documentation with Ansible

To install your Medulla infrastructure, we use Ansible, open-source solution includes software provisioning, configuration management, and application deployment functionality working with SSH.

To simplify documentation, passwords are in clear text. Good practice would suggest that they be encrypted. In this case please refer to the Ansible documentation : https://docs.ansible.com/ansible/latest/vault_guide/index.html

## Contents :

* Included in delivery
* Included in ansible_hosts file
* Run installation with Ansible
* Complete installation
* Glossary of Ansible variables

## Included in delivery

Medulla.tar.gz folder contains :
```bash
ansible
├── ansible_hosts
├── playbook.yml
└── roles
    └── pulse4ambx
        ├── handlers	
        │   └── main.yml
        ├── tasks
        │   └── main.yml
        └── templates
               └── medulla-generate-winupdate-packages.j2
```


Given ansible_hosts file is an exemple, it will install and configure Medulla on your server.

## Included in ansible_hosts file

Following command configure Main Medulla server :

```yaml
hostname.siveo.net INSTALL_TYPE='p' PUBLIC_IP='public_ip_main_server' SERVER_FQDN='full_hostname_main_server' ENTITY='Public' XMPP_DOMAIN='pulse'
```

Following command configure Relay Medulla server (one line or more following number of relay server you have) :

```yaml
hostname-ars-1.siveo.lan INSTALL_TYPE='m' SERVER_FQDN='full_hostname_relay_server' PULSEMAIN_IP='interne_ip_main_server' PULSEMAIN_FQDN='full_hostname_main_server' ENTITY='Private'
```

All the following variables are required to install and configure Medulla :

```yaml
[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
PULSE4REPO_URL='https://git.siveo.net/integration.list'
	#Repo Medulla
PULSE4REPOKEY_URL='https://git.siveo.net/pubkey.txt'
	#Repo key Medulla
ROOT_PASSWORD='siveo' 
	#Root Password
DBHOST='localhost'
	#Databse Host
DBPORT='3306'
	#Database port
DBADMINUSER='root'
	#Database Admin User
DBADMINPASSWD='siveo'
	#Database Admin Password
PKI_PASSWORD='siveo'
	#PKI Password
GLPI_DBHOST='localhost'
	#GLPI Database Host
GLPI_DBPORT='3306'
	#GLPI Database Port
GLPI_DBUSER='glpi'
	#GLPI Database User
GLPI_DBPASSWD='siveo'
	#GLPI Database Password
GLPI_DBNAME='glpi'
	#GLPI Database Table Name
GLPI_BASEURL='http://localhost/glpi'
	#GLPI Database URL
REVERSE_SSH_PORT=''
	#Reverse SSH Port
CLIENTS_SSH_PORT=''
	#SSH Port on client(if different from default)
CLIENTS_VNC_PORT=''
	#VNC Port on client(if different from défault)
SERVER_URBACKUP_PORT=''
	#Urbackup Port
DRIVERS_PASSWORD='secret'
	#Password for drivers
DEB_PHP_VERSION='7.4'
	#PHP Version to install
GLPI_VERSION='9.2'
	#GLPI Version to install
RESET_DB=true
	#Database resetting
ORGANISATION='Siveo Pulse'
	#Organisation on GLPI and generates OPENSSL certificate
URBACKUP_ADMINPASSWD='siveo'
	#API Urbackup password
DBDUMP_DL_BASEURL='https://updates.siveo.net'
	#Microsoft Database URL
```

## Run installation with Ansible

Command-line to install Main Medulla server :
```yaml
ansible-playbook playbook.yml -i ansible_hosts --limit=hostname.siveo.net
```

Command-line to install Relay Medulla server :
```yaml
ansible-playbook playbook.yml -i ansible_hosts --limit=hostname-ars-1.siveo.lan
```

## Complete installation

When installation is done, you can go to your server, Main and Relay.

## Glossary of Ansible variables

* PULSEMAIN_IP
	IP Address Main Server.
* PUBLIC_IP
	Public IP Address (main or relay server).
* IP_ADDRESS
	IP Address (main or relay server).
* SERVER_FQDN
	Hostname server with domain name, ex : server.siveo.net (main or relay).
* PULSEMAIN_FQDN
	Hostname of MAIN Server with domain name, ex : main_server.siveo.net.
* REVERSE_SSH_PORT
	SSH Port.
* CLIENTS_SSH_PORT
	SSH Port on client(if different from default).
* CLIENTS_VNC_PORT
	VNC Port on client(if different from défault).
* INSTALL_TYPE
	Type of installation, (p) for main server, (m) for relay server
* ENTITY
	Server entity, (main server : public, relay : private)
