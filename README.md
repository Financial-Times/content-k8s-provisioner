## Description

This repository contains core automation required to create/update/destroy Kubernetes clusters for UPP (delivery, publishing) and PAC platforms. The setup uses the [kube-aws](https://github.com/kubernetes-incubator/kube-aws) tool to manage Kubernetes infrastructure on AWS. Ansible and bash are used to script and integrate kube-aws with any additional tasks and Docker to package the provisioner setup.


* [Prerequisites](#prerequisites)
* [Build the provisioner Docker image](#build-the-provisioner-docker-image)
* [Provision a new cluster](#provision-a-new-cluster)
* [Update a cluster](#update-a-cluster)
* [Decommission a cluster](#decommission-a-cluster)
* [Access a cluster](#access-a-cluster)
* [Restore Kubernetes Configuration](#restore-kubernetes-configuration)
* [Rotate TLS assets of a cluster](#rotate-tls-assets-of-a-cluster)
  * [Troubleshooting](#troubleshooting)
    * [After rotation one could not login using the normal flow](#after-rotation-one-could-not-login-using-the-normal-flow)
* [Upgrade kube-aws](#upgrade-kube-aws)
  * [Validate that the update works](#validate-that-the-update-works)


## Prerequisites


To use the provisioner the below tools need to be available:

- [docker](https://docs.docker.com/engine/installation)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl)
- [helm version 2.9.1](https://github.com/kubernetes/helm#install). There are breaking changes in newest versions that we need to address at some point, but for now we pin the helm version. See the [getting on board page](https://confluence.ft.com/display/CONTENT/Getting+Onboard) for instruction on how to pin helm version on Mac.


## Build the provisioner Docker image

The docker image is used to package the provisioner setup with pinned tool versions. To use the provisioner first build the docker image locally:

```bash
docker build -t k8s-provisioner:local .
```


## Provision a new cluster

To provision a cluster for a specific platform or cluster type (e.g. pac/publishing/delivery or test cluster) follow the steps below:

1. Build the provisioner docker image locally.
1. Create an empty directory and inside create a directory named `credentials`:
    ```bash
    PROV_DIR=provision-cluster-$(date +%F-%H-%M)/credentials
    cd $HOME ; mkdir -p $PROV_DIR ; cd $PROV_DIR
    ```
1. Create AWS credentials and set environment variables as described in appropriate LastPass note:
    - For generic test cluster: "UPP - k8s Cluster Provisioning env variables".  Use the test credentials and set `prov` for the cluster environment.
    - For UPP cluster: "UPP - k8s Cluster Provisioning env variables"
    - For PAC cluster: "PAC - k8s Cluster Provisioning env variables"
1. Run the docker container that will provision the cluster in AWS:
    ```bash
    docker run \
        -v $(pwd)/credentials:/ansible/credentials \
        -e "AWS_REGION=$AWS_REGION" \
        -e "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" \
        -e "AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" \
        -e "CLUSTER_NAME=$CLUSTER_NAME" \
        -e "CLUSTER_ENVIRONMENT=$CLUSTER_ENVIRONMENT" \
        -e "ENVIRONMENT_TYPE=$ENVIRONMENT_TYPE" \
        -e "OIDC_ISSUER_URL=$OIDC_ISSUER_URL" \
        -e "PLATFORM=$PLATFORM" \
        -e "VAULT_PASS=$VAULT_PASS" \
        k8s-provisioner:local /bin/bash provision.sh
    ```

At this point, you have provisioned a Kubernetes cluster without anything running on it. The next step is to integrate the cluster and add services to run on it. Proceed only if you have to create a complete new environment.


1. If this is a test/team cluster that needs to be shutdown overnight put the `ec2Powercycle` tag on the autoscaling groups in the cluster. You can do this from the AWS console:
    1. [Login](https://awslogin.in.ft.com) to the cluster's account
    1. Go to Ec2 -> Auto Scaling Groups
    1. Select ASG, go to Tags, and add the `ec2Powercycle` tag. Example value:
    ```
    { "start":"30 6 * * 1-5", "stop": "30 18 * * 1-5", "desired": 2, "min": 2}
    ```
    Make sure you get the `desired` and `min` values in sync with the current ASG's values.
1. **IMPORTANT**: Upload the zip found at `credentials/${CLUSTER_NAME}.zip` with the TLS assets in the LastPass note from earlier. These initial credentials are vital for subsequent updates in the cluster.
1. Add the new environment to the [auth setup](https://github.com/Financial-Times/content-k8s-auth-setup/) following the instructions [here](https://github.com/Financial-Times/content-k8s-auth-setup/blob/master/README.md#how-to-add-a-new-cluster)
1. Add the new environment to the Jenkins pipeline. Instructions can be found [here](https://github.com/Financial-Times/k8s-pipeline-library#what-to-do-when-adding-a-new-environment).
1. Make sure you have defined the credentials for the new cluster in Jenkins. See the previous step.
1. **For UPP Clusters**: Create/ amend the app-configs for the [upp-global-configs](https://github.com/Financial-Times/upp-global-configs/tree/master/helm/upp-global-configs/app-configs) repository. Release and deploy a new version of this app to the new environment using this [Jenkins Job](https://upp-k8s-jenkins.in.ft.com/job/k8s-deployment/job/apps-deployment/job/upp-global-configs-auto-deploy/)
1. Deploy all the apps necessary in the current cluster. This can be done in 2 ways:
    1. One slower way, but which is fire & forget: synchronize the cluster with an already existing cluster using this [Jenkins Job](https://upp-k8s-jenkins.in.ft.com/job/k8s-deployment/job/utils/job/diff-between-envs/).
    1. One quick way, but this would require some more manual steps: Restore the config from an S3 backup of another cluster
1. For the ASG controlling the dedicated node for `Thanos` put the `ec2Powercycle` to be in sync with the Thanos compactor job.
    See [Thanos Compactor](https://github.com/Financial-Times/content-k8s-prometheus#thanos-compactor) for details.
    Follow the same steps as above and look for the workers with the `Wt` in the name.
    If this is prod, you should also change the `environment` tag to `t`, so that the `ec2Powercycle` will be considered


## Update a cluster


**IMPORTANT**: Before updating the cluster make sure you put the initial credentials(certificates & keys) that were used when the cluster was initially provisioned in the /credentials folder. Failure in doing this will damage the cluster**.


1. Build the provisioner docker image locally.
1. Create AWS credentials and set environment variables as described in appropriate LastPass note:
    - For UPP cluster: "UPP - k8s Cluster Provisioning env variables"
    - For PAC cluster: "PAC - k8s Cluster Provisioning env variables"
1. Run the provisioner docker container:
    ```bash
    docker run \
        -v $(pwd)/credentials:/ansible/credentials \
        -e "AWS_REGION=$AWS_REGION" \
        -e "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" \
        -e "AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" \
        -e "CLUSTER_NAME=$CLUSTER_NAME" \
        -e "CLUSTER_ENVIRONMENT=$CLUSTER_ENVIRONMENT" \
        -e "ENVIRONMENT_TYPE=$ENVIRONMENT_TYPE" \
        -e "OIDC_ISSUER_URL=$OIDC_ISSUER_URL" \
        -e "PLATFORM=$PLATFORM" \
        -e "VAULT_PASS=$VAULT_PASS" \
        k8s-provisioner:local /bin/bash update.sh
    ```


## Decommission a cluster


1. Build the provisioner docker image locally.
1. Create AWS credentials and set environment variables as described in appropriate LastPass note:
    - For UPP cluster: "UPP - k8s Cluster Provisioning env variables"
    - For PAC cluster: "PAC - k8s Cluster Provisioning env variables"
1. Run the provisioner docker container:
    ```bash
    docker run \
        -e "AWS_REGION=$AWS_REGION" \
        -e "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" \
        -e "AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" \
        -e "CLUSTER_NAME=$CLUSTER_NAME" \
        -e "CLUSTER_ENVIRONMENT=$CLUSTER_ENVIRONMENT" \
        -e "ENVIRONMENT_TYPE=$ENVIRONMENT_TYPE" \
        -e "PLATFORM=$PLATFORM" \
        -e "VAULT_PASS=$VAULT_PASS" \
        k8s-provisioner:local /bin/bash decom.sh
    ```
    Wait for the cluster resource to be removed. Watch the CF stack deletion in the AWS console.
1. Delete the leftover AWS resources associated with the cluster.  Go to AWS console -> Resource groups -> Tag editor -> find all resources by the k8s cluster tag & delete them


## Access a cluster


Existing cluster environments can be accessed via `kubectl-login` or a backup token. Read the [content-k8s-auth-setup README](https://github.com/Financial-Times/content-k8s-auth-setup/) to set up login.


## Restore Kubernetes Configuration


The `kube-resources-autosave` on Kubernetes is a pod which takes and uploads snapshots of all the Kubernetes resources to an S3 bucket in 24 hours interval. The backups are stored in a timestamped folder in the S3 bucket in the following format.
```
s3://<s3-bucket-name>/kube-aws/clusters/<cluster-name>/backup/<backup_timestamped_folder>
```
To restore the k8s cluster state, do the following:

1. Before restoring make sure you have deployed the following apps, using [this Jenkins job](https://upp-k8s-jenkins.in.ft.com/job/k8s-deployment/job/utils/job/deploy-upp-helm-chart/), so that they don't get overwritten by the restore:
    - upp-global-configs
    - kafka-bridges

1. Clone this repository
1. Determine the S3 bucket name where the backup of the source cluster resides. Choose one of the exports bellow:
    - When the source cluster is a test (team) cluster in the EU region. The AWS account is Content Test: 
      ```bash
      export RESTORE_BUCKET=k8s-provisioner-test-eu
      ```
    - When the source cluster is a test (team) cluster in the US region. The AWS account is Content Test: 
      ```bash
      export RESTORE_BUCKET=k8s-provisioner-test-us
      ```
    - When the source cluster is staging or prod in the EU region. The AWS account is Content Prod: 
      ```bash
      export RESTORE_BUCKET=k8s-provisioner-prod-eu
      ```
    - When the source cluster is staging or prod in the US region. The AWS account is Content Prod: 
      ```bash
      export RESTORE_BUCKET=k8s-provisioner-prod-us
      ```

1. Set the AWS credentials for the AWS account where the source cluster resides, based on the previous choice. They are stored in LastPass.
    - For PAC Cluster "PAC - k8s Cluster Provisioning env variables"
    - For UPP Cluster "UPP - k8s Cluster Provisioning env variables"
    ```bash
    export AWS_ACCESS_KEY_ID=
    export AWS_SECRET_ACCESS_KEY=
    # This should be either eu-west-1 or us-east-1, depending on the cluster's region.
    export AWS_DEFAULT_REGION=
    ```
1. Determine the backup folder that should be used for restore. Use awscli for this
    ```bash
    # Check that the source cluster is in the chosen bucket
    aws s3 --human-readable ls s3://$RESTORE_BUCKET/kube-aws/clusters/

    # Determine the backup S3 folder that should be used for restore. This should be a recent folder.
    aws s3 ls --page-size 100 --human-readable s3://$RESTORE_BUCKET/kube-aws/clusters/<source_cluster>/backup/ | sort | tail -n 7
    ```
1. **Make sure you are connected to the right cluster that you are restoring the config to**. Test if you are connected to the correct cluster:
    ```bash
    kubectl cluster-info
    ```
1. Run the following command from the root of this repository to restore the `default` and the `kube-system` namespace
    ```bash
    ./sh/restore.sh s3://$RESTORE_BUCKET/kube-aws/clusters/<source_cluster>/backup/<source_backup_folder> kube-system
    ./sh/restore.sh s3://$RESTORE_BUCKET/kube-aws/clusters/<source_cluster>/backup/<source_backup_folder> default
    ```
1. In order to get the cluster green after an S3 restoration, some manual steps are further required for mongo, kafka and varnish. Steps are detailed [here](README-app_troubleshooting.md)



## Rotate TLS assets of a cluster


1. Build the provisioner docker image locally.
1. Create AWS credentials and set environment variables as described in appropriate LastPass note:
    - For UPP cluster: "UPP - k8s Cluster Provisioning env variables"
    - For PAC cluster: "PAC - k8s Cluster Provisioning env variables"
1. Run the provisioner docker container:
    ```bash
    docker run \
        -v $(pwd)/credentials:/ansible/credentials \
        -e "AWS_REGION=$AWS_REGION" \
        -e "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" \
        -e "AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" \
        -e "CLUSTER_NAME=$CLUSTER_NAME" \
        -e "CLUSTER_ENVIRONMENT=$CLUSTER_ENVIRONMENT" \
        -e "ENVIRONMENT_TYPE=$ENVIRONMENT_TYPE" \
        -e "OIDC_ISSUER_URL=$OIDC_ISSUER_URL" \
        -e "PLATFORM=$PLATFORM" \
        -e "VAULT_PASS=$VAULT_PASS" \
        -e "KEEP_CA=n" \
        k8s-provisioner:local /bin/bash rotate-tls.sh
    ```

After rotating the TLS assets, there are some **important** manual steps that should be done:

1. Validate that the login using the backup token works. Using the **new token** from the output, check the `kubectl-login config` on how to check this. If this validation doesn't work, there must be something wrong. Check the Troubleshooting section.
1. Update the backup token access in the LP note `kubectl-login config`. You can find the new token value in the provisioner output: `backup-access token value is: .....`
1. Update the token used by Jenkins to access the K8s cluster.  The credential has the id `ft.k8s-auth.${full-cluster-name}.token`. Look it up [here](https://upp-k8s-jenkins.in.ft.com/job/k8s-deployment/credentials/store/folder/domain/_/) and update it with the token from the provisioner output: `"jenkins token value is: .......`
1. Validate that Jenkins still has access to the cluster by deploying an existing helm chart version onto the cluster through the [Jenkins job](https://upp-k8s-jenkins.in.ft.com/job/k8s-deployment/job/utils/job/deploy-upp-helm-chart/).
1. Update the TLS assets used by Jenkins for cluster updates.  The credential has the id `ft.k8s-provision.${full-cluster-name}.credentials`. Look it up [here](https://upp-k8s-jenkins.in.ft.com/job/k8s-deployment/credentials/store/folder/domain/_/) and update the zip with the one created in the `credentials` folder with the name `${full-cluster-name}.zip`.
1. Validate that this update worked by triggering a cluster update using the [Jenkins job](https://upp-k8s-jenkins.in.ft.com/job/k8s-deployment/job/utils/job/update-cluster/) on the cluster. It should finish quickly as it doesn't have anything to do.  If it takes a long time and really goes through updating please check that you did the previous step and try again.
1. Validate that the normal flow of login through DEX works.
1. Update the TLS assets in the LP note `UPP - k8s Cluster Provisioning env variables` or `PAC - k8s Cluster Provisioning env variables`
1. Validate that logs are getting into Splunk after the rotation from this environment.


### Troubleshooting


Here are the situations encountered so far when the rotation did not complete successfully:

#### After rotation one could not login using the normal flow


Possible problems:

1. Dex may not be started yet. Wait for 5 mins then give it another go. As an alternative try using the backup token that was newly generated and you updated in the LP note `kubectl-login config`
2. The state of the etcd cluster is not consistent between the nodes.  Here's how to check that this is the situation and overcome this:
    1. First, you need to connect to the cluster. Create a `kubeconfig` file that uses the newly created certificates to login into the cluster. It may look like:
        ```
        apiVersion: v1
        clusters:
        - cluster:
            server: https://{{full-cluster-name}}-api.ft.com
            insecure-skip-tls-verify: true
          name: prov-test
        contexts:
        - context:
            cluster: prov-test
            namespace: kube-system
            user: cert
          name: prov-test-cert-ctx

        current-context: prov-test-cert-ctx

        kind: Config
        preferences: {}
        users:
        - name: cert
          user:
            client-certificate: credentials/admin.pem
            client-key: credentials/admin-key.pem
        ```
    1. set KUBECONFIG in the shell to point to the newly created cluster.
    1. issue some `kubectl get secret` multiple times. If this returns different values each time or there are duplicates in the secrets, it means the state of the etcds is out of sync.
    1. Check which etcd is the leader & terminate the other instances that are not
        1. Connect to SSH to one of the etcd node using [the jumpbox & portforwarding](https://docs.google.com/document/d/1TTih1gcj-Vsqjp1aCAzsP4lpt6ivR8jDIXaZtBxNaUU/edit?pli=1#heading=h.gpl69ce0q0l3)
        1. do an `etcdctl member list`
        1. The leader would be printed in the above command.
        1. From the AWS console to and terminate the 2 instances from the cluster that are not the leader.

## Upgrade kube-aws


When upgrading the Kubernetes version, it is wise to do it on the latest kube-aws version, since they might upgraded already to a closer version that you need.  Here are some guidelines on how to do it:

1. Read all the changelogs involved (kube-aws, kubernetes) to spot any show-stoppers.
1. Generate the plain kube-aws artifacts with the new version of kube-aws
    1. Open a terminal
    1. Create a new folder and go into it `mkdir kube-aws-upgrade; cd kube-aws-upgrade`
    1. [Download the kube-aws](https://github.com/kubernetes-incubator/kube-aws/releases) version that you want to upgrade to and put it in this new folder
    1. Init the cluster.yaml of kube-aws using some dummy values:
        ```bash
        ./kube-aws init \
          --cluster-name=kube-aws-up \
          --external-dns-name=kube-aws-up \
          --region=eu-west-1 \
          --key-name="dum" \
          --kms-key-arn="arn:aws:kms:eu-west-1:99999999999:key/99999999-9999" \
          --no-record-set \
          --s3-uri s3://k8s-provisioner-test-eu \
          --availability-zone=eu-west-1a
        ```
    1. Render the stack:
        ```bash
        ./kube-aws render
        ```
1. At this point, kube-aws should have created 2 folders: `stack-templates` & `userdata`
1. Carefully update the file `ansible/templates/cluster-template.yaml.j2` adapting it to the changes from `kube-aws-upgrade/cluster.yaml`.  One way to do this is to do a merge with a tool like Intellij Idea between the two files.
1. Carefully update the contents of the files from `ansible/stack-templates/` adapting them to the changes from `kube-aws-upgrade/stack-templates`.  Before doing this, it is advisable to look at the Git history of the folder and see if there have been executed some manual changes on the files, as those need to be kept. Use the same technique of merging the files.
1. Carefully update the contents of the files from `ansible/userdata/` adapting them to the changes from `kube-aws-upgrade/userdata`.  Before doing this, it is advisable to look at the Git history of the folder and see if there have been executed some manual changes on the files, as those need to be kept.  Use the same technique of merging the files.
1. Compare the contents of the `credentials` folder with an older credentials folder, for example, the one of `upp-prod-delivery-eu`. You can find these old ones in the LP note `UPP - k8s Cluster Provisioning env variables`.  It is usual that between upgrades some new files will appear in this folder. If this is the case you must be careful and check that at cluster upgrades these files are generated and recreate the credentials zips that are kept in the same LP note.

The update part should be done. Now we need to validate it is really working.

### Validate that the update works


It is advisable to go through the following steps for doing a full validation:

1. Create a new branch in the [k8s-cli-utils](https://github.com/Financial-Times/k8s-cli-utils/) repo  & update the `kube-aws` version.
1. Update the Dockefile of the provisioner to extend from the new version of [k8s-cli-utils Docker image](https://hub.docker.com/r/coco/k8s-cli-utils/tags/) & build the new docker image of the provisioner
1. Test provisioning of a new simple cluster. Use `CLUSTER_ENVIRONMENT=prov` when provisioning. Validate that everything worked well (nodes, kube-system namespace pods)
1. Test that decommissioning still works. Decommission this new cluster and check that AWS resources were deleted.
1. Test upgrading a simple cluster to the new version
    1. Provision a new cluster using the `master` version of the provisioner. Use the same `CLUSTER_ENVIRONMENT=prov`
    1. Update the cluster with the new version of the provisioner
    1. Validate that after the upgrade everything works (nodes, kube-system namespace pods)
1. Test upgrading a replica of a delivery cluster
    1. Provision a new cluster using the `master` version of the provisioner. Use `CLUSTER_ENVIRONMENT=delivery`
    1. Go through the restore procedure. Use as source cluster the `upp-uptst-delivery-eu` cluster
    1. Get the cluster as green as possible
    1. Update the cluster with the new version of the provisioner
    1. Validate that everything is ok & the cluster is still green after the update
    1. [Add the environment to the Jenkins pipeline](https://github.com/Financial-Times/k8s-pipeline-library#what-to-do-when-adding-a-new-environment).
    1. Validate that Jenkins can deploy to the updated cluster. You can trigger a [Diff & Sync](https://upp-k8s-jenkins.in.ft.com/job/k8s-deployment/job/utils/job/diff-between-envs/) job to update from prod.
1. Don't forget to decommission the cluster after all these validations.

After all these validations succeed, you are ready to update the dev clusters.
