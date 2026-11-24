# Question 14 — etcd / control plane repair

## Context

A kubeadm-provisioned cluster was migrated to a new machine. It requires
configuration changes to run successfully.

## Task

Fix a single-node cluster that got damaged during machine migration.

First, identify the damaged cluster components and investigate what breaks them.

> **Note:** The decommissioned cluster uses an external etcd server.

Next, repair the configuration of all damaged cluster components.

> **Note:** Ensure that all necessary services and components are restarted for
> the changes to take effect. Failure to do so may result in a score reduction.

Finally, ensure the cluster is running normally.

Ensure:

- each node and all Pods are in the `Ready` state
