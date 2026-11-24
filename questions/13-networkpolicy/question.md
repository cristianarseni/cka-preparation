# Question 13 — NetworkPolicy

## Task

Review and apply the appropriate NetworkPolicy from the provided YAML samples.
Ensure the selected NetworkPolicy is **not overly permissive** while allowing
communication between the `frontend` and `backend` Deployments running in the
`frontend` and `backend` namespaces.

First, analyze the `frontend` and `backend` Deployments to determine the
specific requirements for the NetworkPolicy that needs to be applied.

Next, check the NetworkPolicy YAML examples located in the `~/netpol` folder.

> **Note:** Do not delete or modify the provided examples. Apply only one of
> them. Failure to do so may result in a score reduction.

Finally, apply the NetworkPolicy that enables communication between the
`frontend` and `backend` Deployments but is not overly permissive.

> **Note:** Do not delete or modify the existing default NetworkPolicy that
> denies all inbound or outbound traffic. Failure to do so may result in a score
> of zero.
