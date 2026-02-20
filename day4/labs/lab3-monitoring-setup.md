# Lab 3: Monitoring with Prometheus and Grafana

## Objective

Install the `kube-prometheus-stack` Helm chart to deploy Prometheus, Grafana, and Alertmanager. Access the Grafana dashboards, generate load to observe metrics, and run PromQL queries against Prometheus directly.

## Background

**Helm** is the package manager for Kubernetes. A **chart** bundles all the manifests for an application into a versioned, configurable package. The `kube-prometheus-stack` chart installs the entire monitoring stack in one command:

```
kube-prometheus-stack
├── Prometheus Operator     manages Prometheus instances via CRDs
├── Prometheus              scrapes metrics from cluster components and apps
├── Alertmanager            routes alerts to Slack, PagerDuty, email, etc.
├── Grafana                 dashboards and visualization
├── kube-state-metrics      exposes cluster-level metrics (pod counts, deployment status)
├── node-exporter           exposes node-level metrics (CPU, disk, network)
└── Prometheus rules        pre-built alerting rules
```

Prometheus uses a **pull model** — it scrapes HTTP endpoints that expose metrics. The Prometheus Operator introduces two CRDs (`ServiceMonitor` and `PodMonitor`) that tell Prometheus which services/pods to scrape, without editing the Prometheus config directly.

## Steps

### 1. Add the Helm Repository

```bash
helm repo add prometheus-community \
  https://prometheus-community.github.io/helm-charts
helm repo update
```

`helm repo update` fetches the latest chart index — always run this before installing to get the newest chart versions.

### 2. Install kube-prometheus-stack

```bash
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set grafana.adminPassword=admin123
```

`--create-namespace` creates the `monitoring` namespace if it doesn't exist. `--set` overrides a specific chart value inline; for many overrides, use a `values.yaml` file with `--values`.

Watch the pods come up:

```bash
kubectl get pods -n monitoring -w
```

Wait until all pods show `Running` or `Completed`. This typically takes 1–2 minutes as images are pulled. Press `Ctrl+C` when stable.

### 3. Access Grafana

Port-forward the Grafana service to your local machine:

```bash
kubectl port-forward svc/monitoring-grafana \
  3000:80 -n monitoring &
```

Open **http://localhost:3000** and log in with `admin` / `admin123`.

Navigate to **Dashboards → Browse** and explore:

| Dashboard | What It Shows |
|-----------|--------------|
| Kubernetes / Cluster | Overall cluster health, node count, pod count |
| Kubernetes / Nodes | Per-node CPU, memory, disk, network |
| Kubernetes / Pods | Per-pod CPU, memory, restarts, network I/O |
| Kubernetes / Deployments | Replica counts, rollout status |
| Node Exporter Full | Deep node metrics — load average, filesystem, interrupts |

> The dashboards are pre-configured to query Prometheus automatically. If a panel shows "No data", wait a minute for Prometheus to complete its first scrape cycle.

### 4. Generate Load and Watch the Dashboard

Deploy a pod that continuously hits a service to generate CPU and network traffic:

```bash
kubectl run load-test \
  --image=busybox \
  -- sh -c "while true; do wget -q -O- http://web.default.svc.cluster.local; done"
```

> If `web.default.svc.cluster.local` doesn't exist, create a quick target:
> ```bash
> kubectl create deployment web --image=nginx
> kubectl expose deployment web --port=80
> ```

In Grafana, open **Kubernetes / Pods**, filter by `namespace=default`, and watch CPU usage climb on the `load-test` pod.

### 5. Query Prometheus Directly

Port-forward Prometheus:

```bash
kubectl port-forward svc/monitoring-kube-prometheus-prometheus \
  9090:9090 -n monitoring &
```

Open **http://localhost:9090** and run these PromQL queries in the Expression field:

```promql
# pods with more than 1 restart
kube_pod_container_status_restarts_total > 1

# memory usage by pod (in bytes)
container_memory_working_set_bytes{namespace="default"}

# CPU rate per pod (5-minute window)
sum(rate(container_cpu_usage_seconds_total[5m])) by (pod)

# number of ready replicas per deployment
kube_deployment_status_replicas_ready
```

Switch between **Table** and **Graph** views to see current values vs. time series. PromQL's `rate()` function calculates per-second rates over a time window — `[5m]` means the last 5 minutes.

### 6. Clean Up the Load Test

```bash
kubectl delete pod load-test
```

## Key Commands Reference

| Command | What it does |
|---------|-------------|
| `helm repo add <name> <url>` | Register a chart repository |
| `helm install <release> <chart>` | Install a chart as a named release |
| `helm list -A` | List all installed releases across namespaces |
| `helm upgrade <release> <chart> --set key=val` | Update a release with new values |
| `helm uninstall <release> -n <ns>` | Remove a release and all its resources |
| `kubectl port-forward svc/<name> <local>:<remote> -n <ns>` | Forward a service port to localhost |

## Troubleshooting

| Problem | Check |
|---------|-------|
| Pods stuck in `Pending` | Check node resource availability: `kubectl describe node` |
| Grafana shows "No data" | Prometheus may still be scraping — wait 60s and refresh |
| Can't access Grafana at localhost:3000 | Confirm port-forward is running: `kubectl get pods -n monitoring` and re-run the port-forward |
| `helm install` fails with "already exists" | Use `helm upgrade --install` to create-or-update in one command |
| Prometheus targets show `DOWN` | Check the target's service and that the pod exposes a `/metrics` endpoint |
