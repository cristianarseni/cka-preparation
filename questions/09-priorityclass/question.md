# Question 9 — PriorityClass

## Task

Please perform the following tasks:

- Create a new PriorityClass named `high-priority` for user-workloads, with a
  value that is **one less than the highest existing user-defined priority class
  value**.
- Patch the existing `busybox-logger` Deployment running in the `priority`
  namespace to use the `high-priority` PriorityClass.
- Ensure that the `busybox-logger` Deployment rolls out successfully with the
  new PriorityClass set.

> **Note:** Do not modify other Deployments running in the `priority` namespace,
> as this may result in a score reduction.
