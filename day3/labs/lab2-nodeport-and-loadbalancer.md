# Lab 2: NodePort and LoadBalancer

## Objective

Expose a Deployment to external traffic using a NodePort Service, then upgrade to a LoadBalancer Service backed by the Linode Cloud Controller Manager (CCM).

## Background

**NodePort** opens a static port (30000–32767) on every node. Traffic arriving at `<any-node-ip>:<nodeport>` is forwarded to the Service. It works without a cloud provider but is not suitable for production external traffic.

**LoadBalancer** extends NodePort by also provisioning an external load balancer (on Linode, a NodeBalancer) and assigning it a public IP. The **Linode CCM** watches for `LoadBalancer` Service objects and automates this provisioning.

## Prerequisites

- The Deployment from Lab 1 (`web`) must be running. If not, recreate it:
  ```bash
  kubectl create deployment k8sapp --image=chadmcrowell/nginx-for-k8s:v2 --replicas=3
  ```

## Steps

### 1. Create a NodePort Service

```bash
kubectl expose deployment k8sapp --port=80 --type=NodePort --name=web-nodeport
kubectl get svc web-nodeport
```

The output shows the assigned node port:

```
NAME           TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
web-nodeport   NodePort   10.96.x.x      <none>        80:30xxx/TCP   10s
```

Test from outside the cluster using any node's IP and the node port shown:

```bash
curl http://<any-node-ip>:<nodeport>
```

> You can find node IPs with `kubectl get nodes -o wide`.

### 2. Create a LoadBalancer Service (Linode CCM)

```bash
kubectl expose deployment k8sapp --port=80 --type=LoadBalancer --name=web-lb
```

Watch for the external IP to be assigned (this takes about 60 seconds as the CCM provisions a NodeBalancer):

```bash
kubectl get svc web-lb -w
```

Once the `EXTERNAL-IP` column shows an IP address instead of `<pending>`, test it:

```bash
curl http://<external-ip>
```

> If the IP stays `<pending>` for more than 2 minutes, check CCM logs:
> `kubectl logs -n kube-system -l app=linode-ccm`

### 3. Inspect the Service

```bash
kubectl describe svc web-lb
```

Notice the `LoadBalancer Ingress` field — this is the public IP assigned by Linode. Also note that a NodePort is still assigned; the load balancer forwards to it internally.

## How the Linode CCM Works

When you create a `LoadBalancer` Service:

1. The CCM detects the new Service via the Kubernetes API
2. It calls the Linode API to create a **NodeBalancer**
3. It adds each cluster node as a backend on the NodeBalancer
4. It writes the NodeBalancer's public IP back to the Service's `status.loadBalancer.ingress`

Deleting the Service triggers the CCM to delete the NodeBalancer automatically.

## Troubleshooting

| Problem | Check |
|---------|-------|
| NodePort not reachable | Check node firewall rules; the node port must be open externally |
| External IP stuck at `<pending>` | `kubectl logs -n kube-system -l app=linode-ccm` |
| External IP assigned but curl fails | Check security group / firewall on the Linode nodes |

## Clean Up

```bash
kubectl delete svc web-nodeport web-lb
```
