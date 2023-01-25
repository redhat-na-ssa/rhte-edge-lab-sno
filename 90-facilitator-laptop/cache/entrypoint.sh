#!/bin/bash -ex

cd /opt/app-root/src

download_source=https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.12/latest

download() {
  grep -F "$1" sha256sum.txt | sha256sum -c || curl -LO "$download_source/$1"
}

curl -LO "$download_source/sha256sum.txt"

download rhcos-live.x86_64.iso

exec nginx -g "daemon off;"
