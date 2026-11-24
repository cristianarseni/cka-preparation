# Question 6 — CNI Calico

## Context

Your cluster's CNI has failed a security audit. It has been removed. You must
install a new CNI that can enforce network policies.

## Task

Install and set up a Container Network Interface (CNI) that meets these
requirements. Pick and install **one** of these CNI options:

**Flannel version 0.26.1**
Manifest:
`https://github.com/flannel-io/flannel/releases/download/v0.26.1/kube-flannel.yml`

**Calico version 3.28.2**
Manifest:
`https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/tigera-operator.yaml`

> Remember what the Context asks for: the CNI must be able to **enforce network
> policies**.
