# Medulla installation documentation with Ansible

To install your Medulla infrastructure, we use Ansible, open-source solution includes software provisioning, configuration management, and application deployment functionality working with SSH.

To simplify documentation, passwords are in clear text. Good practice would suggest that they be encrypted. In this case please refer to the Ansible documentation : https://docs.ansible.com/ansible/latest/vault_guide/index.html

## Repository contains :
```bash
ansible
├── ansible_hosts
├── playbook.yml
└── roles
    └── medulla
        ├── handlers	
        │   └── main.yml
        ├── tasks
        │   └── main.yml
        └── templates
               └── medulla-generate-winupdate-packages.j2
```


## Parameters

The ansible_hosts file contains the parameters needed to configure and install your main server and the relays.

### [hostname]

example for the main Medulla server:

```yaml
hostname.siveo.net INSTALL_TYPE='p' PUBLIC_IP='public_ip_main_server' SERVER_FQDN='full_hostname_main_server' ENTITY='Public' XMPP_DOMAIN='pulse'
```

example for relay Medulla server (one line or more following number of relay server you have) :

```yaml
hostname-ars-1.siveo.lan INSTALL_TYPE='m' SERVER_FQDN='full_hostname_relay_server' PULSEMAIN_IP='interne_ip_main_server' PULSEMAIN_FQDN='full_hostname_main_server' ENTITY='Private'
```

### [all:vars]

Choose your version stable or devel (containing all new features), by filling those two paramters

#### Stable

```bash
#Repo Medulla
PULSE4REPO_URL='https://apt.siveo.net/stable.list'
#Repo key Medulla
PULSE4REPOKEY_URL='https://apt.siveo.net/pubkey.txt'
```

#### Devel
```bash
#Repo Medulla
PULSE4REPO_URL='https://git.siveo.net/xmppmaster.list'
#Repo key Medulla
PULSE4REPOKEY_URL='https://git.siveo.net/pubkey.txt'
```

All the following variables are mandatory to install and configure Medulla :
```bash
[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'

# Repo Medulla
PULSE4REPO_URL='https://git.siveo.net/integration.list'

# Repo key Medulla
PULSE4REPOKEY_URL='https://git.siveo.net/pubkey.txt'

# Root Password
ROOT_PASSWORD='siveo' 

# Databse Host
DBHOST='localhost'

# Database port
DBPORT='3306'

# Database Admin User
DBADMINUSER='root'
	
# Database Admin Password
DBADMINPASSWD='siveo'

# PKI Password
PKI_PASSWORD='siveo'

# GLPI Database Host
GLPI_DBHOST='localhost'

# GLPI Database Port
GLPI_DBPORT='3306'

# GLPI Database User
GLPI_DBUSER='glpi'

# GLPI Database Password
GLPI_DBPASSWD='siveo'
	
# GLPI Database Table Name
GLPI_DBNAME='glpi'

# GLPI Database URL
GLPI_BASEURL='http://localhost/glpi'

# Reverse SSH Port
REVERSE_SSH_PORT=''

# SSH Port on client(if different from default)
CLIENTS_SSH_PORT=''

# VNC Port on client(if different from défault)
CLIENTS_VNC_PORT=''

# Urbackup Port
SERVER_URBACKUP_PORT=''

# Password for drivers
DRIVERS_PASSWORD='secret'

# PHP Version to install
DEB_PHP_VERSION='7.4'

# GLPI Version to install
GLPI_VERSION='9.2'

# The itsm-ng version
ITSM_NG_VERSION='1.3'

# The ITSM to use ( glpi or itsmng )
ITSM_TYPE='glpi'

# The used by default by the itsm
ITSM_USER='itsm'

# Database resetting
RESET_DB=true

# Organisation on GLPI and generates OPENSSL certificate
ORGANISATION='Siveo Pulse'

# API Urbackup password
URBACKUP_ADMINPASSWD='siveo'

# Microsoft Database URL
DBDUMP_DL_BASEURL='https://updates.siveo.net'
	
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

When the installation is done, the url to login is http://ipserver/mmc with your credential.

You can find the medulla-agent here : http://ipserver/downloads


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
