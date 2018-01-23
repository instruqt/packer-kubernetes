#!/bin/bash

MINIKUBE_VERSION=0.24.1
DOCKER_VERSION=


export DEBIAN_FRONTEND=noninteractive 

apt-get update
apt-get -y install \
    git curl wget \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    conntrack

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

apt-get update
apt-get install -y docker-ce

# Download localkube
wget -O /usr/local/bin/localkube https://github.com/kubernetes/minikube/releases/download/v${MINIKUBE_VERSION}/localkube && chmod +x /usr/local/bin/localkube

# Download minikube
wget -O /usr/local/bin/minikube \
        https://github.com/kubernetes/minikube/releases/download/v${MINIKUBE_VERSION}/minikube-linux-amd64 \
        && chmod +x /usr/local/bin/minikube

# Download kubectl
curl -o /usr/local/bin/kubectl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl \
        && chmod +x /usr/local/bin/kubectl

cp -a /tmp/bootstrap/localkube /var/lib/

minikube start --vm-driver=none
minikube enable heapster
minikube stop

cp /var/lib/localkube/kubeconfig /root/.kube
rm -Rf /var/lib/localkube/etcd /var/lib/kubelet/pods/*

cp -a /tmp/bootstrap/*.service /etc/systemd/system/

systemctl daemon-reload
systemctl enable localkube
systemctl enable kubectl-proxy
