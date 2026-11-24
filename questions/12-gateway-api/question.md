# Question 12 — Migrate Ingress to Gateway API

## Task

Migrate an existing web application from Ingress to Gateway API. You must
maintain HTTPS access.

> **Note:** A GatewayClass named `nginx` is installed in the cluster.

First, create a Gateway named `web-gateway` with the host name
`gateway.web.k8s.local` and maintain the existing TLS and listener
configurations of the existing Ingress resource named `web`.

Next, create an HTTPRoute named `web-route` with the host name
`gateway.web.k8s.local` that maintains the existing configuration from the
existing Ingress resource named `web`.

Finally, delete the existing Ingress resource named `web`.
