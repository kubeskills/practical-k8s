# Day 1 — Foundations and Cluster Setup

**Practical Kubernetes Administration and Troubleshooting**

---

## Contents

```
day1/
├── slides.md               # Presentation slides (Slidev)
├── slides/                 # Exported slide PDF
│   └── day1-slides.pdf
├── kubectl-commands.sh     # All commands from the slides, organized by topic
├── labs/                   # Hands-on lab guides
│   ├── README.md
│   ├── lab1-provisioning-the-cluster.md
│   ├── lab2-kubeadm-cluster-initialization.md
│   ├── lab3-cni-plugin-installation.md
│   ├── lab4-cluster-validation.md
│   ├── lab5-exploring-core-components.md
│   └── lab6-onboard-a-pod.md
├── manifests/               # YAML manifests from the slides
│   ├── kubeconfig-example.yaml
│   └── pod-nginx.yaml
└── public/                  # Diagrams and images used in the slides
```

---

## Labs

See [labs/README.md](labs/README.md) for how to use these labs. Work through the labs in order — each lab builds directly on the previous one.

| # | Lab | Topics |
|---|-----|--------|
| 1 | [Provisioning the Cluster](labs/lab1-provisioning-the-cluster.md) | Linode VM setup, hostnames, SSH |
| 2 | [kubeadm Cluster Initialization](labs/lab2-kubeadm-cluster-initialization.md) | Node prep, containerd, kubeadm init, worker join |
| 3 | [CNI Plugin Installation](labs/lab3-cni-plugin-installation.md) | Calico, pod networking, nodes becoming Ready |
| 4 | [Cluster Validation](labs/lab4-cluster-validation.md) | Node status, system pods, DNS test, health endpoints |
| 5 | [Exploring Core Components](labs/lab5-exploring-core-components.md) | etcd, static pods, certificates, kubelet, backup |
| 6 | [Onboard a Pod](labs/lab6-onboard-a-pod.md) | kubectl run, apply, logs, exec, expose, delete |

---

## Manifests

| File | Kind | Description |
|------|------|-------------|
| [kubeconfig-example.yaml](manifests/kubeconfig-example.yaml) | Config | Example kubeconfig structure (reference only, not applied) |
| [pod-nginx.yaml](manifests/pod-nginx.yaml) | Pod | Basic nginx pod for onboarding |

---

## kubectl Commands

All commands from today's slides and labs are collected in [`kubectl-commands.sh`](kubectl-commands.sh), organized by topic:

- Lab 1: Provisioning the cluster (SSH, hostnames)
- Preparing the nodes (swap, kernel modules, sysctl, containerd)
- Installing kubeadm, kubelet, kubectl
- Lab 2: kubeadm cluster initialization, kubectl access, joining workers
- Lab 3: CNI plugin installation (Calico)
- Lab 4: Cluster validation
- Bash autocomplete and alias
- Lab 5: Exploring core components (etcd, certificates, new user)
- Lab 6: Onboard a pod

---

## Reference

See the [Core Reference Pack](../reference/) for printable cheat sheets — kubectl quick reference and the Kubernetes architecture & components overview.
