## Troubleshooting Mongodb:

If mongodb fails to start, do the following:

1. Delete the helm deployment for mongodb
    ```
    helm delete mongodb
    ```
1. Delete the Claim reference in the pv

    To get the list of all pvs:
    ```
    kubectl get pv | grep mongo
    ```
    You should see three mongodb pvs: `mongodb-0-vol`, `mongodb-1-vol`, `mongodb-2-vol`
    Remove the claim reference from all pvc. To remove the claim reference:
    ```
    kubectl edit pv mongodb-0-vol
    kubectl edit pv mongodb-1-vol
    kubectl edit pv mongodb-2-vol
    ```
1. Get the revision number of the latest helm deployment
    ```
    helm history mongodb
    ```
1. Rollback to the latest revision number
    ```
    helm rollback mongodb <revision_number>
    ```
5. Optional: only if this is a newly provisioned cluster, the mongodb replica set needs setup. Deploy the mongo configurator job
    ```
    kubectl apply -f https://raw.githubusercontent.com/Financial-Times/coco-mongodb/master/helm/mongodb/templates/mongo-configurator-job.yaml
    ```    
## Troubleshooting Kafka:

If kafka fails to start, do the following:

1. Delete the helm deployment for kafka
```
helm delete kafka
```
2. Delete the Claim reference in the pv

To get the list of all pvs:
```
kubectl get pv | grep kafka
```
You should see three mongodb pvs: `kafka-pv`
Remove the claim reference from all pvc. To remove the claim reference:
```
kubectl edit pv kafka-pv
```
3. Get the revision number of the latest helm deployment
```
helm history kafka
```
4. Rollback to the latest revision number
```
helm rollback kafka <revision_number>
```

## UPP only: Troubleshooting cluster DNS name is not reachable
You'll need to deploy the frontend varnish, so that the ELB DNS registrator job will kick in.
Use [this Jenkins job](https://upp-k8s-jenkins.in.ft.com/job/k8s-deployment/job/utils/job/deploy-upp-helm-chart/) and build with parameters:
- Chart: delivery-varnish or k8s-pub-auth-varnish
- Version: the latest released version
- Environment: the destination environment. If it does not appear, please add it to the list by configuring this job.
- Cluster: your destination cluster
- Region: your destination region

## Troubleshooting aggregate health check is not responding
Sometimes the aggregate healthcheck is not responding after a cluster restore. It just needs a restart when this happens.
```
# Find the pod
kubectl get pod | grep aggregate
# Delete the pod
kubectl delete pod <pod_name>
```
