# Day 4 Labs — Security, Monitoring, and Troubleshooting

**Practical Kubernetes Administration and Troubleshooting**
February 20, 2026

---

## Labs

Work through the labs in order — each builds on the cluster state from the previous one.

| # | Lab | Topics |
|---|-----|--------|
| 1 | [RBAC and Access Control](lab1-rbac-and-access-control.md) | Roles, RoleBindings, ServiceAccounts, `auth can-i` |
| 2 | [Multi-Node Cluster Operations](lab2-multi-node-cluster-operations.md) | Drain, uncordon, node failure simulation |
| 3 | [Monitoring with Prometheus and Grafana](lab3-monitoring-setup.md) | Helm, kube-prometheus-stack, PromQL |
| 4 | [Cluster Upgrade](lab4-cluster-upgrade.md) | kubeadm upgrade, control plane, workers |
| 5 | [etcd Backup and Restore](lab5-etcd-backup-and-restore.md) | Snapshot save/restore, data recovery |

---

## How to Use These Labs

Each lab file contains:
- **Objective** — what you will accomplish
- **Background** — concepts you need before starting
- **Steps** — commands to run in order, with explanations
- **Troubleshooting** — common problems and how to diagnose them

---

## Quick Reference

```bash
# check all nodes
kubectl get nodes -o wide

# check system pods
kubectl get pods -n kube-system

# check what a user can do
kubectl auth can-i --list --as=<user>

# check events
kubectl get events --sort-by=.metadata.creationTimestamp -A

# etcd snapshot (run on control plane)
export ETCDCTL_API=3
sudo etcdctl snapshot save /tmp/backup.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```
