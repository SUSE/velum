#!/bin/bash

set -e

sed -i "s|<username>|$OSC_USERNAME|g" /root/.oscrc
sed -i "s|<password>|$OSC_PASSWORD|g" /root/.oscrc

log() { echo ">>> $1" ; }
get_result() { osc results Virtualization:containers:Velum velum ; }

until get_result | grep -q "building"
do
    log "Waiting for build to start"
    sleep 5
done

exit 0
