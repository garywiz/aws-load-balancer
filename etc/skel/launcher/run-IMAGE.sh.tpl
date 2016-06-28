#!/bin/bash
#Extracted from %(PARENT_IMAGE) on %(`date`)

# Run as interactive: ./%(DEFAULT_LAUNCHER) [options]
#          or daemon: ./%(DEFAULT_LAUNCHER) -d [options]

IMAGE="%(PARENT_IMAGE)"
INTERACTIVE_SHELL="/bin/bash"

# You can specify the external host and ports for Nginx here.  These variables
# are also passed into the container so that any application code which does redirects
# can use these if need be.

EXT_HOSTNAME=%(CONFIG_EXT_HOSTNAME:-localhost)
EXT_PORT=8443
SSL_FRONT=true
SSL_BACK=false
LB_DETECT_HOSTNAME=live-servers.aws.safeagsystems.com
LB_DETECT_NAMESERVER=ns-47.awsdns-05.com

if [ $SSL_FRONT == "true" ]; then
    PORTOPT="-p $EXT_PORT:8443"
else
    PORTOPT="-p $EXT_PORT:8080"
fi

# If this directory exists and is writable, then it will be used
# as attached storage
STORAGE_LOCATION="$PWD/%(IMAGE_BASENAME)-storage"
STORAGE_USER="$USER"

# The rest should be OK...

if [ "$1" == '-d' ]; then
  shift
  docker_opt="-d $PORTOPT"
  INTERACTIVE_SHELL=""
else
  docker_opt="-t -i -e TERM=$TERM --rm=true $PORTOPT"
fi

docker_opt="$docker_opt \
  -e CONFIG_EXT_HOSTNAME=$EXT_HOSTNAME \
  -e SSL_FRONT=$SSL_FRONT \
  -e SSL_BACK=$SSL_BACK \
  -e LB_DETECT_HOSTNAME=$LB_DETECT_HOSTNAME \
  -e LB_DETECT_NAMESERVER=$LB_DETECT_NAMESERVER"

if [ "$STORAGE_LOCATION" != "" -a -d "$STORAGE_LOCATION" -a -w "$STORAGE_LOCATION" ]; then
  SELINUX_FLAG=$(sestatus 2>/dev/null | fgrep -q enabled && echo :z)
  docker_opt="$docker_opt -v $STORAGE_LOCATION:/apps/var$SELINUX_FLAG"
  chap_opt="--create $STORAGE_USER:/apps/var"
  echo Using attached storage at $STORAGE_LOCATION
fi

# Determine if we need to use 'sudo'
DOCKER_CMD=$(docker version >/dev/null 2>&1 && echo docker || echo 'sudo docker')

$DOCKER_CMD run $docker_opt $IMAGE $chap_opt $* $INTERACTIVE_SHELL
