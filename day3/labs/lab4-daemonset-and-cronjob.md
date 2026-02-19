# Lab 4: DaemonSet and CronJob

## Objective

Deploy a DaemonSet that runs one pod on every node, and create a CronJob that executes a task on a recurring schedule.

## Background

**DaemonSets** are used when you need exactly one copy of a pod on every node — common for log collectors (Fluent Bit), monitoring agents (Prometheus node-exporter), and CNI/CSI node drivers. As nodes are added to the cluster, the DaemonSet controller automatically schedules a pod on the new node.

**CronJobs** create `Job` objects on a schedule using standard Unix cron syntax. Each Job runs one or more pods to completion. CronJobs are useful for backups, report generation, and periodic cleanup tasks.

## Part A: DaemonSet

### 1. Create the DaemonSet

Apply the DaemonSet manifest from the gist:

📎 [gist.github.com/chadmcrowell/7317bc753d0df77ca9e1a7b4042d69fd](https://gist.github.com/chadmcrowell/7317bc753d0df77ca9e1a7b4042d69fd)

Or apply it inline:

```bash
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-logger
spec:
  selector:
    matchLabels:
      app: node-logger
  template:
    metadata:
      labels:
        app: node-logger
    spec:
      containers:
      - name: logger
        image: busybox
        command: ["sh", "-c", "while true; do echo \"$(date) on $(hostname)\"; sleep 10; done"]
EOF
```

### 2. Verify One Pod Per Node

```bash
kubectl get pods -o wide -l app=node-logger
```

You should see one pod for each worker node in the `NODE` column. The `DESIRED`, `CURRENT`, and `READY` counts on the DaemonSet should all match the number of nodes:

```bash
kubectl get daemonset node-logger
```

### 3. View Logs

```bash
kubectl logs -l app=node-logger
```

Each pod logs the current time and the hostname (node name) where it's running. This confirms the DaemonSet is running on each node independently.

### 4. Observe Automatic Scheduling (Optional)

If you add a new node to the cluster, the DaemonSet controller will automatically schedule a `node-logger` pod on it within seconds — without any manual intervention.

## Part B: CronJob

### 1. Create the CronJob

```bash
kubectl create cronjob hello \
  --image=busybox \
  --schedule="*/1 * * * *" \
  -- sh -c 'echo "Hello at $(date)"'
```

This schedule (`*/1 * * * *`) means "every minute". The pod runs `echo`, then exits.

> Cron syntax: `minute hour day-of-month month day-of-week`. Use [crontab.guru](https://crontab.guru) to validate expressions.

### 2. Watch Jobs Being Created

```bash
kubectl get jobs -w
```

Every minute, a new Job will appear with a name like `hello-<timestamp>`. Press `Ctrl+C` to stop watching after you see at least 2 jobs created.

### 3. View Logs from the Most Recent Job

```bash
kubectl logs $(kubectl get pods -l "job-name" --sort-by=.metadata.creationTimestamp -o name | tail -1)
```

You should see output like:

```
Hello at Thu Feb 19 14:32:00 UTC 2026
```

> The `--sort-by=.metadata.creationTimestamp` flag orders pods by creation time so `tail -1` gives the most recent one.

### 4. Inspect the CronJob

```bash
kubectl describe cronjob hello
```

Note the `Last Schedule Time`, `Active` (currently running jobs), and `Successful` (completed jobs) fields. The `successfulJobsHistoryLimit` (default: 3) controls how many completed jobs are kept.

## Understanding ConcurrencyPolicy

If a CronJob is still running when the next scheduled time arrives, `concurrencyPolicy` controls what happens:

| Value | Behavior |
|-------|----------|
| `Allow` (default) | Start a new job even if the previous is still running |
| `Forbid` | Skip the new run; wait for the previous to finish |
| `Replace` | Cancel the previous run and start a new one |

## Clean Up

```bash
kubectl delete cronjob hello
kubectl delete daemonset node-logger
```

Deleting a CronJob also deletes its associated Jobs and pods.
