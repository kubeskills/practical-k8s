# Day 3 Labs — Networking, Scheduling, and Storage

**Practical Kubernetes Administration and Troubleshooting**

---

## Labs

| # | Lab | Topics |
|---|-----|--------|
| 1 | [Services and DNS](lab1-services-and-dns.md) | ClusterIP, CoreDNS, endpoint verification |
| 2 | [NodePort and LoadBalancer](lab2-nodeport-and-loadbalancer.md) | NodePort, Linode CCM, external traffic |
| 3 | [Scheduling with Taints and Tolerations](lab3-scheduling.md) | nodeSelector, taints, tolerations |
| 4 | [DaemonSet and CronJob](lab4-daemonset-and-cronjob.md) | DaemonSets, CronJobs, Jobs |
| 5 | [Persistent Storage with PVC](lab5-persistent-storage.md) | PVCs, Linode CSI driver, dynamic provisioning |
| 6 | [Ingress](lab6-ingress.md) | ingress-nginx, path-based routing, TLS |

---

## How to Use These Labs

Each lab file contains:
- **Objective** — what you will accomplish
- **Background** — concepts you need to understand before starting
- **Steps** — commands to run, in order
- **Troubleshooting** — common problems and how to diagnose them
- **Clean Up** — commands to remove all resources when finished

Work through the labs in order — later labs may depend on resources created in earlier ones.

---

## Quick Reference

```bash
# check what's running in your cluster
kubectl get all

# check nodes
kubectl get nodes -o wide

# check events (useful for debugging)
kubectl get events --sort-by=.metadata.creationTimestamp

# delete everything you've created today
kubectl delete all --all
```
