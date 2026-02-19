# Lab 6: Onboard a Pod

## Objective

Deploy your first application to the cluster, verify it's running, expose it as a Service, and explore the fundamental kubectl commands for inspecting workloads.

## Background

A **Pod** is the smallest deployable unit in Kubernetes. It wraps one or more containers and provides them with a shared network namespace (they share an IP and port space) and optional shared storage.

In practice you'll use Deployments to manage pods (for self-healing and rolling updates), but running a bare Pod is the best way to understand the basics without additional abstraction.

### The kubectl Workflow

```
kubectl run / apply    →  Pod created in API server
API server             →  Scheduler picks a node
Scheduler              →  kubelet on that node is notified
kubelet                →  calls containerd to pull image and start container
containerd             →  container running
kubelet                →  reports status back to API server
kubectl get pods       →  you see "Running"
```

## Steps

### 1. Generate a Pod Manifest

Use `--dry-run=client -o yaml` to generate the manifest without applying it — a best practice that lets you inspect and version-control the YAML:

```bash
kubectl run nginx --image=nginx:latest --port=80 --dry-run=client -o yaml > pod.yaml
```

Inspect the generated file:

```bash
cat pod.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: nginx
  name: nginx
spec:
  containers:
  - image: nginx:latest
    name: nginx
    ports:
    - containerPort: 80
```

> `containerPort` is documentation only — it doesn't actually open a port. Containers are accessible on all ports once running. The field helps humans and tools understand what the app listens on.

### 2. Apply the Manifest

```bash
kubectl apply -f pod.yaml
```

> **`apply` vs `create`:** `kubectl apply` is **declarative** — it creates the resource if it doesn't exist, or updates it if it does. `kubectl create` is **imperative** — it fails if the resource already exists. Prefer `apply` for all day-to-day operations.

### 3. Verify the Pod Is Running

```bash
kubectl get pods -o wide
```

The `-o wide` flag shows which node the pod was scheduled on and its pod IP.

Describe the pod for detailed status and events:

```bash
kubectl describe pod nginx
```

Read the `Events` section at the bottom — it shows the scheduling decision, image pull, and container start sequence.

### 4. Read the Container Logs

```bash
kubectl logs nginx
```

nginx logs every HTTP request it receives. This is where application-level output appears.

> Use `kubectl logs -f nginx` to stream logs in real time (like `tail -f`).

### 5. Execute a Command Inside the Container

```bash
kubectl exec -it nginx -- bash
```

From inside the container, you can inspect the filesystem, check environment variables, or test network connectivity:

```bash
# inside the container:
curl localhost          # nginx serves its own welcome page
cat /etc/nginx/nginx.conf
env | grep KUBERNETES   # Kubernetes injects API server info as env vars
exit
```

### 6. Expose the Pod as a Service

Create a NodePort Service so the pod is reachable from outside the cluster:

```bash
kubectl expose pod nginx --type=NodePort --port=80
kubectl get svc nginx
```

The output shows the node port assigned (e.g., `80:31234/TCP`). Access it:

```bash
curl http://<any-node-ip>:<nodeport>
```

You should receive the nginx welcome page HTML.

### 7. Inspect the Full Pod Spec

Output the live pod spec as YAML to see what Kubernetes added (defaulted fields, status, etc.):

```bash
kubectl get pod nginx -o yaml
```

Notice fields that were auto-populated: `nodeName`, `podIP`, `startTime`, `containerID`, resource defaults, and more.

### 8. Clean Up

```bash
kubectl delete pod nginx
kubectl delete svc nginx
```

Verify the pod is gone:

```bash
kubectl get pods
```

> Deleting a bare pod is permanent — there is no controller to recreate it. This is why production workloads use Deployments (covered on Day 2).

## Key kubectl Commands Reference

| Command | What it does |
|---------|-------------|
| `kubectl get pods` | List pods in the current namespace |
| `kubectl get pods -o wide` | List pods with node and IP info |
| `kubectl describe pod <name>` | Full details and events for a pod |
| `kubectl logs <name>` | Container stdout/stderr |
| `kubectl logs -f <name>` | Stream logs in real time |
| `kubectl exec -it <name> -- bash` | Open an interactive shell in the container |
| `kubectl delete pod <name>` | Delete a pod |
| `kubectl apply -f <file>` | Create or update a resource from a file |
| `kubectl get pod <name> -o yaml` | Get the full live spec and status |

## Troubleshooting

| Problem | Check |
|---------|-------|
| Pod stuck in `Pending` | `kubectl describe pod nginx` → Events (usually scheduling failure) |
| `ImagePullBackOff` | Image name wrong or registry unreachable |
| `CrashLoopBackOff` | Container exits immediately — `kubectl logs nginx` |
| NodePort not reachable externally | Node firewall rules blocking the port |
