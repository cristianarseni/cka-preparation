# Question 4 — Resource allocation (CPU and memory)

The WordPress application in the `relative-fawn` namespace consists of:

- a `wordpress` deployment with 3 replicas

Adjust **all Pod resource requests** as follows:

- divide the node resources among these 3 Pods
- give each Pod a fair share of CPU and memory
- add enough overhead to maintain node stability

You are **not** required to change any resource limits.

It may help to temporarily scale the WordPress deployment to 0 replicas while
updating the resource requests.

After the update, confirm that:

- WordPress maintains 3 replicas
- all Pods are running and ready
