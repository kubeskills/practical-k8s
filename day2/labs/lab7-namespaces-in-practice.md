# Lab 7: Namespaces in Practice

## Objective

Create namespaces to isolate environments, deploy the same application into multiple namespaces, and observe how namespaces provide resource and naming boundaries.

## Background

**Namespaces** are Kubernetes's mechanism for partitioning a single cluster into multiple virtual clusters. They provide:

- **Name isolation** — two teams can both have a Deployment named `web` without conflict
- **Access control** — RBAC roles can be scoped to a namespace
- **Resource quotas** — you can limit total CPU/memory consumption per namespace
- **Network policies** — traffic rules can be applied per namespace

Namespaces are appropriate for separating environments (dev/staging/production), teams, or projects within a shared cluster. For strong isolation between unrelated workloads, separate clusters are preferred.

### Built-in Namespaces

| Namespace | Purpose |
|-----------|---------|
| `default` | Where resources go if no namespace is specified |
| `kube-system` | Kubernetes control-plane components (CoreDNS, kube-proxy, etc.) |
| `kube-public` | Publicly readable data (cluster info) |
| `kube-node-lease` | Node heartbeat lease objects |

## Steps

### 1. Create Namespaces

```bash
kubectl create namespace staging
kubectl create namespace production
```

Verify:

```bash
kubectl get namespaces
```

### 2. Deploy to Each Namespace

Deploy the same application name (`web`) into both namespaces with different replica counts to simulate different environments:

```bash
kubectl create deployment web --image=nginx:1.27 --replicas=2 -n staging
kubectl create deployment web --image=nginx:1.27 --replicas=3 -n production
```

### 3. Compare the Two Deployments

```bash
kubectl get deployment web -n staging
kubectl get deployment web -n production
```

Both are named `web` but exist independently — different replica counts, separate pods, separate ReplicaSets.

View everything across all namespaces at once:

```bash
kubectl get deployments -A
```

The `-A` (or `--all-namespaces`) flag shows resources across all namespaces, with a `NAMESPACE` column added to the output.

### 4. Observe Namespace Isolation

Try to access a resource without specifying a namespace — it defaults to `default`:

```bash
kubectl get deployment web          # looks in 'default' — returns NotFound
kubectl get deployment web -n staging    # correct
```

> This is the most common beginner mistake: forgetting `-n <namespace>`. Always include it when working outside the `default` namespace, or set a default namespace for your context:
> ```bash
> kubectl config set-context --current --namespace=staging
> ```

### 5. Set a Default Namespace (Optional)

Instead of typing `-n staging` on every command, set it as the active namespace:

```bash
kubectl config set-context --current --namespace=staging
kubectl get pods   # now shows pods from 'staging' by default
```

Reset to `default` when done:

```bash
kubectl config set-context --current --namespace=default
```

### 6. Cross-Namespace DNS

Services in other namespaces are still reachable via DNS — you just need the full name:

```
<service>.<namespace>.svc.cluster.local
```

For example, a pod in `staging` can reach a Service in `production` at:
```
web.production.svc.cluster.local
```

This is how microservices in different namespaces communicate.

## Resource Quotas (Optional Extension)

Namespaces can be given a `ResourceQuota` to cap total resource usage:

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: ResourceQuota
metadata:
  name: staging-quota
  namespace: staging
spec:
  hard:
    pods: "10"
    requests.cpu: "2"
    requests.memory: 4Gi
    limits.memory: 8Gi
EOF
```

```bash
kubectl describe resourcequota staging-quota -n staging
```

Any new pods in `staging` that would exceed the quota will be rejected.

## Troubleshooting

| Problem | Check |
|---------|-------|
| `NotFound` for a resource you just created | Wrong namespace — add `-n <namespace>` |
| Can't create resources in a namespace | RBAC — check `kubectl auth can-i create pods -n <namespace>` |
| Pods can't communicate across namespaces | Network Policy may be blocking cross-namespace traffic |
| ResourceQuota exceeded | `kubectl describe resourcequota -n <namespace>` |

## Clean Up

```bash
# deleting a namespace deletes everything inside it
kubectl delete namespace staging
kubectl delete namespace production
```

> Namespace deletion is asynchronous — it enters a `Terminating` state while Kubernetes garbage-collects all contained resources. This can take a few seconds to minutes depending on how many resources exist.
