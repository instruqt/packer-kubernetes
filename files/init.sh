#!/bin/bash

echo "Initializing cluster..."
kubeadm init --pod-network-cidr=192.168.0.0/16 --node-name kubernetes --kubernetes-version $(cat /etc/k8s_version)

echo "Copying autorization file..."
mkdir /root/.kube
cp /etc/kubernetes/admin.conf /root/.kube/config

echo "Waiting until Kubernetes is running..."
while ! nc -z localhost 6443; do sleep 1; done

echo "Installing Calico networking..."
kubectl apply --kubeconfig=/etc/kubernetes/admin.conf -f /etc/kubernetes/manifests/calico/etcd.yaml
kubectl apply --kubeconfig=/etc/kubernetes/admin.conf -f /etc/kubernetes/manifests/calico/rbac.yaml
kubectl apply --kubeconfig=/etc/kubernetes/admin.conf -f /etc/kubernetes/manifests/calico/calico.yaml

echo "Untainting master node..."
kubectl --kubeconfig=/etc/kubernetes/admin.conf taint nodes --all node-role.kubernetes.io/master-

echo "Deploying dashboard..."
kubectl apply --kubeconfig=/etc/kubernetes/admin.conf -f /etc/kubernetes/manifests/dashboard.yaml

echo "Setting permissions for dashboard..."
cat << EOF | kubectl apply --kubeconfig=/etc/kubernetes/admin.conf -f -
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: kubernetes-dashboard
  labels:
    k8s-app: kubernetes-dashboard
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: kubernetes-dashboard
  namespace: kube-system
EOF

echo "source /usr/share/bash-completion/bash_completion" >> ~/.bashrc
echo "source <(kubectl completion bash)" >> ~/.bashrc
echo "alias k=kubectl" >> ~/.bashrc
