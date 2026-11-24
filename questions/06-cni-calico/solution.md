# Question 6 — Solution

## The decision the question is really testing

You are offered Flannel **or** Calico, and the Context says the CNI must
**enforce network policies**.

- **Flannel** provides pod networking only. It does **not** implement
  NetworkPolicy — apply a policy on a Flannel cluster and it is silently
  ignored.
- **Calico** does both.

So Calico is the only valid answer. Picking Flannel gives you a cluster that
looks healthy — nodes Ready, Pods running — and still fails the question.

## 1. Download both manifests

```
curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/tigera-operator.yaml
curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/custom-resources.yaml
ls
```

The second file is the one people miss. See step 3.

## 2. Install the operator

```
k create -f tigera-operator.yaml
k get ns
k get all -n tigera-operator
```

## 3. Apply the Installation resource

```
k create -f custom-resources.yaml
```

**This is the step that actually installs Calico.** The operator is only a
controller: it watches for an `Installation` resource and builds Calico when it
finds one. Stop after step 2 and you have a running operator and still no CNI —
nodes stay NotReady, CoreDNS stays Pending, and it looks like the install
failed.

## 4. Watch it come up

```
k get pods -n calico-system -w
```

Press Ctrl+C once `calico-node` and `calico-kube-controllers` are Running. This
takes a few minutes — images are large.

## 5. Verify the cluster recovered

```
k get nodes
k get pods -A
```

Everything must be Ready / Running. CoreDNS is the best signal: it cannot start
without a working CNI, so CoreDNS Running means pod networking is back.

End-to-end proof:

```
k run probe --image=busybox:stable --restart=Never --command -- sh -c "sleep 60"
k get pod probe -o wide          # it should have a POD IP
k exec probe -- nslookup kubernetes.default
k delete pod probe
```

---

## Why `create` and not `apply`

Both work. `kubectl apply` on very large CRD manifests used to fail with a
"metadata.annotations: Too long" error, because apply stores the whole manifest
in an annotation. Calico's CRDs are big enough to hit that. `create` does not
store the annotation, so it avoids the problem. If you see that error after
typing `apply`, switch to `create` rather than assuming the file is broken.

## What NetworkPolicy enforcement means in practice

Kubernetes defines the NetworkPolicy **API** — the objects always validate and
store, whichever CNI you run. Enforcement is entirely up to the CNI. So on
Flannel you can create a deny-all policy, `kubectl get netpol` shows it happily,
and traffic flows through unaffected.

This matters for question 13 too: if its connectivity check warns that a blocked
Pod got through, the first thing to check is which CNI the cluster runs.
