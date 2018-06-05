#!/bin/bash

set -e

MINIKUBE_VERSION=0.27.0

hostname kubernetes
hostnamectl set-hostname kubernetes

ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf

export DEBIAN_FRONTEND=noninteractive

echo "waiting 180 seconds for cloud-init to update /etc/apt/sources.list"
timeout 180 /bin/bash -c \
  'until stat /var/lib/cloud/instance/boot-finished 2>/dev/null; do echo waiting ...; sleep 1; done'

apt-get update
apt-get -y install \
    git curl wget \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    conntrack \
    jq vim nano emacs joe \
    inotify-tools \
    socat make

apt-get -y remove sshguard

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

#minikube start --vm-driver=none --extra-config=apiserver.Authorization.Mode=RBAC
minikube start --bootstrapper=kubeadm --vm-driver=none
#kubectl create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:default
minikube stop || true

cp /var/lib/localkube/kubeconfig /root/.kube/config
rm -Rf /var/lib/localkube/etcd /var/lib/kubelet/pods/*

cp -a /tmp/bootstrap/*.service /etc/systemd/system/

curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh
chmod 700 get_helm.sh && ./get_helm.sh && rm ./get_helm.sh

systemctl daemon-reload
systemctl enable kubectl-proxy
