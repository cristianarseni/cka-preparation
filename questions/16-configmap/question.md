# Question 16 — ConfigMap

Deployment `nginx-static` in namespace `nginx-static`. In ConfigMap
`nginx-config`, edit `ssl_protocols` to also allow TLSv1.2 connections (keep
1.3 as well).

Set the ssl protocols directive to `ssl_protocols TLSv1.2 TLSv1.3` to also allow
TLSv1.2.

You may recreate, restart or scale resources as necessary.

Finally, make the ConfigMap **immutable**.

You can use the following command to test the changes:

```
curl -k --tls-max 1.2 https://web.k8snginx.local
```
