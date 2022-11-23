#!/bin/bash

set -euo pipefail

metadata_script=/opt/jfrog/artifactory/app/metadata/bin/metadata.sh

if ! [[ -x "$metadata_script" ]]
then
    echo "$metadata_script not found, cannot patch for x86_64 -> aarch64"
    exit 1
fi

if grep -qF aarch64 "$metadata_script"
then
    echo "$metadata_script already references aarch64, modification not needed"
    exit 0
fi

sed -ir "s/x86_64/aarch64/g" /opt/jfrog/artifactory/app/metadata/bin/metadata.sh
#systemctl stop artifactory
#/opt/jfrog/artifactory/app/bin/artifactoryManage.sh stop
#set +e
#systemctl start artifactory

