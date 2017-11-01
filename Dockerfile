FROM coco/k8s-cli-utils

ENV ANSIBLE_HOSTS=/ansible/ansible

RUN apk --update add curl set ansible py-pip \
    && pip install --upgrade pip awscli

# Get the files for the provisioner
RUN mkdir -p /provisioner-configs
RUN mkdir -p /provisioner-configs/credentials
COPY ansible /provisioner-configs/ansibe
COPY cluster-configs /provisioner-configs/cluster-configs
COPY stack-templates /provisioner-configs/stack-templates
COPY cluster-template.yaml /provisioner-configs
COPY sh/* /provisioner-configs/
COPY userdata /provisioner-configs/userdata

WORKDIR /provisioner-configs/
