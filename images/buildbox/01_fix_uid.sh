#!/bin/sh

export ORIGPASSWD=$(cat /etc/passwd | grep developer)
export ORIG_UID=$(echo $ORIGPASSWD | cut -f3 -d:)
export ORIG_GID=$(echo $ORIGPASSWD | cut -f4 -d:)

export ORIG_DOCKER_GID=$(cat /etc/group | grep docker:x | cut -f3 -d:)

export DEV_UID=${DEV_UID:=$ORIG_UID}
export DEV_GID=${DEV_GID:=$ORIG_GID}

ORIG_HOME=$(echo $ORIGPASSWD | cut -f6 -d:)

sed -i -e "s/:$ORIG_UID:$ORIG_GID:/:$DEV_UID:$DEV_GID:/" /etc/passwd
sed -i -e "s/developer:x:$ORIG_GID:/developer:x:$DEV_GID:/" /etc/group
sed -i -e "s/docker:x:$ORIG_DOCKER_GID:/docker:x:$DOCKER_GID:/" /etc/group

chown -R ${DEV_UID}:${DEV_GID} ${ORIG_HOME}

#chmod go-w /home/developer/

#make sure permissions are right for ssh access
# chown developer:developer /home/developer/.ssh
# chmod 700 /home/developer/.ssh

# chown developer:developer /home/developer/.ssh/authorized_keys
# chmod 600 /home/developer/.ssh/authorized_keys
