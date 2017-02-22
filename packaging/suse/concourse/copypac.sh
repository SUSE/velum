#!/bin/bash

set -e

if [ -z "$3" ]; then
  cat <<EOF
usage:
  ./copypac.sh SOURCEPROJECT PACKAGE TARGETPROJECT [APIURL]
EOF
  exit 1
fi

sed -i "s|<username>|$OSC_USERNAME|g" /root/.oscrc
sed -i "s|<password>|$OSC_PASSWORD|g" /root/.oscrc

sourceproject=$1
package=$2
targetproject=$3
if [ -z "$4" ]; then
  apiurl=https://api.opensuse.org
else
  apiurl=$4
fi

log() { echo ">>> $1" ; }

log "copying $package from $sourceproject to $targetproject ..."
osc -A $apiurl copypac $sourceproject $package $targetproject
