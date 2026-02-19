# Lab 5: Persistent Storage with PVC

## Objective

Provision a persistent volume using the Linode Block Storage CSI driver, mount it into a pod, write data, then delete and recreate the pod to confirm the data survives.

## Background

Container filesystems are ephemeral — when a pod is deleted or restarted, all data written to the container's local filesystem is lost. **PersistentVolumes (PV)** and **PersistentVolumeClaims (PVC)** decouple storage from pod lifecycle.

With **dynamic provisioning**, you don't need to pre-create PVs. Instead, you create a PVC that references a **StorageClass**, and the CSI driver automatically provisions the underlying volume (in this case, a Linode Block Storage volume).

The flow is:

```
PVC created → StorageClass triggers CSI driver → Linode Block Storage volume provisioned → PV created and bound to PVC → Pod mounts PVC
```

## Prerequisites

- The Linode Block Storage CSI driver must be installed in the cluster
- The `linode-block-storage` StorageClass must exist:
  ```bash
  kubectl get storageclass
  ```

## Steps

### 1. Create a PersistentVolumeClaim

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: linode-block-storage
EOF
```

Check the status:

```bash
kubectl get pvc data-pvc
```

The PVC will show `Pending` at first. With `WaitForFirstConsumer` volume binding mode, it stays `Pending` until a pod actually requests the volume — this allows the CSI driver to provision the volume in the same availability zone as the pod.

> `ReadWriteOnce` (RWO) means only one node can mount the volume for read/write at a time. Use `ReadWriteMany` (RWX) if multiple pods on different nodes need simultaneous write access (requires a compatible CSI driver like NFS).

### 2. Deploy a Pod that Uses the PVC

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: storage-demo
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "echo 'hello persistent world' > /data/test.txt && sleep 3600"]
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: data-pvc
EOF
```

Once the pod is scheduled, the CSI driver provisions the Linode volume and mounts it at `/data`. The startup command writes a file, then sleeps.

Watch the PVC bind:

```bash
kubectl get pvc data-pvc -w
```

The status will transition from `Pending` → `Bound`. A corresponding PV will be automatically created:

```bash
kubectl get pv
```

### 3. Verify the Data

Read the file from inside the running pod:

```bash
kubectl exec storage-demo -- cat /data/test.txt
```

Expected output:

```
hello persistent world
```

### 4. Delete the Pod and Recreate It

Delete the pod (the volume and PVC remain):

```bash
kubectl delete pod storage-demo
```

Save the pod manifest and recreate it:

```bash
kubectl apply -f storage-demo.yaml
```

Or re-apply the same inline manifest from Step 2.

Wait for the pod to become `Running`:

```bash
kubectl get pod storage-demo -w
```

Read the file again:

```bash
kubectl exec storage-demo -- cat /data/test.txt
```

The data is still there — it persisted across the pod deletion because it lives on the Linode Block Storage volume, not in the container filesystem.

## Understanding Reclaim Policies

When a PVC is deleted, what happens to the underlying storage depends on the PV's `reclaimPolicy`:

| Policy | Behavior |
|--------|----------|
| `Delete` | PV and the Linode volume are **deleted** (default for dynamic provisioning) |
| `Retain` | PV moves to `Released` state; Linode volume is **kept** — admin must manually reclaim |

For production databases, use `Retain` so accidental PVC deletion doesn't destroy your data.

## Troubleshooting

| Problem | Check |
|---------|-------|
| PVC stuck in `Pending` | No pod has been scheduled yet (WaitForFirstConsumer), or StorageClass doesn't exist |
| Pod stuck in `ContainerCreating` | CSI driver is still provisioning the volume; check `kubectl describe pod storage-demo` |
| Pod can't mount volume | Check CSI node driver pods: `kubectl get pods -n kube-system | grep csi` |
| Data missing after pod restart | The pod may have been using a different PVC or `emptyDir` — verify the `volumes` spec |

## Clean Up

```bash
kubectl delete pod storage-demo
kubectl delete pvc data-pvc
```

> Deleting the PVC with the default `Delete` reclaim policy will also delete the underlying Linode Block Storage volume. Make sure you no longer need the data before deleting.
