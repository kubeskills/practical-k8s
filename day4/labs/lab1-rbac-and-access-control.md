# Lab 1: RBAC and Access Control

## Objective

Create a Kubernetes user with a client certificate, grant them scoped read-only access using RBAC, verify the permissions with `kubectl auth can-i`, and create a ServiceAccount for a workload.

## Background

Kubernetes has no built-in user database. Human users are identified by the **Common Name (CN)** field of their x509 client certificate. The cluster CA signs these certificates, and the API server trusts any cert signed by that CA.

Once a user is identified, **RBAC** determines what they can do:

```
User/Group/ServiceAccount  →  RoleBinding  →  Role
                                              (verbs on resources in a namespace)
```

The four core RBAC objects:

| Object | Scope | Purpose |
|--------|-------|---------|
| `Role` | Namespace | Defines permitted verbs on resources within a namespace |
| `ClusterRole` | Cluster-wide | Defines permitted verbs cluster-wide or on non-namespaced resources |
| `RoleBinding` | Namespace | Grants a Role (or ClusterRole) to a subject in a namespace |
| `ClusterRoleBinding` | Cluster-wide | Grants a ClusterRole to a subject cluster-wide |

`kubectl auth can-i` lets you test permissions without switching contexts — the `--as` flag impersonates any user or ServiceAccount.

## Steps

### 1. Generate a Client Certificate for Alice

Generate a private key and a Certificate Signing Request (CSR). The `/CN=alice` sets the username; `/O=developers` sets the group.

```bash
openssl genrsa -out alice.key 2048
openssl req -new -key alice.key -out alice.csr -subj "/CN=alice/O=developers"
```

Sign the CSR with the cluster CA. This is what grants alice a valid identity in the cluster — anyone whose cert is signed by the cluster CA is trusted.

```bash
sudo openssl x509 -req -in alice.csr \
  -CA /etc/kubernetes/pki/ca.crt \
  -CAkey /etc/kubernetes/pki/ca.key \
  -CAcreateserial -out alice.crt -days 365
```

### 2. Add Alice to kubeconfig

Register alice's credentials and create a context pointing at the default namespace:

```bash
kubectl config set-credentials alice \
  --client-certificate=alice.crt \
  --client-key=alice.key

kubectl config set-context alice-context \
  --cluster=kubernetes \
  --namespace=default \
  --user=alice
```

> A **context** in kubeconfig is a named combination of cluster + user + namespace. Switching contexts changes who you are and where you're looking — without touching the server.

### 3. Grant Alice Read-Only Access to Pods

Create a Role that allows listing and inspecting pods, then bind it to alice:

```bash
kubectl create role pod-reader \
  --verb=get,list,watch \
  --resource=pods \
  -n default

kubectl create rolebinding alice-pod-reader \
  --role=pod-reader \
  --user=alice \
  -n default
```

The Role is **namespace-scoped** — alice can only see pods in `default`, not in `kube-system` or any other namespace.

### 4. Test Alice's Permissions

Switch to alice's context and verify what she can and cannot do:

```bash
kubectl config use-context alice-context

kubectl get pods              # should succeed
kubectl delete pod nginx      # should fail (Forbidden)
kubectl get deployments       # should fail (Forbidden)
kubectl get pods -n kube-system   # should fail (wrong namespace)

# switch back to admin
kubectl config use-context kubernetes-admin@kubernetes
```

> If you see `Error from server (Forbidden)`, RBAC is working correctly. That's the expected result for unauthorized actions.

### 5. Verify with `auth can-i`

Use `--as` to impersonate alice without switching contexts — faster for bulk permission checks:

```bash
kubectl auth can-i list pods --as=alice
kubectl auth can-i delete pods --as=alice
kubectl auth can-i list pods --as=alice -n kube-system
kubectl auth can-i list nodes --as=alice
```

Expected output: `yes` for the first, `no` for the rest.

### 6. Create a ServiceAccount for a Workload

Pods that need to call the Kubernetes API should use a dedicated ServiceAccount, not the `default` one. This limits the blast radius if the pod is compromised.

```bash
kubectl create serviceaccount app-reader -n default

kubectl create role deployment-reader \
  --verb=get,list,watch \
  --resource=deployments,replicasets \
  -n default

kubectl create rolebinding app-reader-binding \
  --role=deployment-reader \
  --serviceaccount=default:app-reader \
  -n default
```

When referencing a ServiceAccount as a subject, use the full format: `<namespace>:<name>`.

### 7. Verify the ServiceAccount's Permissions

```bash
kubectl auth can-i list deployments \
  --as=system:serviceaccount:default:app-reader

kubectl auth can-i delete deployments \
  --as=system:serviceaccount:default:app-reader
```

The first should return `yes`, the second `no`.

## Key Commands Reference

| Command | What it does |
|---------|-------------|
| `kubectl auth can-i <verb> <resource> --as=<user>` | Test permissions for any subject |
| `kubectl auth can-i --list --as=<user>` | List all permissions for a subject |
| `kubectl create role` | Create a namespaced Role imperatively |
| `kubectl create rolebinding` | Bind a Role to a subject imperatively |
| `kubectl config use-context` | Switch the active kubeconfig context |
| `kubectl config get-contexts` | List all available contexts |

## Troubleshooting

| Problem | Check |
|---------|-------|
| `Forbidden` when listing pods as alice | Confirm the RoleBinding exists: `kubectl get rolebinding -n default` |
| `auth can-i` returns `no` when you expect `yes` | Check the subject type — `User` vs `ServiceAccount` is case-sensitive in bindings |
| Certificate errors when switching to alice context | Verify `alice.crt` was signed by the same CA the cluster uses (`/etc/kubernetes/pki/ca.crt`) |
| RoleBinding exists but permission still denied | Check `metadata.namespace` on the binding — it must match the namespace where you're testing |
