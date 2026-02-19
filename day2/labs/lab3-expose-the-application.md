# Lab 3: Expose the Application

## Objective

Create a ClusterIP Service to expose the `web` Deployment inside the cluster, test connectivity from another pod, then create a NodePort Service for external access.

## Background

Pods are ephemeral — their IP addresses change every time they restart or reschedule. A **Service** solves this by providing a stable virtual IP (ClusterIP) and DNS name that always routes to healthy pods matching its label selector.

Kubernetes automatically registers a DNS name for every Service:
```
<service-name>.<namespace>.svc.cluster.local
```

Pods in the same namespace can use just the short name (`web`). Pods in other namespaces need the full name (`web.default.svc.cluster.local`).

## Prerequisites

The `web` Deployment from Lab 1 must be running.

## Steps

### 1. Generate the Service Manifest

```bash
kubectl expose deployment web --port=80 --type=ClusterIP \
  --dry-run=client -o yaml > web-service.yaml
```

> `kubectl expose` reads the Deployment's pod template labels and automatically sets the Service `selector` to match. This is why labels on your pods matter.

Inspect the generated file to see the selector:

```bash
cat web-service.yaml
```

You'll see something like `selector: app: web` — the same label that `kubectl create deployment` applied to the pods.

### 2. Apply the Service

```bash
kubectl apply -f web-service.yaml
```

### 3. Test the Service from Within the Cluster

Get the ClusterIP assigned to the Service:

```bash
kubectl get svc web
```

Test from within the cluster by running a temporary curl pod:

```bash
kubectl run curl --image=curlimages/curl --rm -it --restart=Never -- \
  curl http://web.default.svc.cluster.local
```

You should receive the nginx welcome page HTML, confirming that:
- DNS resolved `web.default.svc.cluster.local` to the ClusterIP
- The ClusterIP load-balanced the request to one of the 3 nginx pods
- The pod responded with HTTP 200

> The `--rm` flag deletes the pod automatically after it exits. `--restart=Never` runs it as a one-shot pod rather than a Deployment.

### 4. Check Endpoints

Services route to pods via an **Endpoints** object. Verify all 3 pod IPs are registered:

```bash
kubectl get endpoints web
```

If the Endpoints list is empty, the Service selector doesn't match any pod labels. Compare:

```bash
kubectl describe svc web | grep Selector
kubectl get pods --show-labels
```

### 5. Expose via NodePort

Create a second Service that's reachable from outside the cluster:

```bash
kubectl expose deployment web --port=80 --type=NodePort --name=web-nodeport
kubectl get svc web-nodeport
```

The `PORT(S)` column will show something like `80:31234/TCP`. The second number is the NodePort — accessible at `<any-node-ip>:31234` from outside the cluster.

## Understanding ClusterIP vs NodePort

| | ClusterIP | NodePort |
|--|-----------|----------|
| Reachable from | Inside cluster only | Inside cluster + external |
| How to access | DNS name or ClusterIP | `<node-ip>:<nodeport>` |
| Use case | Internal service-to-service | Dev/testing, direct node access |

## Troubleshooting

| Problem | Check |
|---------|-------|
| `curl` hangs | ClusterIP is correct but no pods are healthy — check `kubectl get pods` |
| DNS name doesn't resolve | CoreDNS may be down: `kubectl get pods -n kube-system -l k8s-app=kube-dns` |
| Endpoints list is empty | Label selector mismatch — compare `svc` selector with pod labels |
| NodePort not reachable externally | Node firewall may be blocking the port |

## Clean Up

Keep the `web` Service running. Clean up the NodePort:

```bash
kubectl delete svc web-nodeport
```
