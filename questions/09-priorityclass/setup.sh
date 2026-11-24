#!/usr/bin/env bash
# Question 9 - PriorityClass : prepare the cluster
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../../lib/common.sh"

echo "[setup] Question 9 - PriorityClass"

kubectl delete priorityclass high-priority --ignore-not-found >/dev/null 2>&1

kubectl apply -f - >/dev/null <<'EOF'
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata: {name: low-priority}
value: 100000
globalDefault: false
description: "low priority for background jobs"
---
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata: {name: medium-priority}
value: 500000
globalDefault: false
description: "normal user workloads"
---
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata: {name: platform-critical}
value: 1000000000
globalDefault: false
description: "highest user-defined priority"
EOF

kubectl create namespace priority --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl apply -f - >/dev/null <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata: {name: busybox-logger, namespace: priority}
spec:
  replicas: 1
  selector: {matchLabels: {app: busybox-logger}}
  template:
    metadata: {labels: {app: busybox-logger}}
    spec:
      containers:
      - name: busybox
        image: busybox:stable
        command: ["sh","-c","while true; do echo logging; sleep 10; done"]
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: metrics-collector, namespace: priority}
spec:
  replicas: 1
  selector: {matchLabels: {app: metrics-collector}}
  template:
    metadata: {labels: {app: metrics-collector}}
    spec:
      containers:
      - name: busybox
        image: busybox:stable
        command: ["sh","-c","sleep 86400"]
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: log-shipper, namespace: priority}
spec:
  replicas: 1
  selector: {matchLabels: {app: log-shipper}}
  template:
    metadata: {labels: {app: log-shipper}}
    spec:
      containers:
      - name: busybox
        image: busybox:stable
        command: ["sh","-c","sleep 86400"]
EOF

for d in busybox-logger metrics-collector log-shipper; do
  kubectl -n priority rollout status deploy $d --timeout=90s
done

# baseline for the "do not modify other Deployments" rule
{
  kubectl get deploy metrics-collector -n priority -o jsonpath='{.metadata.generation}'; echo
  kubectl get deploy log-shipper       -n priority -o jsonpath='{.metadata.generation}'; echo
} > "$STATE_DIR/09-priorityclass.state" 2>/dev/null

echo
echo "[setup] existing PriorityClasses:"
kubectl get priorityclass
echo "[setup] ready"
