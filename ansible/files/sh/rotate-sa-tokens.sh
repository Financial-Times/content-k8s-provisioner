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


# delete all secrets of service accounts so that they get recreated
eval "$(kubectl get secrets --all-namespaces -o=json | jq -r '.items[] | select(.type=="kubernetes.io/service-account-token") | "kubectl delete secret \(.metadata.name) -n \(.metadata.namespace)"')"

# delete all pods in all namespaces
eval "$(kubectl get ns -o=json | jq -r '.items[] | "kubectl delete po --all -n \(.metadata.name)"')"

# Get and output the new Jenkins & backup dev token
printToken "jenkins"
echo ""
printToken "backup-access"
