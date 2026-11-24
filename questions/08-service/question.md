# Question 8 — Service

Reconfigure the existing deployment `front-end` in the namespace
`spline-reticulator` to expose port `80/tcp` of the existing container `nginx`.

Create a new Service named `front-end-svc` exposing the container port
`80/tcp`.

Configure the new Service to also expose the individual Pods via a **NodePort**.
