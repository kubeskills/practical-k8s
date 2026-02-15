---
theme: default
title: "Day 1: Foundations and Cluster Setup"
info: |
  Practical Kubernetes Administration and Troubleshooting
  Day 1 - February 17, 2026
  Instructor: Chad M. Crowell
class: text-center
drawings:
  persist: false
transition: slide-left
mdc: true
---

# Practical Kubernetes Administration and Troubleshooting

## Day 1: Foundations and Cluster Setup

February 17, 2026

<br>

**Instructor:** Chad M. Crowell

CNCF Ambassador | Kubernetes SIG Contributor | KCD Organizer

---
layout: two-cols
---

# About Your Instructor

**Chad M. Crowell**

- CNCF Ambassador
- Kubernetes SIG Contributor
- KCD Organizer & Speaker
- Site Reliability Engineer
- 17+ years in the industry
- 8+ years teaching DevOps & K8s

<br>

Training content on KubeSkills, Cybr, Pluralsight, and INE

Author of **Acing the Certified Kubernetes Administrator Exam - Second Edition** (acingthecka.com)

::right::

<br>
<br>
<br>

### Connect

- https://kubeskills.com
- GitHub: chadmcrowell


<img src="/chad-crowell.png" alt="Chad Crowell" class="h-40 mx-auto" />
<br>
<img src="/linkedin-banner-feb-2026.png" alt="Chad Crowell" class="h-30 mx-auto" />

---

# Welcome

This program is designed to provide a **practical, hands-on** learning experience focused on real-world Kubernetes administration and troubleshooting.

<br>

### What to Expect

- Work directly with Kubernetes clusters in **cloud-based environments**
- Guided labs and instructor-led exercises
- Participation, questions, and discussion encouraged
- Share challenges from your own environment

<br>

### Logistics

- **Duration:** 4 days (7 hours per day, 28 hours total)
- **Format:** Instructor-led, hands-on with cloud lab environments

---

# Day 1 Agenda

<br>

| Time | Topic |
|------|-------|
| **Morning** | Containers vs Virtual Machines |
| | Kubernetes Architecture Overview |
| **Afternoon** | Installing and Configuring Kubernetes |
| | Hands-On Labs |


---

# Labs Today

- Provision a cluster on Ubuntu 24.04 (1 control plane + 1 worker)
- Bootstrap with kubeadm and join worker nodes
- Deploy Calico CNI for pod networking
- Validate the cluster and explore core components
- Deploy your first application

---
layout: section
---

# Containers vs Virtual Machines

Understanding container orchestration

---

# The Evolution of Application Deployment

<img src="/evolution.svg" class="w-4/5 mx-auto" />

- **Traditional:** Apps compete for resources on a single OS
- **Virtualized:** Full OS per VM — isolation but heavy overhead
- **Containers:** Shared kernel, isolated processes — lightweight and fast

---

# Virtual Machines vs Containers

<br>

| Feature | Virtual Machines | Containers |
|---------|-----------------|------------|
| **Isolation** | Full OS-level | Process-level (namespaces, cgroups) |
| **Boot time** | Minutes | Seconds |
| **Size** | Gigabytes | Megabytes |
| **OS** | Each VM has its own OS | Share host kernel |
| **Overhead** | High (hypervisor + guest OS) | Low (shared kernel) |
| **Density** | 10s per host | 100s–1000s per host |
| **Portability** | Tied to hypervisor | Runs anywhere with a container runtime |

<br>

> Containers are not a replacement for VMs — they solve different problems. Many organizations run containers *inside* VMs for an extra layer of isolation.

---

# Why Container Orchestration?

Running a **single container** is easy. Running **hundreds across multiple hosts** is not.


### Challenges Without Orchestration

- How do you schedule containers across nodes?
- What happens when a container crashes?
- How do containers find and talk to each other?
- How do you roll out updates without downtime?
- How do you scale up and down based on demand?


### What Orchestration Provides

- **Scheduling** — Place workloads on available nodes
- **Self-healing** — Restart failed containers automatically
- **Service discovery** — Built-in DNS and load balancing
- **Rolling updates** — Zero-downtime deployments
- **Scaling** — Horizontal pod autoscaling

---

# Why Kubernetes?

<div class="flex gap-8 items-start">
<div class="flex-1">

- Open source, originally designed by Google (based on Borg)
- Donated to the **Cloud Native Computing Foundation (CNCF)** in 2015
- The de facto standard for container orchestration
- Massive ecosystem and community

### Key Benefits

- **Declarative configuration** — describe desired state, K8s makes it happen
- **Portable** — runs on any cloud, on-prem, or hybrid
- **Extensible** — CRDs, operators, plugins for everything
- **Self-healing** — automatically replaces and reschedules failed workloads
- **Scalable** — from a single node to thousands

</div>
<div class="w-48 mt-4">
<img src="/k8s-logo.svg" alt="Kubernetes logo" />
</div>
</div>

> "Kubernetes is the Linux of the cloud." — Kelsey Hightower

---
layout: section
---

# Kubernetes Architecture

Nodes, pods, control plane, and components

---

# Kubernetes Architecture Overview

<img src="/day1-k8s-architecture.png" alt="Alt text" class="h-96 mx-auto" />


---

# Control Plane Components

The control plane makes global decisions about the cluster.

### kube-apiserver

- The front door to the cluster — all communication goes through it
- RESTful API — `kubectl`, dashboards, and other tools talk to this
- Handles authentication, authorization, and admission control

### etcd

- Distributed key-value store
- Stores **all** cluster state and configuration
- The single source of truth — if etcd is gone, the cluster is gone
- Always back it up!

---

# Control Plane Components (cont.)

### kube-scheduler

- Watches for newly created Pods with no assigned node
- Selects the best node based on:
  - Resource requirements (CPU, memory)
  - Affinity/anti-affinity rules
  - Taints and tolerations
  - Data locality

### kube-controller-manager

- Runs controller loops that regulate the state of the cluster
- Key controllers:
  - **Node Controller** — monitors node health
  - **Replication Controller** — maintains correct pod count
  - **Endpoints Controller** — populates service endpoints
  - **Service Account Controller** — creates default accounts for namespaces

---

# Worker Node Components

Every worker node runs these components to maintain running Pods.

### kubelet

- Agent running on each node
- Ensures containers described in PodSpecs are running and healthy
- Reports node status back to the API server

### kube-proxy

- Network proxy running on each node
- Maintains network rules (iptables/IPVS) for Service communication
- Enables the Service abstraction — pods can be reached via stable IPs

### Container Runtime

- Software responsible for running containers
- Kubernetes supports any **CRI-compatible** runtime (e.g. **containerd**, CRI-O)

---

# Pods — The Smallest Deployable Unit

<img src="/pod-anatomy.svg" alt="Pod anatomy diagram" class="h-96 mx-auto" />

---

# How Components Work Together

<img src="/component-flow.svg" alt="Component interaction flow" class="h-105 mx-auto" />

---
layout: section
---

# Installing and Configuring Kubernetes

Cluster deployment with kubeadm on Linode

---

# Cluster Installation Options

| Method | Use Case | Complexity |
|--------|----------|------------|
| **kubeadm** | Production-grade self-managed clusters | Medium |
| **Managed K8s** (EKS, GKE, AKS, LKE) | Cloud-managed control plane | Low |
| **k3s** | Lightweight / edge / IoT | Low |
| **minikube** | Local development | Low |
| **kind** | CI/CD testing | Low |
| **kOps** | AWS-optimized clusters | Medium |
| **Kubespray** | Ansible-based deployment | High |

---

# Today: kubeadm

- The official Kubernetes cluster bootstrapping tool
- Creates a **production-ready** cluster
- Handles certificates, static pods, and component configuration
- Best way to understand what a cluster *actually* consists of

---

# Our Lab Environment

<img src="/lab-environment.svg" alt="Lab environment diagram" class="h-105 mx-auto" />

---

# Preparing the Nodes

Before running kubeadm, every node needs:

### 1. Disable Swap

```bash
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab
```

Kubernetes requires swap to be disabled — the kubelet will not start otherwise.

### 2. Load Required Kernel Modules

```bash
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter
```

---

# Preparing the Nodes (cont.)

### 3. Set Sysctl Parameters

```bash
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
```

---

# Preparing the Nodes (cont.)

### 4. Install containerd

```bash
sudo apt-get update
sudo apt-get install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
```

Set the cgroup driver to systemd:

```bash
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
```

---

# Installing kubeadm, kubelet, and kubectl

### Add the Kubernetes apt Repository

```bash
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | \
  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
  https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list
```

### Install and Pin Versions

```bash
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

> Pin the versions so `apt-get upgrade` doesn't accidentally break your cluster.

---

# Initializing the Control Plane

Run on the **control plane node only**:

```bash
sudo kubeadm init \
  --pod-network-cidr=192.168.0.0/16 \
  --kubernetes-version=stable
```

---

# What kubeadm init Does

<img src="/kubeadm-flow.svg" alt="kubeadm init flow" class="h-105 mx-auto" />

---

# Configuring kubectl Access

After `kubeadm init`, set up your kubeconfig:

```bash
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### Verify the Cluster

```bash
kubectl cluster-info
kubectl get nodes
```

```
NAME    STATUS     ROLES           AGE   VERSION
cp      NotReady   control-plane   1m    v1.31.x
```

> The node shows **NotReady** because we haven't installed a CNI plugin yet. That's next!

---

# Joining Worker Nodes

On each **worker node**, run the join command from `kubeadm init`:

```bash
sudo kubeadm join <control-plane-ip>:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>
```

If you lost the token, generate a new one from the control plane:

```bash
kubeadm token create --print-join-command
```

### Verify from the Control Plane

```bash
kubectl get nodes
```

```
NAME      STATUS     ROLES           AGE   VERSION
cp        NotReady   control-plane   5m    v1.31.x
worker1   NotReady   <none>          1m    v1.31.x
worker2   NotReady   <none>          30s   v1.31.x
```

---

# Installing a CNI Plugin — Calico

A **Container Network Interface (CNI)** plugin provides pod networking.

- Each Pod needs its own IP address
- Pods must communicate across nodes without NAT
- The Kubernetes networking model **requires** a CNI plugin

### Install Calico

```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml
```

### Watch Nodes Become Ready

```bash
kubectl get nodes -w
```

```
NAME      STATUS   ROLES           AGE   VERSION
cp        Ready    control-plane   10m   v1.31.x
worker1   Ready    <none>          5m    v1.31.x
worker2   Ready    <none>          4m    v1.31.x
```

---

# Verifying the Cluster

### Check Node Status

```bash
kubectl get nodes -o wide
```

### Check System Pods

```bash
kubectl get pods -n kube-system
```

You should see:
- `coredns-*` — DNS for the cluster
- `etcd-cp` — the key-value store
- `kube-apiserver-cp` — the API server
- `kube-controller-manager-cp` — the controller manager
- `kube-scheduler-cp` — the scheduler
- `kube-proxy-*` — one on each node
- `calico-node-*` — one on each node (CNI)

---

# Inspecting Core Components

### Static Pods on the Control Plane

```bash
ls /etc/kubernetes/manifests/
```

```
etcd.yaml  kube-apiserver.yaml  kube-controller-manager.yaml  kube-scheduler.yaml
```

These are **static Pods** — managed directly by the kubelet, not the API server.

### Inspect etcd

```bash
kubectl -n kube-system exec etcd-cp -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  member list
```

---

# Inspecting Core Components (cont.)

### Check the API Server

```bash
kubectl get --raw /healthz
kubectl get --raw /version
```

### Check Kubelet Status

```bash
sudo systemctl status kubelet
sudo journalctl -u kubelet --no-pager -l | tail -20
```

### Check the Controller Manager and Scheduler

```bash
kubectl get componentstatuses   # deprecated but still works
kubectl get --raw /readyz?verbose
```

> The **kubelet** is the only component that runs as a systemd service. Everything else on the control plane runs as a static Pod.

---
layout: section
---

# Hands-On Labs

Time to build your cluster!

---

# Lab Overview

### Lab 1: Provisioning the Cluster
Spin up 3 Ubuntu 24.04 instances on Linode (1 control plane + 2 workers)

### Lab 2: kubeadm Cluster Initialization
Prepare nodes, initialize the control plane, and join worker nodes

### Lab 3: CNI Plugin Installation
Deploy Calico for pod networking

### Lab 4: Cluster Validation
Verify all nodes are Ready and core components are running

### Lab 5: Exploring Core Components
Inspect etcd, API server, and verify system status

### Lab 6: Onboard a Pod
Deploy your first application to the cluster

---

# Lab 6: Deploy Your First Pod

### Create an nginx Pod

```bash
kubectl run nginx --image=nginx:latest --port=80
```

### Verify It's Running

```bash
kubectl get pods -o wide
kubectl describe pod nginx
kubectl logs nginx
```

---

# Lab 6: Deploy Your First Pod (cont.)

### Expose It

```bash
kubectl expose pod nginx --type=NodePort --port=80
kubectl get svc nginx
```

### Clean Up

```bash
kubectl delete pod nginx
kubectl delete svc nginx
```

---
layout: center
class: text-center
---

# Day 1 Recap

<br>

**What We Covered Today**

Containers vs Virtual Machines — the evolution of app deployment

Kubernetes Architecture — control plane, worker nodes, and how they interact

Installing Kubernetes — kubeadm from scratch on cloud VMs

Cluster Validation — verifying nodes, components, and networking

<br>

---
layout: center
class: text-center
---

# Coming Up Tomorrow

## Day 2: Core Concepts and Workload Management

- Managing Kubernetes Objects (Namespaces, Pods, Deployments)
- Scaling Applications
- ConfigMaps and Secrets
- Health Checks: Liveness and Readiness Probes
- Working with kubectl

<br>

### Questions?
