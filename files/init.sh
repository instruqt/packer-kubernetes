#!/bin/bash
CALICO_VERSION=3.3

echo "Initializing cluster..."
kubeadm init --pod-network-cidr=192.168.0.0/16 --node-name kubernetes

echo "Copying autorization file..."
mkdir /root/.kube
cp /etc/kubernetes/admin.conf /root/.kube/config

echo "Waiting until Kubernetes is running..."
while ! nc -z localhost 6443; do sleep 1; done

echo "Installing Calico networking..."
kubectl apply --kubeconfig=/etc/kubernetes/admin.conf -f https://docs.projectcalico.org/v$CALICO_VERSION/getting-started/kubernetes/installation/hosted/etcd.yaml
kubectl apply --kubeconfig=/etc/kubernetes/admin.conf -f https://docs.projectcalico.org/v$CALICO_VERSION/getting-started/kubernetes/installation/rbac.yaml
kubectl apply --kubeconfig=/etc/kubernetes/admin.conf -f https://docs.projectcalico.org/v$CALICO_VERSION/getting-started/kubernetes/installation/hosted/calico.yaml

echo "Untainting master node..."
kubectl --kubeconfig=/etc/kubernetes/admin.conf taint nodes --all node-role.kubernetes.io/master-

echo "Deploying dashboard..."
kubectl apply --kubeconfig=/etc/kubernetes/admin.conf -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml

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
