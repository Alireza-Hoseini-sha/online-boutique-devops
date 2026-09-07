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