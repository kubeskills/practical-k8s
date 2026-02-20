# Lab 2: Multi-Node Cluster Operations

## Objective

Safely drain a worker node to simulate maintenance, verify pod rescheduling, uncordon the node to return it to service, and simulate a node failure to observe how Kubernetes responds.

## Background

**Draining** a node does two things at once: it **cordons** the node (marks it unschedulable so no new pods land on it) and **evicts** all running pods (except DaemonSet pods, which are per-node by design). This is the correct procedure before any maintenance that requires the node to be offline — kernel upgrade, hardware replacement, etc.

```
Healthy → Cordoned → Drained → Maintenance → Uncordoned → Healthy
```

Key flags for `kubectl drain`:

| Flag | Effect |
|------|--------|
| `--ignore-daemonsets` | Skip DaemonSet-managed pods (required — drain will refuse otherwise) |
| `--delete-emptydir-data` | Evict pods that use `emptyDir` volumes (data will be lost) |
| `--force` | Evict pods not managed by a controller (bare pods) |

When a node goes `NotReady`, the **node lifecycle controller** waits `node.kubernetes.io/not-ready` tolerations (default 5 minutes) before evicting pods and rescheduling them elsewhere.

## Steps

### 1. Check Pod Distribution Before Draining

See which pods are running on each node:

```bash
kubectl get pods -o wide | grep worker-1
```

> If no application pods are scheduled on `worker-1`, deploy a quick test deployment first:
> ```bash
> kubectl create deployment test-app --image=nginx --replicas=3
> ```

### 2. Drain worker-1

Evict all non-DaemonSet pods from `worker-1` and mark it unschedulable:

```bash
kubectl drain worker-1 \
  --ignore-daemonsets \
  --delete-emptydir-data
```

Kubernetes sends a `SIGTERM` to each pod and waits for graceful shutdown (up to `terminationGracePeriodSeconds`, default 30s) before forcibly terminating. Deployments and ReplicaSets immediately reschedule evicted pods on remaining nodes.

### 3. Verify the Node is Cordoned and Pods Have Moved

```bash
# worker-1 should show SchedulingDisabled
kubectl get nodes

# no application pods should remain on worker-1 (DaemonSet pods are OK)
kubectl get pods -o wide

# inspect the taint that cordon applies
kubectl describe node worker-1 | grep Taints
```

You'll see: `node.kubernetes.io/unschedulable:NoSchedule` — this is the taint that prevents new pods from landing.

### 4. Simulate Maintenance and Uncordon

In a real scenario you'd perform your maintenance now (reboot, kernel update, hardware swap). Here we just uncordon immediately:

```bash
kubectl uncordon worker-1
```

Watch pods reschedule back onto the node:

```bash
kubectl get pods -o wide -w
```

Press `Ctrl+C` when pods stabilize. Note: Kubernetes does **not** automatically rebalance — existing pods stay where they are. Only new pods will be scheduled on the now-available node.

### 5. Simulate a Node Failure

SSH into `worker-2` and stop the kubelet to simulate a crash:

```bash
# on worker-2
sudo systemctl stop kubelet
```

Watch the control plane detect the failure:

```bash
# on the control plane
kubectl get nodes -w
```

After approximately 40 seconds, `worker-2` transitions to `NotReady`. After the eviction timeout (~5 minutes by default), pods are evicted and rescheduled on healthy nodes:

```bash
kubectl get pods -o wide
```

### 6. Recover the Node

Restart the kubelet on `worker-2` to bring it back:

```bash
# on worker-2
sudo systemctl start kubelet
```

Watch the node return to `Ready`:

```bash
kubectl get nodes -w
```

## Key Commands Reference

| Command | What it does |
|---------|-------------|
| `kubectl cordon <node>` | Mark node unschedulable (no new pods) |
| `kubectl drain <node> --ignore-daemonsets` | Evict pods and cordon the node |
| `kubectl uncordon <node>` | Remove the unschedulable taint |
| `kubectl get nodes -w` | Watch node status in real time |
| `kubectl get pods -o wide -w` | Watch pod scheduling changes |
| `kubectl describe node <name>` | Full node details including taints and conditions |

## Troubleshooting

| Problem | Check |
|---------|-------|
| `drain` fails: "cannot delete Pods with local storage" | Add `--delete-emptydir-data` to the drain command |
| `drain` fails: "cannot delete DaemonSet-managed Pods" | Add `--ignore-daemonsets` |
| `drain` hangs | A pod has a long `terminationGracePeriodSeconds` or a finalizer blocking deletion; use `--force` if acceptable |
| Node stays `NotReady` after kubelet restart | Check kubelet logs: `sudo journalctl -u kubelet --no-pager -l | tail -30` |
| Pods not rescheduling after node failure | Pods not managed by a controller (bare pods) are never automatically rescheduled — only Deployment/ReplicaSet-managed pods are |
