#!/bin/bash
#Created by chaplocal on Sun Jun 26 04:05:41 UTC 2016
#
# Used to create a new derivative image with chapdev/chaperone-baseimage as its base. You can
# also just use 'docker build' directly if you wish.  If you don't use this script,
# you need to be sure that etc/version.inc contains the proper baseimage name.
# Launchers and other scripts rely upon this.

# the cd trick assures this works even if the current directory is not current.
cd ${0%/*}

if [ "$CHAP_SERVICE_NAME" != "" ]; then
  echo You need to run build.sh on your docker host, not inside a container.
  exit
fi

# Uncomment to default to your new derivative image name...
prodimage="garywiz/aws-load-balancer"

[ "$1" != "" ] && prodimage="$1"

if [ "$prodimage" == "" ]; then
  echo "Usage: ./build.sh <production-image-name>"
  exit 1
else
  echo Building "$prodimage" ...
fi

if [ ! -f Dockerfile ]; then
  echo "Expecting to find Dockerfile in current directory ... not found!"
  exit 1
fi

./build/create-binaries-alpine.sh

# Update the image information for the new build so that the derivative image is the baseimage
sed "s/^IMAGE_NAME=.*/IMAGE_NAME=${prodimage/\//\\\/}/" <etc/version.inc >build/new_version.inc

DOCKER_CMD=$(docker version >/dev/null 2>&1 && echo docker || echo 'sudo docker')
$DOCKER_CMD build -t $prodimage .

# Remove temporary version file
rm -f build/new_version.inc
