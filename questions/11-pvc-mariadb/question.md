# Question 11 — PVC MariaDB

## Task

The MariaDB Deployment in the `mariadb` namespace has been deleted by mistake.
Your task is to restore the Deployment, ensuring data persistence. Follow these
steps:

Create a PersistentVolumeClaim (PVC) named `mariadb` in the `mariadb` namespace
with the following specifications:

- Access mode: `ReadWriteOnce`
- Storage: `250Mi`

> You **must** use the existing retained PV — failure to do so will result in a
> reduced score. There is only one existing PersistentVolume.

Edit the MariaDB Deployment file located at `~/mariadb-deployment.yaml` to use
the PVC created in the previous step.

Apply the updated Deployment file to the cluster.

Ensure the MariaDB Deployment is running and stable.
