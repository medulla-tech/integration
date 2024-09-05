#Base image
FROM ghcr.io/pandemonium1986/debian12:nightly

#Copy the installation script from host to container
#Script and Dockerfile must be in the same directory
COPY install_from_ansible.sh /usr/local/bin/install_from_ansible.sh
RUN chmod +x /usr/local/bin/install_from_ansible.sh

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Install systemd and other necessary packages
RUN apt-get update && \
    apt-get install -y systemd systemd-sysv && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

    # Install SSH server and any other necessary packages
RUN apt-get update && apt-get install -y openssh-server

# Create the necessary directory
RUN mkdir /var/run/sshd

# Set root password (or add a new user and set its password)
RUN echo 'root:oui123' | chpasswd

# Permit root login by SSH
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Allow password authentication
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Expose ports SSH
EXPOSE 22

# Expose ports MMC 
EXPOSE 7080 9990 9999 139 445 8385 5269 5222 3306 22000 8443 21027

# Expose ports VNC/RDP
EXPOSE 5900 3389 

# Expose ports LDAP
EXPOSE 389 636 

# Expose ports http/s
EXPOSE 80 443 8080 

# Expose ports autre
EXPOSE 111 2049 5985 5986

#Install wget 
RUN apt-get update \
    && apt-get install -y wget \
    && rm -rf /var/lib/apt/lists/* 

#Install needed package
RUN apt-get update \
    && apt-get install -y iproute2 iputils-ping 
  

# Set the default command to run systemd and ssh 



CMD ["/sbin/init","-c","./usr/local/bin/entrypoint.sh","/usr/sbin/sshd","-D"]


#CMD ["/sbin/init"]
#CMD ["/usr/local/bin/install_from_ansible.sh"]

#Ajouter un EXPOSE avec le port que l'on souhaite ecouter pour
#pouvoir s'y connecter

