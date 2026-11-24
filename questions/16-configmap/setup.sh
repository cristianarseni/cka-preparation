#!/usr/bin/env bash
# Question 16 - ConfigMap : prepare the cluster
set -uo pipefail
echo "[setup] Question 16 - ConfigMap (TLS)"

NS=nginx-static
HOSTNAME=web.k8snginx.local

command -v openssl >/dev/null 2>&1 || { echo "[setup] ERROR: openssl is required but not installed."; exit 1; }

# This Pod binds port 443 on the node, so nothing else may hold it.
if kubectl get deploy ingress-nginx-controller -n ingress-nginx >/dev/null 2>&1; then
  echo "[setup] scaling ingress-nginx to 0 - it holds ports 80/443 on the node"
  echo "[setup] (question 2's setup scales it back up)"
  kubectl -n ingress-nginx scale deploy ingress-nginx-controller --replicas=0 >/dev/null 2>&1
  sleep 3
fi

kubectl create namespace $NS --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl -n $NS delete configmap nginx-config --ignore-not-found >/dev/null 2>&1
kubectl -n $NS delete deploy nginx-static --ignore-not-found >/dev/null 2>&1

TMP=$(mktemp -d)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout "$TMP/tls.key" -out "$TMP/tls.crt" \
  -subj "/CN=$HOSTNAME" -addext "subjectAltName=DNS:$HOSTNAME" >/dev/null 2>&1

kubectl -n $NS delete secret nginx-tls --ignore-not-found >/dev/null 2>&1
kubectl -n $NS create secret tls nginx-tls --cert="$TMP/tls.crt" --key="$TMP/tls.key" >/dev/null
rm -rf "$TMP"

# Note: ssl_protocols allows ONLY TLSv1.3 right now - that is what you must change.
kubectl apply -f - >/dev/null <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
  namespace: nginx-static
data:
  nginx.conf: |
    events {}
    http {
        server {
            listen 443 ssl;
            server_name web.k8snginx.local;

            ssl_certificate     /etc/nginx/tls/tls.crt;
            ssl_certificate_key /etc/nginx/tls/tls.key;

            ssl_protocols TLSv1.3;

            location / {
                return 200 "nginx-static ok\n";
            }
        }
    }
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: nginx-static, namespace: nginx-static}
spec:
  replicas: 1
  selector: {matchLabels: {app: nginx-static}}
  template:
    metadata: {labels: {app: nginx-static}}
    spec:
      hostNetwork: true
      dnsPolicy: ClusterFirstWithHostNet
      containers:
      - name: nginx
        image: nginx:alpine
        ports: [{containerPort: 443}]
        volumeMounts:
        - {name: config, mountPath: /etc/nginx/nginx.conf, subPath: nginx.conf}
        - {name: tls,    mountPath: /etc/nginx/tls, readOnly: true}
      volumes:
      - name: config
        configMap: {name: nginx-config}
      - name: tls
        secret: {secretName: nginx-tls}
EOF

kubectl -n $NS rollout status deploy nginx-static --timeout=150s

NODE=$(kubectl get pods -n $NS -l app=nginx-static -o jsonpath='{.items[0].spec.nodeName}' 2>/dev/null)
IP=$(kubectl get node "$NODE" -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null)
if [ -n "$IP" ]; then
  sed -i "/[[:space:]]${HOSTNAME}\$/d" /etc/hosts 2>/dev/null
  echo "$IP $HOSTNAME" >> /etc/hosts 2>/dev/null \
    && echo "[setup] /etc/hosts: $HOSTNAME -> $IP" \
    || echo "[setup] WARNING: could not write /etc/hosts. Add:  $IP $HOSTNAME"
fi

echo
echo "[setup] current behaviour (TLSv1.2 is refused, TLSv1.3 works):"
echo -n "  --tls-max 1.2 -> "; curl -k -o /dev/null -s -w '%{http_code}\n' --tls-max 1.2 --max-time 6 "https://$HOSTNAME" || echo "refused"
echo -n "  --tls-max 1.3 -> "; curl -k -o /dev/null -s -w '%{http_code}\n' --tls-max 1.3 --max-time 6 "https://$HOSTNAME" || echo "refused"
echo "[setup] ready"
