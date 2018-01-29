## Troubleshooting Mongodb:

If mongodb fails to start, do the following:

1. Delete the helm deployment for mongodb
```
helm delete mongodb
```
2. Delete the Claim reference in the pv

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
3. Get the revision number of the latest helm deployment
```
helm history mongodb
```
4. Rollback to the latest revision number
```
helm rollback mongodb <revision_number>
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
