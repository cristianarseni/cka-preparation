# Question 1 — Solution

## 1. Look at what is already there

```
k get deploy -n autoscale
k get hpa -n autoscale
```

Confirm the Deployment `apache-server` exists and that no HPA exists yet.

## 2. Create the HPA

```
k autoscale deployment apache-server -n autoscale \
  --name=apache-server --cpu=50% --min=1 --max=4
```

This covers three of the four requirements: the target Deployment, the 50% CPU
target, and min 1 / max 4.

**The `%` is required.** Newer kubectl uses `--cpu`, which takes two kinds of
value:

| You type      | What the HPA gets                              | Right here? |
| ------------- | ---------------------------------------------- | ----------- |
| `--cpu=50%`   | `type: Utilization`, `averageUtilization: 50`  | yes         |
| `--cpu=50`    | `type: AverageValue`, `averageValue: 50m`      | **no**      |
| `--cpu=500m`  | `type: AverageValue`, `averageValue: 500m`     | no          |

Without the `%`, the number is read as millicores - 50m per pod - which is a
completely different target.

Older kubectl only has `--cpu-percent=50` (plain number, no `%`). It still works
on newer versions, just deprecated. If `--cpu=50%` gives `unknown flag`, the
exam's kubectl is the older one: use `--cpu-percent=50`. Check with
`k autoscale --help | grep cpu`.

## 3. Add the downscale stabilization window

`kubectl autoscale` has no flag for this, so patch it in afterwards:

```
k patch hpa apache-server -n autoscale --type=merge \
  -p '{"spec":{"behavior":{"scaleDown":{"stabilizationWindowSeconds":30}}}}'
```

## 4. Verify

```
k get hpa apache-server -n autoscale
k get hpa apache-server -n autoscale -o yaml
```

In the YAML confirm all four things:

- `spec.scaleTargetRef` -> `kind: Deployment`, `name: apache-server`
- `spec.minReplicas: 1` and `spec.maxReplicas: 4`
- a cpu metric with `type: Utilization` and `averageUtilization: 50`
  (not `averageValue`)
- `spec.behavior.scaleDown.stabilizationWindowSeconds: 30`

---

## Three mistakes in your original notes

These are worth knowing, because each one costs you the question on the exam:

1. **The CPU flag and its `%`.** On current kubectl `--cpu=50%` is correct.
   Drop the `%` (`--cpu=50`) and you get a 50m AverageValue target instead of
   50% utilization - the HPA is created, looks fine, and is wrong. On older
   kubectl the flag is `--cpu-percent=50`, with no `%`.
2. **`apache-server-n autoscale` is missing a space** before `-n`. kubectl reads
   this as an HPA literally named `apache-server-n`, so it reports "not found".
   This appeared in both the patch and the get command.
3. **`-p'{...}'` is missing a space** after `-p`.

## What TARGETS shows

`k get hpa` may show `<unknown>/50%` in the TARGETS column. That only means
metrics-server has not reported CPU yet (it needs ~30-60 seconds after startup).
It does **not** mean your HPA is wrong — the exam grades the HPA object, not
whether the metric has arrived. Wait a minute and look again if you want to see
a real number.
