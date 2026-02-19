# Lab 4: Cluster Validation

## Objective

Verify that all nodes are `Ready`, all core system pods are running, and the cluster is healthy end-to-end.

## Background

A freshly bootstrapped cluster should have all control plane components running as static pods in `kube-system`, all nodes `Ready`, and CoreDNS providing in-cluster DNS. Validating this before running workloads saves significant debugging time later.

## Steps

### 1. Check Node Status

```bash
kubectl get nodes -o wide
```

Expected output — all nodes `Ready` with correct roles and versions:

```
NAME       STATUS   ROLES           AGE   VERSION   INTERNAL-IP     OS-IMAGE
cp         Ready    control-plane   15m   v1.34.x   <cp-ip>         Ubuntu 24.04 LTS
worker-1   Ready    <none>          10m   v1.34.x   <worker-1-ip>   Ubuntu 24.04 LTS
worker-2   Ready    <none>          9m    v1.34.x   <worker-2-ip>   Ubuntu 24.04 LTS
```

> The `-o wide` flag adds IP addresses, OS info, and the container runtime version — useful for confirming containerd is in use.

### 2. Check System Pods

```bash
kubectl get pods -n kube-system
```

Every pod should be `Running` and fully ready:

| Pod Prefix | Component | Count |
|------------|-----------|-------|
| `coredns-*` | DNS server | 2 |
| `etcd-cp` | Key-value store | 1 |
| `kube-apiserver-cp` | API server | 1 |
| `kube-controller-manager-cp` | Controller manager | 1 |
| `kube-scheduler-cp` | Scheduler | 1 |
| `kube-proxy-*` | Node network rules | 1 per node |
| `calico-node-*` | CNI plugin | 1 per node |

If any pod is not `Running`, describe it to read the Events:

```bash
kubectl describe pod <pod-name> -n kube-system
```

### 3. Check the API Server Health Endpoint

```bash
kubectl get --raw /healthz
kubectl get --raw /version
```

`/healthz` should return `ok`. `/version` returns the server version as JSON.

### 4. Check the Kubelet on Each Node

Run on **each node**:

```bash
sudo systemctl status kubelet
```

The kubelet should be `active (running)`. If it's failed:

```bash
sudo journalctl -u kubelet --no-pager -l | tail -30
```

### 5. Verify Cluster Info

```bash
kubectl cluster-info
```

Expected output:

```
Kubernetes control plane is running at https://<cp-ip>:6443
CoreDNS is running at https://<cp-ip>:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

### 6. Run a Connectivity Test

Deploy a temporary pod and verify it gets an IP and can resolve DNS:

```bash
kubectl run test --image=busybox --rm -it --restart=Never -- \
  nslookup kubernetes.default.svc.cluster.local
```

A successful response confirms:
- The pod received a pod IP from Calico
- CoreDNS is resolving in-cluster names
- The pod can reach the API server's Service IP

## Checklist

Use this as a quick reference before declaring the cluster ready:

```
[ ] kubectl get nodes — all nodes Ready
[ ] kubectl get pods -n kube-system — all pods Running
[ ] kubectl get --raw /healthz — returns "ok"
[ ] systemctl status kubelet — active on all nodes
[ ] kubectl cluster-info — control plane and CoreDNS URLs shown
[ ] DNS test pod — resolves kubernetes.default.svc.cluster.local
```

## Troubleshooting

| Problem | Check |
|---------|-------|
| Node shows `NotReady` | `kubectl describe node <name>` → Conditions section |
| `etcd` pod not running | Static pod manifest issue: `ls /etc/kubernetes/manifests/` on control plane |
| `kube-proxy` pods failing | iptables/ipvs mode issue: `kubectl logs kube-proxy-<id> -n kube-system` |
| CoreDNS `CrashLoopBackOff` | ConfigMap issue: `kubectl describe configmap coredns -n kube-system` |
| DNS test pod returns `NXDOMAIN` | CoreDNS not yet healthy; wait and retry |
