# Question 10 — Argo CD

## Task

Install Argo CD in the cluster by performing the following tasks:

- Add the official Argo CD Helm repository `https://argoproj.github.io/argo-helm`
  with the name `argo`.
- The Argo CD CRDs have already been preinstalled in the cluster.
- Generate a template for the Argo CD Helm chart **version 7.7.3** for the
  `argocd` namespace and save it to `/home/candidate/argo-helm.yaml`.
  Configure the chart to **not** install CRDs.
- Install Argo CD using Helm with the release name `argocd`, using the same
  configuration as in the template: version 7.7.3, in the `argocd` namespace,
  configured to not install CRDs.

> **Note:** You do not need to configure access to the Argo CD server UI.
