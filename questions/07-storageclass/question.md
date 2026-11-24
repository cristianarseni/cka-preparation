# Question 7 — StorageClass

## Task

First, create a new StorageClass named `local-path` for the existing
provisioner named `rancher.io/local-path`.

Set the volume binding mode to `WaitForFirstConsumer`.

> **Note:** Not setting the volume binding mode, or setting it to any mode other
> than `WaitForFirstConsumer`, will result in a score reduction.

Next, configure `local-path` as the **default** StorageClass.

> **Note:** Do not modify any existing Deployment and PersistentVolumeClaim,
> otherwise it will lead to a score reduction.
