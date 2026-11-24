# Question 16 — Solution

This is really a **two-part** problem, and part two is where people lose the
marks.

## 1. Confirm what is there

```
k get ns
k get all -n nginx-static
k get configmap -n nginx-static
```

## 2. Edit the ConfigMap

```
k edit configmap nginx-config -n nginx-static
```

Change:

```
            ssl_protocols TLSv1.3;
```

to:

```
            ssl_protocols TLSv1.2 TLSv1.3;
```

Both, space-separated. The task says keep 1.3 as well — replacing it with just
TLSv1.2 fails the second half.

## 3. Understand why the edit alone is not enough

**Editing a ConfigMap does not update the config inside running Pods.**

A ConfigMap is data sitting in the API. If it is mounted as a volume, the
kubelet eventually refreshes the file inside the container — up to about 60–90
seconds, and **not at all** when mounted with `subPath`, as it is here. Even
once the file does change, **nginx does not watch it**. Nginx reads its config
once at startup and keeps using what it loaded until something restarts or
reloads it.

So after the edit, the running nginx is still enforcing TLSv1.3-only.

That is exactly why the task says *"you may recreate, restart or scale resources
as necessary"* — that sentence is telling you the edit is not sufficient.

## 4. Restart the Pods

```
k rollout restart deployment nginx-static -n nginx-static
```

This tells the Deployment controller to replace the Pods. New Pods mount the
ConfigMap fresh, so nginx starts up reading the already-updated file. More
reliable than waiting for the kubelet's sync, and cleaner than exec-ing in to
run `nginx -s reload`.

## 5. Verify the rollout and the Pods

```
k rollout status deployment nginx-static -n nginx-static
k get pods -n nginx-static
```

This matters: if your edit introduced a syntax error — a missing semicolon, say
— the new Pods crash-loop instead of starting. Catch that here rather than
assuming success because the edit command did not complain.

## 6. Test both protocols

```
curl -k --tls-max 1.2 https://web.k8snginx.local
curl -k --tls-max 1.3 https://web.k8snginx.local
```

Both must succeed.

## 7. Only now, make it immutable

```
k patch configmap nginx-config -n nginx-static -p '{"immutable":true}'
k get configmap nginx-config -n nginx-static -o yaml
```

**Order matters.** Once `immutable: true` is set, the ConfigMap can never be
edited again — you would have to delete and recreate it. Do this last, after the
content is correct and verified.

---

## What `immutable` is actually for

Two reasons it exists:

1. **Safety.** A config that cannot change by accident cannot break a running
   app by accident.
2. **Performance.** The kubelet watches every mounted ConfigMap for changes.
   Marking one immutable lets it stop watching, which matters in large clusters.

The transition is one-way: non-immutable → immutable is allowed, the reverse is
not.

## Why `-k` is in the curl command

The certificate is self-signed, so curl would normally refuse it. `-k` skips
verification. It is about the certificate's trust chain, nothing to do with the
TLS *version*, which is what `--tls-max` controls and what this question is
about.
