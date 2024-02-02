#!/bin/bash

#
# This script is run by the user to download the installer and call main_installer.sh
#


# Variables initialisation
INSTALLER_URL='https://github.com/medulla-tech/integration/archive/refs/tags/1.0.1.tar.gz'

# Internal variables
WORKDIR=$(mktemp -d -p /tmp/)

# Internal functions
source internal_functions.sh

display_usage() {
    #
    # Display usage message
    #
    echo -e "\nUsage:\n$0\n"
    echo -e "arguments:"
    echo -e "\t[--installer_url=<URL for downloading Medulla installer]"
    exit 0
}

check_arguments() {
    #
    # Make sure the options passed are valid
    #
    ARGS="$@"
    for i in "$@"; do
        case $i in
            --installer_url*)
                INSTALLER_URL="${i#*=}"
                shift
                ;;
            *)
                # unknown option
                display_usage
                ;;
        esac
    done
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

download_installer() {
    #
    # Download installer scripts
    #
    local CMD="wget -c ${INSTALLER_URL} -O - | tar xz -C ${WORKDIR} --strip-components=1"
    eval ${CMD}
    if [ $? -ne 0 ]; then
        display_error_message "Installer could not be downloaded" "${CMD}"
        exit 1
    fi
}

install_medulla() {
    # 
    # Run command for installing Medulla
    #
    pushd ${WORKDIR}/installer_scripts
    chmod +x *.sh
    local CMD="./main_installer.sh"
    eval ${CMD}
    if [ $? -ne 0 ]; then
        display_error_message "Error installing Medulla" "${CMD}"
        popd
        exit 1
    fi
    popd
}


# ======================================================================
# ======================================================================
# And finally we run the functions
check_arguments "$@"
check_internet_connection
download_installer
install_medulla
