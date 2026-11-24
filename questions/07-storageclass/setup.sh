#!/usr/bin/env bash
# Question 7 - StorageClass : prepare the cluster
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../../lib/common.sh"

echo "[setup] Question 7 - StorageClass"

# The student has to create 'local-path' themselves, so make sure it is absent.
kubectl delete storageclass local-path --ignore-not-found >/dev/null 2>&1

# An existing default StorageClass, so that making local-path the default
# actually requires taking the flag off this one.
kubectl apply -f - >/dev/null <<'EOF'
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: legacy-standard
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: rancher.io/local-path
reclaimPolicy: Delete
volumeBindingMode: Immediate
EOF

# An existing Deployment and PVC that the task says must NOT be modified.
kubectl create namespace sc-workload --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl apply -f - >/dev/null <<'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: archive-data
  namespace: sc-workload
spec:
  accessModes: ["ReadWriteOnce"]
  storageClassName: legacy-standard
  resources:
    requests:
      storage: 100Mi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: archive
  namespace: sc-workload
spec:
  replicas: 1
  selector:
    matchLabels: {app: archive}
  template:
    metadata:
      labels: {app: archive}
    spec:
      containers:
      - name: archive
        image: busybox:stable
        command: ["sh","-c","sleep 86400"]
        volumeMounts:
        - name: data
          mountPath: /data
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: archive-data
EOF

# Baseline, so validate can prove they were left alone.
{
  kubectl get pvc archive-data -n sc-workload -o jsonpath='{.spec.storageClassName}|{.spec.resources.requests.storage}'
  echo
  kubectl get deploy archive -n sc-workload -o jsonpath='{.metadata.generation}'
  echo
} > "$STATE_DIR/07-storageclass.state" 2>/dev/null

echo "[setup] existing StorageClasses:"
kubectl get storageclass
echo "[setup] ready"
