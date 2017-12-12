FROM coco/k8s-cli-utils:kube-aws-upgrade

ENV ANSIBLE_HOSTS=/ansible/hosts

RUN apk --update add python py-pip ansible bash \
    && pip install --upgrade pip boto boto3 awscli

# Get the files for the provisioner
COPY ansible /ansible
COPY credentials/ /ansible/credentials/
COPY sh/* /
