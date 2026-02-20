# Lab 5: etcd Backup and Restore

## Objective

Take a snapshot backup of the etcd database, simulate data loss by corrupting the etcd data directory, and restore the cluster to its pre-loss state from the snapshot.

## Background

**etcd** is the distributed key-value store where Kubernetes saves all cluster state — every pod spec, secret, ConfigMap, node record, and RBAC policy lives here. If etcd is lost without a backup, the cluster cannot be recovered.

Key facts:

- etcd runs as a **static pod** on the control plane at `/etc/kubernetes/manifests/etcd.yaml`
- All `etcdctl` commands require TLS certificates to authenticate
- The `ETCDCTL_API=3` environment variable selects the v3 API (always use v3)
- Snapshots are **point-in-time** — any writes after the snapshot was taken are lost on restore

### The Restore Process

Restoring etcd is a multi-step process because the API server must be offline during the restore (otherwise it keeps writing to etcd mid-restore):

```
1. Stop the API server (move its static pod manifest out of /etc/kubernetes/manifests/)
2. Restore the snapshot to a NEW data directory
3. Update the etcd static pod manifest to point at the new directory
4. Move the API server manifest back
5. Wait for the cluster to recover
```

## Steps

### 1. Set the etcd API Version

```bash
export ETCDCTL_API=3
```

This must be set in every shell session where you use `etcdctl`. The v3 API uses a different protocol than v2.

### 2. Take a Snapshot

```bash
sudo etcdctl snapshot save /tmp/etcd-backup.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```

The three certificate flags are always required:

| Flag | File | Purpose |
|------|------|---------|
| `--cacert` | `etcd/ca.crt` | Verifies the etcd server's certificate |
| `--cert` | `etcd/server.crt` | Client certificate to authenticate |
| `--key` | `etcd/server.key` | Private key for the client certificate |

### 3. Verify the Snapshot

```bash
sudo etcdctl snapshot status /tmp/etcd-backup.db --write-out=table
```

You'll see the snapshot hash, revision, total keys, and size. Confirm the revision is non-zero — an empty snapshot won't help you recover.

### 4. Create Test Resources (to prove restore works)

Create resources that will exist in the snapshot and can be verified after restore:

```bash
kubectl create namespace before-backup
kubectl create deployment test-deploy --image=nginx -n before-backup
kubectl get all -n before-backup
```

> In a real scenario, you'd take the backup first and these resources would already exist. Here we're verifying that post-backup writes are recoverable from the snapshot.

### 5. Simulate Data Loss

Move the etcd data directory out of the way to simulate corruption or loss:

```bash
sudo mv /var/lib/etcd /var/lib/etcd-corrupted
```

The API server will begin failing to communicate with etcd. You'll see errors if you run `kubectl get nodes` — this is expected. The cluster is now "down."

### 6. Restore the Snapshot

Restore the snapshot into a fresh data directory:

```bash
sudo etcdctl snapshot restore /tmp/etcd-backup.db \
  --data-dir=/var/lib/etcd
```

This writes a valid etcd data directory to `/var/lib/etcd`. etcd will use this directory when it next starts.

> The restore command does **not** start etcd — it just writes the data files. The static pod manager (kubelet) will restart the etcd pod, which will pick up the new data directory automatically.

### 7. Wait for the Cluster to Recover

The kubelet detects that the etcd pod's data directory is available again and restarts the pod. The API server reconnects to etcd. This takes 30–90 seconds.

```bash
# keep trying until this succeeds
kubectl get nodes
```

Once `kubectl get nodes` returns, the cluster is back.

### 8. Verify the Restore

Confirm the resources that existed at snapshot time are still present:

```bash
kubectl get namespace before-backup
kubectl get deployment test-deploy -n before-backup
```

Both should exist, confirming the restore was successful.

## Key Commands Reference

| Command | What it does |
|---------|-------------|
| `etcdctl snapshot save <file>` | Write a point-in-time snapshot to a file |
| `etcdctl snapshot status <file> --write-out=table` | Inspect a snapshot's revision, key count, and size |
| `etcdctl snapshot restore <file> --data-dir=<path>` | Restore snapshot to a new data directory |
| `sudo mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/` | Stop the API server by removing its static pod manifest |
| `sudo sed -i 's|/old/path|/new/path|' /etc/kubernetes/manifests/etcd.yaml` | Update etcd's data directory in its static pod manifest |

## Troubleshooting

| Problem | Check |
|---------|-------|
| `etcdctl` fails with "certificate verify failed" | Confirm you're using the correct cert paths under `/etc/kubernetes/pki/etcd/` |
| Snapshot size is 0 bytes | etcd wasn't reachable — check the endpoint and that etcd is running |
| Cluster doesn't recover after restore | Check that the data directory path in `etcd.yaml` matches `--data-dir` used in the restore |
| `kubectl` returns "connection refused" after restore | The API server may still be starting; wait 60s and retry |
| Resources missing after restore | The resources were created after the snapshot was taken — they are gone; this is expected behavior |

## Production Best Practices

- Schedule automated backups with a CronJob or an external script running on the control plane
- Store snapshots off-node (S3, GCS, NFS) — a snapshot on the same disk as etcd doesn't protect against disk failure
- Test your restore procedure regularly — a backup you've never restored is an untested backup
- Retain multiple generations of snapshots (daily for 7 days, weekly for 4 weeks)
- For HA clusters, only one etcd member needs to be snapshotted (all members have the same data)
