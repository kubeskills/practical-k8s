# Lab 2: kubeadm Cluster Initialization

## Objective

Prepare all three nodes, initialize the Kubernetes control plane with kubeadm, configure kubectl access, and join the worker nodes to the cluster.

## Background

**kubeadm** is the official Kubernetes cluster bootstrapping tool. It automates the complex process of:
- Generating all TLS certificates for the cluster PKI
- Creating static Pod manifests for the control plane components
- Configuring the kubelet on every node
- Generating the kubeconfig files for authentication

Every step in this lab must be run on **all nodes** unless explicitly marked as control plane only or worker only.

## Part A: Prepare All Nodes

Run the following on **every node** (control plane and both workers).

### 1. Disable Swap

Kubernetes requires swap to be disabled — the kubelet will refuse to start if swap is active:

```bash
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab
```

> `swapoff -a` disables swap immediately. The `sed` command comments out swap entries in `/etc/fstab` so swap stays disabled after a reboot.

### 2. Load Required Kernel Modules

```bash
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter
```

- **overlay** — union filesystem that layers read-only image layers with a writable container layer
- **br_netfilter** — enables iptables to process traffic passing through Linux network bridges (required for pod networking)

### 3. Set Sysctl Parameters

```bash
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
```

- `bridge-nf-call-iptables` — ensures iptables processes bridged traffic (required for kube-proxy)
- `ip_forward` — allows the node to route packets between pods and the outside world

### 4. Install containerd

containerd is the container runtime. Kubernetes uses it via the CRI (Container Runtime Interface):

```bash
sudo apt-get update
sudo apt-get install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
```

Configure containerd to use the **systemd cgroup driver** (required when systemd manages cgroups, which is the default on Ubuntu 24.04):

```bash
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
```

> If the cgroup driver mismatches between containerd and the kubelet, pods will fail to start. Always set `SystemdCgroup = true` on systems using systemd.

### 5. Install kubeadm, kubelet, and kubectl

Add the Kubernetes apt repository:

```bash
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | \
  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /' | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list
```

Install and pin the versions:

```bash
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

> `apt-mark hold` prevents `apt-get upgrade` from accidentally upgrading Kubernetes components. Kubernetes upgrades must be done deliberately, one minor version at a time.

## Part B: Initialize the Control Plane

Run the following **on the control plane node only**.

### 6. Run kubeadm init

```bash
sudo kubeadm init \
  --pod-network-cidr=192.168.0.0/16 \
  --kubernetes-version=stable
```

> `--pod-network-cidr=192.168.0.0/16` reserves this CIDR for pod IPs. This must match what the CNI plugin expects — Calico defaults to `192.168.0.0/16`.

kubeadm will:
1. Run preflight checks (swap off, ports free, etc.)
2. Generate the cluster CA and all component certificates under `/etc/kubernetes/pki/`
3. Create static Pod manifests in `/etc/kubernetes/manifests/`
4. Wait for the API server to become healthy
5. Bootstrap the RBAC configuration
6. Print a `kubeadm join` command — **copy this output**, you'll need it in Step 8

### 7. Configure kubectl Access

```bash
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Verify the control plane is reachable:

```bash
kubectl cluster-info
kubectl get nodes
```

The node will show `NotReady` — that's expected until the CNI plugin is installed in Lab 3.

### 7b. (Optional) kubectl Access from Your Local Machine

Copy the kubeconfig to your laptop:

```bash
# run from your local machine
scp root@<control-plane-ip>:/etc/kubernetes/admin.conf ~/.kube/config
```

Add the control plane hostname to your local `/etc/hosts`:

```bash
echo "<control-plane-ip>  cp" | sudo tee -a /etc/hosts
```

Now `kubectl get nodes` works from your laptop.

## Part C: Join the Worker Nodes

### 8. Run the Join Command on Each Worker

On **each worker node**, run the join command printed by `kubeadm init`:

```bash
sudo kubeadm join <control-plane-ip>:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>
```

> Tokens expire after 24 hours. If yours has expired, generate a new join command from the control plane:
> ```bash
> kubeadm token create --print-join-command
> ```

### 9. Verify from the Control Plane

```bash
kubectl get nodes
```

You should see all three nodes (still `NotReady` until CNI is installed):

```
NAME       STATUS     ROLES           AGE   VERSION
cp         NotReady   control-plane   5m    v1.34.x
worker-1   NotReady   <none>          1m    v1.34.x
worker-2   NotReady   <none>          30s   v1.34.x
```

### 10. Set Up bash Autocomplete and Alias

```bash
apt update && apt install -y bash-completion
echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'source /usr/share/bash-completion/bash_completion' >> ~/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc
echo 'complete -o default -F __start_kubectl k' >> ~/.bashrc
source ~/.bashrc
```

## Troubleshooting

| Problem | Check |
|---------|-------|
| `kubeadm init` preflight fails on swap | Re-run `swapoff -a` and verify with `free -h` |
| API server not reachable after init | Check `sudo systemctl status kubelet` and `journalctl -u kubelet` |
| Worker join fails with token error | Token expired — regenerate with `kubeadm token create --print-join-command` |
| `kubectl get nodes` shows no workers | Worker join didn't complete — check kubelet on the worker node |
