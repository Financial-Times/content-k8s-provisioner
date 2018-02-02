# USE https://github.com/Financial-Times/upp-global-configs FOR GLOBAL CONFIGS

## Description
This repository contains the files required to provision clusters using Kubernetes on AWS for UPP (delivery, publishing, neo4j) and PAC platforms.

It uses [kube-aws](https://coreos.com/kubernetes/docs/latest/kubernetes-on-aws.html) for provisioning the cluster on AWS.

## Prerequisites
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

The following steps has to be manually done:

1. Connect to the cluster and grant admin to the default user
```
kubectl create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=default:default
```
2. Add the new environment to the jenkins pipeline. Instructions can be found [here](https://github.com/Financial-Times/k8s-pipeline-library#what-to-do-when-adding-a-new-environment). 
3. Make sure you have defined the credentials for the new cluster in Jenkins.
4. Create/ amend the app-configs for the [upp-global-configs](https://github.com/Financial-Times/upp-global-configs/tree/master/helm/upp-global-configs/app-configs) repository. Build and deploy the global config to the new environment using this [Jenkins Job](https://upp-k8s-jenkins.in.ft.com/job/k8s-deployment/job/apps-deployment/job/upp-global-configs-auto-deploy/)
5. [Restore](#restore-k8s-config) the config from a S3 backup or synchronize the cluster with an already existing cluster to deploy all the applications using this [Jenkins Job](https://upp-k8s-jenkins.in.ft.com/job/k8s-deployment/job/utils/job/diff-between-envs/).
6. Connect through SSH to one of the etcd servers and use the command “etcdctl mk <key> <value>” to introduce the following etcd keys needed for forwarding the logs to splunk
```
/ft/config/environment_tag
/ft/config/splunk-forwarder/batchsize
/ft/config/splunk-forwarder/splunk_hec_token
/ft/config/splunk-forwarder/splunk_hec_url
```
The Splunk hec token and the url can be found in lastpass.

```
## For UPP Dev clusters
## LastPass: content-test: Splunk HEC token
## For UPP Prod & Staging clusters
## LastPass: content-prod: Splunk HEC token
## For PAC Prod Clusters
## LastPas: PAC - Splunk HEC Token
```
7. Enable access logs on the ELB's

Note:
* If you are re-provisioning a cluster, the restoration of the config from the S3 backup should bring the cluster healthy.
* If you are creating a new cluster, after the restoration of the config, manual intervention is required for mongodb and kafka. Steps are detailed [here](README-app_troubleshooting.md)

##  Updating a cluster

**Before updating the cluster make sure you put the initial credentials(certificates & keys) that were used when 
the cluster was initially provisioned in the /credentials folder. Failure in doing this will damage the cluster**
 
```
## Login credentials and the environments variables are stored in LastPass
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

##  Restore k8s Config

`kube-resources-autosave` on kubernetes is a pod which takes and uploads snapshots of all the kubernetes resources to an S3 bucket in 24 hours interval. The backups are stored in a timestamped folder in the S3 bucket in the following format.
```
s3://<s3-bucket-name>/kube-aws/clusters/<cluster-name>/backup/<backup_timestamped_folder>
```
To restore a config to a new cluster, do the following:

1. Clone this repository
2. Get the `<backup_timestamped_folder>` of the cluster config (preferably latest) that you want to be restored. The S3 buckets that holds the backups are as follows:


| AWS Account   | Region   |       S3 Bucket           |
|-------------- | -------- | ------------------------- |
| Content Test  | EU       |  k8s-provisioner-test-eu  |
|               | US       |  k8s-provisioner-test-us  |
| Content Prod  | EU       |  k8s-provisioner-prod-eu  |
|               | US       |  k8s-provisioner-prod-us  |
               

3. Set the S3 bucket URI for the backup that needs to be restored to the new cluster.
```
s3://<s3-bucket-name>/kube-aws/clusters/<cluster-name>/backup/<backup_timestamped_folder>
```
4. Set the AWS credentials as environment variables. They are stored in lastpass.
```
## For PAC Cluster
## LastPass: PAC - k8s Cluster Provisioning env variables
## For UPP Cluster
## LastPass: UPP - k8s Cluster Provisioning env variables
```

5. Run the following command from the root of this repository to restore the `default` and the `kube-system` namespace
```
./sh/restore <S3URI-from-step-3> default
./sh/restore <S3URI-from-step-3> kube-system
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

## Accessing the cluster

See [here](https://github.com/Financial-Times/upp-kubeconfig).
