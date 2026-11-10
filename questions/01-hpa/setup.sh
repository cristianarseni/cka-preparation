#!/usr/bin/env bash
# Question 1 - HPA : prepare the cluster
set -uo pipefail

echo "[setup] Question 1 - HPA"

# Clean start: remove an HPA left over from a previous attempt
kubectl -n autoscale delete hpa apache-server --ignore-not-found >/dev/null 2>&1

kubectl create namespace autoscale --dry-run=client -o yaml | kubectl apply -f - >/dev/null

kubectl apply -f - >/dev/null <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: apache-server
  namespace: autoscale
  labels:
    app: apache-server
spec:
  replicas: 1
  selector:
    matchLabels:
      app: apache-server
  template:
    metadata:
      labels:
        app: apache-server
    spec:
      containers:
      - name: httpd
        image: httpd:2.4-alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 100m
            memory: 64Mi
          limits:
            cpu: 200m
            memory: 128Mi
EOF

# metrics-server is NOT required to create or validate the HPA object,
# but without it the HPA shows <unknown> in the TARGETS column.
if ! kubectl get deploy metrics-server -n kube-system >/dev/null 2>&1; then
  echo "[setup] installing metrics-server (optional, so TARGETS is not <unknown>)"
  kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml >/dev/null 2>&1 \
    && kubectl -n kube-system patch deploy metrics-server --type=json \
       -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]' >/dev/null 2>&1 \
    || echo "[setup] metrics-server could not be installed - the task still works"
fi

kubectl -n autoscale rollout status deploy apache-server --timeout=90s

echo "[setup] ready"
