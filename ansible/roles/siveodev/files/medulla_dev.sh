#!/bin/bash
WORKING_ENV=/root/medulla-dev
ACTION=$1
BRANCH_NAME=$2

if [ -z "$ACTION" ]; then
    echo "Usage: $0 <action> <branch_name>"
    echo "Actions: backup, copytogit, updateserver"
    exit 1
fi

if [ "$ACTION" == "copytogit" ]; then
    if [ -z "$BRANCH_NAME" ]; then
        echo "Usage: $0 copytogit <branch_name>"
        exit 1
    fi
fi

if [ -f "/etc/debian_version" ]; then
    PYDIR='/usr/lib/python3/dist-packages'
elif [ -f "/etc/redhat-release" ]; then
    PYDIR='/usr/lib/python3.11/site-packages'
fi

checkout_branch() {
    DESTINATION=$1
    echo "### Checking out branch ${BRANCH_NAME} to ${DESTINATION}"
    # Check if the directory already exists
    # If it does, exit the script
    # If it doesn't, create the directory
    if [ -d "${DESTINATION}" ]; then
        echo "Directory ${DESTINATION} already exists. Exiting."
        exit 1
    fi
    mkdir -p ${DESTINATION}
    # Checkout medulla
    git clone git@github.com:medulla-tech/medulla.git ${DESTINATION}/medulla
    # If the clone fails, try using https
    if [ $? -ne 0 ]; then
        echo "Failed to clone medulla repository using ssh. Trying https."
        git clone https://github.com/medulla-tech/medulla.git ${DESTINATION}/medulla
        if [ $? -ne 0 ]; then
            echo "Failed to clone medulla repository. Exiting."
            exit 1
        fi
    fi
    cd ${DESTINATION}/medulla
    git config core.fileMode false
    git checkout ${BRANCH_NAME}
    git pull origin ${BRANCH_NAME}
    # Checkout medulla-agent
    git clone git@github.com:medulla-tech/medulla-agent.git ${DESTINATION}/medulla-agent
    # If the clone fails, exit the script
    if [ $? -ne 0 ]; then
        echo "Failed to clone medulla-agent repository using ssh. Trying https."
        git clone https://github.com/medulla-tech/medulla-agent.git ${DESTINATION}/medulla-agent
        if [ $? -ne 0 ]; then
            echo "Failed to clone medulla repository. Exiting."
            exit 1
        fi
    fi
    cd ${DESTINATION}/medulla-agent
    git config core.fileMode false
    git checkout ${BRANCH_NAME}
    git pull origin ${BRANCH_NAME}
}

copy_changes() {
    DESTINATION=$1
    echo "### Copying changes to ${DESTINATION}"
    mkdir -p ${DESTINATION}
    cd ${DESTINATION}

    # /usr/share/mmc -> medulla/web
    mkdir -p medulla/web
    cp -a /usr/share/mmc/* medulla/web/
    echo "/usr/share/mmc copied to ${DESTINATION}/medulla/web"

    # ${PYDIR}/mmc -> medulla/agent/mmc
    mkdir -p medulla/agent/mmc
    find ${PYDIR}/mmc -type f \( -name "*.pyc" -o -name "*.pyo" \) -delete
    cp -a ${PYDIR}/mmc/* medulla/agent/mmc/
    echo "${PYDIR}/mmc copied to ${DESTINATION}/medulla/agent/mmc"

    # ${PYDIR}/pulse2 -> medulla/services/pulse2
    mkdir -p medulla/services/pulse2
    find ${PYDIR}/pulse2 -type f \( -name "*.pyc" -o -name "*.pyo" \) -delete
    cp -a ${PYDIR}/pulse2/* medulla/services/pulse2/
    echo "${PYDIR}/pulse2 copied to ${DESTINATION}/medulla/services/pulse2"

    # ${PYDIR}/pulse_xmpp_agent -> medulla-agent/pulse_xmpp_agent
    mkdir -p medulla-agent/pulse_xmpp_agent
    find ${PYDIR}/pulse_xmpp_agent -type f \( -name "*.pyc" -o -name "*.pyo" \) -delete
    cp -a ${PYDIR}/pulse_xmpp_agent/* medulla-agent/pulse_xmpp_agent/
    echo "${PYDIR}/pulse_xmpp_agent copied to ${DESTINATION}/medulla-agent/pulse_xmpp_agent"

    # ${PYDIR}/pulse_xmpp_master_substitute -> medulla-agent/pulse_xmpp_master_substitute/
    mkdir -p medulla-agent/pulse_xmpp_master_substitute
    find ${PYDIR}/pulse_xmpp_master_substitute -type f \( -name "*.pyc" -o -name "*.pyo" \) -delete
    cp -a ${PYDIR}/pulse_xmpp_master_substitute/* medulla-agent/pulse_xmpp_master_substitute/
    echo "${PYDIR}/pulse_xmpp_master_substitute copied to ${DESTINATION}/medulla-agent/pulse_xmpp_master_substitute"

    # /etc/mmc -> medulla-config
    mkdir -p medulla-config
    cp -a /etc/mmc medulla-config/
    echo "/etc/mmc backed up to ${DESTINATION}/medulla-config/mmc"

    # /etc/pulse-xmpp-agent -> medulla-config
    mkdir -p medulla-config
    cp -a /etc/pulse-xmpp-agent medulla-config/
    echo "/etc/pulse-xmpp-agent backed up to ${DESTINATION}/medulla-config/pulse-xmpp-agent"

    # /etc/pulse-xmpp-agent-substitute -> medulla-config
    mkdir -p medulla-config
    cp -a /etc/pulse-xmpp-agent-substitute medulla-config/
    echo "/etc/pulse-xmpp-agent-substitute backed up to ${DESTINATION}/medulla-config/pulse-xmpp-agent-substitute"

    # /var/lib/pulse2/xmpp_baseremoteagent -> medulla-xmpp_base
    mkdir -p medulla-xmpp_base
    cp -a /var/lib/pulse2/xmpp_baseremoteagent medulla-xmpp_base/
    echo "/var/lib/pulse2/xmpp_baseremoteagent backed up to ${DESTINATION}/medulla-xmpp_base/xmpp_baseremoteagent"

    # /var/lib/pulse2/xmpp_baseplugin -> medulla-xmpp_base
    mkdir -p medulla-xmpp_base
    cp -a /var/lib/pulse2/xmpp_baseplugin medulla-xmpp_base/
    echo "/var/lib/pulse2/xmpp_baseplugin backed up to ${DESTINATION}/medulla-xmpp_base/xmpp_baseplugin"

    # /var/lib/pulse2/xmpp_basepluginscheduler -> medulla-xmpp_base
    mkdir -p medulla-xmpp_base
    cp -a /var/lib/pulse2/xmpp_basepluginscheduler medulla-xmpp_base/
    echo "/var/lib/pulse2/xmpp_basepluginscheduler backed up to ${DESTINATION}/medulla-xmpp_base/xmpp_basepluginscheduler"
}

update_server() {
    echo "### Updating server"
    if [ -f "/etc/debian_version" ]; then
        apt update && apt -y upgrade
    elif [ -f "/etc/redhat-release" ]; then
        yum clean metadata && yum -y update
    fi
    # If above command fails, exit
    if [ $? -ne 0 ]; then
        echo "Failed to update server. Exiting."
        exit 1
    else
        echo "Server updated successfully."
    fi
}

reinit_git() {
    echo "### Reinitializing git on all folders"
    /usr/sbin/medulla_dev_gitinit.sh
}

add_prompt_to_bashrc() {
    local bashrc_file="$HOME/.bashrc"
    local lines_to_add=(
        export PS1='\[\033[01;34m\]\w\[\033[00m\]\[\033[01;32m\]$(__git_ps1 " (%s)")\[\033[00m\]\$ '
    )

    for line in "${lines_to_add[@]}"; do
        if ! grep -Fxq "$line" "$bashrc_file"; then
            echo "$line" >> "$bashrc_file"
        fi
    done
}

add_prompt_to_bashrc() {
    local bashrc_file="$HOME/.bashrc"
    local lines_to_add=(
        "export GIT_PS1_SHOWDIRTYSTATE=1 GIT_PS1_SHOWSTASHSTATE=1 GIT_PS1_SHOWUNTRACKEDFILES=1"
        "export GIT_PS1_SHOWUPSTREAM=verbose GIT_PS1_DESCRIBE_STYLE=branch"
        "PS1=\"\[\033[01;34m\]\w\[\033[00m\]\$(__git_ps1 \" (%s)\")\$ \""
        'export PROMPT_COMMAND="__git_ps1 \"\u@\h:\w\" \" \\\$ \""'
    )

    for line in "${lines_to_add[@]}"; do
        if ! grep -Fxq "$line" "$bashrc_file"; then
            echo "$line" >> "$bashrc_file"
        fi
    done
}


add_prompt_to_bashrc
if [ "$ACTION" == "backup" ]; then
    BACKUP_FOLDER=${WORKING_ENV}/livebackup_$(date +%Y%m%d_%H%M%S)
    copy_changes ${BACKUP_FOLDER}
elif [ "$ACTION" == "copytogit" ]; then
    WORKDIR=${WORKING_ENV}/${BRANCH_NAME}
    checkout_branch ${WORKDIR}
    copy_changes ${WORKDIR}
elif [ "$ACTION" == "updateserver" ]; then
    BACKUP_FOLDER=${WORKING_ENV}/livebackup_$(date +%Y%m%d_%H%M%S)
    copy_changes ${BACKUP_FOLDER}
    update_server
    reinit_git
else
    echo "Invalid action. Valid actions are: backup, copytogit, updateserver"
    exit 1
fi
