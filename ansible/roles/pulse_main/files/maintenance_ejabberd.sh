#! /usr/bin/env bash

#
# Maintenance of ejabberd database
#

# Get database parameters
DBHOST=$(crudini --get /etc/mmc/plugins/xmppmaster.ini.local database dbhost 2> /dev/null || echo localhost)
DBPORT=$(crudini --get /etc/mmc/plugins/xmppmaster.ini.local database dbport 2> /dev/null || echo 3306)
DBUSER=$(crudini --get /etc/mmc/plugins/xmppmaster.ini.local database dbuser 2> /dev/null || echo mmc) 
DBPASS=$(crudini --get /etc/mmc/plugins/xmppmaster.ini.local database dbpasswd)
MYSQL_PARAMS=" -s -h ${DBHOST} -P ${DBPORT} -u${DBUSER} -p${DBPASS}"

# Delete accounts that didn't log in in the last day
ACCOUNTS_STATUS=$(ejabberdctl --no-timeout delete_old_users 1 | grep 'Deleted .* user')
echo "$(date +%Y/%m/%d\ %H:%M) - Accounts deletion status: ${ACCOUNTS_STATUS}"

# Delete offline messages older than one day
ejabberdctl --no-timeout delete_old_messages 1

# Delete roster items that are not present in both rosters
QUERY="SELECT UNIQUE(CONCAT(':', jidsubtitute)) FROM substituteconf WHERE type = 'subscription'"
SUBSCRIPTION_SUBSTITUTES=$(mysql ${MYSQL_PARAMS} xmppmaster -e "${QUERY}")
ROSTERITEMS_STATUS=$(ejabberdctl --no-timeout process_rosteritems delete none none master@pulse${SUBSCRIPTION_SUBSTITUTES} any | grep 'Progress 100%')
echo "$(date +%Y/%m/%d\ %H:%M) - Roster items deletion status: ${ROSTERITEMS_STATUS}"
