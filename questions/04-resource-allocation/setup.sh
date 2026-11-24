#!/usr/bin/env bash
# Question 4 - Resource allocation : prepare the cluster
set -uo pipefail
echo "[setup] Question 4 - Resource allocation CPU and memory"

kubectl create namespace relative-fawn --dry-run=client -o yaml | kubectl apply -f - >/dev/null

# Clean start: 'kubectl apply' would keep requests added on a previous attempt,
# leaving the task already solved. Delete and wait so the new Pods start bare.
kubectl -n relative-fawn delete deploy wordpress --ignore-not-found --wait=true >/dev/null 2>&1
kubectl -n relative-fawn wait --for=delete pod -l app=wordpress --timeout=60s >/dev/null 2>&1 || true

# Deployed with NO resource requests at all - that is the whole point of the task.
kubectl apply -f - >/dev/null <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress
  namespace: relative-fawn
  labels:
    app: wordpress
spec:
  replicas: 3
  selector:
    matchLabels:
      app: wordpress
  template:
    metadata:
      labels:
        app: wordpress
    spec:
      initContainers:
      - name: init-permissions
        image: busybox:stable
        command: ["sh", "-c", "echo preparing; sleep 2"]
      containers:
      - name: wordpress
        image: httpd:2.4-alpine
        ports:
        - containerPort: 80
EOF

kubectl -n relative-fawn rollout status deploy wordpress --timeout=120s

echo
echo "[setup] Node resources you will have to work with:"
kubectl get nodes -o custom-columns=\
'NAME:.metadata.name,CPU:.status.allocatable.cpu,MEMORY:.status.allocatable.memory,TAINTS:.spec.taints[*].effect'
echo "[setup] ready"
