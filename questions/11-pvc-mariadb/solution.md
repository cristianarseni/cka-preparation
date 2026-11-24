# Question 11 — Solution

## 1. Inspect the retained PV first

```
k get pv
```

This is the step that decides whether the question passes. A PVC does **not**
simply take any PV — it binds to one whose attributes match. Note three things:

- **capacity** — `250Mi`
- **storageClassName** — `standard`
- **access mode** — `ReadWriteOnce`

Your PVC must ask for values compatible with all three, or it sits in
**Pending** forever and the Deployment never starts.

```
k get pv mariadb-pv -o yaml
```

## 2. Create the PVC to match

```
vim pvc.yaml
```

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mariadb
  namespace: mariadb
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 250Mi
  storageClassName: standard
  volumeName: mariadb-pv
```

```
k apply -f pvc.yaml
```

`volumeName` names the PV explicitly. The task says you *must* use the existing
retained PV, and this removes any doubt — without it, a default StorageClass
could dynamically provision a brand new volume instead, which still "works" and
still scores zero.

## 3. Confirm the bind before going further

```
k get pvc -n mariadb
```

STATUS must be **Bound** and VOLUME must be **mariadb-pv**. Do not move on while
it says Pending — fix the PVC first.

## 4. Edit and apply the Deployment

```
vim ~/mariadb-deployment.yaml
```

Under `spec.template.spec.volumes`, set the claim name:

```yaml
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: mariadb
```

```
k apply -f ~/mariadb-deployment.yaml
```

## 5. Verify

```
k rollout status deploy mariadb -n mariadb
k get pods -n mariadb -o wide
k logs -n mariadb -l app=mariadb --tail=20
```

The logs are the real proof: MariaDB printing **ready for connections** means it
opened the data directory on the retained volume successfully.

---

## Why `storageClassName` matters so much here

If you leave `storageClassName` out of the PVC, Kubernetes applies the
**default** StorageClass. Your PV has class `standard`; if the cluster's default
is something else, the classes do not match, and the PVC either provisions a new
empty volume or stays Pending. Either way the retained data is gone — which is
the entire point of the question.

Rule of thumb for "use the existing PV" tasks: read the PV first, copy its
capacity, access mode and storage class into the PVC, and name it with
`volumeName`.

## What "Retain" means

`persistentVolumeReclaimPolicy: Retain` is why this PV still exists. With
`Delete` (the usual default for dynamically provisioned volumes), deleting the
PVC destroys the underlying volume and its data. `Retain` keeps both, so the
volume outlives the claim and can be re-bound later — exactly the situation this
question drops you into.
