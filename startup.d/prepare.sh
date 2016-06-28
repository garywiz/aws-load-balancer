#!/bin/bash

mkdir -p $VAR_DIR/nginx_temp

if [ ! -d $VAR_DIR/nginx_ssl ]; then
    cp -a $APPS_DIR/etc/nginx_ssl $VAR_DIR
fi

if manage-nginx --force; then
    echo NGINX ready to start. Will start on first check interval.
else
    echo NOTE: No backends.  Will start when available.
fi
