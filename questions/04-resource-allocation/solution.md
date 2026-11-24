# Question 4 — Solution

## 1. Find out what you actually have to divide

```
k get nodes
k describe node node01
```

In `describe node`, two blocks matter:

- **Allocatable** — what the kubelet will hand out to Pods. Not Capacity.
- **Allocated resources** — what existing Pods already requested.

Also check the taints. A control-plane node with `NoSchedule` cannot take your
Pods, so you divide **only the schedulable node's** resources.

Typical KillerCoda numbers: `node01` allocatable **1000m CPU, ~1803Mi memory**,
with roughly **100m CPU and 10Mi memory** already taken by existing workloads.

## 2. Do the arithmetic

Left to share: `1000m - 100m = 900m` CPU, `1803Mi - 10Mi = ~1793Mi` memory.

Across 3 Pods that is 300m / ~597Mi each. Now subtract overhead so the node
stays stable — do not allocate every last millicore:

- **CPU: 250m per Pod** → 750m used, 150m spare
- **Memory: 500Mi per Pod** → 1500Mi used, ~290Mi spare

An important subtlety: this Pod has an **init container as well as a main
container**. A Pod reserves `max(largest init container, sum of main
containers)`, not the sum of everything — they never run at the same time. So
setting both to 250m/500Mi still reserves only 250m/500Mi per Pod.

## 3. Apply it

Scale to 0 first, as the task hints:

```
k -n relative-fawn scale deploy wordpress --replicas=0
k -n relative-fawn edit deploy wordpress
```

Under **both** `spec.template.spec.initContainers[]` and
`spec.template.spec.containers[]`:

```yaml
        resources:
          requests:
            cpu: "250m"
            memory: "500Mi"
```

Then scale back:

```
k -n relative-fawn scale deploy wordpress --replicas=3
```

## 4. Verify

```
k -n relative-fawn get deploy wordpress
k -n relative-fawn get pods -o wide
```

All 3 must be **Running and Ready**. If any Pod sits in **Pending**, run
`k -n relative-fawn describe pod <name>` and read the Events — `Insufficient
cpu` or `Insufficient memory` means your requests were too greedy. Lower them
and scale again.

---

## Careful: the numbers in your old notes were too small

Your notes used `cpu: 100m` / `memory: 128Mi`. The Pods do start, but that
commits only about **40% of the CPU and 22% of the memory** of the node. The
task says to *divide the node resources among these 3 Pods* — leaving three
quarters of the memory unused is not dividing it, and on the exam that scores
poorly even though the Pods run.

The check script holds you to **40–95% of the node committed**: below that you
did not divide it, above that you left no overhead.

## Why "requests" and not "limits"

The task explicitly says you are not required to change limits. **Requests** are
what the scheduler reserves and what this task is graded on. **Limits** are the
ceiling the kubelet enforces at runtime. Only requests decide whether 3 Pods fit
on the node, so only requests need to change here.
