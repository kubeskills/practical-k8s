# kubectl Quick Reference

> Adapted from the official [Kubernetes kubectl Quick Reference](https://kubernetes.io/docs/reference/kubectl/quick-reference/), © The Kubernetes Authors, licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Reorganized here for the Practical Kubernetes course; command syntax preserved from source.

## Autocomplete

```bash
source <(kubectl completion bash)                 # bash
source <(kubectl completion zsh)                  # zsh
echo 'kubectl completion fish | source' >> ~/.config/fish/completions/kubectl.fish  # fish

kubectl get pods --all-namespaces   # kubectl -A is shorthand for --all-namespaces
```

## Context and Configuration

```bash
kubectl config view                                      # show merged kubeconfig
kubectl config get-contexts                               # list all contexts
kubectl config current-context                             # show current context
kubectl config use-context <name>                          # switch context
kubectl config set-context --current --namespace=<ns>       # set default namespace
kubectl config set-credentials <user>                       # add user credentials
```

## Apply (declarative — preferred for production)

```bash
kubectl apply -f ./manifest.yaml
kubectl apply -f ./dir                                   # apply all manifests in a directory
kubectl apply -f https://example.com/manifest.yaml
kubectl diff -f ./my-manifest.yaml                        # preview changes before applying
```

## Creating Objects (imperative)

```bash
kubectl create deployment nginx --image=nginx
kubectl create job hello --image=busybox:1.28 -- echo "Hello World"
kubectl create cronjob hello --image=busybox:1.28 --schedule="*/1 * * * *"
kubectl explain pods                                      # field-level docs for a resource
kubectl explain pods.spec.containers                       # drill into a nested field
```

## Viewing and Finding Resources

```bash
kubectl get services
kubectl get pods --all-namespaces
kubectl get pods -o wide
kubectl get pod <name> -o yaml
kubectl describe nodes <name>
```

**Sorting & selecting:**

```bash
kubectl get services --sort-by=.metadata.name
kubectl get pods --sort-by='.status.containerStatuses[0].restartCount'
kubectl get pods --selector=app=cassandra
kubectl get node --selector='!node-role.kubernetes.io/control-plane'
kubectl get pods --field-selector=status.phase=Running
```

**JSONPath / custom output:**

```bash
kubectl get pods --selector=app=cassandra -o jsonpath='{.items[*].metadata.labels.version}'
kubectl get configmap myconfig -o jsonpath='{.data.ca\.crt}'
kubectl get nodes -o custom-columns='NODE_NAME:.metadata.name,STATUS:.status.conditions[?(@.type=="Ready")].status'
```

**Events:**

```bash
kubectl get events --sort-by=.metadata.creationTimestamp
kubectl events --types=Warning
```

## Updating Resources

```bash
kubectl set image deployment/nginx nginx=nginx:1.9.1
kubectl rollout status deployment/nginx
kubectl rollout undo deployment/nginx
kubectl rollout undo deployment/nginx --to-revision=2
kubectl rollout pause deployment/nginx
kubectl rollout resume deployment/nginx
```

## Patching & Editing

```bash
kubectl patch node k8s-node -p '{"spec":{"unschedulable":true}}'
kubectl edit svc/docker-registry
kubectl edit deployment/myapp
```

## Scaling

```bash
kubectl scale --replicas=3 rs/foo
kubectl scale --replicas=3 -f foo.yaml
kubectl scale --current-replicas=2 --replicas=3 deployment/mysql
kubectl autoscale deployment nginx --min=10 --max=15
```

## Deleting Resources

```bash
kubectl delete pod,service baz foo
kubectl delete pods,services -l name=myLabel
kubectl delete pod foo --now
kubectl delete pod foo --grace-period=0 --force
kubectl delete deployment/foo
```

## Interacting with Running Pods

```bash
kubectl logs my-pod
kubectl logs my-pod --previous                            # previous container instance
kubectl logs my-pod -c my-container
kubectl logs -f deployment/my-app --all-containers=true    # stream all containers
kubectl run -i --tty busybox --image=busybox -- sh
kubectl attach my-pod -i
kubectl port-forward pod/my-pod 5000:6000
kubectl exec my-pod -- ls /
kubectl exec --stdin --tty my-pod -- /bin/bash
```

## Copying Files

```bash
kubectl cp /tmp/foo_dir my-pod:/tmp/bar_dir
kubectl cp my-pod:/tmp/foo /tmp/bar
kubectl cp my-namespace/my-pod:/tmp/foo /tmp/bar
```

## Deployments & Services

```bash
kubectl set image deployment/frontend www=image:v2
kubectl rollout status -w deployment/frontend
kubectl rollout undo deployment/frontend
kubectl get replicaset
kubectl get pods --selector=app=nginx
kubectl annotate pods my-pod icon-url=http://example.com/icon.png
kubectl autoscale deployment foo --min=2 --max=10
```

## Nodes & Cluster

```bash
kubectl cordon my-node                                    # prevent scheduling
kubectl drain my-node                                     # gracefully terminate pods
kubectl uncordon my-node                                  # resume scheduling
kubectl top nodes
kubectl top pods --all-namespaces
kubectl cluster-info
kubectl cluster-info dump
```

## Common Resource Types (with short names)

| Resource | Short name |
|---|---|
| pods | `po` |
| services | `svc` |
| deployments | `deploy` |
| replicasets | `rs` |
| statefulsets | `sts` |
| daemonsets | `ds` |
| jobs | — |
| cronjobs | — |
| configmaps | `cm` |
| secrets | — |
| namespaces | `ns` |
| nodes | `no` |
| persistentvolumes | `pv` |
| persistentvolumeclaims | `pvc` |
| ingresses | `ing` |

## Output Formatting

```bash
-o json                      # JSON
-o yaml                      # YAML
-o wide                      # additional columns
-o name                      # resource name only
-o custom-columns=<spec>     # custom columns
-o jsonpath=<template>       # JSONPath template
```

## Verbosity / Debugging

```bash
--v=0   # always visible
--v=1   # reasonable default
--v=2   # useful steady-state info
--v=3   # extended info about changes
--v=4   # debug level
--v=5   # trace level
--v=6 --alsologtostderr   # log to file and stderr
```
