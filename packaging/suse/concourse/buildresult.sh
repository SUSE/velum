#!/bin/bash

set -e

if [ -z "$1" ] || [ -z "$2" ]; then
  cat <<EOF
usage:
  ./buildresult.sh REPOSITORY ARCH
EOF
  exit 1
fi

sed -i "s|<username>|$OSC_USERNAME|g" /root/.oscrc
sed -i "s|<password>|$OSC_PASSWORD|g" /root/.oscrc

log() { echo ">>> $1" ; }
get_result() { osc results Virtualization:containers:Velum velum ; }

repository=$1
arch=$2
result=$(get_result | grep "$repository.*$arch")

log "fetching build results"
until get_result | grep -Eq "^$repository.*$arch.*(succeeded|failed|excluded|unresolvable)$";
do
    result=$(get_result | grep "$repository.*$arch")
    log "Waiting for $repository $arch build to finish"
    sleep 10
done

echo $result | grep "succeeded" && exit 0

log "build failed with: $result"
exit 1
