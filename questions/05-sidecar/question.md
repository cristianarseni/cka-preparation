# Question 5 — Sidecar container

## Context

A legacy app needs to be integrated into the Kubernetes built-in logging
architecture (`kubectl logs`). Adding a streaming co-located container is a
good common way to accomplish this requirement.

## Task

Update the existing Deployment `synergy-leverager`, adding a co-located
container named `sidecar` using the `busybox:stable` image to the existing Pod.

The new co-located container has to run the following command:

```
/bin/sh -c 'tail -n+1 -f /var/log/synergy-leverager.log'
```

Use a Volume mounted at `/var/log` to make the log file
`synergy-leverager.log` available to the co-located container.

**Do not modify the specifications of existing containers** except to add the
required volume mounts.
