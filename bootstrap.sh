#!/bin/bash
CALICO_VERSION=3.3

set -e

export HOME=/root

IP=$(ip addr show ens4 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
echo $IP > /etc/oldip

hostname kubernetes
hostnamectl set-hostname kubernetes
sed -i 's/localhost$/localhost kubernetes/' /etc/hosts

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
    socat make golang-go \
    docker.io

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

apt-get -y remove sshguard

curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh
chmod 700 get_helm.sh && ./get_helm.sh && rm ./get_helm.sh

cp -a /tmp/bootstrap/*.sh /usr/bin
cp -a /tmp/bootstrap/*.service /lib/systemd/system/
systemctl daemon-reload

systemctl enable kubeadm kubectl-proxy docker

systemctl start docker

kubeadm config images pull

docker pull quay.io/calico/node:v3.3.1
docker pull quay.io/calico/cni:v3.3.1
docker pull quay.io/calico/kube-controllers:v3.3.1
docker pull quay.io/coreos/etcd:v3.3.9
docker pull k8s.gcr.io/kubernetes-dashboard-amd64:v1.10.0
