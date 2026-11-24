#!/usr/bin/env bash
# Question 2 - Ingress : prepare the cluster
# This one installs an ingress controller, so it takes a few minutes.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../../lib/common.sh"

CLASS=edge-proxy
NS=sound-repeater

echo "[setup] Question 2 - Ingress  (installs an ingress controller, be patient)"

kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl -n "$NS" delete ingress echo --ignore-not-found >/dev/null 2>&1

kubectl apply -f - >/dev/null <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata: {name: echoserver, namespace: sound-repeater}
spec:
  replicas: 1
  selector: {matchLabels: {app: echoserver}}
  template:
    metadata: {labels: {app: echoserver}}
    spec:
      containers:
      - name: echoserver
        image: ealen/echo-server:latest
        ports: [{containerPort: 80}]
        env:
        - {name: PORT, value: "80"}
---
apiVersion: v1
kind: Service
metadata: {name: echoserver-service, namespace: sound-repeater}
spec:
  selector: {app: echoserver}
  ports:
  - {port: 8080, targetPort: 80, protocol: TCP}
EOF

# ---------------------------------------------------------------- controller
if kubectl get deploy -n ingress-nginx ingress-nginx-controller >/dev/null 2>&1; then
  echo "[setup] ingress-nginx is already installed"
else
  echo "[setup] installing ingress-nginx..."
  INSTALLED=no
  for V in controller-v1.12.1 controller-v1.11.3 controller-v1.10.1; do
    URL="https://raw.githubusercontent.com/kubernetes/ingress-nginx/${V}/deploy/static/provider/baremetal/deploy.yaml"
    if kubectl apply -f "$URL" >/dev/null 2>&1; then
      echo "[setup] applied $V"; INSTALLED=yes; break
    fi
  done
  if [ "$INSTALLED" = no ]; then
    echo "[setup] ERROR: could not download an ingress-nginx manifest."
    echo "[setup] Check the cluster has internet access, then run this again."
    exit 1
  fi
fi

# Run the controller on the node's own network so that plain http://example.org
# (port 80) reaches it, rather than a NodePort in the 30000s.
kubectl -n ingress-nginx patch deploy ingress-nginx-controller --type=strategic -p \
  '{"spec":{"template":{"spec":{"hostNetwork":true,"dnsPolicy":"ClusterFirstWithHostNet"}}}}' >/dev/null 2>&1

# Point the controller at an IngressClass called "edge-proxy" instead of "nginx".
PATCHED=$(kubectl -n ingress-nginx get deploy ingress-nginx-controller -o json | python3 -I -c '
import json, sys
d = json.load(sys.stdin)
c = d["spec"]["template"]["spec"]["containers"][0]
c["args"] = [a for a in c.get("args", []) if not a.startswith("--ingress-class=")]
c["args"].append("--ingress-class='"$CLASS"'")
print(json.dumps({"spec":{"template":{"spec":{"containers":[{"name":c["name"],"args":c["args"]}]}}}}))
' 2>/dev/null)
[ -n "$PATCHED" ] && kubectl -n ingress-nginx patch deploy ingress-nginx-controller --type=strategic -p "$PATCHED" >/dev/null 2>&1

kubectl delete ingressclass nginx --ignore-not-found >/dev/null 2>&1
kubectl apply -f - >/dev/null <<EOF
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: $CLASS
spec:
  controller: k8s.io/ingress-nginx
EOF

# question 16 scales this to 0 because it needs port 443 on the node
kubectl -n ingress-nginx scale deploy ingress-nginx-controller --replicas=1 >/dev/null 2>&1

echo "[setup] waiting for the controller to come up..."
kubectl -n ingress-nginx rollout status deploy ingress-nginx-controller --timeout=240s || true

# The admission webhook rejects Ingresses until its certificate job has run.
# In a throwaway practice cluster it is more trouble than it is worth.
kubectl wait --for=condition=complete job -n ingress-nginx -l app.kubernetes.io/component=admission-webhook --timeout=90s >/dev/null 2>&1 \
  || kubectl delete validatingwebhookconfiguration ingress-nginx-admission --ignore-not-found >/dev/null 2>&1

# ------------------------------------------------------------- name resolution
NODE=$(kubectl -n ingress-nginx get pods -l app.kubernetes.io/component=controller \
        -o jsonpath='{.items[0].spec.nodeName}' 2>/dev/null)
IP=$(kubectl get node "$NODE" -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null)
if [ -n "$IP" ]; then
  sed -i '/[[:space:]]example\.org$/d' /etc/hosts 2>/dev/null
  echo "$IP example.org" >> /etc/hosts 2>/dev/null \
    && echo "[setup] /etc/hosts: example.org -> $IP" \
    || echo "[setup] WARNING: could not write /etc/hosts (need root). Add:  $IP example.org"
else
  echo "[setup] WARNING: could not work out the ingress controller's node IP."
fi

echo
kubectl get ingressclass
echo "[setup] ready"
