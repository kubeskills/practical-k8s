# Lab 1: Provisioning the Cluster

## Objective

Provision three Ubuntu 24.04 cloud instances on Linode that will form your Kubernetes cluster: one control plane node and two worker nodes.

## Background

A Kubernetes cluster requires at minimum:
- **1 control plane node** — runs the API server, etcd, controller manager, and scheduler
- **1+ worker nodes** — run your application workloads via the kubelet and container runtime

For this course we use **Linode** (Akamai Cloud) as the cloud provider. Each node is a separate Linux VM. kubeadm will handle the Kubernetes installation in Lab 2 — this lab is purely about getting the infrastructure in place.

### Recommended Instance Sizes

| Role | Count | Linode Plan | vCPUs | RAM |
|------|-------|-------------|-------|-----|
| Control Plane | 1 | Linode 4GB | 2 | 4 GB |
| Worker | 2 | Linode 4GB | 2 | 4 GB |

> Kubernetes requires at least 2 CPUs and 2 GB RAM on the control plane. Worker nodes can be smaller for lab purposes but 2 vCPUs / 4 GB is comfortable.

## Steps

### 1. Log In to Linode Cloud Manager

Navigate to [cloud.linode.com](https://cloud.linode.com) and sign in.

### 2. Create the Control Plane Node

1. Click **Create → Linode**
2. Choose **Ubuntu 24.04 LTS** as the image
3. Select a region close to you (e.g., US East)
4. Choose the **Linode 4 GB** shared plan
5. Set the label: `cp` (control plane)
6. Set a strong root password (or add your SSH key — recommended)
7. Click **Create Linode**

### 3. Create Two Worker Nodes

Repeat the process twice more with labels `worker-1` and `worker-2`. Use the same region, image, and plan as the control plane.

### 4. Wait for All Nodes to Boot

Wait until all three instances show **Running** status in the Cloud Manager. This typically takes 1–2 minutes.

### 5. Note the IP Addresses

From the Linode dashboard, record the **public IPv4 address** of each node:

```
cp        <control-plane-ip>
worker-1  <worker-1-ip>
worker-2  <worker-2-ip>
```

You will need these addresses throughout the lab.

### 6. SSH into Each Node

Open three terminal sessions and SSH into each node:

```bash
ssh root@<control-plane-ip>
ssh root@<worker-1-ip>
ssh root@<worker-2-ip>
```

> If you added an SSH key during provisioning, use `ssh -i ~/.ssh/your-key root@<ip>`. If you're using password auth, you'll be prompted for the root password you set.

### 7. Set Hostnames (Run on Each Node)

Set a meaningful hostname on each node so they're easy to identify in `kubectl get nodes`:

```bash
# on the control plane node:
hostnamectl set-hostname cp

# on worker-1:
hostnamectl set-hostname worker-1

# on worker-2:
hostnamectl set-hostname worker-2
```

### 8. Add Entries to /etc/hosts (Run on Each Node)

So nodes can resolve each other by hostname, add all three IPs to `/etc/hosts` on every node:

```bash
cat <<EOF | sudo tee -a /etc/hosts
<control-plane-ip>  cp
<worker-1-ip>       worker-1
<worker-2-ip>       worker-2
EOF
```

Replace the IP placeholders with your actual Linode IP addresses.

## Verification

On each node, confirm connectivity:

```bash
ping -c2 cp
ping -c2 worker-1
ping -c2 worker-2
```

All pings should succeed. Your infrastructure is ready for kubeadm in Lab 2.

## Troubleshooting

| Problem | Check |
|---------|-------|
| SSH connection refused | Linode may still be booting — wait 1–2 minutes |
| Ping between nodes fails | Linode firewalls (Cloud Firewall) — ensure ICMP and TCP ports are open between nodes |
| Wrong hostname shown | Re-run `hostnamectl set-hostname` and open a new shell session |
