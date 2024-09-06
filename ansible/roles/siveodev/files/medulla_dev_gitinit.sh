#!/bin/bash

if [ -f "/etc/debian_version" ]; then
    PYDIR='/usr/lib/python3/dist-packages'
elif [ -f "/etc/redhat-release" ]; then
    PYDIR='/usr/lib/python3.11/site-packages'
fi

for folder in /usr/share/mmc ${PYDIR}/mmc ${PYDIR}/pulse2 ${PYDIR}/pulse_xmpp_agent ${PYDIR}/pulse_xmpp_master_substitute /etc/mmc /etc/pulse-xmpp-agent /etc/pulse-xmpp-agent-substitute
do
    rm -rf ${folder}/.git
    pushd ${folder}
    git init
    git add --all
    popd
done
