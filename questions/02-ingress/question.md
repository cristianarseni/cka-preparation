# Question 2 — Ingress

## Task

Create a new Ingress resource as follows:

- **Name:** `echo`
- **Namespace:** `sound-repeater`
- Exposing Service `echoserver-service` on `http://example.org/echo` using
  Service port `8080`

The availability of Service `echoserver-service` can be checked using the
following command, which should return `200`:

```
curl -o /dev/null -s -w "%{http_code}\n" http://example.org/echo
```
