#!/bin/bash

source /home/container/prepare-env.sh

/home/container/tools/usr/sbin/sslh -n \
  -p "0.0.0.0:$1" -p "[::]:$1" \
  --ssh 127.0.0.1:22 \
  --tls 127.0.0.1:443 --http 127.0.0.1:80 \
  --anyprot 127.0.0.1:8000 \
  2>&1
