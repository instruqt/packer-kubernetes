#!/bin/bash

set -e

export HOME=/root

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

# Download minikube
wget -O /usr/local/bin/minikube \
        https://github.com/kubernetes/minikube/releases/download/${MINIKUBE_VERSION}/minikube-linux-amd64 \
        && chmod +x /usr/local/bin/minikube

# Download kubectl
curl -o /usr/local/bin/kubectl -LO https://storage.googleapis.com/kubernetes-release/release/${K8S_VERSION}/bin/linux/amd64/kubectl \
        && chmod +x /usr/local/bin/kubectl

curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh
chmod 700 get_helm.sh && ./get_helm.sh && rm ./get_helm.sh

export MINIKUBE_WANTUPDATENOTIFICATION=false
export MINIKUBE_WANTREPORTERRORPROMPT=false
export MINIKUBE_HOME=$HOME
export CHANGE_MINIKUBE_NONE_USER=true
mkdir -p $HOME/.kube
touch $HOME/.kube/config

export KUBECONFIG=$HOME/.kube/config

minikube start --vm-driver=none

for i in {1..150}; do # timeout for 5 minutes
   kubectl get po &> /dev/null
   if [ $? -ne 1 ]; then
      break
  fi
  sleep 2
done

minikube stop || true

umount /var/lib/kubelet/pods/*/volumes/*/* || true

rm -Rf /data/minikube /etc/kubernetes /var/lib/localkube /var/lib/kube* /root/.kube

cp -a /tmp/bootstrap/*.service /etc/systemd/system/
systemctl daemon-reload

systemctl enable minikube
systemctl enable kubectl-proxy
