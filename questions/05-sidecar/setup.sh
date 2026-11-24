#!/usr/bin/env bash
# Question 5 - Sidecar : prepare the cluster
set -uo pipefail
echo "[setup] Question 5 - Sidecar"

kubectl delete deploy synergy-leverager --ignore-not-found >/dev/null 2>&1

# The legacy app: writes to a log file instead of stdout, which is the whole
# reason a streaming sidecar is needed.
kubectl apply -f - >/dev/null <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: synergy-leverager
  labels:
    app: synergy-leverager
spec:
  replicas: 1
  selector:
    matchLabels:
      app: synergy-leverager
  template:
    metadata:
      labels:
        app: synergy-leverager
    spec:
      containers:
      - name: monitor
        image: busybox:stable
        env:
        - name: LOG_FILENAME
          value: /var/log/synergy-leverager.log
        command: ["/bin/sh", "-c"]
        args:
        - 'i=0; while true; do i=$((i+1)); echo "$(date -Iseconds) synergy-leverager event $i" >> "$LOG_FILENAME"; sleep 5; done'
        ports:
        - containerPort: 80
          name: http
          protocol: TCP
EOF

kubectl rollout status deploy synergy-leverager --timeout=120s
echo "[setup] ready - the app is writing to /var/log/synergy-leverager.log inside the container"
