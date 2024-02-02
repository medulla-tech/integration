#!/bin/bash

#
# This script is called by the installer to create a VirtualBox VM
#

# Variables initialisation
DEST_PATH=$(mktemp -d -p /tmp/)

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
    echo -e "\nUsage:\n$0 [--standalone]\n"
    echo -e "arguments:"
    echo -e "\t[--interactive]"
    echo -e "or:"
    echo -e "\t[--timezone=<Server's timezone> eg. Europe/Paris]"
    echo -e "\t[--medulla_root_pw=<Medulla root password>]"
    echo -e "\t[--public-ip=<Public IP if available>]"
    echo -e "\t[--server-fqdn=<FQDN of server>]"
    exit 0
}

check_arguments() {
    #
    # Make sure the options passed are valid
    #
    ARGS="$@"
    for i in "$@"; do
        case $i in
            --standalone*)
                STANDALONE=1
                shift
                ;;
            --interactive*)
                INTERACTIVE=1
                shift
                ;;
            --timezone*)
                TIMEZONE="${i#*=}"
                shift
                ;;
            --playbook_url*)
                PLAYBOOK_URL="${i#*=}"
                shift
                ;;
            --medulla_root_pw*)
                ROOT_PASSWORD="${i#*=}"
                shift
                ;;
            --public_ip*)
                PUBLIC_IP="${i#*=}"
                shift
                ;;
            --server_fqdn*)
                SERVER_FQDN="${i#*=}"
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
    local ENTER_DEST_PATH=$(ask "The default destination path is ${DEST_PATH}. Do you want to change it?" y n)
    if [[ ${ENTER_DEST_PATH} == "y" ]]; then
        DEST_PATH=$(get_user_input "Define the path where the VirtualBox VM will be created:")
    fi
    local ENTER_BRIDGE_INTERFACE=$(ask "")
    local ENTER_ROOT_PASSWORD=$(ask "A password will be generated for root user and displayed subsequently. Do you want to define it yourself?" y n)
    if [[ ${ENTER_ROOT_PASSWORD} == "y" ]]; then
        ROOT_PASSWORD=$(get_user_input "Enter the password you wish to use for Medulla admin account:")
    fi
}

display_summary() {
    #
    # Display parameters that will be used for installing Medulla
    #
    colored_echo blue "Medulla will be installed with the following parameters:"
    colored_echo blue "- DEST_PATH: ${DEST_PATH}"
    colored_echo blue "- ROOT_PASSWORD: ${ROOT_PASSWORD}"
}

# ======================================================================
get_local_interface() {
    #
    # Try to guess the interface to use for bridging
    #
    host ${LOCAL_FQDN} &> /dev/null
    if [ $? -ne 0 ]; then
        display_error_message "The machine's name is not resolvable"
        exit 1
    fi
}

find_first_available_ip() {
    #
    # Try to guess the static IP address to use
    #
    host ${LOCAL_FQDN} &> /dev/null
    if [ $? -ne 0 ]; then
        display_error_message "The machine's name is not resolvable"
        exit 1
    fi
}

create_vm() {
    #
    # Create VirtualBox VM
    #
    local CMD="VBoxManage createvm --name Medulla --ostype Debian_64 --register"
    eval ${CMD}
    if [ $? -ne 0 ]; then
        display_error_message "The VM could not be created" "${CMD}"
        exit 1
    fi
    local CMD="VBoxManage modifyvm Medulla --cpus 2 --memory 2048 --vram 12"
    eval ${CMD}
    if [ $? -ne 0 ]; then
        display_error_message "The VM resources could not be modified" "${CMD}"
        exit 1
    fi
    local CMD="VBoxManage modifyvm Medulla --nic1 bridged --bridgeadapter1 eth0"
    eval ${CMD}
    if [ $? -ne 0 ]; then
        display_error_message "The VM network settings could not be created" "${CMD}"
        exit 1
    fi
    local CMD="VBoxManage createhd --filename ${DEST_PATH}/Medulla.vdi --size 5120 --variant Standard"
    eval ${CMD}
    if [ $? -ne 0 ]; then
        display_error_message "The VM storage file could not be created" "${CMD}"
        exit 1
    fi
    local CMD="VBoxManage storagectl Medulla --name 'SATA Controller' --add sata --bootable on"
    eval ${CMD}
    if [ $? -ne 0 ]; then
        display_error_message "The VM storage controller could not be added" "${CMD}"
        exit 1
    fi
    local CMD="VBoxManage storageattach Medulla --storagectl 'SATA Controller' --port 0 --device 0 --type hdd --medium ${DEST_PATH}/Medulla.vdi"
    eval ${CMD}
    if [ $? -ne 0 ]; then
        display_error_message "The VM storage file could not be attached to the SATA controller" "${CMD}"
        exit 1
    fi
    local CMD="VBoxManage storagectl Medulla --name 'IDE Controller' --add ide"
    eval ${CMD}
    if [ $? -ne 0 ]; then
        display_error_message "The VM disk controller could not be added" "${CMD}"
        exit 1
    fi
    local CMD="VBoxManage storageattach Medulla --storagectl 'IDE Controller' --port 0 --device 0 --type dvddrive --medium host:/dev/dvd"
    eval ${CMD}
    if [ $? -ne 0 ]; then
        display_error_message "The OS ISO image could not be attached to the IDE controller" "${CMD}"
        exit 1
    fi
}



aux_base_path="$(mktemp -d --tmpdir unattended-install-XXXXX)"
VBoxManage unattended install Medulla --iso=install-iso --user=login --password=password --country=UK --time-zone=UTC --hostname=testserver.local --install-additions --language=en-US --auxiliary-base-path "$aux_base_path"/
sed -i 's/^default vesa.*/default install/' "$aux_base_path"/isolinux-isolinux.cfg

VBoxManage startvm Medulla

Note: the commands above are for unix shell (Linux & MacOS). For Windows console, use an existing folder path like %UserProfile%/ instead of "$aux_base_path/" and use:
$f = Get-Content isolinux-isolinux.cfg | %{$_ -replace "^default vesa.*","default install"}
$f > isolinux-isolinux.cfg

# ======================================================================
# ======================================================================
# And finally we run the functions
check_arguments "$@"
if [[ ${INTERACTIVE} == 1 ]]; then
    display_wizard
fi
display_summary
