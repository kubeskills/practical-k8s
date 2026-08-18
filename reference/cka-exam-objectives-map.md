# CKA Exam Objectives → Course Map

Maps every objective in the official [CKA Exam Curriculum v1.35](https://github.com/cncf/curriculum/blob/master/CKA_Curriculum_v1.35.pdf) (Cloud Native Computing Foundation) to where it's covered in this course. Objective wording is verbatim from the CNCF curriculum.

Students preparing for the [Certified Kubernetes Administrator](https://www.cncf.io/training/certification/cka/) exam can use this to find the lab or slide section for a given topic, and to see at a glance what falls outside this 4-day course and needs additional self-study.

## Domain Weights

| Domain | Weight |
|---|---|
| Troubleshooting | 30% |
| Cluster Architecture, Installation and Configuration | 25% |
| Services and Networking | 20% |
| Workloads and Scheduling | 15% |
| Storage | 10% |

---

## 25% — Cluster Architecture, Installation and Configuration

| Objective | Covered in |
|---|---|
| Manage role based access control (RBAC) | [Day 4 slides — RBAC](../day4/slides.md), [Lab: RBAC and Access Control](../day4/labs/lab1-rbac-and-access-control.md) |
| Prepare underlying infrastructure for installing a Kubernetes cluster | [Lab: Provisioning the Cluster](../day1/labs/lab1-provisioning-the-cluster.md) |
| Create and manage Kubernetes clusters using kubeadm | [Lab: kubeadm Cluster Initialization](../day1/labs/lab2-kubeadm-cluster-initialization.md) |
| Manage the lifecycle of Kubernetes clusters | [Lab: Cluster Upgrade](../day4/labs/lab4-cluster-upgrade.md), [Lab: etcd Backup and Restore](../day4/labs/lab5-etcd-backup-and-restore.md), [Lab: Multi-Node Cluster Operations](../day4/labs/lab2-multi-node-cluster-operations.md) |
| Implement and configure a highly-available control plane | Day 4 slides — HA control plane concepts (join `--control-plane`, stacked etcd) |
| Use Helm and Kustomize to install cluster components | Helm — [Lab: Monitoring with Prometheus and Grafana](../day4/labs/lab3-monitoring-setup.md) (kube-prometheus-stack). **Kustomize is not covered in this course** — self-study needed |
| Understand extension interfaces (CNI, CSI, CRI, etc.) | [Lab: CNI Plugin Installation](../day1/labs/lab3-cni-plugin-installation.md) (Calico); containerd (CRI) in [Lab: kubeadm Cluster Initialization](../day1/labs/lab2-kubeadm-cluster-initialization.md); CSI/StorageClass in [Day 3 — storageclass-linode.yaml](../day3/manifests/storageclass-linode.yaml) |
| Understand CRDs, install and configure operators | Gateway API CRDs in Day 3 slides; Prometheus Operator + `PrometheusRule` CRD in [Lab: Monitoring with Prometheus and Grafana](../day4/labs/lab3-monitoring-setup.md) |

## 20% — Services and Networking

| Objective | Covered in |
|---|---|
| Understand connectivity between Pods | [Lab: CNI Plugin Installation](../day1/labs/lab3-cni-plugin-installation.md), [Lab: Services and DNS](../day3/labs/lab1-services-and-dns.md) |
| Define and enforce Network Policies | Day 3 manifests — [netpol-allow-frontend.yaml](../day3/manifests/netpol-allow-frontend.yaml), [netpol-deny-all-ingress.yaml](../day3/manifests/netpol-deny-all-ingress.yaml), [netpol-deny-all-egress.yaml](../day3/manifests/netpol-deny-all-egress.yaml) |
| Use ClusterIP, NodePort, LoadBalancer service types and endpoints | [Lab: Services and DNS](../day3/labs/lab1-services-and-dns.md), [Lab: NodePort and LoadBalancer](../day3/labs/lab2-nodeport-and-loadbalancer.md), [Lab: Expose the Application](../day2/labs/lab3-expose-the-application.md) |
| Use the Gateway API to manage Ingress traffic | Day 3 slides — Gateway API, [gatewayclass-nginx.yaml](../day3/manifests/gatewayclass-nginx.yaml), [gateway-prod.yaml](../day3/manifests/gateway-prod.yaml), [httproute-web.yaml](../day3/manifests/httproute-web.yaml) |
| Know how to use Ingress controllers and Ingress resources | [Lab: Ingress](../day3/labs/lab6-ingress.md) |
| Understand and use CoreDNS | [Lab: Services and DNS](../day3/labs/lab1-services-and-dns.md); DNS troubleshooting in [Lab: Namespaces in Practice](../day2/labs/lab7-namespaces-in-practice.md) |

## 15% — Workloads and Scheduling

| Objective | Covered in |
|---|---|
| Understand application deployments and how to perform rolling update and rollbacks | [Lab: Rolling Updates and Rollbacks](../day2/labs/lab2-rolling-updates-and-rollbacks.md) |
| Use ConfigMaps and Secrets to configure applications | [Lab: ConfigMaps and Secrets](../day2/labs/lab4-configmaps-and-secrets.md) |
| Configure workload autoscaling | Day 2 slides — Horizontal Pod Autoscaler, [hpa-nginx.yaml](../day2/manifests/hpa-nginx.yaml) |
| Understand the primitives used to create robust, self-healing, application deployments | [Lab: Deploy a Multi-Replica Application](../day2/labs/lab1-deploy-multi-replica.md), [Lab: Health Checks](../day2/labs/lab5-health-checks.md), [Lab: DaemonSet and CronJob](../day3/labs/lab4-daemonset-and-cronjob.md) |
| Configure Pod admission and scheduling (limits, node affinity, etc.) | [Lab: Scheduling](../day3/labs/lab3-scheduling.md) (taints/tolerations, node affinity); resource limits in [Lab: Deploy a Multi-Replica Application](../day2/labs/lab1-deploy-multi-replica.md); Pod Security Standards / admission in Day 4 slides |

## 10% — Storage

| Objective | Covered in |
|---|---|
| Implement storage classes and dynamic volume provisioning | [Lab: Persistent Storage](../day3/labs/lab5-persistent-storage.md), [storageclass-linode.yaml](../day3/manifests/storageclass-linode.yaml) |
| Configure volume types, access modes and reclaim policies | [Lab: Persistent Storage](../day3/labs/lab5-persistent-storage.md), [pv-manual.yaml](../day3/manifests/pv-manual.yaml) |
| Manage persistent volumes and persistent volume claims | [Lab: Persistent Storage](../day3/labs/lab5-persistent-storage.md), [pvc-manual.yaml](../day3/manifests/pvc-manual.yaml), [pvc-app-storage.yaml](../day3/manifests/pvc-app-storage.yaml) |

## 30% — Troubleshooting

| Objective | Covered in |
|---|---|
| Troubleshoot clusters and nodes | [Lab: Cluster Validation](../day1/labs/lab4-cluster-validation.md), [Lab: Multi-Node Cluster Operations](../day4/labs/lab2-multi-node-cluster-operations.md) |
| Troubleshoot cluster components | [Lab: Exploring Core Components](../day1/labs/lab5-exploring-core-components.md) (etcd, static pods, certificates, kubelet) |
| Monitor cluster and application resource usage | `kubectl top`, [Lab: Monitoring with Prometheus and Grafana](../day4/labs/lab3-monitoring-setup.md) |
| Manage and evaluate container output streams | [Lab: Troubleshoot a Broken Pod](../day2/labs/lab6-troubleshoot-broken-pod.md), [Lab: Onboard a Pod](../day1/labs/lab6-onboard-a-pod.md) (`kubectl logs`, `exec`) |
| Troubleshoot services and networking | [Lab: Namespaces in Practice](../day2/labs/lab7-namespaces-in-practice.md) (cross-namespace DNS), Day 4 slides — systematic troubleshooting for pods/nodes/networking |

---

## Not Covered in This Course

A few CKA objectives fall outside this course's scope and need dedicated self-study:

- **Kustomize** — the course covers Helm for installing cluster components, but not Kustomize overlays/patches.
- **Writing/authoring CRDs and operators** — the course installs and uses operators (Prometheus Operator, Gateway API CRDs) but doesn't cover authoring a CRD or operator from scratch.

See the [Kubernetes from Scratch course](https://community.kubeskills.com/c/kubernetes-from-scratch) on KubeSkills for a deeper dive into these and other advanced topics (cluster internals, controllers, operators).
