# Architecture — Online Boutique

## Overview

Online Boutique is a sample e-commerce application composed of 11 microservices. Each service is written in a different language to demonstrate that Kubernetes can run any technology stack. Services communicate with each other over gRPC.

## Services

| Service | Language | Role |
|---|---|---|
| frontend | Go | Web UI, the only service exposed externally |
| productcatalogservice | Go | Stores and serves the product list |
| cartservice | C# | Manages the shopping cart, backed by Redis |
| checkoutservice | Go | Orchestrates the checkout flow, calls payment/shipping/email services |
| paymentservice | Node.js | Simulates payment processing |
| shippingservice | Go | Calculates shipping cost and delivery time |
| emailservice | Python | Sends order confirmation emails |
| currencyservice | C++/Node | Converts prices between currencies |
| recommendationservice | Python | Suggests related products |
| adservice | Java | Serves product-related ads |
| loadgenerator | Python | Generates synthetic traffic to simulate real users |

## Data Store

- **Redis** is the only datastore in the project, used exclusively by `cartservice` to persist users' shopping carts.

## Communication

- All internal service-to-service communication happens over **gRPC**.
- Only `frontend` is exposed externally (via `minikube service` in this setup).
- Every other service is reachable only through the cluster's internal DNS (`ClusterIP`).

## Request Flow (example: viewing the homepage)

```
User → frontend → productcatalogservice (product list)
                → recommendationservice (suggestions)
                → adservice (ads)
                → currencyservice (price display in selected currency)
```

## Request Flow (example: completing checkout)

```
User → frontend → checkoutservice
                     ├── cartservice (reads cart from Redis)
                     ├── paymentservice
                     ├── shippingservice
                     └── emailservice
```

## Notes

- [Add your own notes here after running the app — e.g. how long it took pods to reach Running, any errors encountered]
