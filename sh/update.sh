#!/bin/sh

# Create Ansible Vault credentials
echo ${VAULT_PASS} > /ansible/vault.pass
cd /ansible

ansible-playbook --vault-password-file=vault.pass update.yaml --extra-vars "\
aws_region=${AWS_REGION} \
cluster_name=${CLUSTER_NAME} \
platform=${PLATFORM} \
environment_type=${ENVIRONMENT_TYPE} "
