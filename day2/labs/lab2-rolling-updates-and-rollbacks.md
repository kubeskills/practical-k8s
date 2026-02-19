# Lab 2: Rolling Updates and Rollbacks

## Objective

Perform a rolling update on a Deployment, intentionally break it with a bad image, then roll back to the last working version.

## Background

A **rolling update** replaces pods one at a time (by default) so that the application stays available during the update. Kubernetes keeps the old ReplicaSet around with 0 replicas — this is what makes rollbacks instantaneous.

The default rolling update strategy:
- `maxUnavailable: 25%` — at most 25% of pods can be down at once
- `maxSurge: 25%` — at most 25% extra pods can exist during the update

Every `kubectl set image` or `kubectl apply` with a new image tag creates a new **revision** in the Deployment's rollout history.

## Prerequisites

The `web` Deployment from Lab 1 must be running with 3 replicas.

## Steps

### 1. Perform a Rolling Update

Update the nginx image to a newer version:

```bash
kubectl set image deployment/web nginx=nginx:1.28
```

Watch the rollout progress in real time:

```bash
kubectl rollout status deployment/web
```

You will see output like:
```
Waiting for deployment "web" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "web" rollout to finish: 2 out of 3 new replicas have been updated...
deployment "web" successfully rolled out
```

Check the ReplicaSets — you should briefly see two:

```bash
kubectl get rs
```

The old ReplicaSet scales down to 0 but is kept for rollback purposes. Once the rollout is complete, only the new one has pods.

### 2. Trigger a Bad Update

Update to a non-existent image tag to simulate a bad deploy:

```bash
kubectl set image deployment/web nginx=nginx:9.99.99
```

Watch what happens:

```bash
kubectl rollout status deployment/web
kubectl get pods
```

You will see new pods stuck in `ImagePullBackOff` or `ErrImagePull`. The rolling update strategy protects you — because `maxUnavailable` prevents removing old pods until new ones are healthy, your application keeps serving traffic from the old pods.

> This is the key benefit of rolling updates: a bad deploy doesn't take down the whole application.

### 3. Roll Back

Revert to the last working revision:

```bash
kubectl rollout undo deployment/web
```

Verify recovery:

```bash
kubectl rollout status deployment/web
kubectl get pods
```

All pods should return to `Running` with the `nginx:1.28` image.

### 4. View Rollout History

```bash
kubectl rollout history deployment/web
```

Each entry corresponds to a revision. To see the details of a specific revision:

```bash
kubectl rollout history deployment/web --revision=1
```

To roll back to a specific revision (not just the previous one):

```bash
kubectl rollout undo deployment/web --to-revision=1
```

## How Rollbacks Work

Kubernetes never deletes old ReplicaSets immediately. When you `rollout undo`:

1. The Deployment controller finds the previous ReplicaSet
2. It scales it back up (one pod at a time by default)
3. It scales down the current ReplicaSet simultaneously
4. The `REVISION` counter increments — a rollback creates a new revision entry

## Troubleshooting

| Problem | Check |
|---------|-------|
| `rollout status` hangs | Pods are in `Pending` or `CrashLoopBackOff`; check `kubectl get pods` |
| `rollout undo` doesn't seem to work | Check `kubectl get rs` — the old RS must still exist |
| All pods went down during bad update | Check `maxUnavailable` — it may be set to 100% |

## Clean Up

Keep the `web` Deployment running — it is used in Lab 3.
