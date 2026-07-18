# Day 3 — Networking, Scheduling, and Storage

**Practical Kubernetes Administration and Troubleshooting**

---

## Contents

```
day3/
├── slides.md               # Presentation slides (Slidev)
├── kubectl-commands.sh     # All kubectl commands from the slides
├── labs/                   # Hands-on lab guides
│   ├── README.md
│   ├── lab1-services-and-dns.md
│   ├── lab2-nodeport-and-loadbalancer.md
│   ├── lab3-scheduling.md
│   ├── lab4-daemonset-and-cronjob.md
│   ├── lab5-persistent-storage.md
│   └── lab6-ingress.md
└── manifests/              # All YAML manifests from the slides
    ├── service-clusterip.yaml
    ├── service-nodeport.yaml
    ├── service-loadbalancer.yaml
    ├── service-externalname.yaml
    ├── netpol-allow-frontend.yaml
    ├── netpol-deny-all-ingress.yaml
    ├── netpol-deny-all-egress.yaml
    ├── daemonset-node-exporter.yaml
    ├── job-db-migrate.yaml
    ├── cronjob-backup.yaml
    ├── pv-manual.yaml
    ├── pvc-manual.yaml
    ├── pvc-app-storage.yaml
    ├── pvc-data.yaml
    ├── pod-postgres.yaml
    ├── pod-storage-demo.yaml
    ├── storageclass-linode.yaml
    ├── ingress-web.yaml
    ├── ingress-web-tls.yaml
    ├── ingress-demo.yaml
    ├── gatewayclass-nginx.yaml
    ├── gateway-prod.yaml
    └── httproute-web.yaml
```

---

## Labs

Work through the labs in order — later labs may depend on resources from earlier ones.

| # | Lab | Topics |
|---|-----|--------|
| 1 | [Services and DNS](labs/lab1-services-and-dns.md) | ClusterIP, CoreDNS, endpoint verification |
| 2 | [NodePort and LoadBalancer](labs/lab2-nodeport-and-loadbalancer.md) | NodePort, Linode CCM, external traffic |
| 3 | [Scheduling with Taints and Tolerations](labs/lab3-scheduling.md) | nodeSelector, taints, tolerations |
| 4 | [DaemonSet and CronJob](labs/lab4-daemonset-and-cronjob.md) | DaemonSets, CronJobs, Jobs |
| 5 | [Persistent Storage with PVC](labs/lab5-persistent-storage.md) | PVCs, Linode CSI driver, dynamic provisioning |
| 6 | [Ingress](labs/lab6-ingress.md) | ingress-nginx, path-based routing, TLS |

---

## Manifests

All YAML manifests from the slides, ready to apply with `kubectl apply -f`.

| File | Kind | Description |
|------|------|-------------|
| [service-clusterip.yaml](manifests/service-clusterip.yaml) | Service | ClusterIP — cluster-internal only |
| [service-nodeport.yaml](manifests/service-nodeport.yaml) | Service | NodePort — external via node IP |
| [service-loadbalancer.yaml](manifests/service-loadbalancer.yaml) | Service | LoadBalancer — external via cloud LB |
| [service-externalname.yaml](manifests/service-externalname.yaml) | Service | ExternalName — DNS alias to external host |
| [netpol-allow-frontend.yaml](manifests/netpol-allow-frontend.yaml) | NetworkPolicy | Allow frontend → backend on port 8080 |
| [netpol-deny-all-ingress.yaml](manifests/netpol-deny-all-ingress.yaml) | NetworkPolicy | Deny all inbound traffic to all pods |
| [netpol-deny-all-egress.yaml](manifests/netpol-deny-all-egress.yaml) | NetworkPolicy | Deny all outbound traffic from all pods |
| [daemonset-node-exporter.yaml](manifests/daemonset-node-exporter.yaml) | DaemonSet | Prometheus node-exporter on every node |
| [job-db-migrate.yaml](manifests/job-db-migrate.yaml) | Job | One-off database migration job |
| [cronjob-backup.yaml](manifests/cronjob-backup.yaml) | CronJob | Nightly backup at 2:00 AM |
| [pv-manual.yaml](manifests/pv-manual.yaml) | PersistentVolume | Manually provisioned hostPath PV |
| [pvc-manual.yaml](manifests/pvc-manual.yaml) | PersistentVolumeClaim | PVC bound to manual StorageClass |
| [pvc-app-storage.yaml](manifests/pvc-app-storage.yaml) | PersistentVolumeClaim | Dynamic PVC via Linode StorageClass |
| [pvc-data.yaml](manifests/pvc-data.yaml) | PersistentVolumeClaim | Lab 5 PVC (data-pvc) |
| [pod-postgres.yaml](manifests/pod-postgres.yaml) | Pod | PostgreSQL pod with PVC mount |
| [pod-storage-demo.yaml](manifests/pod-storage-demo.yaml) | Pod | Lab 5 storage demo pod |
| [storageclass-linode.yaml](manifests/storageclass-linode.yaml) | StorageClass | Linode Block Storage dynamic provisioner |
| [ingress-web.yaml](manifests/ingress-web.yaml) | Ingress | Host + path routing for web and api |
| [ingress-web-tls.yaml](manifests/ingress-web-tls.yaml) | Ingress | TLS-terminated ingress |
| [ingress-demo.yaml](manifests/ingress-demo.yaml) | Ingress | Lab 6 demo ingress (no host match) |
| [gatewayclass-nginx.yaml](manifests/gatewayclass-nginx.yaml) | GatewayClass | Gateway API — nginx controller class |
| [gateway-prod.yaml](manifests/gateway-prod.yaml) | Gateway | Gateway API — HTTP listener on port 80 |
| [httproute-web.yaml](manifests/httproute-web.yaml) | HTTPRoute | Gateway API — traffic split 90/10 canary |

---

## kubectl Commands

All commands from today's slides are collected in [`kubectl-commands.sh`](kubectl-commands.sh), organized by topic:

- Services (ClusterIP, NodePort, LoadBalancer)
- Endpoints & DNS troubleshooting
- Network Policies
- Scheduling (labels, taints, tolerations)
- DaemonSets, Jobs, CronJobs
- Persistent storage (PVs, PVCs, StorageClasses)
- Ingress & Gateway API
- Linode CCM
- Labs 1–6
