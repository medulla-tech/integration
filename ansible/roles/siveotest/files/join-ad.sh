#!/bin/bash

# Parameters
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
WINRM_PORT='5985'
VAGRANT_USERNAME='vagrant'
AD_ADMINISTRATOR='Administrateur'

display_usage() {
    echo -e "${RED}Usage: $0 --ip=<target_ip> [--password=<target_password>] --adpassword=<ad_admin_password> [--port=<winrm_port>] [--username=<target_username>] [--adadmin=<ad_admin_username>]"
    echo -e "${NC}"
    echo "Example:"
    echo "  $0 --ip=10.10.0.153 --port=5985 --username=vagrant --password=vagrant --adadmin=Administrateur --adpassword=AdMinP@55W0rd"
}

check_arguments() {
    if [[ $# -lt 3 ]]; then
        display_usage
        exit 1
    fi
    for i in "$@"; do
        case $i in
            --ip=*)
                IP="${i#*=}"
                shift
                ;;
            --port=*)
                PORT="${i#*=}"
                shift
                ;;
            --username=*)
                USERNAME="${i#*=}"
                shift
                ;;
            --password=*)
                PASSWORD="${i#*=}"
                shift
                ;;
            --adadmin=*)
                AD_ADMIN="${i#*=}"
                shift
                ;;
            --adpassword=*)
                AD_PASSWORD="${i#*=}"
                shift
                ;;
            *)
                # unknown option
                display_usage
                ;;
        esac
    done
    if [ -z ${PORT+x} ]; then
        PORT=${WINRM_PORT}
    fi
    if [ -z ${USERNAME+x} ]; then
        USERNAME=${VAGRANT_USERNAME}
    fi
    if [ -z ${AD_ADMIN+x} ]; then
        AD_ADMIN=${AD_ADMINISTRATOR}
    fi
}

join_ad() {
    # Run powershell command on IP
    echo -e "$1: Running pwsh -Command \"
\$pw = ConvertTo-SecureString -AsPlainText -Force -String ************
\$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "${USERNAME}",\$pw
Invoke-Command -ComputerName $1 -Port ${PORT} -Authentication Negotiate -Credential \$cred -FilePath /var/lib/pulse2/clients/win/join-ad.ps1 -ArgumentList "${AD_ADMIN}", "************"
\""

    pwsh -Command "
\$pw = ConvertTo-SecureString -AsPlainText -Force -String ${PASSWORD}
\$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "${USERNAME}",\$pw
Invoke-Command -ComputerName $1 -Port ${PORT} -Authentication Negotiate -Credential \$cred -FilePath /var/lib/pulse2/clients/win/join-ad.ps1 -ArgumentList "${AD_ADMIN}", "${AD_PASSWORD}"
"
}

check_arguments "$@"
join_ad ${IP}
