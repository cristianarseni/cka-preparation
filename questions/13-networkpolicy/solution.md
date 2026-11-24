# Question 13 — Solution

The task gives you three policies and asks you to pick one. So the work is
**reading**, not writing.

## 1. Find out what the policy has to allow

```
k get all -n frontend
k get all -n backend
```

Then get the labels, because a NetworkPolicy selects on labels and nothing else:

```
k get pods -n frontend --show-labels
k get pods -n backend --show-labels
```

You should see `app=frontend` and `app=backend`.

Also check the backend Service port — the policy's `ports` section has to match
it (port 80 here).

## 2. Work out which namespace the policy belongs in

This is the conceptual point of the question.

**NetworkPolicies apply to the pods receiving the traffic.** An ingress rule
lives with the destination. Traffic flows frontend → backend, so the policy
belongs in the **backend** namespace:

```
k get networkpolicy -n backend
```

You will find the existing `default-deny` there. Leave it alone — the task says
deleting it scores zero.

## 3. Read the three samples

```
cd ~/netpol
cat network-policy-1.yaml
cat network-policy-2.yaml
cat network-policy-3.yaml
```

- **network-policy-1** — `podSelector: {}` with `ingress: [{}]`. Empty selector
  means *every pod in the namespace*; an empty `from` means *from anywhere*.
  This allows all ingress from every pod in every namespace. It makes the app
  work, and it is exactly the "overly permissive" answer the task warns about.
- **network-policy-2** — selects `app: backend`, and allows ingress only from
  pods labelled `app: frontend` in the namespace labelled
  `kubernetes.io/metadata.name: frontend`, on TCP port 80. **This is the
  answer.**
- **network-policy-3** — uses `ipBlock: 0.0.0.0/0`. That is the entire IPv4
  internet expressed as a CIDR. It looks precise because it has a number in it,
  but it allows more than policy 1 in some setups, and it is brittle: pod IPs
  change, so CIDR-based rules are the wrong tool for pod-to-pod traffic.

## 4. Apply the one you chose, and nothing else

```
k apply -f ~/netpol/network-policy-2.yaml
```

Do not edit the file. Do not apply two "just in case" — the task says apply only
one.

## 5. Verify it works

```
k get netpol -n backend
k describe netpol allow-frontend-to-backend -n backend
```

Then prove it end to end from a frontend Pod:

```
k exec -n frontend <frontend-pod> -- wget -q -O- http://backend.backend
```

---

## The `namespaceSelector` + `podSelector` subtlety

In policy 2, note how these two are written:

```yaml
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: frontend
      podSelector:
        matchLabels:
          app: frontend
```

They are **one list item** (a single `-`), so they combine with AND: *pods
labelled `app=frontend` **that are in** the frontend namespace*.

Write them as two list items instead:

```yaml
  - from:
    - namespaceSelector: {...}
    - podSelector: {...}
```

and it becomes OR: *anything in the frontend namespace, **or** anything
labelled `app=frontend` anywhere*. Much more permissive, and a single dash is
the only visible difference. This is the most common NetworkPolicy mistake there
is — check the indentation every time.

The label `kubernetes.io/metadata.name` is added automatically by Kubernetes to
every namespace, which is why the policy can select a namespace by name without
anyone having labelled it.

## Why the default-deny matters

With `podSelector: {}` and `policyTypes: [Ingress, Egress]` and no rules, the
default-deny blocks everything to and from every Pod in the namespace. Policies
are **additive and allow-only** — there is no "deny" rule in Kubernetes
NetworkPolicy. So the deny-all establishes the baseline, and your chosen policy
punches one specific hole in it. Delete the baseline and every hole becomes
meaningless, which is why that one scores zero.
