# Using kube-aws 0.9.9
FROM coco/k8s-cli-utils:kube-aws-0.10

ENV ANSIBLE_HOSTS=/ansible/hosts

RUN apk --update add python py-pip ansible bash \
    && pip install --upgrade pip boto boto3 awscli

# Get the files for the provisioner
COPY ansible /ansible
COPY credentials/ /ansible/credentials/
COPY sh/* /
