# Question 9 — Solution

## 1. Find the highest user-defined value

```
k get priorityclass
```

You will see something like:

```
NAME                      VALUE        GLOBAL-DEFAULT
low-priority              100000       false
medium-priority           500000       false
platform-critical         1000000000   false
system-cluster-critical   2000000000   false
system-node-critical      2000001000   false
```

The two `system-*` classes are **built into Kubernetes**, not user-defined, so
ignore them. The highest user-defined value is **1000000000**, and the task asks
for one less: **999999999**.

Getting this wrong by picking 2000001000 (the real maximum) is the trap in this
question.

## 2. Create the PriorityClass

```
k create priorityclass high-priority --value=999999999 \
  --description="high priority for user workloads"
```

Do **not** add `--global-default`. That would apply this priority to every Pod
in the cluster that does not name a class, which is far beyond what was asked.

## 3. Patch the Deployment

```
k patch deployment busybox-logger -n priority \
  -p '{"spec":{"template":{"spec":{"priorityClassName":"high-priority"}}}}'
```

Because this changes the **Pod template**, it triggers a new rollout, which is
what the third bullet of the task wants.

## 4. Verify

```
k rollout status deployment busybox-logger -n priority
k get pods -n priority -o wide
k describe pod <pod-name> -n priority
```

In `describe pod`, look for `Priority: 999999999` and
`Priority Class Name: high-priority`. Checking the **Pod** matters, not just the
Deployment — if the rollout failed, the old Pod without the priority is still
the one running.

Also confirm you did not disturb the neighbours:

```
k get deploy -n priority -o custom-columns=NAME:.metadata.name,PRIORITY:.spec.template.spec.priorityClassName
```

Only `busybox-logger` should show a priority class.

---

## What PriorityClass actually does

Two things, both at scheduling time:

1. **Ordering.** When several Pods are waiting to be scheduled, higher-value
   Pods are placed first.
2. **Preemption.** If a high-priority Pod cannot fit anywhere, the scheduler may
   **evict** lower-priority Pods to make room.

That second point is why the task warns you not to touch the other Deployments:
on a small cluster, carelessly giving several workloads a huge priority can
start evicting each other.

The `system-cluster-critical` and `system-node-critical` classes exist so that
control-plane components always win that contest — which is exactly why they are
above anything you are meant to create.
