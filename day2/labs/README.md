# Day 2 Labs — Workloads, Configuration, and Troubleshooting

**Practical Kubernetes Administration and Troubleshooting**

---

## Labs

Work through the labs in order — later labs build on resources created in earlier ones.

| # | Lab | Topics |
|---|-----|--------|
| 1 | [Deploy a Multi-Replica Application](lab1-deploy-multi-replica.md) | Deployments, ReplicaSets, resource requests/limits |
| 2 | [Rolling Updates and Rollbacks](lab2-rolling-updates-and-rollbacks.md) | Rolling updates, bad deploys, rollback, revision history |
| 3 | [Expose the Application](lab3-expose-the-application.md) | ClusterIP Service, DNS, endpoints, NodePort |
| 4 | [ConfigMaps and Secrets](lab4-configmaps-and-secrets.md) | ConfigMaps, Secrets, envFrom, secretKeyRef |
| 5 | [Health Checks](lab5-health-checks.md) | Liveness probes, readiness probes, exec/HTTP/TCP |
| 6 | [Troubleshoot a Broken Pod](lab6-troubleshoot-broken-pod.md) | ImagePullBackOff, CrashLoopBackOff, kubectl describe |
| 7 | [Namespaces in Practice](lab7-namespaces-in-practice.md) | Namespaces, isolation, cross-namespace DNS, ResourceQuotas |

---

## How to Use These Labs

Each lab file contains:
- **Objective** — what you will accomplish
- **Background** — concepts you need to understand before starting
- **Steps** — commands to run, in order, with explanations
- **Troubleshooting** — common problems and how to diagnose them
- **Clean Up** — commands to remove all resources when finished

---

## Quick Reference

```bash
# check what's running
kubectl get all

# check a specific namespace
kubectl get all -n <namespace>

# see why a pod is failing
kubectl describe pod <name>

# read container logs
kubectl logs <name>

# read logs from a previously crashed container
kubectl logs --previous <name>

# watch resources update in real time
kubectl get pods -w
```
