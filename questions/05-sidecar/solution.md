# Question 5 — Solution

## 1. Find the Deployment and its namespace

```
k get deployments -A | grep synergy-leverager
k describe deployment synergy-leverager
```

Before editing anything, know which namespace it is in.

## 2. Understand the two halves of a volume

This is the concept the question is really testing:

- **`spec.template.spec.volumes`** — declared once, at the **Pod** level. "This
  Pod has a storage volume named X, backed by some storage type." `emptyDir: {}`
  means an empty directory on the node, created when the Pod starts and deleted
  when the Pod is removed.
- **`spec.template.spec.containers[].volumeMounts`** — declared **per
  container**. "Take the Pod volume named X and mount it into this container's
  filesystem at path Y."

The **volume name** is the string linking the two. Think of `volumes` as a USB
drive plugged into the Pod, and `volumeMounts` as where each container plugs
that same drive into its own filesystem.

Both the existing container and the new sidecar need to see
`/var/log/synergy-leverager.log`, so **both must mount the same named volume at
`/var/log`**. That is the only way they look at the same underlying storage.

Docs: Volumes → emptyDir.

## 3. Edit the Deployment

```
k edit deployment synergy-leverager
```

Add the Pod-level volume, a mount on the existing container, and the new
container:

```yaml
    spec:
      volumes:
      - name: logs
        emptyDir: {}
      containers:
      - name: monitor
        image: busybox:stable
        # ... everything else here stays exactly as it was ...
        volumeMounts:
        - name: logs
          mountPath: /var/log
      - name: sidecar
        image: busybox:stable
        command: ["/bin/sh", "-c", "tail -n+1 -f /var/log/synergy-leverager.log"]
        volumeMounts:
        - name: logs
          mountPath: /var/log
```

The only change to the existing container is the `volumeMounts` block — that is
exactly what the task permits.

## 4. Verify

```
k rollout status deployment synergy-leverager
k get pods
k logs <pod-name> -c sidecar
```

The last command is the real proof: the log lines the legacy app writes to its
file now come out of `kubectl logs`.

---

## One mistake in your old notes

Your YAML had `tail -f`, but the task asks for **`tail -n+1 -f`**.

`-n+1` means "start from line 1" — stream the whole file from the beginning,
then keep following it. Plain `-f` only shows lines written **after** the
sidecar starts, so everything the app logged before that is lost. The task
states the exact command, so a grader comparing the container spec marks this
wrong. The check script requires `-n+1`.

## Why not just change the app to log to stdout?

That would be the normal fix, but the task calls it a **legacy** app — you are
not allowed to change it. The sidecar pattern exists exactly for that case:
leave the app alone, and put a second container beside it whose only job is to
read the file and write it to stdout, where `kubectl logs` can reach it.
