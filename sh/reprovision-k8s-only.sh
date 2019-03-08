#!/bin/bash

# Create Ansible Vault credentials
echo ${VAULT_PASS} > /ansible/vault.pass
cd /ansible

ansible-playbook --vault-password-file=vault.pass reprovision-k8s-only.yaml --extra-vars "\
aws_region=${AWS_REGION} \
cluster_name=${CLUSTER_NAME} \
aws_access_key=${AWS_ACCESS_KEY_ID} \
aws_secret_access_key=${AWS_SECRET_ACCESS_KEY} \
platform=${PLATFORM} \
environment_type=${ENVIRONMENT_TYPE} \
reuse_credentials=${REUSE_CREDENTIALS} \
share_cluster_credentials=${SHARE_CLUSTER_CREDENTIALS} \
cluster_environment=${CLUSTER_ENVIRONMENT} \
oidc_issuer_url=${OIDC_ISSUER_URL}"
