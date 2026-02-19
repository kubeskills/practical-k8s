# Lab 3: Scheduling with Taints and Tolerations

## Objective

Control pod placement using node labels with `nodeSelector`, and restrict or permit scheduling on specific nodes using taints and tolerations.

## Background

The Kubernetes scheduler places pods on nodes using a two-phase process: **filtering** (eliminating nodes that can't run the pod) and **scoring** (ranking remaining nodes). You can influence both phases:

- **nodeSelector** — the simplest constraint; requires a node to have a specific label
- **Taints** — placed on nodes to *repel* pods by default
- **Tolerations** — placed on pods to *allow* them onto tainted nodes

Together, taints and tolerations are used to dedicate nodes to specific workloads (e.g., GPU nodes, high-memory nodes) without affecting unrelated pods.

## Steps

### 1. Label and Taint Nodes

Label `worker-1` to indicate it has an SSD disk:

```bash
kubectl label node worker-1 disktype=ssd
kubectl get nodes --show-labels
```

Taint `worker-2` so that only pods with the matching toleration can schedule there:

```bash
kubectl taint node worker-2 dedicated=gpu:NoSchedule
```

> Taint format: `key=value:effect`. The `NoSchedule` effect means new pods without a matching toleration will not be placed on this node.

Verify the taint was applied:

```bash
kubectl describe node worker-2 | grep Taint
```

### 2. Deploy with nodeSelector

Generate a Deployment manifest and add a `nodeSelector`:

```bash
kubectl create deployment ssd-app --image=nginx:1.27 --replicas=3 \
  --dry-run=client -o yaml > ssd-app.yaml
```

Edit `ssd-app.yaml` and add the following under `spec.template.spec` (at the same level as `containers`):

```yaml
      nodeSelector:
        disktype: ssd
```

Apply and verify all pods land on `worker-1`:

```bash
kubectl apply -f ssd-app.yaml
kubectl get pods -o wide
```

> If no node has the label `disktype=ssd`, pods will remain `Pending` with an event saying "0/N nodes matched the node selector".

### 3. Deploy with a Toleration for the Tainted Node

Generate a Deployment manifest for the GPU workload:

```bash
kubectl create deployment gpu-app --image=nginx:1.27 \
  --dry-run=client -o yaml > gpu-app.yaml
```

Edit `gpu-app.yaml` and add the following under `spec.template.spec`:

```yaml
      tolerations:
      - key: "dedicated"
        operator: "Equal"
        value: "gpu"
        effect: "NoSchedule"
```

Apply and verify the pod schedules on `worker-2`:

```bash
kubectl apply -f gpu-app.yaml
kubectl get pods -o wide
```

> A toleration does **not** force the pod onto the tainted node — it merely *allows* it. If you want to guarantee placement, combine the toleration with a `nodeSelector` or `nodeAffinity`.

### 4. Observe Scheduling Blocked Without Toleration

Deploy a pod without any toleration and confirm it avoids `worker-2`:

```bash
kubectl create deployment no-toleration --image=nginx:1.27 --replicas=2
kubectl get pods -o wide
```

With `worker-1` reserved for `disktype=ssd` and `worker-2` tainted, these pods may go `Pending`. Describe one to see the scheduler's reasoning:

```bash
kubectl describe pod <pending-pod-name> | grep -A10 Events
```

## Understanding Taint Effects

| Effect | Behavior |
|--------|----------|
| `NoSchedule` | New pods without toleration won't be scheduled here |
| `PreferNoSchedule` | Scheduler tries to avoid this node, but isn't forced to |
| `NoExecute` | Existing pods without toleration are **evicted**; new pods won't schedule |

## Clean Up

```bash
kubectl taint node worker-2 dedicated=gpu:NoSchedule-
kubectl label node worker-1 disktype-
kubectl delete deployment ssd-app gpu-app no-toleration
```

> Removing a taint uses the same syntax as adding it, but with a trailing `-`.
