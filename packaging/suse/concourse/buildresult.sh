#!/bin/bash

set -e

if [ -z "$4" ]; then
  cat <<EOF
usage:
  ./buildresult.sh PROJECT PACKAGE REPOSITORY ARCH [APIURL]
EOF
  exit 1
fi

sed -i "s|<username>|$OSC_USERNAME|g" /root/.oscrc
sed -i "s|<password>|$OSC_PASSWORD|g" /root/.oscrc

project=$1
package=$2
repository=$3
arch=$4
if [ -z "$5" ]; then
  apiurl=https://api.opensuse.org
else
  apiurl=$5
fi
result=$(get_result | grep "$repository.*$arch")

log() { echo ">>> $1" ; }
get_result() { osc -A $apiurl results $project $package ; }

log "fetching build results"
until get_result | grep -Eq "^$repository.*$arch.*(succeeded|failed|excluded|unresolvable)(\*|)$";
do
    result=$(get_result | grep "$repository.*$arch")
    log "Waiting for $repository $arch build to finish"
    sleep 10
done

echo $result | grep "succeeded" && exit 0

log "build failed with: $result"
exit 1
