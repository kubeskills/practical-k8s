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

Co-author of *Acing the CKA*

::right::

<br>
<br>
<br>

### Connect

- https://kubeskills.com
- GitHub: chadmcrowell

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
- **Location:** 4101 Smith School Rd., Bldg. IV, Ste. 100, Austin, TX 78744
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

<br>

### Labs Today

- Provision a cluster on Ubuntu 24.04 (1 control plane + 2 workers)
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

<br>

```
Traditional Era          Virtualized Era          Container Era
┌──────────────┐    ┌──────────────────┐    ┌──────────────────┐
│    App A      │    │  ┌────┐ ┌────┐  │    │ ┌──┐┌──┐┌──┐┌──┐│
│    App B      │    │  │ VM │ │ VM │  │    │ │C1││C2││C3││C4││
│    App C      │    │  │App │ │App │  │    │ └──┘└──┘└──┘└──┘│
│               │    │  │ A  │ │ B  │  │    │   Container      │
│  One OS       │    │  │OS  │ │OS  │  │    │    Runtime       │
│               │    │  └────┘ └────┘  │    │                  │
│  Bare Metal   │    │   Hypervisor     │    │   Host OS        │
│  Hardware     │    │   Hardware       │    │   Hardware       │
└──────────────┘    └──────────────────┘    └──────────────────┘
```

<br>

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

<br>

### Challenges Without Orchestration

- How do you schedule containers across nodes?
- What happens when a container crashes?
- How do containers find and talk to each other?
- How do you roll out updates without downtime?
- How do you scale up and down based on demand?

<br>

### What Orchestration Provides

- **Scheduling** — Place workloads on available nodes
- **Self-healing** — Restart failed containers automatically
- **Service discovery** — Built-in DNS and load balancing
- **Rolling updates** — Zero-downtime deployments
- **Scaling** — Horizontal pod autoscaling

---

# Why Kubernetes?

<br>

- Open source, originally designed by Google (based on Borg)
- Donated to the **Cloud Native Computing Foundation (CNCF)** in 2015
- The de facto standard for container orchestration
- Massive ecosystem and community

<br>

### Key Benefits

- **Declarative configuration** — describe desired state, K8s makes it happen
- **Portable** — runs on any cloud, on-prem, or hybrid
- **Extensible** — CRDs, operators, plugins for everything
- **Self-healing** — automatically replaces and reschedules failed workloads
- **Scalable** — from a single node to thousands

<br>

> "Kubernetes is the Linux of the cloud." — Kelsey Hightower

---
layout: section
---

# Kubernetes Architecture

Nodes, pods, control plane, and components

---

# Kubernetes Architecture Overview

<br>

```
                        ┌─────────────────────────────────────────┐
                        │            CONTROL PLANE                │
                        │                                         │
                        │  ┌───────────┐  ┌──────────────────┐   │
                        │  │ API Server │  │ Controller Manager│   │
                        │  └─────┬─────┘  └──────────────────┘   │
                        │        │                                │
                        │  ┌─────┴─────┐  ┌──────────────────┐   │
                        │  │   etcd    │  │    Scheduler     │   │
                        │  └───────────┘  └──────────────────┘   │
                        └──────────────────┬──────────────────────┘
                                           │
                    ┌──────────────────────┼──────────────────────┐
                    │                      │                      │
            ┌───────┴────────┐    ┌───────┴────────┐    ┌───────┴────────┐
            │   WORKER NODE  │    │   WORKER NODE  │    │   WORKER NODE  │
            │                │    │                │    │                │
            │  kubelet       │    │  kubelet       │    │  kubelet       │
            │  kube-proxy    │    │  kube-proxy    │    │  kube-proxy    │
            │  container     │    │  container     │    │  container     │
            │  runtime       │    │  runtime       │    │  runtime       │
            │                │    │                │    │                │
            │  ┌───┐ ┌───┐  │    │  ┌───┐ ┌───┐  │    │  ┌───┐ ┌───┐  │
            │  │Pod│ │Pod│  │    │  │Pod│ │Pod│  │    │  │Pod│ │Pod│  │
            │  └───┘ └───┘  │    │  └───┘ └───┘  │    │  └───┘ └───┘  │
            └────────────────┘    └────────────────┘    └────────────────┘
```

---

# Control Plane Components

The control plane makes global decisions about the cluster.

<br>

### kube-apiserver

- The front door to the cluster — all communication goes through it
- RESTful API — `kubectl`, dashboards, and other tools talk to this
- Handles authentication, authorization, and admission control

<br>

### etcd

- Distributed key-value store
- Stores **all** cluster state and configuration
- The single source of truth — if etcd is gone, the cluster is gone
- Always back it up!

---

# Control Plane Components (cont.)

<br>

### kube-scheduler

- Watches for newly created Pods with no assigned node
- Selects the best node based on:
  - Resource requirements (CPU, memory)
  - Affinity/anti-affinity rules
  - Taints and tolerations
  - Data locality

<br>

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

<br>

### kubelet

- Agent running on each node
- Ensures containers described in PodSpecs are running and healthy
- Reports node status back to the API server
- Does **not** manage containers not created by Kubernetes

<br>

### kube-proxy

- Network proxy running on each node
- Maintains network rules (iptables/IPVS) for Service communication
- Enables the Service abstraction — pods can be reached via stable IPs

<br>

### Container Runtime

- Software responsible for running containers
- Kubernetes supports any **CRI-compatible** runtime
- Common choices: **containerd**, CRI-O

---

# Pods — The Smallest Deployable Unit

<br>

```
┌─────────────────── Pod ───────────────────┐
│                                           │
│  ┌─────────────┐    ┌─────────────┐       │
│  │  Container   │    │  Container   │       │
│  │  (app)       │    │  (sidecar)   │       │
│  └─────────────┘    └─────────────┘       │
│                                           │
│  Shared network namespace (localhost)     │
│  Shared storage volumes                   │
│  Shared IPC namespace                     │
│                                           │
│  IP: 10.244.1.5                           │
└───────────────────────────────────────────┘
```

<br>

- A Pod is a **group of one or more containers** with shared networking and storage
- Each Pod gets its own **IP address**
- Containers in a Pod communicate over `localhost`
- Pods are **ephemeral** — they can be created, destroyed, and replaced at any time
- You rarely create Pods directly — use Deployments, ReplicaSets, etc.

---

# How Components Work Together

<br>

### Example: Creating a Deployment

```
1. kubectl apply → API Server
       │
2. API Server validates and stores in etcd
       │
3. Scheduler watches for unassigned Pods
       │
4. Scheduler assigns Pod to a Node
       │
5. kubelet on that Node sees the assignment
       │
6. kubelet tells container runtime to pull image and start container
       │
7. kube-proxy sets up networking rules for the Pod
       │
8. Controller Manager ensures desired replica count is maintained
```

<br>

> Every component has a single responsibility. They communicate through the **API Server** — no direct component-to-component communication.

---
layout: section
---

# Installing and Configuring Kubernetes

Cluster deployment with kubeadm on Linode

---

# Cluster Installation Options

<br>

| Method | Use Case | Complexity |
|--------|----------|------------|
| **kubeadm** | Production-grade self-managed clusters | Medium |
| **Managed K8s** (EKS, GKE, AKS, LKE) | Cloud-managed control plane | Low |
| **k3s** | Lightweight / edge / IoT | Low |
| **minikube** | Local development | Low |
| **kind** | CI/CD testing | Low |
| **kOps** | AWS-optimized clusters | Medium |
| **Kubespray** | Ansible-based deployment | High |

<br>

### Today: kubeadm

- The official Kubernetes cluster bootstrapping tool
- Creates a **production-ready** cluster
- Handles certificates, static pods, and component configuration
- Best way to understand what a cluster *actually* consists of

---

# Our Lab Environment

<br>

```
┌─────────────────────────────────────────────────────┐
│                    Linode Cloud                      │
│                                                     │
│  ┌─────────────────┐                                │
│  │  Control Plane   │  Ubuntu 24.04                  │
│  │  (cp)            │  4 GB RAM                      │
│  │                  │  2 CPU                          │
│  └────────┬─────────┘                                │
│           │                                          │
│     ┌─────┴─────┐                                    │
│     │           │                                    │
│  ┌──┴────────┐  ┌──┴────────┐                        │
│  │ Worker 1   │  │ Worker 2   │                       │
│  │ (worker1)  │  │ (worker2)  │  Ubuntu 24.04         │
│  │            │  │            │  4 GB RAM              │
│  └────────────┘  └────────────┘  2 CPU                │
│                                                     │
└─────────────────────────────────────────────────────┘
```

<br>

- **3 nodes:** 1 control plane + 2 workers
- **OS:** Ubuntu 24.04 LTS
- **Cloud:** Linode (Akamai Cloud)

---

# Preparing the Nodes

Before running kubeadm, every node needs:

<br>

### 1. Disable Swap

```bash
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab
```

Kubernetes requires swap to be disabled — the kubelet will not start otherwise.

<br>

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

<br>

### 3. Set Sysctl Parameters

```bash
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
```

<br>

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

<br>

### Add the Kubernetes apt Repository

```bash
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | \
  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
  https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list
```

<br>

### Install and Pin Versions

```bash
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

> **Important:** Pin the versions so `apt-get upgrade` doesn't accidentally break your cluster.

---

# Initializing the Control Plane

Run on the **control plane node only**:

<br>

```bash
sudo kubeadm init \
  --pod-network-cidr=192.168.0.0/16 \
  --kubernetes-version=stable
```

<br>

### What kubeadm init Does

1. **Pre-flight checks** — validates the system is ready
2. **Generates certificates** — CA, API server, kubelet, etc.
3. **Generates kubeconfig files** — admin, controller-manager, scheduler
4. **Creates static Pod manifests** — API server, etcd, scheduler, controller-manager
5. **Starts the kubelet** — which launches the static Pods
6. **Applies cluster configuration** — stored in ConfigMaps
7. **Outputs a join command** — for worker nodes

<br>

> Save the `kubeadm join` command! You'll need it for the worker nodes.

---

# Configuring kubectl Access

After `kubeadm init`, set up your kubeconfig:

<br>

```bash
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

<br>

### Verify the Cluster

```bash
kubectl cluster-info
kubectl get nodes
```

<br>

```
NAME    STATUS     ROLES           AGE   VERSION
cp      NotReady   control-plane   1m    v1.31.x
```

> The node shows **NotReady** because we haven't installed a CNI plugin yet. That's next!

---

# Joining Worker Nodes

On each **worker node**, run the join command from `kubeadm init`:

<br>

```bash
sudo kubeadm join <control-plane-ip>:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>
```

<br>

### If You Lost the Join Token

Generate a new one from the control plane:

```bash
kubeadm token create --print-join-command
```

<br>

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

<br>

### Why Do We Need a CNI?

- Each Pod needs its own IP address
- Pods must communicate across nodes without NAT
- The Kubernetes networking model **requires** a CNI plugin

<br>

### Install Calico

```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml
```

<br>

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

<br>

### Check Node Status

```bash
kubectl get nodes -o wide
```

<br>

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

<br>

### Static Pods on the Control Plane

```bash
ls /etc/kubernetes/manifests/
```

```
etcd.yaml
kube-apiserver.yaml
kube-controller-manager.yaml
kube-scheduler.yaml
```

These are **static Pods** — managed directly by the kubelet, not the API server.

<br>

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

<br>

### Check the API Server

```bash
kubectl get --raw /healthz
kubectl get --raw /version
```

<br>

### Check Kubelet Status

```bash
sudo systemctl status kubelet
sudo journalctl -u kubelet --no-pager -l | tail -20
```

<br>

### Check the Controller Manager and Scheduler

```bash
kubectl get componentstatuses   # deprecated but still works
kubectl get --raw /readyz?verbose
```

<br>

> Understand that the **kubelet** is the only component that runs as a systemd service. Everything else on the control plane runs as a static Pod.

---
layout: section
---

# Hands-On Labs

Time to build your cluster!

---

# Lab Overview

<br>

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

<br>

### Create an nginx Pod

```bash
kubectl run nginx --image=nginx:latest --port=80
```

<br>

### Verify It's Running

```bash
kubectl get pods -o wide
kubectl describe pod nginx
kubectl logs nginx
```

<br>

### Expose It

```bash
kubectl expose pod nginx --type=NodePort --port=80
kubectl get svc nginx
```

<br>

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
