#!/usr/bin/env bash
# Question 11 - PVC MariaDB : prepare the cluster
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../../lib/common.sh"

echo "[setup] Question 11 - PVC MariaDB"

kubectl create namespace mariadb --dry-run=client -o yaml | kubectl apply -f - >/dev/null
# the Deployment "was deleted by mistake" - and so was any PVC
kubectl -n mariadb delete deploy mariadb --ignore-not-found >/dev/null 2>&1
kubectl -n mariadb delete pvc mariadb --ignore-not-found >/dev/null 2>&1
kubectl delete pv mariadb-pv --ignore-not-found >/dev/null 2>&1
sleep 2

# The retained PV that survived. There is exactly one.
kubectl apply -f - >/dev/null <<'EOF'
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mariadb-pv
  labels:
    cka-prep/question: "11"
spec:
  capacity:
    storage: 250Mi
  accessModes: ["ReadWriteOnce"]
  persistentVolumeReclaimPolicy: Retain
  storageClassName: standard
  hostPath:
    path: /mnt/data/mariadb
    type: DirectoryOrCreate
EOF

# The Deployment manifest the task tells you to edit.
cat > "$HOME/mariadb-deployment.yaml" <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mariadb
  namespace: mariadb
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mariadb
  template:
    metadata:
      labels:
        app: mariadb
    spec:
      containers:
      - name: mariadb
        image: mariadb:10.11
        env:
        - name: MARIADB_ALLOW_EMPTY_ROOT_PASSWORD
          value: "yes"
        ports:
        - containerPort: 3306
        volumeMounts:
        - name: data
          mountPath: /var/lib/mysql
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: CHANGE_ME
EOF

# remember the PV's identity so validate can prove you reused it
kubectl get pv mariadb-pv -o jsonpath='{.metadata.uid}' > "$STATE_DIR/11-pvc-mariadb.state" 2>/dev/null

echo
echo "[setup] the surviving PersistentVolume:"
kubectl get pv
echo
echo "[setup] the Deployment file to edit:  $HOME/mariadb-deployment.yaml"
echo "[setup] ready"
