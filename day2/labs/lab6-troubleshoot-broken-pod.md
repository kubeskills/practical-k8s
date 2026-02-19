# Lab 6: Troubleshoot a Broken Pod

## Objective

Deploy a pod with an intentionally broken configuration, use standard kubectl commands to diagnose the problem, and fix it.

## Background

Troubleshooting pods follows a systematic pattern:

1. **`kubectl get pods`** — identify the pod's state and restart count
2. **`kubectl describe pod <name>`** — read the Events section for the root cause
3. **`kubectl logs <name>`** — read container output for application-level errors
4. **Fix** — correct the underlying issue

Common pod failure states:

| State | Meaning |
|-------|---------|
| `Pending` | Pod is waiting to be scheduled (resource constraints, node selector mismatch) |
| `ImagePullBackOff` | Image doesn't exist or registry is unreachable |
| `ErrImagePull` | First pull attempt failed (transitions to `ImagePullBackOff` after retries) |
| `CrashLoopBackOff` | Container starts then exits repeatedly |
| `OOMKilled` | Container exceeded its memory limit |
| `Error` | Container exited with a non-zero exit code |

## Steps

### 1. Deploy a Broken Pod

```bash
kubectl run broken --image=nginx:nonexistent --port=80
```

This uses a tag (`nonexistent`) that doesn't exist in the Docker Hub nginx repository.

### 2. Investigate

**Step 1 — What state is the pod in?**

```bash
kubectl get pods
```

You should see the pod in `ErrImagePull` or `ImagePullBackOff` with 0 restarts.

**Step 2 — What do the events say?**

```bash
kubectl describe pod broken
```

Scroll to the `Events` section at the bottom. You will see messages like:

```
Failed to pull image "nginx:nonexistent": rpc error: code = NotFound desc = ...
Warning  Failed     BackOff    Back-off pulling image "nginx:nonexistent"
```

> The `Events` section is almost always the most useful output from `kubectl describe`. It shows exactly what Kubernetes tried to do and what went wrong.

**Step 3 — What are the logs?**

```bash
kubectl logs broken
```

Since the container never started (the image couldn't be pulled), there are no logs. This confirms the problem is at the image pull stage, not inside the application.

### 3. Fix It

Update the pod's image to a valid tag:

```bash
kubectl set image pod/broken broken=nginx:1.27
```

> **Why does this work on a bare pod but not on most other fields?**
> `kubectl set image` is one of the few fields that can be updated on a running pod. Most pod spec fields (like `resources`, `volumes`, `command`) are immutable — you must delete and recreate the pod to change them. This is why using a **Deployment** is strongly preferred: you update the Deployment spec, and Kubernetes handles pod replacement automatically.

Watch the pod recover:

```bash
kubectl get pods -w
```

The pod should transition from `ImagePullBackOff` → `ContainerCreating` → `Running`.

### 4. Practice: Diagnose a CrashLoopBackOff

For additional practice, create a pod that crashes immediately:

```bash
kubectl run crasher --image=busybox -- sh -c "exit 1"
```

Observe:

```bash
kubectl get pods -w                  # watch RESTARTS increase
kubectl logs crasher                 # empty — exited immediately
kubectl describe pod crasher         # Events show "Back-off restarting failed container"
```

The `CrashLoopBackOff` state means the container started but exited with a non-zero code. The backoff time doubles after each restart (10s, 20s, 40s, up to 5 minutes) to prevent thrashing.

## Systematic Troubleshooting Checklist

```
1. kubectl get pods
   → What is the STATUS? How many RESTARTS?

2. kubectl describe pod <name>
   → Read Events at the bottom
   → Check resource requests vs node capacity
   → Check volume mounts, ConfigMap/Secret references

3. kubectl logs <name>
   → Application logs for runtime errors
   → Use --previous to see logs from a crashed container

4. kubectl get events --sort-by=.metadata.creationTimestamp
   → Cluster-wide events, useful when the pod doesn't exist yet
```

## Troubleshooting

| State | Most Likely Cause | Fix |
|-------|------------------|-----|
| `ImagePullBackOff` | Wrong image name/tag | `kubectl set image pod/<name> <container>=<correct-image>` |
| `CrashLoopBackOff` | App crashing on start | `kubectl logs --previous <name>` to see crash output |
| `Pending` | No node has enough resources | Check resource requests; `kubectl describe pod` → Events |
| `OOMKilled` | Memory limit too low | Increase `limits.memory` in the pod spec |

## Clean Up

```bash
kubectl delete pod broken crasher
```
