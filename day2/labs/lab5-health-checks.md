# Lab 5: Health Checks

## Objective

Deploy a pod with liveness and readiness probes, observe how Kubernetes reacts when the probes start failing, and understand the difference between the two probe types.

## Background

Kubernetes uses three types of probes to determine the state of a container:

| Probe | Purpose | On Failure |
|-------|---------|------------|
| **Liveness** | Is the container alive and not deadlocked? | Container is **restarted** |
| **Readiness** | Is the container ready to receive traffic? | Pod is **removed from Service endpoints** (not restarted) |
| **Startup** | Has the container finished initializing? | Container is restarted (used for slow-starting apps) |

The key distinction:
- **Liveness failure** → container is killed and restarted. Use this for deadlock detection.
- **Readiness failure** → traffic is stopped but the container keeps running. Use this when the app is temporarily unable to serve (e.g., loading data, warming up cache).

In this lab, both probes check for the same file (`/tmp/healthy`). The app creates the file on startup, then deletes it after 30 seconds — simulating an app that starts healthy, then becomes unhealthy.

## Steps

### 1. Create the Probe Manifest

Create `probe-demo.yaml` (or use the file from [day2/assets/probe-demo.yaml](../assets/probe-demo.yaml)):

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: probe-demo
spec:
  containers:
  - name: app
    image: busybox
    command:
    - sh
    - -c
    - |
      touch /tmp/healthy
      echo "App started"
      sleep 30
      rm /tmp/healthy
      echo "App became unhealthy"
      sleep 600
    livenessProbe:
      exec:
        command: ["cat", "/tmp/healthy"]
      initialDelaySeconds: 5
      periodSeconds: 5
    readinessProbe:
      exec:
        command: ["cat", "/tmp/healthy"]
      initialDelaySeconds: 5
      periodSeconds: 5
```

> `initialDelaySeconds: 5` gives the container 5 seconds to start before the first probe runs. `periodSeconds: 5` runs the probe every 5 seconds.

### 2. Deploy and Watch

```bash
kubectl apply -f probe-demo.yaml
```

Watch the pod status in real time (leave this running in a terminal):

```bash
kubectl get pods -w
```

### 3. Observe the Sequence of Events

Over the next ~90 seconds, you will see:

| Time | Event |
|------|-------|
| 0s | Pod starts, `/tmp/healthy` is created |
| ~5s | First probe runs — passes. Pod becomes `1/1 READY` |
| ~30s | `/tmp/healthy` is deleted |
| ~35s | Readiness probe fails — pod becomes `0/1 READY` |
| ~50s | Liveness probe fails 3 consecutive times (default `failureThreshold: 3`) |
| ~50s | Container is **killed and restarted** (`RESTARTS` counter increments) |
| ~55s | New container starts, `/tmp/healthy` is recreated |
| ~60s | Probes pass again — pod is `1/1 READY` |

> The default `failureThreshold` is 3 — the probe must fail 3 consecutive times before action is taken. This prevents single transient failures from causing unnecessary restarts.

### 4. Check Events

```bash
kubectl describe pod probe-demo | grep -A10 Events
```

Look for these event messages:
- `Unhealthy: Readiness probe failed: cat: can't open '/tmp/healthy': No such file or directory`
- `Unhealthy: Liveness probe failed: ...`
- `Killing: Container app failed liveness probe, will be restarted`

### 5. Verify the Restart Count

```bash
kubectl get pod probe-demo
```

The `RESTARTS` column should show `1` after the first cycle completes.

## Probe Types

This lab used `exec` probes. Kubernetes also supports:

**HTTP probe** — performs a GET request; non-2xx/3xx response = failure:
```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 10
```

**TCP probe** — checks if the port accepts connections:
```yaml
livenessProbe:
  tcpSocket:
    port: 8080
  periodSeconds: 10
```

## Key Probe Parameters

| Parameter | Default | Meaning |
|-----------|---------|---------|
| `initialDelaySeconds` | 0 | Seconds to wait before first probe |
| `periodSeconds` | 10 | How often to run the probe |
| `failureThreshold` | 3 | Consecutive failures before action |
| `successThreshold` | 1 | Consecutive successes to become healthy |
| `timeoutSeconds` | 1 | Seconds before probe times out |

## Troubleshooting

| Problem | Check |
|---------|-------|
| Pod keeps restarting immediately | `initialDelaySeconds` too low — app hasn't started yet when probe runs |
| Pod never becomes ready | Readiness probe path/port is wrong |
| `RESTARTS` count is very high | Liveness probe is too aggressive; increase `failureThreshold` or `initialDelaySeconds` |

## Clean Up

```bash
kubectl delete pod probe-demo
```
