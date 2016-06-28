#!/bin/bash

# This is NOT run during the docker image build, but is here for convenience because it is part of
# a pre-build setp.  Some installations require gcc and all the development tools, which adds 100MB or
# more to the image!  Hate that!  So, what we do in the Makefile is this:
#
#  	docker run -i ubuntu:14.04 --rm=true <image/setup/create-binaries.in >image/setup/binaries.out
#
# It runs a separate container, builds the binary packages, then includees them in a root-extractable
# bundle.  Since this is the same architecture as used by the image build, all should be compatible.

# Find our absolute directory so we can mount ./setup
cd ${0%/*}/..
absdir=$PWD

if [ -f $absdir/build/nginx-lb.deb ]; then
  echo $absdir/build/nginx-lb.deb exists and will not be recreated
  exit
fi

zflag=$(sestatus 2>/dev/null | fgrep -q enabled && echo :z)
docker run -i -v $absdir/build:/setup$zflag --rm=true ubuntu:14.04 /bin/bash <<"EOF"

# Obtain UID of the mounted volume so we don't copy as root
uid=`ls -l / | awk '/setup$/{print $3}'`
useradd -u $uid usetup

echo Install all development tools...
apt-get update
apt-get install -y libpcre3-dev build-essential libssl-dev gcc
apt-get install -y unzip checkinstall curl

echo Download needed modules and prepare
mkdir -p /root/build
cd /root/build

curl https://bitbucket.org/nginx-goodies/nginx-sticky-module-ng/get/c78b7dd79d0d.zip >sticky.zip
curl http://nginx.org/download/nginx-1.11.1.tar.gz >nginx.tar.gz
tar xzf nginx.tar.gz
unzip sticky.zip

# So we can easily recognize the name...
mv nginx-goodies-nginx* nginx-sticky-module-ng

# Build nginx
cd nginx-*
./configure --with-http_ssl_module --with-http_realip_module --with-http_gunzip_module --with-http_gzip_static_module \
    --pid-path=/tmp/nginx.pid \
    --error-log-path=/tmp/nginx-error.log \
    --http-log-path=/tmp/nginx-access.log \
    --add-module=../nginx-sticky-module-ng
make
checkinstall <<CINST
y
Nginx-Load-Balancer

CINST

ls -l
echo Copy them to our shared mount bin...
su usetup -c 'cp -v *.deb /setup/nginx-lb.deb'

EOF
