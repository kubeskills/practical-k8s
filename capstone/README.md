# Capstone — The Notes App

**Practical Kubernetes Administration and Troubleshooting**

A cumulative lab that combines skills from all four days into one small
but complete application: a Deployment-backed frontend and a
PVC-backed PostgreSQL backend, secured with NetworkPolicies, RBAC, and Pod
Security Standards, exposed via Ingress, and — as a stretch goal — recovered
from a simulated disaster with an etcd backup.

Unlike the daily labs, this one is objective-driven rather than
command-by-command. It's meant to be attempted after finishing Day 4, once
you have every underlying skill it draws on.

---

## Contents

```
capstone/
├── README.md
├── capstone-lab.md          # The lab itself — objectives, hints, verification checklist
└── manifests/                # Reference solution
    ├── 00-namespace.yaml
    ├── 01-configmap-frontend.yaml
    ├── 02-secret-db-credentials.yaml
    ├── 03-pvc-postgres-data.yaml
    ├── 04-deployment-backend.yaml
    ├── 05-service-backend.yaml
    ├── 06-deployment-frontend.yaml
    ├── 07-service-frontend.yaml
    ├── 08-networkpolicy-default-deny.yaml
    ├── 09-networkpolicy-allow-dns.yaml
    ├── 10-networkpolicy-frontend-to-backend.yaml
    ├── 11-networkpolicy-allow-ingress-to-frontend.yaml
    ├── 12-ingress-frontend.yaml
    ├── 13-rbac-viewer.yaml
    └── 14-resourcequota-limitrange.yaml
```

---

## How to Use This Lab

1. Read [capstone-lab.md](capstone-lab.md) and attempt each stage yourself first — it links back to the specific day/lab that taught each underlying skill.
2. Check your work against [`manifests/`](manifests/) rather than starting from it.
3. **Update the Secret before applying anything** — `manifests/02-secret-db-credentials.yaml` ships with a placeholder password (`change-me-before-applying`). Replace it with your own value, or regenerate it with `kubectl create secret generic ... --dry-run=client -o yaml`.
4. To apply the full reference solution directly:

   ```bash
   kubectl apply -f manifests/
   ```

   Files are numbered so `kubectl apply -f manifests/` applies them in a
   sane order, but Kubernetes will retry unready dependencies (e.g. a
   Deployment referencing a Secret that hasn't landed yet), so strict
   ordering isn't required.

---

## Manifests

| File | Kind | Description |
|------|------|-------------|
| [00-namespace.yaml](manifests/00-namespace.yaml) | Namespace | `capstone` namespace, labeled for the `restricted` Pod Security Standard |
| [01-configmap-frontend.yaml](manifests/01-configmap-frontend.yaml) | ConfigMap | Static `index.html` for the frontend |
| [02-secret-db-credentials.yaml](manifests/02-secret-db-credentials.yaml) | Secret | Postgres username/password |
| [03-pvc-postgres-data.yaml](manifests/03-pvc-postgres-data.yaml) | PersistentVolumeClaim | 2Gi volume for Postgres data |
| [04-deployment-backend.yaml](manifests/04-deployment-backend.yaml) | Deployment | PostgreSQL, non-root, read-only root filesystem |
| [05-service-backend.yaml](manifests/05-service-backend.yaml) | Service | ClusterIP for the backend, port 5432 |
| [06-deployment-frontend.yaml](manifests/06-deployment-frontend.yaml) | Deployment | nginx (unprivileged image), 2 replicas |
| [07-service-frontend.yaml](manifests/07-service-frontend.yaml) | Service | ClusterIP for the frontend, port 80 |
| [08-networkpolicy-default-deny.yaml](manifests/08-networkpolicy-default-deny.yaml) | NetworkPolicy | Deny all ingress/egress by default |
| [09-networkpolicy-allow-dns.yaml](manifests/09-networkpolicy-allow-dns.yaml) | NetworkPolicy | Allow DNS egress for all pods |
| [10-networkpolicy-frontend-to-backend.yaml](manifests/10-networkpolicy-frontend-to-backend.yaml) | NetworkPolicy | Allow frontend → backend on 5432 |
| [11-networkpolicy-allow-ingress-to-frontend.yaml](manifests/11-networkpolicy-allow-ingress-to-frontend.yaml) | NetworkPolicy | Allow ingress-nginx → frontend on 8080 |
| [12-ingress-frontend.yaml](manifests/12-ingress-frontend.yaml) | Ingress | Routes external traffic to the frontend Service |
| [13-rbac-viewer.yaml](manifests/13-rbac-viewer.yaml) | ServiceAccount, Role, RoleBinding | Least-privilege read-only access, scoped to the namespace |
| [14-resourcequota-limitrange.yaml](manifests/14-resourcequota-limitrange.yaml) | ResourceQuota, LimitRange | Caps namespace consumption, defaults container requests/limits |

---

## Reference

See the [Core Reference Pack](../reference/) for printable cheat sheets, and the [CKA exam objectives map](../reference/cka-exam-objectives-map.md) — this capstone exercises objectives from all five CKA domains in one place.
