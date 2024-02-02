#!/bin/bash

#
# This script is called by the installer downloader to install Medulla on various media
#


# Variables initialisation
TARGET_SERVER=localhost

# Internal variables
WORKDIR=$(mktemp -d -p /tmp/)
TARGET_PLATFORM=d


# Internal functions
source internal_functions.sh

display_error_message() {
    local TEXT=$1
    local CMD=$2
    colored_echo red "### ${TEXT}. Exiting"
    if [[ ${CMD} != "" ]]; then
        colored_echo red "Failed command: ${CMD}"
    fi
    colored_echo red "Run the following command to re-install in interactive mode:"
    colored_echo red "$0 --interactive"
}

display_usage() {
    #
    # Display usage message
    #
    echo -e "\nUsage:\n$0\n"
    echo -e "arguments:"
    echo -e "\t[--target_server]"
    exit 0
}

check_arguments() {
    #
    # Make sure the options passed are valid
    #
    ARGS="$@"
    for i in "$@"; do
        case $i in
            --target_platform*)
                TARGET_PLATFORM="${i#*=}"
                shift
                ;;
            --target_server*)
                TARGET_SERVER="${i#*=}"
                shift
                ;;
            *)
                # unknown option
                display_usage
                ;;
        esac
    done
}

display_wizard() {
    #
    # Ask questions to user for customising the installation
    #
    local ENTER_TARGET_PLATFORM=$(ask "The default target is a docker container. Do you want to change it?" y n)
    if [[ ${ENTER_TARGET_PLATFORM} == "y" ]]; then
        TARGET_PLATFORM=$(ask "The two other options are (V)irtualBox and (A)lready installed server" V A)
    fi
}


# ======================================================================
check_internet_connection() {
    #
    # Make sure the machine is connected to the Internet
    #
    wget -q --spider http://google.com &> /dev/null
    if [ $? -ne 0 ]; then
        display_error_message "The machine is not connected to the Internet"
        exit 1
    fi
}

install_needed_tools() {
    #
    # install needed packages on user's machine
    #
    local CMD="apt install sshpass rsync"
    eval ${CMD}
    if [ $? -ne 0 ]; then
        display_error_message "The needed tools could not be installed" "${CMD}"
        exit 1
    fi
}

create_docker_container() {
    # 
    # Call script to create a docker container for Medulla
    #
    local CMD="./create_docker_container.sh"
    eval ${CMD}
    if [ $? -ne 0 ]; then
        display_error_message "Error creating the Docker container" "${CMD}"
        exit 1
    fi
}

create_vbox_vm() {
    # 
    # Call script to create a VirtualBox VM for Medulla
    #
    local CMD="./create_vbox_vm.sh"
    eval ${CMD}
    if [ $? -ne 0 ]; then
        display_error_message "Error creating the VirtualBox VM" "${CMD}"
        exit 1
    fi
}

generate_sshkeys() {
    #
    # Generate SSH keys and setup authentication to target server
    #
    ssh-keygen -f ~/.ssh/id_rsa -N '' -b 2048 -t rsa -q
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys 
    ssh-keyscan -t rsa $(hostname) >> ~/.ssh/known_hosts

    ssh-keyscan ${PULSEMAIN_IP} >> /root/.ssh/known_hosts
    sshpass -p ${ROOT_PASSWORD} ssh-copy-id ${PULSEMAIN_IP}
}

copy_playbook() {
    #
    # Copy playbook to target server
    #
    local CMD="rsync -a ${WORKDIR} root@${TARGET_SERVER}:/tmp/"
    eval ${CMD}
    if [ $? -ne 0 ]; then
        display_error_message "Error copying playbook to target server" "${CMD}"
        exit 1
    fi

}

install_medulla_from_ansible() {
    # 
    # Call script to install Medulla using ansible
    #
    local CMD="ssh root@${TARGET_SERVER}:${WORKDIR}/install_from_ansible.sh"
    eval ${CMD}
    if [ $? -ne 0 ]; then
        display_error_message "Error installing Medulla" "${CMD}"
        exit 1
    else
        display_final_message
    fi
    popd
}


# ======================================================================
# ======================================================================
# And finally we run the functions
check_arguments "$@"
if [[ ${INTERACTIVE} == 1 ]]; then
    display_wizard
fi
check_internet_connection
install_needed_tools
case ${TARGET_PLATFORM} in 
    d)
        create_docker_container
        ;;
    v)
        create_vbox_vm
        ;;
    a)
        # Call install_medulla_from_ansible
        ;;
    *)
        # unknown option
        display_usage
        ;;
esac

generate_sshkeys

copy_playbook

install_medulla_from_ansible --nostandalone
