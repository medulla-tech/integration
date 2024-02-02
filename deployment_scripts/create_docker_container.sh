#!/bin/bash

#
# This script is called by the installer to create a Docker container
#

# Variables initialisation
DEST_PATH=

# Internal functions
source internal_functions.sh


# ======================================================================
create_docker_image() {
    #
    # Create docker image
    #
    local CMD="echo > Dockerfile"
    eval ${CMD}
    if [ $? -ne 0 ]; then
        display_error_message "The Dockerfile could not be created" "${CMD}"
        exit 1
    fi
    local CMD="docker build -t debian12"
    eval ${CMD}
    if [ $? -ne 0 ]; then
        display_error_message "The Docker image could not be created" "${CMD}"
        exit 1
    fi
}

run_docker_container() {
    #
    # Run the docker container for Medulla
    #
    local CMD="docker run --name Medulla -p 80:80 debian12"
    eval ${CMD}
    if [ $? -ne 0 ]; then
        display_error_message "The Docker container could not be started" "${CMD}"
        exit 1
    fi
}
