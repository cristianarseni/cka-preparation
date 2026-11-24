#!/usr/bin/env bash
# Question 12 - Migrate Ingress to Gateway API : prepare the cluster
set -uo pipefail
echo "[setup] Question 12 - Migrate Ingress to Gateway API"

NS=default
HOST=gateway.web.k8s.local

command -v openssl >/dev/null 2>&1 || { echo "[setup] ERROR: openssl is required."; exit 1; }

# --- Gateway API CRDs ---------------------------------------------------------
if kubectl get crd gateways.gateway.networking.k8s.io >/dev/null 2>&1; then
  echo "[setup] Gateway API CRDs are already installed"
else
  echo "[setup] installing the Gateway API CRDs..."
  OK=no
  for V in v1.2.1 v1.1.0 v1.0.0; do
    URL="https://github.com/kubernetes-sigs/gateway-api/releases/download/${V}/standard-install.yaml"
    if kubectl apply -f "$URL" >/dev/null 2>&1; then
      echo "[setup] applied Gateway API $V"; OK=yes; break
    fi
  done
  [ "$OK" = no ] && { echo "[setup] ERROR: could not download the Gateway API CRDs (no internet?)"; exit 1; }
fi

# --- the GatewayClass the task says is installed ------------------------------
kubectl apply -f - >/dev/null <<'EOF'
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: nginx
spec:
  controllerName: gateway.nginx.org/nginx-gateway-controller
EOF

# --- reset anything from a previous attempt -----------------------------------
kubectl delete gateway web-gateway --ignore-not-found >/dev/null 2>&1
kubectl delete httproute web-route --ignore-not-found >/dev/null 2>&1

# --- the app and the Ingress being migrated -----------------------------------
TMP=$(mktemp -d)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout "$TMP/tls.key" -out "$TMP/tls.crt" \
  -subj "/CN=$HOST" -addext "subjectAltName=DNS:$HOST" >/dev/null 2>&1
kubectl delete secret web-tls --ignore-not-found >/dev/null 2>&1
kubectl create secret tls web-tls --cert="$TMP/tls.crt" --key="$TMP/tls.key" >/dev/null
rm -rf "$TMP"

kubectl apply -f - >/dev/null <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata: {name: web}
spec:
  replicas: 1
  selector: {matchLabels: {app: web}}
  template:
    metadata: {labels: {app: web}}
    spec:
      containers:
      - name: nginx
        image: nginx:alpine-slim
        ports: [{containerPort: 80}]
---
apiVersion: v1
kind: Service
metadata: {name: web}
spec:
  selector: {app: web}
  ports: [{port: 80, targetPort: 80, protocol: TCP}]
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web
spec:
  ingressClassName: nginx
  tls:
  - hosts: ["gateway.web.k8s.local"]
    secretName: web-tls
  rules:
  - host: gateway.web.k8s.local
    http:
      paths:
      - path: /
        pathType: PathPrefix
        backend:
          service:
            name: web
            port:
              number: 80
EOF

kubectl rollout status deploy web --timeout=120s

echo
echo "[setup] the Ingress you are migrating:"
kubectl get ingress web
echo
kubectl get gatewayclass
echo "[setup] ready"
