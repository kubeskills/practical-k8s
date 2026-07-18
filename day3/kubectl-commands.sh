#!/usr/bin/env bash
# Day 3 kubectl Commands
# Practical Kubernetes Administration and Troubleshooting

# ============================================================
# SERVICES — ClusterIP
# ============================================================

kubectl get svc web

# ============================================================
# SERVICES — NodePort
# ============================================================

kubectl get svc web-nodeport

# access from outside the cluster
curl http://<any-node-ip>:30080

# ============================================================
# SERVICES — LoadBalancer
# ============================================================

kubectl get svc web-lb

# access from the internet
curl http://45.79.123.45

# ============================================================
# ENDPOINTS AND TROUBLESHOOTING
# ============================================================

# see the pod IPs behind a service
kubectl get endpoints web

# diagnose empty endpoints (selector mismatch)
kubectl describe svc web | grep Selector
kubectl get pods --show-labels

# ============================================================
# DNS AND COREDNS
# ============================================================

# test DNS from inside a pod
kubectl run dns-test --image=busybox --rm -it --restart=Never -- \
  nslookup web.default.svc.cluster.local

# CoreDNS runs as a Deployment
kubectl get deployment coredns -n kube-system

# and exposes a Service
kubectl get svc kube-dns -n kube-system

# each pod gets this injected into /etc/resolv.conf
kubectl exec -it <pod-name> -- cat /etc/resolv.conf

# view CoreDNS configuration
kubectl get configmap coredns -n kube-system -o yaml

# ============================================================
# DNS TROUBLESHOOTING
# ============================================================

# test from inside a pod
kubectl run dns-test --image=busybox --rm -it --restart=Never -- sh

# inside the pod:
nslookup kubernetes.default          # should resolve to 10.96.0.1
nslookup web.default.svc.cluster.local
nslookup google.com                  # external DNS (forwarded by CoreDNS)

# check CoreDNS logs
kubectl logs -n kube-system -l k8s-app=kube-dns

# check CoreDNS pods are running
kubectl get pods -n kube-system -l k8s-app=kube-dns

# ============================================================
# NETWORK POLICIES
# ============================================================

kubectl apply -f netpol.yaml
kubectl get networkpolicy

# ============================================================
# SCHEDULING — NODE SELECTORS
# ============================================================

# label a node
kubectl label node worker-1 disktype=ssd
kubectl get nodes --show-labels

# ============================================================
# SCHEDULING — TAINTS AND TOLERATIONS
# ============================================================

# syntax: key=value:effect
kubectl taint node worker-2 gpu=true:NoSchedule

# remove the taint
kubectl taint node worker-2 gpu=true:NoSchedule-

# control plane nodes are tainted by default
kubectl describe node control-plane | grep Taint

# ============================================================
# SCHEDULING — DEBUGGING
# ============================================================

# check which node a pod landed on
kubectl get pod <name> -o wide

# see why a pod is Pending
kubectl describe pod <name> | grep -A10 Events

# ============================================================
# DAEMONSETS
# ============================================================

# DaemonSets running in kube-system
kubectl get daemonsets -n kube-system

# ============================================================
# JOBS
# ============================================================

kubectl get jobs
kubectl describe job db-migrate
kubectl logs job/db-migrate

# ============================================================
# CRONJOBS
# ============================================================

kubectl get cronjobs
kubectl get jobs    # shows jobs created by the cronjob

# ============================================================
# STORAGE — STORAGECLASSES
# ============================================================

kubectl get storageclasses

# ============================================================
# STORAGE — LINODE BLOCK STORAGE CSI DRIVER
# ============================================================

# install the CSI driver
kubectl apply -f https://raw.githubusercontent.com/linode/linode-blockstorage-csi-driver/master/pkg/linode-bs/deploy/releases/linode-blockstorage-csi-driver-latest.yaml

# watch PVC status (Pending → Bound once a pod schedules)
kubectl get pvc app-storage -w

# ============================================================
# STORAGE — PVC RECLAIM POLICY
# ============================================================

# check a PV's reclaim policy
kubectl get pv

# ============================================================
# INGRESS — INSTALL ingress-nginx
# ============================================================

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.0/deploy/static/provider/cloud/deploy.yaml

# verify the controller is running
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx

# ============================================================
# INGRESS — TLS SECRET
# ============================================================

# create the TLS secret from cert files
kubectl create secret tls myapp-tls --cert=tls.crt --key=tls.key

# ============================================================
# GATEWAY API — INSTALL CRDs
# ============================================================

kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml

kubectl get crd | grep gateway

# ============================================================
# LINODE CLOUD CONTROLLER MANAGER (CCM)
# ============================================================

# CCM runs as a Deployment on control plane nodes
kubectl get pods -n kube-system | grep ccm

# create a LoadBalancer Service
kubectl expose deployment web --type=LoadBalancer --port=80

# CCM provisions a NodeBalancer and assigns an external IP (~60s)
kubectl get svc web -w

# access from the internet
curl http://170.187.xxx.xx

# if external IP is stuck in <pending>, check CCM logs
kubectl logs -n kube-system -l app=linode-ccm

# ============================================================
# LAB 1: SERVICES AND DNS
# ============================================================

kubectl create deployment web --image=nginx:1.27 --replicas=3
kubectl expose deployment web --port=80 --name=web-clusterip

# test DNS resolution
kubectl run dns-test --image=busybox --rm -it --restart=Never -- \
  nslookup web-clusterip.default.svc.cluster.local

# verify endpoints
kubectl get endpoints web-clusterip
kubectl describe svc web-clusterip

# test connectivity
kubectl run curl-test --image=curlimages/curl --rm -it --restart=Never -- \
  curl http://web-clusterip.default.svc.cluster.local

# ============================================================
# LAB 2: NODEPORT AND LOADBALANCER
# ============================================================

kubectl expose deployment web --port=80 --type=NodePort --name=web-nodeport
kubectl get svc web-nodeport

# test from outside the cluster using any node's IP
curl http://<any-node-ip>:<nodeport>

kubectl expose deployment web --port=80 --type=LoadBalancer --name=web-lb

# watch for external IP assignment (~60s)
kubectl get svc web-lb -w

# test from the internet
curl http://<external-ip>

# clean up
kubectl delete svc web-nodeport web-lb

# ============================================================
# LAB 3: SCHEDULING WITH TAINTS AND TOLERATIONS
# ============================================================

# label and taint nodes
kubectl label node worker-1 disktype=ssd
kubectl taint node worker-2 dedicated=gpu:NoSchedule

# generate deployment YAML for nodeSelector
kubectl create deployment ssd-app --image=nginx:1.27 --replicas=3 \
  --dry-run=client -o yaml > ssd-app.yaml

kubectl apply -f ssd-app.yaml
kubectl get pods -o wide    # all pods should land on worker-1

# generate deployment YAML for toleration
kubectl create deployment gpu-app --image=nginx:1.27 \
  --dry-run=client -o yaml > gpu-app.yaml

kubectl apply -f gpu-app.yaml
kubectl get pods -o wide    # pod can now schedule on worker-2

# remove the taint and clean up
kubectl taint node worker-2 dedicated=gpu:NoSchedule-
kubectl delete deployment ssd-app gpu-app

# ============================================================
# LAB 4: DAEMONSET AND CRONJOB
# ============================================================

# one pod per node
kubectl get pods -o wide -l app=node-logger

# create a CronJob
kubectl create cronjob hello \
  --image=busybox \
  --schedule="*/1 * * * *" \
  -- sh -c 'echo "Hello at $(date)"'

# watch jobs being created every minute
kubectl get jobs -w

# view logs from the most recently created job
kubectl logs $(kubectl get pods -l "job-name" --sort-by=.metadata.creationTimestamp -o name | tail -1)

# clean up
kubectl delete cronjob hello
kubectl delete daemonset node-logger

# ============================================================
# LAB 5: PERSISTENT STORAGE WITH PVC
# ============================================================

# create a PVC
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

kubectl get pvc data-pvc    # Pending → Bound after pod uses it

# deploy a pod that uses the PVC
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

kubectl get pvc data-pvc             # should be Bound
kubectl exec storage-demo -- cat /data/test.txt

# delete and recreate — data persists
kubectl delete pod storage-demo
kubectl apply -f storage-demo.yaml
kubectl exec storage-demo -- cat /data/test.txt   # data still there!

# ============================================================
# LAB 6: INGRESS
# ============================================================

# deploy two services
kubectl create deployment web --image=nginx:1.27
kubectl expose deployment web --port=80 --name=web-svc

kubectl create deployment api --image=hashicorp/http-echo \
  -- /http-echo -text="hello from api"
kubectl expose deployment api --port=5678 --name=api-svc

# get the ingress controller's external IP
kubectl get svc -n ingress-nginx ingress-nginx-controller

# test path routing
curl http://<ingress-ip>/
curl http://<ingress-ip>/api

# inspect
kubectl describe ingress demo-ingress
kubectl get ingress

# full clean up
kubectl delete ingress demo-ingress
kubectl delete svc web-svc api-svc
kubectl delete deployment web api
kubectl delete pod storage-demo
kubectl delete pvc data-pvc
