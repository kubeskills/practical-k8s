#!/usr/bin/env bash
# Day 4: Security, Monitoring, and Troubleshooting
# Practical Kubernetes Administration and Troubleshooting

# ============================================================
# RBAC — Roles, ClusterRoles, Bindings
# ============================================================

# check what permissions a user has
kubectl auth can-i list pods --as=jane
kubectl auth can-i list pods --as=jane -n production
kubectl auth can-i "*" "*"    # check if you're cluster-admin

# list all ClusterRoles
kubectl get clusterroles

# inspect the built-in view role
kubectl describe clusterrole view

# grant the edit ClusterRole to a user in a specific namespace
kubectl create rolebinding jane-edit \
  --clusterrole=edit \
  --user=jane \
  --namespace=staging

# ============================================================
# RBAC for Groups
# ============================================================

# create a user in the "dev-team" group
openssl req -new -key dev.key -out dev.csr \
  -subj "/CN=bob/O=dev-team"

# sign the cert with the cluster CA
sudo openssl x509 -req -in dev.csr \
  -CA /etc/kubernetes/pki/ca.crt \
  -CAkey /etc/kubernetes/pki/ca.key \
  -CAcreateserial -out bob.crt -days 365

# ============================================================
# Service Accounts
# ============================================================

# list service accounts
kubectl get serviceaccounts

# inspect the token mounted in a pod
kubectl exec <pod> -- \
  cat /var/run/secrets/kubernetes.io/serviceaccount/token

# from inside a pod, call the API server using the mounted token
kubectl exec -it api-client -- sh
# TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
# curl -sk -H "Authorization: Bearer $TOKEN" \
#   https://kubernetes.default.svc.cluster.local/api/v1/namespaces/default/pods

# ============================================================
# Pod Security Standards
# ============================================================

# label a namespace to enforce the restricted profile
kubectl label namespace production \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/warn=restricted \
  pod-security.kubernetes.io/audit=restricted

# test what would happen without enforcing
kubectl label namespace staging \
  pod-security.kubernetes.io/warn=baseline

# ============================================================
# RBAC Troubleshooting
# ============================================================

# check if a user/SA can perform an action
kubectl auth can-i create deployments --as=jane
kubectl auth can-i create deployments --as=jane -n production
kubectl auth can-i "*" "*" --as=system:serviceaccount:default:my-sa

# see all permissions for a service account
kubectl auth can-i --list --as=system:serviceaccount:default:monitoring-agent

# describe who can do what
kubectl get rolebindings,clusterrolebindings -A | grep jane

# check the pod's service account and its bindings
kubectl get pod <name> -o jsonpath='{.spec.serviceAccountName}'
kubectl get rolebinding,clusterrolebinding -A -o yaml | grep <sa-name>

# ============================================================
# Secrets Encryption at Rest
# ============================================================

# reference the config in kube-apiserver (add to static pod manifest)
# --encryption-provider-config=/etc/kubernetes/encryption-config.yaml

# verify a secret is stored encrypted in etcd
sudo etcdctl get /registry/secrets/default/my-secret \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key | hexdump -C | head

# ============================================================
# Helm
# ============================================================

# install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version

# add repositories
helm repo add stable https://charts.helm.sh/stable
helm repo add prometheus-community \
  https://prometheus-community.github.io/helm-charts
helm repo update

# search for charts
helm search repo prometheus

# inspect a chart before installing
helm show values prometheus-community/kube-prometheus-stack

# install a chart
helm install my-release prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace

# list installed releases
helm list -A

# upgrade a release with new values
helm upgrade my-release prometheus-community/kube-prometheus-stack \
  --set grafana.adminPassword=newpassword

# uninstall a release
helm uninstall my-release -n monitoring

# package and template (dry run)
helm template my-release prometheus-community/kube-prometheus-stack \
  --values my-values.yaml | head -50

# ============================================================
# kube-prometheus-stack
# ============================================================

helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set grafana.adminPassword=admin123 \
  --set prometheus.prometheusSpec.retention=7d

# verify everything is running
kubectl get pods -n monitoring
kubectl get svc -n monitoring

# ============================================================
# Prometheus
# ============================================================

# port-forward to access Prometheus UI
kubectl port-forward svc/monitoring-kube-prometheus-prometheus \
  9090:9090 -n monitoring
# open http://localhost:9090

# ============================================================
# Grafana
# ============================================================

# port-forward to access Grafana UI
kubectl port-forward svc/monitoring-grafana 3000:80 -n monitoring
# open http://localhost:3000
# default credentials: admin / admin123

# import additional community dashboards
# go to Dashboards → Import → enter dashboard ID from grafana.com/dashboards
# popular IDs: 6417 (k8s cluster), 1860 (node exporter)

# ============================================================
# kubectl top (Metrics Server)
# ============================================================

# install metrics-server (if not already installed)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# node resource usage
kubectl top nodes

# pod resource usage
kubectl top pods -A --sort-by=memory
kubectl top pods -n default

# ============================================================
# Alertmanager
# ============================================================

kubectl port-forward svc/monitoring-kube-prometheus-alertmanager \
  9093:9093 -n monitoring

# ============================================================
# Systematic Troubleshooting
# ============================================================

# 1. Is the cluster healthy?
kubectl get nodes
kubectl get pods -n kube-system

# 2. What is the resource's current state?
kubectl get <resource> -o wide

# 3. What does the full spec and status say?
kubectl describe <resource>

# 4. What are the logs saying?
kubectl logs <pod>
kubectl logs <pod> --previous

# 5. What events are in the cluster?
kubectl get events --sort-by=.metadata.creationTimestamp -A

# 6. Can I exec into the pod and test from inside?
kubectl exec -it <pod> -- sh

# ============================================================
# Diagnosing Pod Issues
# ============================================================

# full pod details and events
kubectl describe pod <name>

# current logs
kubectl logs <name>

# logs from previous container run
kubectl logs <name> --previous

# stream logs
kubectl logs -f <name>

# exec into a running container
kubectl exec -it <name> -- sh

# copy files to/from a pod
kubectl cp <pod>:/path/to/file ./local-file

# ============================================================
# Diagnosing Node Issues
# ============================================================

# check node status and conditions
kubectl get nodes -o wide
kubectl describe node <node-name>

# check kubelet and containerd on the node (SSH in first)
sudo systemctl status kubelet
sudo journalctl -u kubelet -f --no-pager | tail -50

sudo systemctl status containerd
sudo crictl ps           # list running containers via CRI
sudo crictl pods         # list pods via CRI
sudo crictl logs <container-id>

# ============================================================
# Common Networking Failures
# ============================================================

# 1. does the service exist?
kubectl get svc <name>

# 2. does it have endpoints?
kubectl get endpoints <name>
# empty = selector mismatch

# 3. do the labels match?
kubectl describe svc <name> | grep Selector
kubectl get pods --show-labels

# 4. test from inside a pod
kubectl run debug --image=busybox --rm -it \
  --restart=Never -- sh
# wget -qO- http://<svc-name>.<ns>.svc.cluster.local

# DNS troubleshooting
# 1. is CoreDNS running?
kubectl get pods -n kube-system \
  -l k8s-app=kube-dns

# 2. test DNS from a pod
kubectl run dns-test --image=busybox \
  --rm -it --restart=Never -- \
  nslookup kubernetes.default

# 3. check CoreDNS logs
kubectl logs -n kube-system \
  -l k8s-app=kube-dns

# 4. check pod resolv.conf
kubectl exec <pod> -- \
  cat /etc/resolv.conf

# ============================================================
# Common Deployment Failures
# ============================================================

# deployment not rolling out
kubectl rollout status deployment/<name>
kubectl describe deployment <name>

# ReplicaSet not creating pods
kubectl get rs
kubectl describe rs <name>

# pods created but all Pending
kubectl get pods -o wide
kubectl describe pod <name>

# decode a failing event
kubectl get events \
  --field-selector involvedObject.name=<pod-name> \
  --sort-by=.metadata.creationTimestamp

# attach a debug container to a running pod (Kubernetes 1.23+)
kubectl debug -it <pod-name> \
  --image=busybox \
  --target=<container-name>

# ============================================================
# Ephemeral Debug Pods
# ============================================================

# create a privileged debug pod on a specific node
kubectl debug node/<node-name> \
  -it \
  --image=ubuntu \
  -- bash

# inside the debug pod, the node filesystem is at /host
# ls /host/etc/kubernetes/manifests/
# chroot /host    # enter the node's root filesystem

# copy a running pod and add a debug container
kubectl debug <pod-name> \
  -it \
  --image=busybox \
  --copy-to=debug-pod \
  --share-processes

# ============================================================
# Cluster Upgrade — Control Plane
# ============================================================

# 1. update the package repository to the new version
sudo sed -i 's|/v1.34/|/v1.35/|' /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update

# 2. upgrade kubeadm
sudo apt-mark unhold kubeadm
sudo apt-get install -y kubeadm=1.35.0-1.1
sudo apt-mark hold kubeadm

# 3. review the upgrade plan
sudo kubeadm upgrade plan

# 4. apply the upgrade
sudo kubeadm upgrade apply v1.35.0

# 5. drain the control plane (optional for single-node control plane)
kubectl drain cp --ignore-daemonsets

# 6. upgrade kubelet and kubectl
sudo apt-mark unhold kubelet kubectl
sudo apt-get install -y kubelet=1.35.0-1.1 kubectl=1.35.0-1.1
sudo apt-mark hold kubelet kubectl
sudo systemctl daemon-reload && sudo systemctl restart kubelet

# 7. uncordon
kubectl uncordon cp

# ============================================================
# Cluster Upgrade — Worker Nodes
# ============================================================

# from the control plane — drain the worker
kubectl drain worker-1 --ignore-daemonsets --delete-emptydir-data

# SSH into worker-1 and run:
sudo sed -i 's|/v1.34/|/v1.35/|' /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update

sudo apt-mark unhold kubeadm kubelet kubectl
sudo apt-get install -y kubeadm=1.35.0-1.1 kubelet=1.35.0-1.1 kubectl=1.35.0-1.1
sudo apt-mark hold kubeadm kubelet kubectl

sudo kubeadm upgrade node

sudo systemctl daemon-reload && sudo systemctl restart kubelet

# back on the control plane — uncordon the worker
kubectl uncordon worker-1

# verify the upgraded node
kubectl get nodes

# ============================================================
# etcd Backup and Restore
# ============================================================

export ETCDCTL_API=3

# take a snapshot
sudo etcdctl snapshot save \
  /tmp/etcd-backup-$(date +%Y%m%d).db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# verify the snapshot
sudo etcdctl snapshot status \
  /tmp/etcd-backup-$(date +%Y%m%d).db \
  --write-out=table

# stop the API server (remove static pod manifest)
sudo mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/

# restore the snapshot to a new data directory
sudo etcdctl snapshot restore \
  /tmp/etcd-backup.db \
  --data-dir=/var/lib/etcd-restored

# update etcd to use the new data directory
sudo sed -i 's|/var/lib/etcd|/var/lib/etcd-restored|' \
  /etc/kubernetes/manifests/etcd.yaml

# restore the API server
sudo mv /tmp/kube-apiserver.yaml \
  /etc/kubernetes/manifests/

# verify cluster is back
kubectl get nodes

# ============================================================
# Cluster Maintenance Operations
# ============================================================

# cordon a node — prevent new pods from scheduling
kubectl cordon worker-1

# drain a node — evict all pods and cordon
kubectl drain worker-1 \
  --ignore-daemonsets \
  --delete-emptydir-data

# uncordon a node — allow scheduling again
kubectl uncordon worker-1

# force delete a stuck pod (lost node)
kubectl delete pod <name> --force --grace-period=0

# remove a node from the cluster
kubectl delete node worker-2
# on worker-2: sudo kubeadm reset

# ============================================================
# HA Control Plane
# ============================================================

# initialize HA control plane with a load balancer VIP
sudo kubeadm init \
  --control-plane-endpoint="<lb-ip>:6443" \
  --upload-certs \
  --pod-network-cidr=192.168.0.0/16

# join additional control plane nodes
sudo kubeadm join <lb-ip>:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash> \
  --control-plane \
  --certificate-key <cert-key>

# ============================================================
# Lab 1: RBAC and Access Control
# ============================================================

# generate key and CSR for alice in the dev group
openssl genrsa -out alice.key 2048
openssl req -new -key alice.key -out alice.csr -subj "/CN=alice/O=developers"

# sign with cluster CA
sudo openssl x509 -req -in alice.csr \
  -CA /etc/kubernetes/pki/ca.crt \
  -CAkey /etc/kubernetes/pki/ca.key \
  -CAcreateserial -out alice.crt -days 365

# add alice to kubeconfig
kubectl config set-credentials alice \
  --client-certificate=alice.crt \
  --client-key=alice.key

kubectl config set-context alice-context \
  --cluster=kubernetes \
  --namespace=default \
  --user=alice

# grant alice read-only access to pods in default namespace
kubectl create role pod-reader \
  --verb=get,list,watch \
  --resource=pods \
  -n default

kubectl create rolebinding alice-pod-reader \
  --role=pod-reader \
  --user=alice \
  -n default

# switch to alice's context
kubectl config use-context alice-context

kubectl get pods              # should succeed
kubectl delete pod nginx      # should fail (Forbidden)
kubectl get deployments       # should fail (Forbidden)
kubectl get pods -n kube-system   # should fail (wrong namespace)

# switch back to admin
kubectl config use-context kubernetes-admin@kubernetes

# verify with auth can-i
kubectl auth can-i list pods --as=alice
kubectl auth can-i delete pods --as=alice
kubectl auth can-i list pods --as=alice -n kube-system
kubectl auth can-i list nodes --as=alice

# create a ServiceAccount for a workload
kubectl create serviceaccount app-reader -n default

kubectl create role deployment-reader \
  --verb=get,list,watch \
  --resource=deployments,replicasets \
  -n default

kubectl create rolebinding app-reader-binding \
  --role=deployment-reader \
  --serviceaccount=default:app-reader \
  -n default

# verify
kubectl auth can-i list deployments \
  --as=system:serviceaccount:default:app-reader

# ============================================================
# Lab 2: Multi-Node Cluster Operations
# ============================================================

# check pods on worker-1
kubectl get pods -o wide | grep worker-1

# drain worker-1
kubectl drain worker-1 \
  --ignore-daemonsets \
  --delete-emptydir-data

# verify no non-daemonset pods on worker-1
kubectl get pods -o wide

# check taints
kubectl describe node worker-1 | grep Taints

# uncordon
kubectl uncordon worker-1

# verify pods reschedule
kubectl get pods -o wide -w

# simulate a node failure — on worker-2: stop the kubelet
sudo systemctl stop kubelet

# watch from control plane
kubectl get nodes -w     # worker-2 goes NotReady after ~40s
kubectl get pods -o wide # pods eventually evict and reschedule

# ============================================================
# Lab 3: Monitoring Setup
# ============================================================

helm repo add prometheus-community \
  https://prometheus-community.github.io/helm-charts
helm repo update

helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set grafana.adminPassword=admin123

# watch everything come up
kubectl get pods -n monitoring -w

# access Grafana
kubectl port-forward svc/monitoring-grafana \
  3000:80 -n monitoring &

# deploy a load-generating pod
kubectl run load-test \
  --image=busybox \
  -- sh -c "while true; do wget -q -O- http://web.default.svc.cluster.local; done"

# query Prometheus directly
kubectl port-forward svc/monitoring-kube-prometheus-prometheus \
  9090:9090 -n monitoring &

# ============================================================
# Lab 4: Cluster Upgrade
# ============================================================

# check current version
kubectl get nodes
kubeadm version
kubectl version

# upgrade the control plane (same steps as above, repeated for lab context)
sudo sed -i 's|/v1.34/|/v1.35/|' /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-mark unhold kubeadm
sudo apt-get install -y kubeadm=1.35.0-1.1
sudo apt-mark hold kubeadm
sudo kubeadm upgrade plan
sudo kubeadm upgrade apply v1.35.0
sudo apt-mark unhold kubelet kubectl
sudo apt-get install -y kubelet=1.35.0-1.1 kubectl=1.35.0-1.1
sudo apt-mark hold kubelet kubectl
sudo systemctl daemon-reload && sudo systemctl restart kubelet

# drain and upgrade worker-1
kubectl drain worker-1 --ignore-daemonsets --delete-emptydir-data

# SSH into worker-1:
sudo sed -i 's|/v1.34/|/v1.35/|' /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-mark unhold kubeadm kubelet kubectl
sudo apt-get install -y kubeadm=1.35.0-1.1 kubelet=1.35.0-1.1 kubectl=1.35.0-1.1
sudo apt-mark hold kubeadm kubelet kubectl
sudo kubeadm upgrade node
sudo systemctl daemon-reload && sudo systemctl restart kubelet

# from control plane: uncordon and verify
kubectl uncordon worker-1
kubectl get nodes

# ============================================================
# Lab 5: etcd Backup and Restore
# ============================================================

export ETCDCTL_API=3

# take a backup
sudo etcdctl snapshot save /tmp/etcd-backup.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

sudo etcdctl snapshot status /tmp/etcd-backup.db --write-out=table

# create a resource to prove it exists in etcd
kubectl create namespace before-backup
kubectl create deployment test-deploy --image=nginx -n before-backup

# "destroy" etcd data (for lab purposes only)
sudo mv /var/lib/etcd /var/lib/etcd-corrupted

# restore from snapshot
sudo etcdctl snapshot restore /tmp/etcd-backup.db \
  --data-dir=/var/lib/etcd

# wait for the API server to recover
kubectl get nodes

# verify the namespace still exists
kubectl get namespace before-backup
