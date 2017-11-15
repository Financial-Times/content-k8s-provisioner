#!/bin/bash

# Create Ansible Vault credentials
echo ${VAULT_PASS} > /ansible/vault.pass
cd /ansible

ansible-playbook --vault-password-file=vault.pass update.yaml --extra-vars "\
aws_region=${AWS_REGION} \
cluster_name=${CLUSTER_NAME} \
platform=${PLATFORM} \
cluster_environment=${CLUSTER_ENVIRONMENT} \
environment_type=${ENVIRONMENT_TYPE} "
