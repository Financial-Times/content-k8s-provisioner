#!/bin/sh
# Retrieves the API Server DNS name

# Set AWS credentials
export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}"
export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}"
export CLUSTER_NAME="${CLUSTER_NAME}"

if [[ -z ${AWS_REGION} ]]; then
   AWS_REGION="eu-west-1"
fi

# Tag the subnets with the cluster value
for subnet in "$@"; do
    aws ec2 create-tags --resources ${subnet} --tags Key=kubernetes.io/cluster/${CLUSTER_NAME},Value=true --region=${REGION}
done

echo "All public subnets are tagged with the kubernetes tag kubernetes.io/cluster/${CLUSTER_NAME}"
