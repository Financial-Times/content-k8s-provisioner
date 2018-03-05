#!/bin/bash

# Create Ansible Vault credentials
echo ${VAULT_PASS} > /ansible/vault.pass
cd /ansible

ansible-playbook --vault-password-file=vault.pass provision.yaml --extra-vars "\
aws_region=${AWS_REGION} \
aws_access_key=${AWS_ACCESS_KEY} \
aws_secret_access_key=${AWS_SECRET_ACCESS_KEY} \
cluster_name=${CLUSTER_NAME} \
share_cluster_credentials=${SHARE_CLUSTER_CREDENTIALS} \
platform=${PLATFORM} \
environment_type=${ENVIRONMENT_TYPE} \
cluster_environment=${CLUSTER_ENVIRONMENT} "
