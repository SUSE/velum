#!/bin/bash

set -e

if [ -z "$2" ]; then
  cat <<EOF
usage:
  ./wait_for_build.sh PROJECT PACKAGE [APIURL]
EOF
  exit 1
fi

sed -i "s|<username>|$OSC_USERNAME|g" /root/.oscrc
sed -i "s|<password>|$OSC_PASSWORD|g" /root/.oscrc

project=$1
package=$2
if [ -z "$3" ]; then
  apiurl=https://api.opensuse.org
else
  apiurl=$3
fi

log() { echo ">>> $1" ; }
get_result() { osc -A $apiurl results $project $package ; }

until get_result | grep -q "building"
do
    log "Waiting for build to start"
    sleep 5
done

exit 0
