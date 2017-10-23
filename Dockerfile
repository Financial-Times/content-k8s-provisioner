FROM alpine:3.6


RUN apk --update add curl sed py-pip \
    && pip install --upgrade pip awscli

# Install kube-aws
ENV KUBE_AWS_VERSION 0.9.8

RUN curl -L https://github.com/kubernetes-incubator/kube-aws/releases/download/v${KUBE_AWS_VERSION}/kube-aws-linux-amd64.tar.gz -o /tmp/kube-aws-linux-amd64.tar.gz && \
    tar -zxvf /tmp/kube-aws-linux-amd64.tar.gz -C /tmp  && \
    mv /tmp/linux-amd64/kube-aws /usr/local/bin && \
    rm -f /tmp/kube-aws-linux-amd64* && \
    rm -rf /tmp/linux-amd64

# Install kubectl
ENV KUBECTL_VERSION 1.7.6

RUN curl -L https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl 

# Get the files for the provisioner
RUN mkdir -p /provisioner-configs
RUN mkdir -p /provisioner-configs/credentials
COPY cluster-configs /provisioner-configs/cluster-configs
COPY stack-templates /provisioner-configs/stack-templates
COPY cluster-template.yaml /provisioner-configs
COPY sh/* /provisioner-configs/
COPY userdata /provisioner-configs/userdata

WORKDIR /provisioner-configs/
