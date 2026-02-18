#!/bin/bash
# Day 2: Core Concepts and Workload Management
# All kubectl commands from the Day 2 slides

# ============================================================
# Namespaces
# ============================================================

# Create a namespace
kubectl create namespace dev

# List pods in the dev namespace
kubectl get pods -n dev

# List pods across ALL namespaces
kubectl get pods -A

# Set the default namespace for the current context
kubectl config set-context --current --namespace=dev

# Verify
kubectl config view --minify | grep namespace

# ============================================================
# Labels and Selectors
# ============================================================

# Find all pods with app=frontend
kubectl get pods -l app=frontend

# Find pods matching multiple labels
kubectl get pods -l "app=frontend,env=production"

# Find pods where env is NOT production
kubectl get pods -l "env!=production"

# ============================================================
# Deployments
# ============================================================

# Create a deployment (imperative)
kubectl create deployment nginx --image=nginx:1.27 --replicas=3

# See deployment status
kubectl get deployments

# Detailed info including strategy, conditions, and events
kubectl describe deployment nginx

# See the ReplicaSets managed by this Deployment
kubectl get rs

# See the pods created by the ReplicaSet
kubectl get pods --show-labels

# ============================================================
# Rolling Updates
# ============================================================

# Update the image
kubectl set image deployment/nginx nginx=nginx:1.28

# Watch the rollout
kubectl rollout status deployment/nginx

# See both ReplicaSets during the transition
kubectl get rs -w

# ============================================================
# Rollbacks
# ============================================================

# View rollout history
kubectl rollout history deployment/nginx

# Roll back to the previous version
kubectl rollout undo deployment/nginx

# Roll back to a specific revision
kubectl rollout undo deployment/nginx --to-revision=1

# ============================================================
# Scaling
# ============================================================

# Scale to 5 replicas
kubectl scale deployment/nginx --replicas=5

# Verify
kubectl get deployment nginx
kubectl get pods

# Scale to zero (pause a workload without deleting it)
kubectl scale deployment/nginx --replicas=0

# Install Metrics Server (required for HPA)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Create an HPA
kubectl autoscale deployment/nginx --min=2 --max=10 --cpu-percent=50

# Check HPA status
kubectl get hpa

# ============================================================
# Imperative Commands
# ============================================================

# Create
kubectl create deployment nginx --image=nginx:1.27 --replicas=3

# Update
kubectl set image deployment/nginx nginx=nginx:1.28

# Scale
kubectl scale deployment/nginx --replicas=5

# Delete
kubectl delete deployment nginx

# ============================================================
# Declarative Management
# ============================================================

# Apply the desired state — creates or updates
kubectl apply -f deployment.yaml

# Delete by file
kubectl delete -f deployment.yaml

# ============================================================
# Generating YAML from Imperative Commands
# ============================================================

# Generate a Deployment YAML without creating it
kubectl create deployment nginx --image=nginx:1.27 --replicas=3 \
  --dry-run=client -o yaml > deployment.yaml

# Generate a Service YAML
kubectl expose deployment nginx --port=80 --type=ClusterIP \
  --dry-run=client -o yaml > service.yaml

# Generate a ConfigMap YAML
kubectl create configmap app-config --from-literal=ENV=production \
  --dry-run=client -o yaml > configmap.yaml

# Apply generated YAML
kubectl apply -f deployment.yaml

# ============================================================
# ConfigMaps
# ============================================================

# Create from literals
kubectl create configmap app-config \
  --from-literal=APP_ENV=production \
  --from-literal=LOG_LEVEL=info

# Create from a file
echo "server.port=8080" > app.properties
kubectl create configmap app-config --from-file=app.properties

# ============================================================
# Secrets
# ============================================================

# Create from literals
kubectl create secret generic db-credentials \
  --from-literal=DB_USER=admin \
  --from-literal=DB_PASS=s3cretP@ss

# Create a TLS secret
kubectl create secret tls my-tls-secret \
  --cert=tls.crt \
  --key=tls.key

# Create a Docker registry secret
kubectl create secret docker-registry regcred \
  --docker-server=registry.example.com \
  --docker-username=user \
  --docker-password=pass

# ============================================================
# Troubleshooting
# ============================================================

# Check pod status
kubectl get pods                           # quick status overview
kubectl get pods -o wide                   # show node placement and IP
kubectl describe pod <pod-name>            # detailed events and conditions

# Reading logs
kubectl logs <pod-name>
kubectl logs <pod-name> -f                 # follow logs in real-time
kubectl logs <pod-name> --previous         # logs from previous container instance
kubectl logs <pod-name> -c <container-name>  # specific container in multi-container pod
kubectl logs <pod-name> --tail=50          # last 50 lines
kubectl logs <pod-name> --since=5m         # logs from last 5 minutes

# Exec into a container
kubectl exec -it <pod-name> -- /bin/bash
kubectl exec <pod-name> -- env
kubectl exec -it <pod-name> -c <container-name> -- /bin/sh

# Inspecting events
kubectl get events --sort-by='.lastTimestamp'
kubectl describe pod <pod-name>
kubectl get events -A
kubectl get events -w

# Troubleshooting workflow
kubectl get pods                           # What state is the pod in?
kubectl describe pod <name>                # What do the events say?
kubectl logs <name>                        # What does the app say?
kubectl logs <name> --previous             # Did it crash? What were the last logs?
kubectl exec -it <name> -- sh              # Can I poke around inside?
kubectl get events --sort-by=time          # What's happening cluster-wide?

# Is it a scheduling problem?
kubectl describe pod <name> | grep -A5 "Events"

# Is it an image problem?
kubectl describe pod <name> | grep -A3 "State"

# Is it a config problem?
kubectl describe pod <name> | grep -A3 "Environment"

# ============================================================
# Lab 1: Deploy a Multi-Replica Application
# ============================================================

kubectl create deployment web --image=nginx:1.27 --replicas=3 \
  --dry-run=client -o yaml > web-deployment.yaml

# (edit web-deployment.yaml to add resource requests/limits)

kubectl apply -f web-deployment.yaml

kubectl get deployment web
kubectl get rs
kubectl get pods -l app=web -o wide

# ============================================================
# Lab 2: Rolling Updates and Rollbacks
# ============================================================

# Perform a rolling update
kubectl set image deployment/web nginx=nginx:1.28
kubectl rollout status deployment/web
kubectl get rs

# Trigger a bad update
kubectl set image deployment/web nginx=nginx:9.99.99
kubectl rollout status deployment/web
kubectl get pods

# Roll back
kubectl rollout undo deployment/web
kubectl rollout status deployment/web
kubectl get pods

# ============================================================
# Lab 3: Expose the Application
# ============================================================

kubectl expose deployment web --port=80 --type=ClusterIP \
  --dry-run=client -o yaml > web-service.yaml

kubectl apply -f web-service.yaml

# Get the ClusterIP
kubectl get svc web

# Test from within the cluster
kubectl run curl --image=curlimages/curl --rm -it --restart=Never -- \
  curl http://web.default.svc.cluster.local

# Expose via NodePort
kubectl expose deployment web --port=80 --type=NodePort --name=web-nodeport
kubectl get svc web-nodeport

# ============================================================
# Lab 4: ConfigMaps and Secrets
# ============================================================

kubectl create configmap web-config \
  --from-literal=WELCOME_MSG="Hello from Day 2!" \
  --from-literal=APP_COLOR=blue

kubectl create secret generic web-secret \
  --from-literal=API_KEY=my-secret-api-key-12345

kubectl get configmap web-config -o yaml
kubectl get secret web-secret -o yaml

# Decode a secret value
kubectl get secret web-secret -o jsonpath='{.data.API_KEY}' | base64 -d

kubectl apply -f configmap-pod.yaml
kubectl logs config-demo

# ============================================================
# Lab 5: Health Checks
# ============================================================

kubectl apply -f probe-demo.yaml
kubectl get pods -w

# Check the events
kubectl describe pod probe-demo | grep -A10 Events

# ============================================================
# Lab 6: Troubleshoot a Broken Pod
# ============================================================

kubectl run broken --image=nginx:nonexistent --port=80

# Investigate
kubectl get pods
kubectl describe pod broken
kubectl logs broken

# Fix it
kubectl set image pod/broken broken=nginx:1.27

# ============================================================
# Lab 7: Namespaces in Practice
# ============================================================

kubectl create namespace staging
kubectl create namespace production

kubectl create deployment web --image=nginx:1.27 --replicas=2 -n staging
kubectl create deployment web --image=nginx:1.27 --replicas=3 -n production

# Compare
kubectl get deployment web -n staging
kubectl get deployment web -n production
kubectl get deployments -A

# Clean up — deleting a namespace deletes everything inside it
kubectl delete namespace staging
kubectl delete namespace production
