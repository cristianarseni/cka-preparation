#!/usr/bin/env bash
# Question 13 - NetworkPolicy : prepare the cluster
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../../lib/common.sh"

echo "[setup] Question 13 - NetworkPolicy"

for ns in frontend backend; do
  kubectl create namespace $ns --dry-run=client -o yaml | kubectl apply -f - >/dev/null
done

# remove any policy applied on a previous attempt, keep the default deny
for p in $(kubectl get netpol -n backend -o name 2>/dev/null | grep -v 'default-deny'); do
  kubectl delete -n backend "$p" >/dev/null 2>&1
done

kubectl apply -f - >/dev/null <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata: {name: frontend, namespace: frontend}
spec:
  replicas: 1
  selector: {matchLabels: {app: frontend}}
  template:
    metadata: {labels: {app: frontend}}
    spec:
      containers:
      - name: client
        image: busybox:stable
        command: ["sh","-c","sleep 86400"]
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: backend, namespace: backend}
spec:
  replicas: 1
  selector: {matchLabels: {app: backend}}
  template:
    metadata: {labels: {app: backend}}
    spec:
      containers:
      - name: web
        image: nginx:alpine-slim
        ports: [{containerPort: 80}]
---
apiVersion: v1
kind: Service
metadata: {name: backend, namespace: backend}
spec:
  selector: {app: backend}
  ports: [{port: 80, targetPort: 80, protocol: TCP}]
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: default-deny, namespace: backend}
spec:
  podSelector: {}
  policyTypes: [Ingress, Egress]
EOF

# ------------------------------------------------------------ the sample files
mkdir -p "$HOME/netpol"

cat > "$HOME/netpol/network-policy-1.yaml" <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-all-ingress
  namespace: backend
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - {}
EOF

cat > "$HOME/netpol/network-policy-2.yaml" <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: frontend
      podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 80
EOF

cat > "$HOME/netpol/network-policy-3.yaml" <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-cidr-ingress
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - ipBlock:
        cidr: 0.0.0.0/0
    ports:
    - protocol: TCP
      port: 80
EOF

# checksums, so validate can prove the samples were not edited
( cd "$HOME/netpol" && md5sum network-policy-*.yaml ) > "$STATE_DIR/13-networkpolicy.state" 2>/dev/null

for d in frontend/frontend backend/backend; do
  kubectl -n ${d%%/*} rollout status deploy ${d##*/} --timeout=120s
done

echo
echo "[setup] sample policies in $HOME/netpol:"
ls -1 "$HOME/netpol"
echo "[setup] ready"
