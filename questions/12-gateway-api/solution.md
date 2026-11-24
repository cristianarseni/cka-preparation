# Question 12 — Solution

The whole job is: read the old Ingress, copy its settings into two new objects,
delete the old one.

## 1. Read the Ingress you are replacing

```
k get ingress web -o yaml
```

Write down four things — everything you create next comes from here:

- the **namespace** of the Ingress (if not `default`)
- the **TLS secretName** → `web-tls`
- the **service name and port** → `web:80`
- the **path** → `/`

## 2. Create the Gateway

```
vim gateway.yaml
```

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: web-gateway
spec:
  gatewayClassName: nginx
  listeners:
  - name: https
    port: 443
    protocol: HTTPS
    hostname: gateway.web.k8s.local
    tls:
      mode: Terminate
      certificateRefs:
      - kind: Secret
        name: web-tls
```

```
k apply -f gateway.yaml
```

## 3. Create the HTTPRoute

```
vim httproute.yaml
```

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: web-route
spec:
  parentRefs:
  - name: web-gateway
    sectionName: https
  hostnames:
  - gateway.web.k8s.local
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: web
      port: 80
```

```
k apply -f httproute.yaml
```

## 4. Verify, then delete the Ingress

```
k get gateway
k get httproute
k describe httproute web-route
```

Only once both exist:

```
k delete ingress web
```

Do this last. Delete the Ingress first and you have an outage while you work out
the Gateway YAML.

---

## The mental model: one object became two

An Ingress mixes two concerns in one object. Gateway API splits them, because in
real organisations two different teams own them:

| Ingress field | Gateway API | Who owns it |
| --- | --- | --- |
| `ingressClassName` | `Gateway.spec.gatewayClassName` | platform team |
| `tls.secretName` | `Gateway` listener `tls.certificateRefs` | platform team |
| listening port | `Gateway` listener `port` / `protocol` | platform team |
| `rules.host` | both — listener `hostname` **and** `HTTPRoute.hostnames` | both |
| `rules.http.paths` | `HTTPRoute.rules.matches` | app team |
| `backend.service` | `HTTPRoute.rules.backendRefs` | app team |

**Gateway** = where traffic enters and how TLS is handled.
**HTTPRoute** = where matching traffic goes.

`parentRefs` is the link between them — the HTTPRoute attaching itself to the
Gateway. That is the field to check first when a migration does not work.

## Things that trip people up

- **`certificateRefs` is a list**, and each entry needs `kind: Secret`. Writing
  `secretName:` as in an Ingress is invalid here.
- **`mode: Terminate`** means TLS is decrypted at the Gateway and plain HTTP
  goes to the backend — the same thing an Ingress with a TLS secret does. The
  alternative, `Passthrough`, forwards encrypted traffic untouched, which would
  change the behaviour.
- **`sectionName: https`** ties the route to that one named listener. Without
  it, the route attaches to every listener on the Gateway.
- **The API group is `gateway.networking.k8s.io`**, not `networking.k8s.io`.
  Easy to mistype, and the error message is unhelpful.
