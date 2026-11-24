# Question 8 — Solution

Read the task carefully: it is **two** jobs, not one.

1. the Deployment's container must *declare* port 80
2. a NodePort Service must expose it

## 1. Look at what is there

```
k get deploy front-end -n spline-reticulator -o yaml
```

The container `nginx` has no `ports` block at all. That is the first thing to
fix.

## 2. Add the container port

```
k edit deployment front-end -n spline-reticulator
```

Under the `nginx` container:

```yaml
      - name: nginx
        image: nginx:alpine-slim
        ports:
        - containerPort: 80
          protocol: TCP
```

## 3. Create the Service

```
k expose deployment front-end -n spline-reticulator \
  --name=front-end-svc --port=80 --target-port=80 --type=NodePort
```

Note the backslashes at the end of each line — they join the lines into one
command. Without them the shell runs `k expose deployment front-end -n
spline-reticulator` on its own, which creates a Service with the wrong name and
no NodePort.

## 4. Verify

```
k get svc front-end-svc -n spline-reticulator
k get endpoints front-end-svc -n spline-reticulator
```

`get endpoints` is the real test. If the ENDPOINTS column shows Pod IPs, the
Service selector matches the Pods. If it says `<none>`, the Service exists but
routes to nothing, and the question scores zero.

Then prove it works end to end, using the NodePort from the PORT(S) column:

```
curl http://localhost:<nodeport>/
```

---

## Why declaring containerPort matters here

Strictly speaking, Kubernetes routes traffic to a Pod whether or not
`containerPort` is declared — the Service's `targetPort` is what counts. So why
does the task insist on it?

Because the task says so, and the grader checks the Deployment spec. On the
exam, do exactly what is asked. In real life the field is still worth setting:
it documents what the container listens on, and it is what `kubectl expose`
reads when you do not pass `--target-port`.

## The three Service port fields

These get confused constantly:

- **`port`** — the port the Service itself listens on inside the cluster
  (`front-end-svc:80`)
- **`targetPort`** — the port on the **Pod** that traffic is forwarded to
- **`nodePort`** — the port opened on **every node's** IP, in the 30000-32767
  range, allocated automatically unless you pick one

A NodePort Service has all three. Here `port` and `targetPort` are both 80, and
`nodePort` is whatever Kubernetes assigns.
