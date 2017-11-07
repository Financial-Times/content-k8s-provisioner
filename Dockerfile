FROM coco/k8s-cli-utils

ENV ANSIBLE_HOSTS=/ansible/hosts

RUN apk --update add python py-pip ansible \
    && pip install --upgrade pip awscli

# Get the files for the provisioner
COPY ansible /ansible
COPY credentials/ /ansible/credentials/
COPY sh/* /
