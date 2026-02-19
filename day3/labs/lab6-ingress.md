# Lab 6: Ingress

## Objective

Deploy two backend services, create an Ingress resource that routes traffic to each based on URL path, and test the routing from outside the cluster.

## Background

A **LoadBalancer Service** per application is expensive at scale — each one provisions a separate cloud load balancer. **Ingress** solves this by acting as a reverse proxy: one external load balancer (the Ingress Controller) handles all incoming traffic and routes it to the correct backend Service based on HTTP host names and paths.

The **Ingress resource** is just configuration — it requires an **Ingress Controller** (such as ingress-nginx) to watch for Ingress objects and configure the underlying proxy accordingly.

```
Internet → LoadBalancer (1 IP) → ingress-nginx controller → /      → web-svc
                                                           → /api   → api-svc
```

## Prerequisites

The ingress-nginx controller must be installed and have an external IP:

```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller
```

If not installed:

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.0/deploy/static/provider/cloud/deploy.yaml
```

Wait for the controller pod to be `Running` and for the external IP to be assigned:

```bash
kubectl get pods -n ingress-nginx -w
kubectl get svc -n ingress-nginx ingress-nginx-controller -w
```

## Steps

### 1. Deploy Two Backend Services

**Web service** — serves the default nginx page:

```bash
kubectl create deployment web --image=nginx:1.27
kubectl expose deployment web --port=80 --name=web-svc
```

**API service** — returns a simple text response:

```bash
kubectl create deployment api --image=hashicorp/http-echo \
  -- /http-echo -text="hello from api"
kubectl expose deployment api --port=5678 --name=api-svc
```

Verify both services are running:

```bash
kubectl get deployments
kubectl get svc
```

### 2. Create the Ingress Resource

Apply the Ingress manifest from the gist:

📎 [gist.github.com/chadmcrowell/c8fcf57d994d97cab0f336046635aa22](https://gist.github.com/chadmcrowell/c8fcf57d994d97cab0f336046635aa22)

Or apply it inline:

```bash
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: demo-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-svc
            port:
              number: 80
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-svc
            port:
              number: 5678
EOF
```

> The `rewrite-target: /` annotation strips the matched path prefix before forwarding to the backend. Without it, `/api` would be forwarded as `/api` to the backend, which may not have that route.

### 3. Inspect the Ingress

```bash
kubectl describe ingress demo-ingress
kubectl get ingress
```

The `ADDRESS` column will show the external IP of the ingress-nginx controller — this is the single public IP that handles all traffic.

### 4. Test Path Routing

Get the ingress controller's external IP:

```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller
```

Test the root path (should return nginx welcome page):

```bash
curl http://<ingress-ip>/
```

Test the `/api` path (should return "hello from api"):

```bash
curl http://<ingress-ip>/api
```

> If you have a domain name, you can set it to point to the ingress IP and use `host`-based routing rules in the Ingress spec instead of (or in addition to) path-based routing.

## How ingress-nginx Works

1. You apply an `Ingress` resource to the cluster
2. The ingress-nginx controller (running as a pod) watches for `Ingress` objects via the Kubernetes API
3. It dynamically generates an nginx configuration and reloads nginx — no downtime
4. The controller's Service (of type `LoadBalancer`) receives external traffic and forwards it to the nginx pods
5. nginx matches the request against the routing rules and proxies it to the correct backend Service

## Adding TLS

To serve traffic over HTTPS, create a TLS Secret from your certificate and reference it in the Ingress:

```bash
kubectl create secret tls myapp-tls --cert=tls.crt --key=tls.key
```

Then add to your Ingress spec:

```yaml
spec:
  tls:
  - hosts:
    - myapp.example.com
    secretName: myapp-tls
```

In production, use **cert-manager** with Let's Encrypt to automate certificate issuance and renewal.

## Troubleshooting

| Problem | Check |
|---------|-------|
| `curl` returns 404 | Path doesn't match any rule; check `kubectl describe ingress` |
| `curl` returns 502 | Backend Service is down or selector doesn't match pods |
| External IP is `<pending>` | ingress-nginx controller's LoadBalancer not yet assigned; check CCM logs |
| Ingress class not found | Ensure `ingressClassName: nginx` matches the installed controller |

## Clean Up

```bash
kubectl delete ingress demo-ingress
kubectl delete svc web-svc api-svc
kubectl delete deployment web api
kubectl delete pod storage-demo 2>/dev/null || true
kubectl delete pvc data-pvc 2>/dev/null || true
```
