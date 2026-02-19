# Lab 4: ConfigMaps and Secrets

## Objective

Create a ConfigMap and a Secret, then consume both inside a pod — the ConfigMap via `envFrom` and the Secret via a targeted `env` entry.

## Background

**ConfigMaps** store non-sensitive configuration as key-value pairs. They decouple configuration from the container image, so you can change settings without rebuilding.

**Secrets** store sensitive data (passwords, API keys, tokens). The values are base64-encoded in the API (not encrypted by default — use encryption at rest or an external secrets manager for production). Kubernetes ensures Secrets are only sent to nodes that need them and are stored in `tmpfs` (memory) inside the pod, not on disk.

There are three ways to consume ConfigMaps and Secrets in a pod:
1. **`envFrom`** — inject all keys as environment variables at once
2. **`env[].valueFrom`** — inject a single key as a named environment variable
3. **Volume mount** — project as files in the container filesystem (best for TLS certs or multi-line config files)

This lab uses all three patterns.

## Steps

### 1. Create a ConfigMap

Create a ConfigMap with two key-value pairs:

```bash
kubectl create configmap web-config \
  --from-literal=WELCOME_MSG="Hello from Day 2!" \
  --from-literal=APP_COLOR=blue
```

Inspect it:

```bash
kubectl get configmap web-config -o yaml
```

> The `--from-literal` flag is convenient for simple values. For files use `--from-file=config.properties`, and for environment files use `--from-env-file=.env`.

### 2. Create a Secret

```bash
kubectl create secret generic web-secret \
  --from-literal=API_KEY=my-secret-api-key-12345
```

Inspect it:

```bash
kubectl get secret web-secret -o yaml
```

Notice the value is base64-encoded — this is **not** encryption. Decode it to verify:

```bash
kubectl get secret web-secret -o jsonpath='{.data.API_KEY}' | base64 -d
```

> In production, use **Sealed Secrets**, **External Secrets Operator**, or a cloud secrets manager (AWS Secrets Manager, HashiCorp Vault) to store secrets securely outside the cluster.

### 3. Consume Both in a Pod

Create `configmap-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: config-demo
spec:
  containers:
  - name: demo
    image: busybox
    command: ["sh", "-c", "echo $WELCOME_MSG && echo API_KEY=$API_KEY && sleep 3600"]
    envFrom:
    - configMapRef:
        name: web-config     # inject ALL keys from web-config as env vars
    env:
    - name: API_KEY
      valueFrom:
        secretKeyRef:
          name: web-secret   # inject only the API_KEY key from web-secret
          key: API_KEY
```

Apply it:

```bash
kubectl apply -f configmap-pod.yaml
```

### 4. Verify

Check the pod logs to confirm both values were injected:

```bash
kubectl logs config-demo
```

Expected output:
```
Hello from Day 2!
API_KEY=my-secret-api-key-12345
```

> If the pod exits too quickly to read the logs, you can run `kubectl exec config-demo -- env` to see all environment variables set in the container.

### 5. Update the ConfigMap (Optional)

Change the welcome message and observe what happens:

```bash
kubectl create configmap web-config \
  --from-literal=WELCOME_MSG="Updated message!" \
  --from-literal=APP_COLOR=blue \
  --dry-run=client -o yaml | kubectl apply -f -
```

> Environment variables injected via `envFrom` are set at pod **start time** — a running pod does NOT see ConfigMap updates automatically. You must restart the pod to pick up changes. Volume-mounted ConfigMaps do update automatically (with a short delay).

## Understanding envFrom vs env.valueFrom

| Method | Use When |
|--------|----------|
| `envFrom: configMapRef` | You want all keys from a ConfigMap as env vars |
| `envFrom: secretRef` | You want all keys from a Secret as env vars |
| `env[].valueFrom.configMapKeyRef` | You want a single key, possibly renamed |
| `env[].valueFrom.secretKeyRef` | You want a single Secret key, possibly renamed |

## Troubleshooting

| Problem | Check |
|---------|-------|
| Pod fails with `CreateContainerConfigError` | The referenced ConfigMap or Secret doesn't exist |
| Env var is empty | Key name in `valueFrom` doesn't match the key in the ConfigMap/Secret |
| Pod not picking up ConfigMap changes | Env vars are set at start time — delete and recreate the pod |

## Clean Up

```bash
kubectl delete pod config-demo
kubectl delete configmap web-config
kubectl delete secret web-secret
```
