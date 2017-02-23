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
  if ! [[ "$apiurl" =~ "https://api.opensuse.org" ]]; then
    sed -i "s|https://api.opensuse.org|$apiurl|g" /root/.oscrc
  fi
fi

log() { echo ">>> $1" ; }
get_result() { osc -A $apiurl results $project $package ; }
cache_result() { result=$(get_result | grep "$repository.*$arch") ; }

cache_result
log "fetching build results for $apiurl/package/show/$project/$package"
until get_result | grep -Eq "^$repository.*$arch.*(succeeded|failed|excluded|unresolvable)(\*|)$";
do
    cache_result
    log "Waiting for $project $package $repository $arch build to finish"
    sleep 10
done
cache_result

echo $result | grep "succeeded" && exit 0

log "build failed with: $result"
exit 1
