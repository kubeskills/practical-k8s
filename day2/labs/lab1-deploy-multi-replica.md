# Lab 1: Deploy a Multi-Replica Application

## Objective

Create a Deployment with multiple replicas, add resource requests and limits to the pod spec, and verify that Kubernetes created the underlying ReplicaSet and pods.

## Background

A **Deployment** is the standard way to run stateless workloads in Kubernetes. It manages a **ReplicaSet**, which in turn ensures the desired number of pod replicas are always running. If a pod crashes, the ReplicaSet controller automatically creates a replacement.

**Resource requests and limits** tell the scheduler how much CPU and memory a container needs:
- `requests` — the minimum guaranteed resources; used by the scheduler to find a node with enough capacity
- `limits` — the maximum resources the container may consume; the container is throttled (CPU) or killed (memory) if it exceeds this

Setting requests is important even in development — without them, the scheduler has no information to make good placement decisions.

## Steps

### 1. Generate the Deployment Manifest

Use `--dry-run=client -o yaml` to generate a YAML manifest without applying it:

```bash
kubectl create deployment web --image=nginx:1.27 --replicas=3 \
  --dry-run=client -o yaml > web-deployment.yaml
```

> `--dry-run=client` performs validation locally without contacting the API server. `-o yaml` outputs the resulting manifest. This is the fastest way to produce a valid starting template.

### 2. Add Resource Requests and Limits

Edit `web-deployment.yaml` and add the following under the `containers[0]` entry (at the same indentation level as `image`):

```yaml
    resources:
      requests:
        cpu: "50m"
        memory: "64Mi"
      limits:
        memory: "128Mi"
```

The full container spec should look like:

```yaml
      containers:
      - name: web
        image: nginx:1.27
        resources:
          requests:
            cpu: "50m"
            memory: "64Mi"
          limits:
            memory: "128Mi"
```

> `50m` CPU = 50 millicores = 5% of one CPU core. `64Mi` = 64 mebibytes. Notice there is no CPU limit — this is intentional. CPU limits cause throttling even when the node has spare capacity; it's often better to set only a CPU request and let the container burst freely.

### 3. Apply the Manifest

```bash
kubectl apply -f web-deployment.yaml
```

### 4. Verify

Check that the Deployment, ReplicaSet, and pods are all created:

```bash
kubectl get deployment web
kubectl get rs
kubectl get pods -l app=web -o wide
```

**What to look for:**
- `READY` on the Deployment should show `3/3`
- `kubectl get rs` shows one ReplicaSet with `DESIRED=3`, `CURRENT=3`, `READY=3`
- `kubectl get pods` shows 3 pods, each on potentially different nodes (see the `NODE` column with `-o wide`)

### 5. Inspect a Pod's Resource Allocation

```bash
kubectl describe pod <pod-name> | grep -A6 "Requests\|Limits"
```

You should see the requests and limits you defined.

## How the ReplicaSet Controller Works

When you apply the Deployment:

1. The Deployment controller creates a ReplicaSet with `replicas: 3`
2. The ReplicaSet controller sees 0 pods exist, so it creates 3
3. Each pod is placed on a node by the scheduler (using the resource requests to filter nodes)
4. If a pod is deleted, the ReplicaSet controller immediately creates a replacement to maintain the desired count

## Troubleshooting

| Problem | Check |
|---------|-------|
| Pods are `Pending` | Not enough resources on any node: `kubectl describe pod <name>` → Events |
| `ImagePullBackOff` | Image name or tag is wrong, or registry is unreachable |
| `READY` is `0/3` | Container is crashing: `kubectl logs <pod-name>` |

## Clean Up

Keep the `web` Deployment running — it is used in Lab 2 and Lab 3.
