#!/usr/bin/env sh

set -eu

if ! [ -f /var/opt/jfrog/artifactory/etc/system.yaml ] ||
	! grep -Fq metadata: /var/opt/jfrog/artifactory/etc/system.yaml ||
	! [ -f /var/opt/jfrog/artifactory/etc/security/master.key ] ||
	! [ -f /var/opt/jfrog/artifactory/etc/security/join.key ]
then
    cp -a /var/opt/jfrog/artifactory.orig/* /var/opt/jfrog/artifactory/
fi
sudo -u artifactory /usr/local/bin/load-secrets.sh
ex '+g/^::1/d' -cwq /etc/hosts
exec /opt/jfrog/artifactory/app/bin/artifactoryManage.sh wait
