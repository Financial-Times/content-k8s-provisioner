#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

COMMENT="Auto change action $CNAME_ACTION @ $(date) from the content-k8s-provisioner"
API_FQDN="${API_DOMAIN_NAME}.${DNS_ZONE}"

echo "DEBUG: variable and values:"
echo "Action: $CNAME_ACTION"
echo "Hosted zone: $HOSTED_ZONE_ID"
echo "Domain name: $API_DOMAIN_NAME"
echo "DNS zone: $DNS_ZONE"
echo "Name: $API_FQDN"
echo "LB FQDN: $LB_FQDN"


echo "Assume the Route53 DNS prod role"
aws_sts_assume_role=$(aws sts assume-role \
  --role-arn "arn:aws:iam::345152836601:role/route53-iam-dnsonlyroleuppprodE94AAA36-CAPB27QPX3K8" \
  --role-session-name "content-k8s-provisioner-session"
)

export AWS_ACCESS_KEY_ID=$(echo $aws_sts_assume_role | jq -r .Credentials.AccessKeyId)
export AWS_SECRET_ACCESS_KEY=$(echo $aws_sts_assume_role | jq -r .Credentials.SecretAccessKey)
export AWS_SESSION_TOKEN=$(echo $aws_sts_assume_role | jq -r .Credentials.SessionToken)

aws sts get-caller-identity

echo "Generate change set file..."
TMPFILE=$(mktemp /tmp/temporary-file.XXXXXXXX)
cat > ${TMPFILE} << EOF
    {
      "Comment":"$COMMENT",
      "Changes":[
        {
          "Action":"$CNAME_ACTION",
          "ResourceRecordSet":{
            "ResourceRecords":[
              {
                "Value":"$LB_FQDN"
              }
            ],
            "Name":"$API_FQDN",
            "Type":"CNAME",
            "TTL": 30
          }
        }
      ]
    }
EOF

cat "$TMPFILE"


echo "Change record set..."
aws route53 change-resource-record-sets \
    --hosted-zone-id "$HOSTED_ZONE_ID" \
    --change-batch file://"$TMPFILE"

rm "$TMPFILE"

echo "Done."
