FROM  debian:12.5

# Mettre à jour le système et installer les dépendances nécessaires
RUN apt-get update && \
    apt-get install -y \
    software-properties-common \
    gnupg2 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Ajouter le dépôt Ansible et installer Ansible
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367 && \
    echo 'deb http://ppa.launchpad.net/ansible/ansible/ubuntu focal main' > /etc/apt/sources.list.d/ansible.list && \
    apt-get update && \
    apt-get install -y ansible && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

CMD ["ansible", "--version"]