# Question 7 — Solution

## 1. Look at what exists

```
k get sc
```

There is no `local-path` StorageClass, so you have to write one. There *is*
another StorageClass already marked `(default)` — remember that, it matters for
the second half of the task.

## 2. Write the StorageClass

There is no `kubectl create storageclass` command, so this one is YAML. Open the
Kubernetes docs, search **StorageClass**, copy the example, and strip the fields
you do not need:

```
vim sc.yaml
```

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-path
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: rancher.io/local-path
volumeBindingMode: WaitForFirstConsumer
```

```
k apply -f sc.yaml
```

Setting the annotation here does both halves of the task in one go.

## 3. Remove the default flag from the old one

A cluster should have exactly one default. Take the flag off the previous
default:

```
k get sc
k patch sc legacy-standard -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
```

## 4. Verify

```
k get sc
k describe sc local-path
```

Exactly one line should say `(default)`, and it must be `local-path`.

---

## The mistake in your old notes

Your YAML said `name: local-storage`, but the task asks for **`local-path`**.

This is the most expensive kind of mistake on the exam, because everything else
about the object is right — the provisioner, the binding mode, the annotation —
and it still scores zero, since the grader looks up the object by name and finds
nothing. Re-read the name in the task before you apply.

## What WaitForFirstConsumer actually does

- **`Immediate`** — the volume is provisioned as soon as the PVC is created,
  before anything knows which node the Pod will land on. With node-local
  storage, the volume can end up on a node the Pod cannot be scheduled to, and
  the Pod stays Pending forever.
- **`WaitForFirstConsumer`** — provisioning is delayed until a Pod actually uses
  the PVC. The scheduler picks the node first, then the volume is created on
  that node.

That is why a local-path provisioner essentially always wants
`WaitForFirstConsumer`, and why the task warns that any other value loses marks.

## Why you must not touch the existing PVC or Deployment

Changing the default StorageClass only affects **new** PVCs that do not name a
class. PVCs that already exist keep the class they were bound with. If you edit
the existing PVC to "fix" it, you have modified a resource the task told you to
leave alone — the check script compares both against their original state.
