#!/usr/bin/env bash
# Question 8 - Service : prepare the cluster
set -uo pipefail
echo "[setup] Question 8 - Service"

kubectl create namespace spline-reticulator --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl -n spline-reticulator delete svc front-end-svc --ignore-not-found >/dev/null 2>&1

# Note: the container deliberately declares NO ports - the task asks you to add it.
kubectl apply -f - >/dev/null <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: front-end
  namespace: spline-reticulator
spec:
  replicas: 2
  selector:
    matchLabels: {app: front-end}
  template:
    metadata:
      labels: {app: front-end}
    spec:
      containers:
      - name: nginx
        image: nginx:alpine-slim
EOF

kubectl -n spline-reticulator rollout status deploy front-end --timeout=120s
echo "[setup] ready"
