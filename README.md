# USE https://github.com/Financial-Times/upp-global-configs FOR GLOBAL CONFIGS

# Delivery cluster on Kubernetes POC

## Description
This repository contains the files required to provision clusters using Kubernetes on AWS for UPP (delivery, publishing, neo4j) and PAC platforms.

It uses [kube-aws](https://coreos.com/kubernetes/docs/latest/kubernetes-on-aws.html) for provisioning the cluster on AWS.

## Prerequisites for development
1. [Install docker](https://docs.docker.com/engine/installation/) locally
2. [Install kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-binary-via-curl), the latest version (preferably >1.8). OSX users can install using brew.
```
brew install kubernetes-cli
```
You can check the client version by running 
```
kubectl version
```
3. [Install helm](https://github.com/kubernetes/helm#install), the latest version (preferably >2.7).

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

Once the stack is created, update the kubeconfig file with the API servers DNS name and test if you can connect to the cluster by doing
```
kubectl cluster-info
```

The following steps has to be manually done (will be automated):

1. Connect to the cluster and grant admin to the default user
```
kubectl create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=default:default
```
1. Add the new environment to the jenkins pipeline. Instructions can be found [here](https://github.com/Financial-Times/k8s-pipeline-library#what-to-do-when-adding-a-new-environment). 
1. Make sure you have defined the credentials for the new cluster in Jenkins.
1. Create/ amend the app-configs for the [upp-global-configs](https://github.com/Financial-Times/upp-global-configs/tree/master/helm/upp-global-configs/app-configs) repository. Deploy the global config to the new environment.
1. Restore the config from a S3 backup or synchronize the cluster with an already existing cluster to deploy all the applications using this [Jenkins Job](https://upp-k8s-jenkins.in.ft.com/job/k8s-deployment/job/utils/job/diff-between-envs/).

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

##  Restore config for a cluster


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

## Accessing the cluster

See [here](https://github.com/Financial-Times/upp-kubeconfig).
