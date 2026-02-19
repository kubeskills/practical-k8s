# Lab 1: Services and DNS

## Objective

Create a ClusterIP Service for a Deployment and verify that Kubernetes DNS resolves the service name correctly from inside the cluster.

## Background

When you create a Service, Kubernetes automatically registers a DNS name for it via **CoreDNS**. Pods in the same namespace can reach the service by its short name (e.g., `web-clusterip`). Pods in other namespaces must use the fully qualified name: `<service>.<namespace>.svc.cluster.local`.

ClusterIP is the default Service type. It assigns a stable virtual IP that is only reachable from within the cluster. `kube-proxy` programs iptables rules on every node to redirect traffic from the ClusterIP to one of the backing pod IPs.

## Steps

### 1. Deploy an Application

Create a Deployment with 3 replicas and expose it as a ClusterIP Service:

```bash
kubectl create deployment web --image=nginx:1.27 --replicas=3
kubectl expose deployment web --port=80 --name=web-clusterip
```

> `kubectl expose` creates a Service whose selector matches the labels that `kubectl create deployment` automatically applies (`app=web`).

### 2. Test DNS Resolution

Spin up a temporary busybox pod and run `nslookup` against the service's fully qualified DNS name:

```bash
kubectl run dns-test --image=busybox --rm -it --restart=Never -- \
  nslookup web-clusterip.default.svc.cluster.local
```

You should see output like:

```
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      web-clusterip.default.svc.cluster.local
Address 1: 10.96.x.x
```

> The `--rm` flag deletes the pod after it exits. `--restart=Never` ensures it runs as a one-shot pod, not a Deployment.

### 3. Verify Endpoints

Confirm that Kubernetes has registered all 3 pod IPs as endpoints:

```bash
kubectl get endpoints web-clusterip
kubectl describe svc web-clusterip
```

**What to look for:**
- `ENDPOINTS` should list 3 IP:port pairs (one per replica)
- If the list is empty, the service selector doesn't match the pod labels — check with `kubectl get pods --show-labels`

### 4. Test Connectivity

Use a curl pod to make an HTTP request to the service by DNS name:

```bash
kubectl run curl-test --image=curlimages/curl --rm -it --restart=Never -- \
  curl http://web-clusterip.default.svc.cluster.local
```

You should receive the nginx welcome page HTML, confirming that DNS resolved correctly and the service routed to a healthy pod.

## Troubleshooting

| Problem | Check |
|---------|-------|
| `nslookup` hangs or times out | `kubectl get pods -n kube-system -l k8s-app=kube-dns` — CoreDNS may be down |
| `nslookup` returns `NXDOMAIN` | Service name or namespace is wrong; use the fully qualified name |
| Endpoints list is empty | Labels on pods don't match the service selector |
| `curl` returns connection refused | Pod is not listening on the expected port (`targetPort`) |

## Clean Up

```bash
kubectl delete deployment web
kubectl delete svc web-clusterip
```
