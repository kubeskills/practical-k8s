# Day 2 — Workloads, Configuration, and Troubleshooting

**Practical Kubernetes Administration and Troubleshooting**

---

## Contents

```
day2/
├── slides.md               # Presentation slides (Slidev)
├── kubectl-commands.sh     # All kubectl commands from the slides
├── labs/                   # Hands-on lab guides
│   ├── README.md
│   ├── lab1-deploy-multi-replica.md
│   ├── lab2-rolling-updates-and-rollbacks.md
│   ├── lab3-expose-the-application.md
│   ├── lab4-configmaps-and-secrets.md
│   ├── lab5-health-checks.md
│   ├── lab6-troubleshoot-broken-pod.md
│   └── lab7-namespaces-in-practice.md
└── manifests/              # All YAML manifests from the slides
    ├── namespace.yaml
    ├── pod-nginx.yaml
    ├── replicaset-nginx.yaml
    ├── deployment-nginx.yaml
    ├── rolling-update-strategy.yaml
    ├── recreate-strategy.yaml
    ├── hpa-nginx.yaml
    ├── resource-requests-limits.yaml
    ├── lab1-resource-requests.yaml
    ├── configmap-app-config.yaml
    ├── configmap-envfrom.yaml
    ├── configmap-env-key.yaml
    ├── configmap-volume.yaml
    ├── configmap-pod.yaml
    ├── secret-stringdata.yaml
    ├── secret-envfrom.yaml
    ├── secret-volume.yaml
    ├── liveness-http.yaml
    ├── liveness-tcp.yaml
    ├── liveness-exec.yaml
    ├── readiness-http.yaml
    ├── startup-probe.yaml
    └── probe-demo.yaml
```

---

## Labs

Work through the labs in order — later labs build on resources created in earlier ones.

| # | Lab | Topics |
|---|-----|--------|
| 1 | [Deploy a Multi-Replica Application](labs/lab1-deploy-multi-replica.md) | Deployments, ReplicaSets, resource requests/limits |
| 2 | [Rolling Updates and Rollbacks](labs/lab2-rolling-updates-and-rollbacks.md) | Rolling updates, bad deploys, rollback, revision history |
| 3 | [Expose the Application](labs/lab3-expose-the-application.md) | ClusterIP Service, DNS, endpoints, NodePort |
| 4 | [ConfigMaps and Secrets](labs/lab4-configmaps-and-secrets.md) | ConfigMaps, Secrets, envFrom, secretKeyRef |
| 5 | [Health Checks](labs/lab5-health-checks.md) | Liveness probes, readiness probes, exec/HTTP/TCP |
| 6 | [Troubleshoot a Broken Pod](labs/lab6-troubleshoot-broken-pod.md) | ImagePullBackOff, CrashLoopBackOff, kubectl describe |
| 7 | [Namespaces in Practice](labs/lab7-namespaces-in-practice.md) | Namespaces, isolation, cross-namespace DNS, ResourceQuotas |

---

## Manifests

All YAML manifests from the slides, ready to apply with `kubectl apply -f`.

| File | Kind | Description |
|------|------|-------------|
| [namespace.yaml](manifests/namespace.yaml) | Namespace | Example namespace definition |
| [pod-nginx.yaml](manifests/pod-nginx.yaml) | Pod | Basic nginx pod |
| [replicaset-nginx.yaml](manifests/replicaset-nginx.yaml) | ReplicaSet | nginx ReplicaSet with 3 replicas |
| [deployment-nginx.yaml](manifests/deployment-nginx.yaml) | Deployment | nginx Deployment |
| [rolling-update-strategy.yaml](manifests/rolling-update-strategy.yaml) | Deployment | Rolling update strategy configuration |
| [recreate-strategy.yaml](manifests/recreate-strategy.yaml) | Deployment | Recreate strategy configuration |
| [hpa-nginx.yaml](manifests/hpa-nginx.yaml) | HorizontalPodAutoscaler | CPU-based autoscaling for nginx |
| [resource-requests-limits.yaml](manifests/resource-requests-limits.yaml) | — | Resource requests and limits snippet |
| [lab1-resource-requests.yaml](manifests/lab1-resource-requests.yaml) | — | Lab 1 resource requests snippet |
| [configmap-app-config.yaml](manifests/configmap-app-config.yaml) | ConfigMap | App configuration key-value pairs |
| [configmap-envfrom.yaml](manifests/configmap-envfrom.yaml) | Pod | Pod consuming ConfigMap via envFrom |
| [configmap-env-key.yaml](manifests/configmap-env-key.yaml) | Pod | Pod consuming a single ConfigMap key |
| [configmap-volume.yaml](manifests/configmap-volume.yaml) | Pod | Pod mounting ConfigMap as a volume |
| [configmap-pod.yaml](manifests/configmap-pod.yaml) | Pod | Lab 4 demo pod (ConfigMap + Secret) |
| [secret-stringdata.yaml](manifests/secret-stringdata.yaml) | Secret | Secret using stringData (plain text input) |
| [secret-envfrom.yaml](manifests/secret-envfrom.yaml) | Pod | Pod consuming Secret via envFrom |
| [secret-volume.yaml](manifests/secret-volume.yaml) | Pod | Pod mounting Secret as a volume |
| [liveness-http.yaml](manifests/liveness-http.yaml) | Pod | HTTP liveness probe example |
| [liveness-tcp.yaml](manifests/liveness-tcp.yaml) | Pod | TCP liveness probe example |
| [liveness-exec.yaml](manifests/liveness-exec.yaml) | Pod | Exec liveness probe example |
| [readiness-http.yaml](manifests/readiness-http.yaml) | Pod | HTTP readiness probe example |
| [startup-probe.yaml](manifests/startup-probe.yaml) | Pod | Startup probe for slow-starting apps |
| [probe-demo.yaml](manifests/probe-demo.yaml) | Pod | Lab 5 probe demo (liveness + readiness) |

---

## kubectl Commands

All commands from today's slides are collected in [`kubectl-commands.sh`](kubectl-commands.sh), organized by topic:

- Namespaces
- Labels and Selectors
- Deployments, Rolling Updates, Rollbacks
- Scaling and HPA
- Imperative vs Declarative commands
- Generating YAML with `--dry-run`
- ConfigMaps and Secrets
- Health probes
- Troubleshooting
- Labs 1–7

---

## Reference

See the [Core Reference Pack](../reference/) for printable cheat sheets — kubectl quick reference and the Kubernetes architecture & components overview.
