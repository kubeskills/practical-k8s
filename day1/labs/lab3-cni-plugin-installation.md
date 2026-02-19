# Lab 3: CNI Plugin Installation

## Objective

Install the Calico CNI plugin to provide pod networking, and verify that all nodes transition from `NotReady` to `Ready`.

## Background

After `kubeadm init`, the cluster is running but the nodes show `NotReady`. This is because Kubernetes does not ship with a built-in network plugin — it delegates pod networking to a **CNI (Container Network Interface)** plugin.

The CNI plugin is responsible for:
- Assigning an IP address to every pod
- Setting up routing so pods on different nodes can communicate
- Enforcing Network Policies (depending on the plugin)

Without a CNI plugin, pods cannot be created on worker nodes and the `coredns` pods will remain `Pending`.

### Why Calico?

| Feature | Calico |
|---------|--------|
| Pod networking | ✓ (BGP or VXLAN) |
| Network Policy enforcement | ✓ |
| Performance | High (eBPF dataplane available) |
| Cloud support | All major providers |
| Used in production | Widely |

Calico is configured to use `192.168.0.0/16` as the pod CIDR — this is why we passed `--pod-network-cidr=192.168.0.0/16` to `kubeadm init` in Lab 2.

## Steps

### 1. Install Calico

Run on the **control plane node**:

```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml
```

This creates:
- A `calico-system` (or `kube-system`) namespace with Calico's components
- A DaemonSet (`calico-node`) that runs one pod per node to handle networking
- A Deployment (`calico-kube-controllers`) that manages network policy and IPAM

### 2. Watch Nodes Become Ready

```bash
kubectl get nodes -w
```

Within 1–2 minutes you should see all nodes transition to `Ready`:

```
NAME       STATUS     ROLES           AGE   VERSION
cp         NotReady   control-plane   10m   v1.34.x
worker-1   NotReady   <none>          6m    v1.34.x
worker-2   NotReady   <none>          5m    v1.34.x
cp         Ready      control-plane   11m   v1.34.x
worker-1   Ready      <none>          7m    v1.34.x
worker-2   Ready      <none>          6m    v1.34.x
```

Press `Ctrl+C` once all nodes show `Ready`.

### 3. Verify Calico Pods Are Running

```bash
kubectl get pods -n kube-system -l k8s-app=calico-node
```

You should see one `calico-node` pod per node, all in `Running` state.

### 4. Verify CoreDNS Is Now Running

CoreDNS was `Pending` before the CNI was installed (it couldn't get a pod IP). Check that it's now running:

```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns
```

Both CoreDNS pods should be `Running` and `1/1 READY`.

## How Calico Works

When a pod is scheduled on a node:

1. The kubelet calls the Calico CNI plugin via the CNI interface
2. Calico assigns an IP from the pod CIDR (`192.168.0.0/16`)
3. Calico creates a virtual network interface (veth pair) connecting the pod to the node
4. Calico programs BGP routes (or VXLAN tunnels) so pods on other nodes are reachable
5. iptables rules are installed to enforce any NetworkPolicy resources

## Troubleshooting

| Problem | Check |
|---------|-------|
| Nodes still `NotReady` after 2 minutes | `kubectl describe node <name>` — look for a `NetworkPluginNotReady` condition |
| `calico-node` pods in `CrashLoopBackOff` | CIDR mismatch — ensure `kubeadm init` used `--pod-network-cidr=192.168.0.0/16` |
| CoreDNS still `Pending` after Calico | Calico not fully ready yet — wait another minute and check `calico-node` pod logs |
| `kubectl apply` fails on the manifest URL | Network issue on the control plane — check internet connectivity with `curl -I https://raw.githubusercontent.com` |
