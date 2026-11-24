# Question 2 — Solution

## 1. Confirm the namespace exists

```
k get ns
```

Look for `sound-repeater`.

## 2. See everything in that namespace

```
k get all -n sound-repeater
```

Note the Service name (`echoserver-service`) and its port (`8080`) — you plug
both into the rule. Confirm the Pod is Running.

## 3. Check the IngressClass

```
k get ingressclass
```

**No `-n` here.** IngressClass is cluster-scoped, like StorageClass and
PriorityClass. Note the class name: `edge-proxy`. You pass it to `--class`.

## 4. Create the Ingress

```
k create ingress echo \
  --rule="example.org/echo=echoserver-service:8080" \
  --class=edge-proxy \
  -n sound-repeater
```

The `--rule` syntax is `HOST/PATH=SERVICE:PORT` — all four values in one string.

## 5. Verify the rule points at a real backend

```
k describe ingress echo -n sound-repeater
```

Under **Rules**, it must read `echoserver-service:8080 (<pod-ip>:80)` — with an
actual Pod IP in the brackets. If the brackets are empty, the Service name in
your rule is wrong and nothing will answer.

## 6. Wait for the address, then test

```
k get ingress echo -n sound-repeater
```

Wait for the **ADDRESS** column to fill in before curling. Then:

```
curl -o /dev/null -s -w "%{http_code}\n" http://example.org/echo
```

Expect `200`.

---

## If you get 404 — diagnose, do not recreate

Deleting and recreating the Ingress is the reflex, and it is almost always the
wrong move. Run these two instead:

```
grep example.org /etc/hosts
curl -o /dev/null -s -w "%{http_code}\n" -H "Host: example.org" http://localhost/echo
```

- **No `example.org` line in `/etc/hosts`** → the name does not resolve. Your
  Ingress is fine; DNS is the problem.
- **The `Host:` header version returns 200 while the plain one 404s** → same
  conclusion. The controller is matching correctly; the hostname just is not
  resolving to it.

That distinction is worth internalising: an Ingress rule matches on the **Host
header**, not on DNS. Curl only sends the right Host header if the URL has the
right hostname in it, and the name only connects anywhere if it resolves. Two
separate things, two separate failures.

## Two things that will bite you

1. **Straight quotes only.** Type `"` and `'` directly in the terminal. If you
   paste from a notes app, you can get smart quotes (`"` `'`), and curl fails
   with a confusing error. This caught you before.
2. **No `-n` on `kubectl get ingressclass`.** Cluster-scoped resources have no
   namespace. Adding `-n` does not error — it is silently ignored — so it is
   easy to not notice you have misunderstood the resource.
