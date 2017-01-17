# Delivery cluster on Kubernetes POC


## Description
This repository contains the files needed to run the delivery cluster
using Kubernetes on AWS.

It uses [kube-aws](https://coreos.com/kubernetes/docs/latest/kubernetes-on-aws.html) for provisioning the cluster on AWS.

## Prerequisites for development
1. Install the [latest kube-aws](https://github.com/coreos/kube-aws/releases) 
1. [Install kubectl version](https://kubernetes.io/docs/user-guide/prereqs/) > 1.5.1 (latest should do), since we're using Kubernetes 1.5.1. 
You can check the client version by running 
```
kubectl version
```

## Accessing the cluster
We'll share the same Kubernetes cluster that was provisioned on aws. Please do the following setup:

1. Clone this repository
1. Go to lastpass and search for the secure note "Kubernetes AWS test CA key". 
1. Download the attachment from this secure note and unzip it in the credentials folder. You should have now the ca-key.pem and ca.pam files into this folder.
1. From the root of the cloned repository run: `kube-aws render credentials`. This will generate, among others, the client certificate that kubectl will communicate with the Kubernetes cluster. 
1. Set the environment variable `KUBECONFIG` to point to the kubeconfig file in the cloned folder

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