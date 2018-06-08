#!/bin/bash

if [ $# -ne 1 ]; then
  echo "Usage: $0 \"up|start|stop|down|ps|bash\""
  exit
fi

composeCommand="$1"

case "$composeCommand" in
  "up")    composeCommand="up --build --remove-orphans -d" ;;
  "start") composeCommand="start" ;;
  "stop")  composeCommand="stop" ;;
  "down")  composeCommand="down --remove-orphans" ;;
  "ps")    composeCommand="ps" ;;
  "bash")  composeCommand="exec --user developer buildbox bash" ;;
  *) echo "Unknown command"; exit 1
esac

export DOCKER_GID=`cat /etc/group | grep docker:x | cut -f3 -d:`
export DEV_UID=`id -u`
export DEV_GID=`id -u`

docker-compose \
  -f images/toolset.yml \
  --project-name toolset \
  $composeCommand