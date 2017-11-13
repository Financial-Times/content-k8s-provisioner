#!/bin/bash
# Retrieves the API Server DNS name

# Set AWS credentials
export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}"
export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}"
export VOLUME_NAME="${VOLUME_NAME}"

if [[ -z ${AWS_REGION} ]]; then
   AWS_REGION="eu-west-1"
fi

# Delete the volumes natching the name 
for volume in $(aws ec2 describe-volumes --filters Name=tag-key,Values="Name" Name=tag-value,Values="${VOLUME_NAME}*" --query 'Volumes[*].{ID:VolumeId}' --region=${AWS_REGION} --output text); do
    aws ec2 delete-volume --volume-id ${volume} --region=${AWS_REGION}
done
