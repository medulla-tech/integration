#!/bin/bash
    
# Start SSH service
service ssh start

echo "172.17.0.2 pulse" >> /etc/hosts

# Execute the install_from_ansible.sh script
exec /usr/local/bin/install_from_ansible.sh --public-ip=192.168.26.141


