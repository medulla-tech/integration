#!/bin/bash

#
# This script contains all functions common to all scripts and must be sourced in them
#

# Internal functions
colored_echo() {
    # Output colored lines to shell
    local COLOR=$1;
    if ! [[ $COLOR =~ '^[0-9]$' ]] ; then
        case $(echo $COLOR | tr '[:upper:]' '[:lower:]') in
            black) COLOR=0 ;;
            red) COLOR=1 ;;
            green) COLOR=2 ;;
            yellow) COLOR=3 ;;
            blue) COLOR=4 ;;
            magenta) COLOR=5 ;;
            cyan) COLOR=6 ;;
            white|*) COLOR=7 ;; # white or invalid color
        esac
    fi
    tput setaf $COLOR;
    echo "${@:2}";
    tput sgr0;
}

ask() {
    # Ask user a yes/no question
    local TEXT=$1
    local OPTION1=$2
    local OPTION2=$3
    local RESULT=N
    while [ ${RESULT} == "N" ]; do
        local PROMPT="$OPTION1/$OPTION2"
        # Ask the question - use /dev/tty in case stdin is redirected from somewhere else
        read -p "${TEXT} [${PROMPT}] " REPLY </dev/tty
        # Check if the reply is valid
        case "${REPLY}" in
            ${OPTION1^^}|${OPTION1,,})
                RESULT=Y
                echo ${OPTION1,,}
                ;;
            ${OPTION2^^}|${OPTION2,,})
                RESULT=Y
                echo ${OPTION2,,}
                ;;
        esac
    done
}

get_user_input() {
    #
    # Ask user for a string input
    #
    local TEXT=$1
    while [[ ${RESULT} == '' ]]; do
        read -p "${TEXT} " RESULT
    done
    echo ${RESULT}
}
