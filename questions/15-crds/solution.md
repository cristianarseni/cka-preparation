# Question 15 — Solution

## 1. Confirm the CRDs are there

```
k get crd | grep cert-manager.io
```

Six CRDs: `certificates`, `certificaterequests`, `issuers`, `clusterissuers`,
`orders`, `challenges`.

## 2. Save the list — in the default output format

The task is explicit: **kubectl's default output format**. That means the plain
table kubectl prints when you add no `-o` flag at all. Do not add `-o yaml`,
despite the `.yaml` filename.

The clean way is to let kubectl do the filtering with a label selector:

```
k get crd -l app.kubernetes.io/name=cert-manager > /home/candidate/resources.yaml
```

If the CRDs carry no such label, name them explicitly:

```
k get crd certificates.cert-manager.io certificaterequests.cert-manager.io \
          issuers.cert-manager.io clusterissuers.cert-manager.io \
          orders.acme.cert-manager.io challenges.acme.cert-manager.io \
          > /home/candidate/resources.yaml
```

Check what you wrote:

```
cat /home/candidate/resources.yaml
```

The first line should be the `NAME   CREATED AT` header.

## 3. Save the field documentation

```
k explain certificate.spec.subject > /home/candidate/subject.yaml
cat /home/candidate/subject.yaml
```

You should see the description of `subject` plus its sub-fields —
`organizations`, `countries`, `localities`, `organizationalUnits`, and so on. If
the file contains an error instead, the resource name is wrong; check it against
`k get crd`.

---

## About the `grep` shortcut in your old notes

Your notes used:

```
k get crd | grep cert-manager.io > /home/candidate/resources.yaml
```

This mostly works — it is still kubectl's default format, just with the header
line stripped by grep. Two reasons to prefer the kubectl-side filter:

1. The task says *using kubectl*, and `grep` is doing the selecting.
2. `grep` drops the `NAME   CREATED AT` header. A grader comparing against
   `kubectl get crd ...` output sees a different file.

It will probably pass either way, but there is no reason to take the risk when
a selector or an explicit list costs nothing.

## Why `kubectl explain` works on a CRD at all

`kubectl explain` normally reads the built-in API schema. It works here because
a CRD carries an **OpenAPI v3 schema** in its `spec.versions[].schema` — the
same schema the API server uses to validate your YAML. Installing a CRD
therefore teaches `kubectl explain` about a resource that did not exist before.

Worth remembering for the exam: when you meet an unfamiliar custom resource, you
do not need the vendor's website. `k explain <resource>.spec` tells you the
fields, right there in the terminal.
