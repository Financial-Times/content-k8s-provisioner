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


# Install the RBAC helm chart
helm init -c
helm repo add upp http://upp-helm-repo.s3-website-eu-west-1.amazonaws.com
helm install -n content-k8s-rbac upp/content-k8s-rbac

# Get and output the Jenkins & backup dev token
printToken "jenkins"
echo ""
printToken "backup-access"
