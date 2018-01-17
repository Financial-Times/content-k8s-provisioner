# USE https://github.com/Financial-Times/upp-global-configs FOR GLOBAL CONFIGS

# Delivery cluster on Kubernetes POC

## Description
This repository contains the files needed to run the delivery cluster
using Kubernetes on AWS.

It uses [kube-aws](https://coreos.com/kubernetes/docs/latest/kubernetes-on-aws.html) for provisioning the cluster on AWS.

## Building the Docker image
The k8s provisioner can be built locally as a Docker image:

```
docker build -t k8s-provisioner:local .
```

##  Provisioning a new cluster

```
## Set the environments variables to provision a cluster. The variables are stored in LastPass
## For PAC Cluster
## LastPass: PAC - k8s Cluster Provisioning env variables
## For UPP Cluster
## LastPass: UPP - k8s Cluster Provisioning env variables

docker run \
    -v $(pwd)/credentials:/ansible/credentials \
    -e "AWS_REGION=$AWS_REGION" \
    -e "CLUSTER_NAME=$CLUSTER_NAME" \
    -e "CLUSTER_ENVIRONMENT=$CLUSTER_ENVIRONMENT" \
    -e "ENVIRONMENT_TYPE=$ENVIRONMENT_TYPE" \
    -e "SHARE_CLUSTER_CREDENTIALS=$SHARE_CLUSTER_CREDENTIALS" \
    -e "PLATFORM=$PLATFORM" \
    -e "VAULT_PASS=$VAULT_PASS" \
    k8s-provisioner:local /bin/bash provision.sh
```

##  Updating a cluster

**Before updating the cluster make sure you put the initial credentials(certificates & keys) that were used when 
the cluster was initially provisioned in the /credentials folder. Failure in doing this will damage the cluster**
 
```
## Set the environments variables to provision a cluster. The variables are stored in LastPass
## For PAC Cluster
## LastPass: PAC - k8s Cluster Provisioning env variables
## For UPP Cluster
## LastPass: UPP - k8s Cluster Provisioning env variables

docker run \
    -v $(pwd)/credentials:/ansible/credentials \
    -e "AWS_REGION=$AWS_REGION" \
    -e "CLUSTER_NAME=$CLUSTER_NAME" \
    -e "CLUSTER_ENVIRONMENT=$CLUSTER_ENVIRONMENT" \
    -e "ENVIRONMENT_TYPE=$ENVIRONMENT_TYPE" \
    -e "PLATFORM=$PLATFORM" \
    -e "VAULT_PASS=$VAULT_PASS" \
    k8s-provisioner:local /bin/bash update.sh
```

##  Decommissioning a cluster

```
## Set the environments variables to provision a cluster. The variables are stored in LastPass
## For PAC Cluster
## LastPass: PAC - k8s Cluster Provisioning env variables
## For UPP Cluster
## LastPass: UPP - k8s Cluster Provisioning env variables

docker run \
    -e "AWS_REGION=$AWS_REGION" \
    -e "CLUSTER_NAME=$CLUSTER_NAME" \
    -e "CLUSTER_ENVIRONMENT=$CLUSTER_ENVIRONMENT" \
    -e "ENVIRONMENT_TYPE=$ENVIRONMENT_TYPE" \
    -e "PLATFORM=$PLATFORM" \
    -e "VAULT_PASS=$VAULT_PASS" \
    k8s-provisioner:local /bin/bash decom.sh
```

Follow the steps in [here](https://docs.google.com/document/d/1TTih1gcj-Vsqjp1aCAzsP4lpt6ivR8jDIXaZtBxNaUU/edit?pli=1#heading=h.idonu4gksr10) 

## Prerequisites for development
1. [Install kubectl version](https://kubernetes.io/docs/user-guide/prereqs/) > 1.5.1 (latest should do), since we're using Kubernetes 1.5.1. 
You can check the client version by running 
```
kubectl version
```

## Accessing k8s clusters

1. Clone this repository
1. Go to lastpass and search for the secure note "upp-k8s-stack infraprod credentials". 
1. Download the attachment from this secure note (either one is fine) and unzip it in the credentials folder. You should have now the key files needed to communicate with the Kubernetes cluster into this folder.
    1. To download attachments, you need to install [LP binary plugin](https://lastpass.com/support.php?cmd=showfaq&id=3206) and access the vault through the add-on/extension.
1. Set the environment variable `KUBECONFIG` to point to the absolute path of the file:
    1. `export KUBECONFIG=~/k8s-aws-delivery-poc/kubeconfig`
1. Set your context:
    1. `kubectl config use-context upp-prod-delivery-eu`

Available clusters are:
```
upp-prod-delivery-eu
upp-prod-publish-eu
upp-prod-neo4j-eu
upp-prod-delivery-us
upp-prod-publish-us
upp-prod-neo4j-us
```

You should be all set now. Test your setup by running
```
kubectl cluster-info
```
You should get something like:
```
Kubernetes master is running at https://sorin-kube-aws-test.ft.com
Heapster is running at https://sorin-kube-aws-test.ft.com/api/v1/proxy/namespaces/kube-system/services/heapster
KubeDNS is running at https://sorin-kube-aws-test.ft.com/api/v1/proxy/namespaces/kube-system/services/kube-dns
kubernetes-dashboard is running at https://sorin-kube-aws-test.ft.com/api/v1/proxy/namespaces/kube-system/services/kubernetes-dashboard
```
