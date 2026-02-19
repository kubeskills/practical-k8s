# Day 1 Labs — Foundations and Cluster Setup

**Practical Kubernetes Administration and Troubleshooting**
February 17, 2026

---

## Labs

Work through the labs in order — each lab builds directly on the previous one.

| # | Lab | Topics |
|---|-----|--------|
| 1 | [Provisioning the Cluster](lab1-provisioning-the-cluster.md) | Linode VM setup, hostnames, SSH |
| 2 | [kubeadm Cluster Initialization](lab2-kubeadm-cluster-initialization.md) | Node prep, containerd, kubeadm init, worker join |
| 3 | [CNI Plugin Installation](lab3-cni-plugin-installation.md) | Calico, pod networking, nodes becoming Ready |
| 4 | [Cluster Validation](lab4-cluster-validation.md) | Node status, system pods, DNS test, health endpoints |
| 5 | [Exploring Core Components](lab5-exploring-core-components.md) | etcd, static pods, certificates, kubelet, backup |
| 6 | [Onboard a Pod](lab6-onboard-a-pod.md) | kubectl run, apply, logs, exec, expose, delete |

---

## How to Use These Labs

Each lab file contains:
- **Objective** — what you will accomplish
- **Background** — concepts you need to understand before starting
- **Steps** — commands to run, in order, with explanations
- **Troubleshooting** — common problems and how to diagnose them

---

## Quick Reference

```bash
# check all nodes
kubectl get nodes -o wide

# check system pods
kubectl get pods -n kube-system

# check API server health
kubectl get --raw /healthz

# check kubelet on a node
sudo systemctl status kubelet
sudo journalctl -u kubelet --no-pager -l | tail -20

# check certificate expiration
sudo kubeadm certs check-expiration

# regenerate a join command (if token expired)
kubeadm token create --print-join-command
```
