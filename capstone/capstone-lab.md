# Capstone Lab: The Notes App

## Objective

Deploy, secure, expose, monitor, break, and recover a small two-tier
application on the cluster you built on Day 1 — using nothing you haven't
already learned. This lab pulls together Deployments, ConfigMaps, and
Secrets (Day 2); Services, NetworkPolicies, and persistent storage (Day 3);
and RBAC, SecurityContext, and troubleshooting (Day 4).

Unlike the daily labs, this one gives you **objectives, not exact
commands**. Each stage links back to the lab or slide section that taught
the underlying skill — use those as your reference, not a script to
copy-paste. A full reference solution is in [`manifests/`](manifests/) if
you get stuck or want to check your work afterward.

## Architecture

```
                    Internet
                       │
                 ┌─────▼─────┐
                 │  Ingress   │  frontend-ingress (nginx)
                 └─────┬─────┘
                       │ :80
                 ┌─────▼─────┐
                 │  frontend  │  Deployment, 2 replicas
                 │  (nginx)   │  Service: frontend :80 → :8080
                 └─────┬─────┘
                       │ :5432 (NetworkPolicy-restricted)
                 ┌─────▼─────┐
                 │  backend   │  Deployment, 1 replica
                 │ (postgres) │  Service: backend :5432
                 └─────┬─────┘
                       │
                 ┌─────▼─────┐
                 │    PVC     │  postgres-data (2Gi)
                 └────────────┘
```

## Prerequisites

- A working cluster from Day 1 (kubeadm + Calico), or an equivalent cluster
- An ingress controller installed (`ingressClassName: nginx` — see [Day 3 Lab 6: Ingress](../day3/labs/lab6-ingress.md))
- A StorageClass available for dynamic provisioning (see [Day 3 Lab 5: Persistent Storage](../day3/labs/lab5-persistent-storage.md))

---

## Stage 1 — Cluster Readiness (Day 1)

Before deploying anything, confirm the cluster itself is healthy — this is
the same checklist from [Lab 4: Cluster Validation](../day1/labs/lab4-cluster-validation.md).

**Objectives:**
- [ ] All nodes are `Ready`
- [ ] All `kube-system` pods are `Running`
- [ ] The API server responds to `kubectl get --raw /healthz`

---

## Stage 2 — Deploy the App (Day 2)

**Objectives:**
- [ ] Create the `capstone` namespace
- [ ] Create a ConfigMap holding a static `index.html` for the frontend
- [ ] Create a Secret holding database credentials (`DB_USER`, `DB_PASS`)
- [ ] Deploy `backend` (PostgreSQL) as a Deployment, consuming the Secret via `envFrom`/`secretKeyRef`
- [ ] Deploy `frontend` (nginx) as a Deployment with 2 replicas, mounting the ConfigMap as a volume
- [ ] Both Deployments have **resource requests and limits** and **liveness + readiness probes**
- [ ] `kubectl get pods -n capstone` shows every pod `Running` and `1/1 Ready`

**Relevant labs:** [ConfigMaps and Secrets](../day2/labs/lab4-configmaps-and-secrets.md), [Health Checks](../day2/labs/lab5-health-checks.md), [Deploy a Multi-Replica Application](../day2/labs/lab1-deploy-multi-replica.md)

**Hint:** the official `postgres` image already runs as a non-root user
(uid `999`). The official `nginx` image does not — you'll hit this in
Stage 4. `docker.io/nginxinc/nginx-unprivileged` solves it (listens on
`8080` instead of `80`).

---

## Stage 3 — Networking and Storage (Day 3)

**Objectives:**
- [ ] Back the backend's data directory with a PVC, not `emptyDir` — data must survive a pod restart
- [ ] Create a ClusterIP Service for each Deployment
- [ ] Verify frontend → backend connectivity **before** adding NetworkPolicies, using a throwaway pod (the same pattern as [Day 3's `mysql-web` connectivity test](../day3/slides.md))
- [ ] Apply a default-deny NetworkPolicy for the namespace, then explicit allow rules for: frontend → backend on `5432`, DNS egress for all pods, and ingress-controller → frontend
- [ ] Re-run the connectivity test — it should still work
- [ ] Expose the frontend externally via Ingress

**Relevant labs:** [Persistent Storage](../day3/labs/lab5-persistent-storage.md), [Services and DNS](../day3/labs/lab1-services-and-dns.md), [Ingress](../day3/labs/lab6-ingress.md)

**Verification:**
```bash
kubectl delete pod -n capstone -l app=backend   # force a restart
# once the new pod is Running, confirm the data directory still has content
```

---

## Stage 4 — Security, RBAC, and Monitoring (Day 4)

**Objectives:**
- [ ] Both Deployments run with `runAsNonRoot: true`, `allowPrivilegeEscalation: false`, `readOnlyRootFilesystem: true`, and `capabilities.drop: ["ALL"]`
- [ ] Label the namespace for the `restricted` Pod Security Standard — pods that violate it should be rejected outright
- [ ] Create a `capstone-viewer` ServiceAccount with a Role scoped to `get`/`list`/`watch` on Pods, Services, and ConfigMaps **in this namespace only** — no Secrets access, no cluster-wide access
- [ ] Verify the scope with `kubectl auth can-i --as=system:serviceaccount:capstone:capstone-viewer <verb> <resource> -n capstone` — confirm it can list pods but cannot read secrets or act outside the namespace
- [ ] Apply a ResourceQuota and LimitRange to the namespace
- [ ] If the Day 4 monitoring stack is still installed, confirm `kubectl top pods -n capstone` returns data

**Relevant labs:** [RBAC and Access Control](../day4/labs/lab1-rbac-and-access-control.md), [Monitoring with Prometheus and Grafana](../day4/labs/lab3-monitoring-setup.md)

**Common trap:** setting `readOnlyRootFilesystem: true` on nginx or
postgres without also giving them writable `emptyDir` mounts for their
cache/temp/socket paths will crash-loop the container. Both images need
somewhere writable even with a read-only root filesystem — see the
reference solution's `volumes` sections for exactly which paths.

---

## Stage 5 — Break It, Then Fix It

This is the part that actually tests understanding — everything above can
be done by following instructions. This can't.

Have a classmate (or your instructor) introduce **exactly one** of the
following faults into your running namespace, without telling you which:

1. A typo in the backend's image tag
2. A mismatched Secret key name (Deployment references a key the Secret doesn't have)
3. A missing or overly-narrow NetworkPolicy rule between frontend and backend

Using only `kubectl describe`, `kubectl logs`, `kubectl get events`, and
`kubectl exec` — the [Day 4 systematic troubleshooting](../day4/slides.md)
approach — identify which of the three it is and fix it. Don't guess by
checking all three; diagnose it.

> If you're working alone, write a script that picks one of the three
> faults at random and applies it, so you don't know which one you're
> looking at either.

---

## Stage 6 — Stretch Goal: Disaster Recovery

**This stage is destructive to the whole cluster's etcd state, not just
this namespace. Only attempt it on a disposable practice cluster, and
ideally as the last thing you do before tearing the environment down.**

Once your namespace is fully healthy:

1. Take an etcd snapshot from the control plane node (see [Day 4 Lab 5: etcd Backup and Restore](../day4/labs/lab5-etcd-backup-and-restore.md))
2. Simulate a disaster: `kubectl delete namespace capstone`
3. Restore etcd from the snapshot
4. Confirm the `capstone` namespace and all its resources are back

This closes the loop from Day 1 — where etcd was introduced as "the single
source of truth" — to Day 4, where you learn what happens when you actually
have to rely on that being true.

---

## Verification Checklist

- [ ] `kubectl get all -n capstone` shows the expected Deployments, Services, and Pods, all healthy
- [ ] `curl` (or a browser, via `/etc/hosts` or port-forward) reaches the frontend through the Ingress
- [ ] A connectivity test pod can reach `backend.capstone.svc.cluster.local:5432` — but only because a NetworkPolicy explicitly allows it
- [ ] `kubectl auth can-i` confirms `capstone-viewer` is scoped correctly (allowed: list pods; denied: read secrets, act outside the namespace)
- [ ] Deleting the backend pod does not lose data (PVC survived)
- [ ] `kubectl get pods -n capstone -o jsonpath='{.items[*].spec.securityContext.runAsNonRoot}'` returns `true` for every pod
- [ ] You correctly diagnosed the Stage 5 fault using logs/events/describe, not trial and error

## Cleanup

```bash
kubectl delete namespace capstone
```

Deleting the namespace deletes everything inside it, including the PVC
(and, depending on the StorageClass's `reclaimPolicy`, the underlying
volume — see [Day 3's `storageclass-linode.yaml`](../day3/manifests/storageclass-linode.yaml)).
