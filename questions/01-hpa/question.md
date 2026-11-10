# Question 1 — HPA (HorizontalPodAutoscaler)

Create a new HorizontalPodAutoscaler (HPA) named `apache-server` in the
`autoscale` namespace.

This HPA must target the existing Deployment called `apache-server` in the
`autoscale` namespace.

- Set the HPA to aim for **50% CPU usage** per pod.
- Configure it to have **at least 1 pod** and **no more than 4 pods**.
- Also set the **downscale stabilization window to 30 seconds**.
