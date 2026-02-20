# Lab 4: Cluster Upgrade

## Objective

Upgrade the Kubernetes control plane and a worker node from one minor version to the next using `kubeadm`, following the safe upgrade sequence: upgrade kubeadm → plan → apply → drain → upgrade kubelet/kubectl → uncordon.

## Background

Kubernetes releases a new minor version (e.g., 1.34 → 1.35) approximately every 4 months. The upgrade rules:

- **Always upgrade one minor version at a time.** Skipping versions (e.g., 1.32 → 1.34) is unsupported.
- **The control plane must be upgraded first.** Worker node kubelets can be at most one minor version behind the API server, but never ahead.
- **kubeadm must be upgraded first** on each node before upgrading kubelet and kubectl.

### Upgrade Sequence

```
Control Plane Node:
  1. Upgrade kubeadm
  2. kubeadm upgrade plan       (see what's available)
  3. kubeadm upgrade apply      (upgrades control plane components)
  4. Drain the node             (optional for single-node control planes)
  5. Upgrade kubelet + kubectl
  6. Restart kubelet
  7. Uncordon

Worker Nodes (one at a time):
  1. Drain from control plane
  2. SSH into the worker
  3. Upgrade kubeadm, kubelet, kubectl
  4. kubeadm upgrade node
  5. Restart kubelet
  6. Uncordon from control plane
  7. Verify
```

The `apt-mark hold` / `apt-mark unhold` commands prevent apt from auto-upgrading Kubernetes packages during a routine `apt upgrade` — you always want to upgrade Kubernetes deliberately.

## Steps

### 1. Check the Current Version

```bash
kubectl get nodes
kubeadm version
kubectl version
```

All components should be at the same version before you begin.

### 2. Upgrade the Control Plane — kubeadm

Update the apt repository to point at the new version, then upgrade kubeadm:

```bash
# point apt at the new minor version
sudo sed -i 's|/v1.34/|/v1.35/|' /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update

# unhold, upgrade, re-hold kubeadm
sudo apt-mark unhold kubeadm
sudo apt-get install -y kubeadm=1.35.0-1.1
sudo apt-mark hold kubeadm
```

> `apt-mark hold` pins a package so that `apt upgrade` won't touch it. Always re-hold immediately after upgrading.

### 3. Review the Upgrade Plan

```bash
sudo kubeadm upgrade plan
```

This shows the current and available versions for each control plane component (API server, controller manager, scheduler, etcd, CoreDNS). Review the output before proceeding — it also checks for any pre-flight issues.

### 4. Apply the Upgrade

```bash
sudo kubeadm upgrade apply v1.35.0
```

This upgrades the **static pod manifests** for the API server, controller manager, and scheduler under `/etc/kubernetes/manifests/`. The kubelet detects the changed manifests and restarts those containers. This step takes 1–3 minutes.

### 5. Upgrade kubelet and kubectl on the Control Plane

```bash
sudo apt-mark unhold kubelet kubectl
sudo apt-get install -y kubelet=1.35.0-1.1 kubectl=1.35.0-1.1
sudo apt-mark hold kubelet kubectl
sudo systemctl daemon-reload && sudo systemctl restart kubelet
```

Verify the control plane node shows the new version:

```bash
kubectl get nodes
```

The control plane node should show `v1.35.0` while worker nodes still show the old version — this is expected and valid during an in-progress upgrade.

### 6. Upgrade Worker-1 — Drain First

From the **control plane**, drain `worker-1` to safely evict its pods:

```bash
kubectl drain worker-1 --ignore-daemonsets --delete-emptydir-data
```

### 7. Upgrade worker-1 — SSH In and Upgrade

```bash
# SSH into worker-1, then:
sudo sed -i 's|/v1.34/|/v1.35/|' /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update

sudo apt-mark unhold kubeadm kubelet kubectl
sudo apt-get install -y kubeadm=1.35.0-1.1 kubelet=1.35.0-1.1 kubectl=1.35.0-1.1
sudo apt-mark hold kubeadm kubelet kubectl

sudo kubeadm upgrade node

sudo systemctl daemon-reload && sudo systemctl restart kubelet
```

`kubeadm upgrade node` (on workers) updates the node's kubelet configuration to match the new control plane — it does not upgrade control plane components.

### 8. Uncordon worker-1

Back on the **control plane**:

```bash
kubectl uncordon worker-1
```

### 9. Verify

```bash
kubectl get nodes
```

Both the control plane and `worker-1` should now show `v1.35.0`. Repeat steps 6–9 for any remaining worker nodes.

## Key Commands Reference

| Command | What it does |
|---------|-------------|
| `sudo kubeadm upgrade plan` | Show available upgrade targets and pre-flight checks |
| `sudo kubeadm upgrade apply <version>` | Upgrade control plane static pod manifests |
| `sudo kubeadm upgrade node` | Update worker node kubelet config (run on worker) |
| `apt-mark hold <pkg>` | Pin a package to prevent accidental upgrades |
| `apt-mark unhold <pkg>` | Unpin a package to allow upgrading it |
| `systemctl daemon-reload && systemctl restart kubelet` | Reload systemd and restart kubelet after binary upgrade |

## Troubleshooting

| Problem | Check |
|---------|-------|
| `kubeadm upgrade plan` shows no available versions | Verify the apt repo URL was updated and `apt-get update` was run |
| `kubeadm upgrade apply` fails pre-flight | Read the error — common causes: etcd not healthy, API server unreachable |
| Node stuck at old version after kubelet upgrade | Confirm `systemctl restart kubelet` succeeded: `sudo systemctl status kubelet` |
| Worker node stays `NotReady` after upgrade | Check kubelet logs: `sudo journalctl -u kubelet --no-pager -l | tail -30` |
| Pods not rescheduling after uncordon | Pods from Deployments reschedule automatically; bare pods do not |
