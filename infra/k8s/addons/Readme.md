# Metrics Server

Metrics Server is deployed as a Kubernetes addon.

## Installation

```bash
kubectl apply -f components.yaml
```

## TLS Configuration  |  NOT RECOMMENDED FOR PRODUCTION

The Metrics Server Deplyment is configured with:

```yaml
- --kubelet-insecure-tls
```

This is used because the kubelet serving certificates in this lab cluster do not contain the nodes' InternalIP addresses in their Subject Alternative Names (SANs).

This disables certificate verification between Metrics Server and kubelet and is therefore intended only for this lab environment.

## NGINX Ingress Controller

The cluster uses the NGINX Ingress Controller to handle external HTTP/HTTPS traffic.

The controller is deployed using the official `baremetal` provider manifest because this is a self-managed Kubernetes cluster running on bare-metal/libvirt rather than a cloud environment with a managed LoadBalancer.

The manifest is pinned to:

```text
ingress-nginx controller v1.11.2
```

### Why Bare-Metal?

Cloud Kubernetes environments can provision a `LoadBalancer` automatically. This cluster does not have a cloud LoadBalancer integration.

Therefore, the Ingress Controller is exposed through a `NodePort`.

Current ports:

The Ingress Controller is exposed through NodePort.

The assigned NodePorts can be checked with:

```bash
kubectl get svc ingress-nginx-controller -n ingress-nginx
```

### Deployment

```bash
kubectl apply -f ingress-controller.yaml
```

Verify:

```bash
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

Expected controller Service:

```text
ingress-nginx-controller   NodePort
```

### Architecture

```text
External Client
      │
      ▼
NodePort
      │
      ▼
NGINX Ingress Controller
      │
      ▼
Ingress Resource
      │
      ▼
Application Service
```

The application-specific Ingress configuration is maintained separately under:

```text
../ingress/
```
