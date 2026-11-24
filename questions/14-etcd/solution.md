# Question 14 — Solution

This question gives you **no hint what is broken**. The skill being tested is
diagnosis, so work through it in order rather than guessing.

## 1. See how bad it is

```
kubectl get nodes
kubectl get pods -n kube-system
```

If kubectl itself hangs or refuses, the API server is down — expected here.

## 2. Ask the kubelet what is wrong

The kubelet runs as a systemd service and keeps working even when the API server
is dead, so its log is where the truth is:

```
sudo journalctl -u kubelet --no-pager -l | tail -30
```

Look for a line like:

```
dial tcp 127.0.0.1:2380: connect: connection refused
```

Note **both the IP and the port** — the port is the clue.

## 3. Cross-check the containers directly

`crictl` talks to the container runtime, not the API server, so it works when
kubectl does not:

```
sudo crictl ps -a | grep -E "apiserver|etcd"
```

You will see the apiserver container repeatedly exiting while etcd stays up.
That tells you the fault is on the apiserver side, not in etcd.

## 4. Read the apiserver manifest

```
sudo cat /etc/kubernetes/manifests/kube-apiserver.yaml | grep -E "advertise-address|etcd-servers"
```

## 5. Confirm what etcd actually listens on

```
ip addr show | grep "inet "
sudo ss -tlnp | grep 2379
```

etcd listens on **2379**. The manifest says **2380**. There is the bug.

## 6. Fix fault 1

```
sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml
```

Change `--etcd-servers=https://127.0.0.1:2380` to
`--etcd-servers=https://127.0.0.1:2379`.

**No restart is needed.** The kubelet watches `/etc/kubernetes/manifests/` and
recreates a static Pod the moment its file changes. Wait 30–60 seconds.

## 7. Find fault 2

Once the API server is back:

```
kubectl get pods -n kube-system
```

`kube-scheduler` is not Running. Find out why:

```
kubectl describe pod kube-scheduler-controlplane -n kube-system | tail -20
```

You will see an `OutOfcpu` style rejection — the Pod requests more CPU than the
node has.

```
sudo vi /etc/kubernetes/manifests/kube-scheduler.yaml
```

Change the `cpu:` request under `resources.requests` back to something sane —
`100m` is the kubeadm default.

## 8. Final verification — this is the pass condition

```
kubectl get nodes
kubectl get pods -A
```

Every node **Ready**, every Pod **Running** (or Completed for one-shot init
Jobs).

---

## 2379 vs 2380 — worth memorising

- **2379** = etcd's **client** port. Clients, including the API server, connect
  here.
- **2380** = etcd's **peer** port. Only other etcd members use it, for
  replication.

Point a client at 2380 and the connection is simply refused. It is a one-digit
difference and a very common exam fault.

## When you DO need to restart the kubelet

Editing a file in `/etc/kubernetes/manifests/` needs **no restart** — the
kubelet is watching that directory.

You do need a restart when you change the kubelet's own configuration
(`/var/lib/kubelet/config.yaml`, `/etc/kubernetes/kubelet.conf`, or its systemd
unit):

```
sudo systemctl daemon-reload
sudo systemctl restart kubelet
```

Knowing which case you are in saves time and avoids restarting the kubelet
pointlessly while an unrelated fault is the real problem.

## The order matters

Fix the API server first. Until it is up you cannot run `kubectl get pods`, so
you cannot even see that the scheduler is broken. Faults in a control plane
mask each other — always repair from the bottom of the stack upward: etcd →
apiserver → everything else.

## Other things worth checking in this kind of question

Not broken in this lab, but check them on the exam — the wording ("migrated to
a new machine") points at exactly these:

```
grep "server:" /etc/kubernetes/kubelet.conf /etc/kubernetes/controller-manager.conf \
               /etc/kubernetes/scheduler.conf /etc/kubernetes/admin.conf
```

All four must point at the correct API server address. After a machine
migration, a stale IP in any of them breaks that component.
