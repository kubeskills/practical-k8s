# Day 4 — Security, Monitoring, and Troubleshooting

**Practical Kubernetes Administration and Troubleshooting**

---

## Directory Structure

```
day4/
├── slides.md               # Presentation slides (Slidev)
├── kubectl-commands.sh     # All commands from the slides, organized by topic
├── labs/                   # Hands-on lab guides
│   ├── README.md
│   ├── lab1-rbac-and-access-control.md
│   ├── lab2-multi-node-cluster-operations.md
│   ├── lab3-monitoring-setup.md
│   ├── lab4-cluster-upgrade.md
│   └── lab5-etcd-backup-and-restore.md
└── manifests/              # YAML manifests from the slides
    ├── role-pod-reader.yaml
    ├── clusterrole-node-reader.yaml
    ├── rolebinding-jane-read-pods.yaml
    ├── rolebinding-dev-team-edit.yaml
    ├── serviceaccount-monitoring-agent.yaml
    ├── pod-api-client.yaml
    ├── pod-secure-app.yaml
    ├── encryption-configuration.yaml
    ├── secret-alertmanager-config.yaml
    └── prometheusrule-pod-alerts.yaml
```

---

## Labs

See [labs/README.md](labs/README.md) for how to use these labs.

| # | Lab | Topics |
|---|-----|--------|
| 1 | [RBAC and Access Control](labs/lab1-rbac-and-access-control.md) | Roles, RoleBindings, ServiceAccounts, `auth can-i` |
| 2 | [Multi-Node Cluster Operations](labs/lab2-multi-node-cluster-operations.md) | Drain, uncordon, node failure simulation |
| 3 | [Monitoring with Prometheus and Grafana](labs/lab3-monitoring-setup.md) | Helm, kube-prometheus-stack, PromQL |
| 4 | [Cluster Upgrade](labs/lab4-cluster-upgrade.md) | kubeadm upgrade, control plane and workers |
| 5 | [etcd Backup and Restore](labs/lab5-etcd-backup-and-restore.md) | Snapshot save/restore, data recovery |

---

## Manifests

| File | Kind | Description |
|------|------|-------------|
| [role-pod-reader.yaml](manifests/role-pod-reader.yaml) | Role | Read-only access to pods in default namespace |
| [clusterrole-node-reader.yaml](manifests/clusterrole-node-reader.yaml) | ClusterRole | Read access to nodes and metrics cluster-wide |
| [rolebinding-jane-read-pods.yaml](manifests/rolebinding-jane-read-pods.yaml) | RoleBinding | Grants pod-reader Role to user jane |
| [rolebinding-dev-team-edit.yaml](manifests/rolebinding-dev-team-edit.yaml) | RoleBinding | Grants edit ClusterRole to the dev-team group in staging |
| [serviceaccount-monitoring-agent.yaml](manifests/serviceaccount-monitoring-agent.yaml) | ServiceAccount + ClusterRoleBinding | Monitoring SA with cluster-wide view access |
| [pod-api-client.yaml](manifests/pod-api-client.yaml) | Pod | Pod using a custom ServiceAccount to call the API |
| [pod-secure-app.yaml](manifests/pod-secure-app.yaml) | Pod | Pod with pod- and container-level SecurityContext |
| [encryption-configuration.yaml](manifests/encryption-configuration.yaml) | EncryptionConfiguration | AES-CBC encryption for Secrets at rest |
| [secret-alertmanager-config.yaml](manifests/secret-alertmanager-config.yaml) | Secret | Alertmanager Slack notification config |
| [prometheusrule-pod-alerts.yaml](manifests/prometheusrule-pod-alerts.yaml) | PrometheusRule | Alerts for pod crash-looping and not-ready |

---

## Commands

[kubectl-commands.sh](kubectl-commands.sh) contains all commands from the slides, organized by section:

| Section | Commands |
|---------|----------|
| RBAC — Roles, ClusterRoles, Bindings | `kubectl auth can-i`, `create role`, `create rolebinding` |
| RBAC for Groups | `openssl` cert generation for group-based access |
| Service Accounts | `kubectl get serviceaccounts`, token inspection |
| Pod Security Standards | Namespace labeling with `pod-security.kubernetes.io/*` |
| RBAC Troubleshooting | `auth can-i --list`, binding inspection |
| Secrets Encryption | `etcdctl get` with hexdump verification |
| Helm | `helm repo add`, `install`, `upgrade`, `uninstall`, `template` |
| kube-prometheus-stack | Install and verify the full monitoring stack |
| Prometheus / Grafana / Alertmanager | Port-forwarding to access UIs |
| kubectl top | Metrics Server install, node and pod usage |
| Systematic Troubleshooting | Outside-in diagnostic checklist |
| Pod / Node / Networking Diagnostics | `describe`, `logs`, `exec`, `crictl`, DNS testing |
| Deployment Failures | Rollout status, events, ephemeral debug containers |
| Cluster Upgrade | Control plane and worker node upgrade steps |
| etcd Backup and Restore | Snapshot save/restore procedure |
| Cluster Maintenance | Cordon, drain, uncordon, HA control plane join |
| Labs 1–5 | All lab commands in sequence |

---

## Reference

See the [Core Reference Pack](../reference/) for printable cheat sheets — kubectl quick reference and the Kubernetes architecture & components overview.
