#!/usr/bin/env bash

function printToken() {
  local tokenName=$1

  # Wait for the secret to be created
  local secretName=""
  while [ -z "${secretName}" ]; do
    secretName=$(kubectl get secret| grep ${tokenName}-token | awk '{print $1}')
  done

  local tokenValue=$(kubectl get secret ${secretName} -o yaml | grep token: | sed "s/^.*token: \(.*\)$/\1/g" | base64 -d)
  echo "${tokenName} token value is: ${tokenValue}"
}

# Using 'kube-aws render stack' to generate the kubeconfig file used for logging into the cluster
mv stack-templates stack-templates-bak
mv userdata userdata-bak
kube-aws render stack
rm -rf userdata stack-templates
mv userdata-bak userdata
mv stack-templates-bak stack-templates

export KUBECONFIG=/ansible/kubeconfig

# Install the RBAC helm chart
helm init -c
helm repo add upp http://upp-helm-repo.s3-website-eu-west-1.amazonaws.com
helm install -n content-k8s-rbac upp/content-k8s-rbac

# Get and output the Jenkins & backup dev token
printToken "jenkins"
echo ""
printToken "backup-access"
