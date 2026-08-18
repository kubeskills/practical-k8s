#!/bin/bash
# Day 1: Foundations and Cluster Setup
# All commands from the Day 1 slides and labs, organized by topic

# ============================================================
# Lab 1: Provisioning the Cluster (Linode)
# ============================================================

# SSH into each node
ssh root@<control-plane-ip>
ssh root@<worker-1-ip>
ssh root@<worker-2-ip>

# Set hostnames (run on each node)
hostnamectl set-hostname cp          # on the control plane node
hostnamectl set-hostname worker-1    # on worker-1
hostnamectl set-hostname worker-2    # on worker-2

# Add entries to /etc/hosts so nodes resolve each other (run on each node)
cat <<EOF | sudo tee -a /etc/hosts
<control-plane-ip>  cp
<worker-1-ip>       worker-1
<worker-2-ip>       worker-2
EOF

# Verify connectivity
ping -c2 cp
ping -c2 worker-1
ping -c2 worker-2

# ============================================================
# Preparing the Nodes (run on every node)
# ============================================================

# 1. Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# 2. Load required kernel modules
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# 3. Set sysctl parameters
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

# 4. Install containerd
sudo apt-get update
sudo apt-get install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

# Set the cgroup driver to systemd
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd

# ============================================================
# Installing kubeadm, kubelet, and kubectl (run on every node)
# ============================================================

sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# Download the Kubernetes GPG signing key
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add the Kubernetes apt repository
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Install and pin versions
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# ============================================================
# Lab 2: kubeadm Cluster Initialization
# ============================================================

# Initialize the control plane (control plane node only)
sudo kubeadm init \
  --pod-network-cidr=10.100.0.0/16 \
  --kubernetes-version=stable

# Configure kubectl access (control plane node)
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Verify the cluster
kubectl cluster-info
kubectl get nodes

# --- kubectl access from your local machine ---

# 1. Copy the kubeconfig to your local machine
scp root@<control-plane-ip>:/etc/kubernetes/admin.conf ~/.kube/config

# 2. Find the hostname the API server certificate expects
ssh root@<control-plane-ip>
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout | grep -A1 "Subject Alternative Name"

# 3. Update your local hosts file
echo "<control-plane-ip>  cp" | sudo tee -a /etc/hosts

# --- Joining worker nodes ---

# On each worker node, run the join command from kubeadm init
sudo kubeadm join <control-plane-ip>:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>

# If the token expired, generate a new one from the control plane
kubeadm token create --print-join-command

# Verify from the control plane
kubectl get nodes

# ============================================================
# Lab 3: CNI Plugin Installation (Calico)
# ============================================================

# Download the manifest
wget https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml

# Edit the CALICO_IPV4POOL_CIDR to match --pod-network-cidr
sed -i 's|# - name: CALICO_IPV4POOL_CIDR|- name: CALICO_IPV4POOL_CIDR|' calico.yaml
sed -i 's|# value: "192.168.0.0/16"| value: "10.100.0.0/16"|' calico.yaml

# Apply
kubectl apply -f calico.yaml

# Watch nodes become Ready
kubectl get nodes -w

# ============================================================
# Lab 4: Cluster Validation
# ============================================================

# Check node status
kubectl get nodes -o wide

# Check system pods
kubectl get pods -n kube-system

# Check API server health
kubectl get --raw /healthz
kubectl get --raw /version

# ============================================================
# Bash Autocomplete and Alias
# ============================================================

apt update && apt install -y bash-completion
echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'source /usr/share/bash-completion/bash_completion' >> ~/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc
echo 'complete -o default -F __start_kubectl k' >> ~/.bashrc
source ~/.bashrc

# ============================================================
# Lab 5: Exploring Core Components
# ============================================================

# Static pods on the control plane — managed by the kubelet, not the API server
ls /etc/kubernetes/manifests/

# Inspect etcd via kubectl exec
kubectl -n kube-system exec etcd-cp -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  member list

# --- Install etcdctl on the host ---

ETCD_VERSION="v3.5.21"
curl -fsSL https://github.com/etcd-io/etcd/releases/download/${ETCD_VERSION}/etcd-${ETCD_VERSION}-linux-amd64.tar.gz \
  | sudo tar -xz --strip-components=1 -C /usr/local/bin/ etcd-${ETCD_VERSION}-linux-amd64/etcdctl

export ETCDCTL_API=3   # etcdctl defaults to API v2; Kubernetes uses v3
etcdctl version

# --- Take an etcd snapshot ---

sudo etcdctl snapshot save /tmp/etcd-backup.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

sudo etcdctl snapshot status /tmp/etcd-backup.db --write-out=table

# --- Check kubelet status ---

sudo systemctl status kubelet
sudo journalctl -u kubelet --no-pager -l | tail -20

# --- Check the controller manager and scheduler ---

kubectl get componentstatuses   # deprecated but still works
kubectl get --raw /readyz?verbose

# --- Examine certificates ---

# List all certificates and their expiration dates
sudo kubeadm certs check-expiration

# Inspect a specific certificate
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout | grep -A2 "Validity"

# Renew all certificates before they expire (valid for 1 year by default)
sudo kubeadm certs renew all

# --- Create a new user (certificate-based) ---

# 1. Generate a private key and CSR
openssl genrsa -out jane.key 2048
openssl req -new -key jane.key -out jane.csr -subj "/CN=jane/O=dev-team"

# 2. Sign the certificate with the cluster CA
sudo openssl x509 -req -in jane.csr \
  -CA /etc/kubernetes/pki/ca.crt \
  -CAkey /etc/kubernetes/pki/ca.key \
  -CAcreateserial \
  -out jane.crt -days 365

# 3. Add credentials to kubeconfig
kubectl config set-credentials jane \
  --client-certificate=jane.crt \
  --client-key=jane.key

kubectl config set-context jane-context \
  --cluster=kubernetes \
  --namespace=default \
  --user=jane

# 4. Test the new user (fails — no RBAC permissions yet; RBAC is covered Day 4)
kubectl config use-context jane-context
kubectl get pods

# ============================================================
# Lab 6: Onboard a Pod
# ============================================================

# Generate a Pod manifest without applying it
kubectl run nginx --image=nginx:latest --port=80 --dry-run=client -o yaml > pod.yaml

# Apply the manifest
kubectl apply -f pod.yaml

# Verify it's running
kubectl get pods -o wide
kubectl describe pod nginx
kubectl logs nginx
kubectl logs -f nginx              # stream logs in real time

# Exec into the container
kubectl exec -it nginx -- bash
# inside the container:
#   curl localhost
#   cat /etc/nginx/nginx.conf
#   env | grep KUBERNETES
#   exit

# Expose the pod as a Service
kubectl expose pod nginx --type=NodePort --port=80
kubectl get svc nginx
curl http://<any-node-ip>:<nodeport>

# Inspect the full live Pod spec
kubectl get pod nginx -o yaml

# Clean up
kubectl delete pod nginx
kubectl delete svc nginx
