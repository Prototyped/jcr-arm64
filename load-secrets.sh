#!/usr/bin/env bash

set -euo pipefail

OCI_CLI_AUTH=instance_principal
export OCI_CLI_AUTH

# Substitute database password in the system.yaml.
base64_artifactory_password="$(/opt/oci/bin/oci secrets secret-bundle get --secret-id ocid1.vaultsecret.oc1.uk-london-1.amaaaaaavtd7ioya3vz7i2hojuvfdx4yhzl5gdlltea6qwrnkqnie7gmhoda --raw-output --query 'data."secret-bundle-content".content')"
artifactory_password="$(echo -n $base64_artifactory_password | base64 -d)"
sed "s/<dbpassword>/$artifactory_password/" /opt/jfrog/artifactory/system.yaml > /opt/jfrog/artifactory/var/etc/system.yaml

mkdir -p /opt/jfrog/artifactory/var/etc/security

# Write the master.key.
base64_master_key="$(/opt/oci/bin/oci secrets secret-bundle get --secret-id ocid1.vaultsecret.oc1.uk-london-1.amaaaaaavtd7ioyastw6gwefocvdbmpnukw6ngqc5wuyqullg4kfffxynfqq --raw-output --query 'data."secret-bundle-content".content')"
echo -n "$base64_master_key" | base64 -d > /opt/jfrog/artifactory/var/etc/security/master.key

# Write the join.key.
base64_join_key="$(/opt/oci/bin/oci secrets secret-bundle get --secret-id ocid1.vaultsecret.oc1.uk-london-1.amaaaaaavtd7ioyas4lkszb53w5mf3uauskvrhw6af5xxjrnkiy6ajetnb2q --raw-output --query 'data."secret-bundle-content".content')"
echo -n "$base64_join_key" | base64 -d > /opt/jfrog/artifactory/var/etc/security/join.key
