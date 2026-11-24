# Question 10 — Solution

This question went wrong for you on the exam, so read the "where it broke" part
at the bottom.

## 1. Add the repo

```
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm repo list
```

## 2. Generate the template

```
helm template argocd argo/argo-cd \
  --version 7.7.3 \
  --namespace argocd \
  --set crds.install=false \
  > /home/candidate/argo-helm.yaml
```

Check it landed:

```
ls -l /home/candidate/argo-helm.yaml
grep -c 'kind: CustomResourceDefinition' /home/candidate/argo-helm.yaml
```

The grep must print `0`. That is the proof `crds.install=false` took effect.

## 3. Install, with the same settings

```
helm install argocd argo/argo-cd \
  --version 7.7.3 \
  --namespace argocd \
  --create-namespace \
  --set crds.install=false
```

## 4. Verify

```
helm list -n argocd
kubectl get pods -n argocd
```

`helm list` must show CHART `argo-cd-7.7.3` and STATUS `deployed`. Pods take a
minute or two to pull images.

---

## Where this broke on the exam

Your notes say: *"i could see the yaml file but did not install. there is
already ns created called argocd, but when i run k get all -n argocd it said no
namespace."*

Two separate things went wrong, and they are worth separating.

### `helm template` does not install anything

`helm template` renders the chart to stdout and **stops**. It never contacts the
cluster. So after step 2 you correctly had a YAML file and correctly had nothing
running — that was not a failure, it was the command doing its job. The install
is a second, separate command (`helm install`). This is the single most useful
thing to take from this question.

### The backslashes

Your notes show the commands written like this:

```
helm template argocd argo/argo-cd
--version 7.7.3
--namespace argocd
--set crds.install=false \ > /home/candidate/argo-helm.yaml
```

Without a `\` at the end of **every** continued line, the shell runs
`helm template argocd argo/argo-cd` alone and then tries to run `--version` as
its own command. And `\ >` in the last line escapes the space, not the newline.

Either put `\` at the end of every line except the last, or just type the whole
thing on one line. Under exam pressure, one line is safer.

### "no namespace"

If `helm install` never ran, nothing was created in `argocd`, so
`k get all -n argocd` reported nothing — even though the namespace existed.
`kubectl get all` only shows a handful of resource types and prints nothing when
they are all absent; it is not a reliable "does this namespace exist" check. Use
`k get ns argocd` for that.

## Why the task says not to install CRDs

The CRDs were preinstalled separately. If the chart installed them again, Helm
would own objects that already exist, and you would get an "already exists"
conflict or a resource whose lifecycle is tied to the release — so uninstalling
Argo CD would delete CRDs that something else depends on. Keeping CRDs outside
the release is the normal production pattern, which is why the exam tests it.
