# Using kube-aws 0.10
FROM coco/k8s-cli-utils:kube-aws-version-update

ENV ANSIBLE_HOSTS=/ansible/hosts

RUN apk --update add python py-pip ansible bash zip jq \
    && pip install --upgrade pip boto boto3 awscli

# Get the files for the provisioner
COPY ansible /ansible
COPY sh/* /
