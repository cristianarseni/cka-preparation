# Question 3 — Solution

Two halves: install a package and run a service, then set four kernel
parameters **twice over** — once for now, once for after reboot.

## Part 1 — install and enable cri-dockerd

Check the precondition the task mentions:

```
docker --version
```

Install the package with `dpkg`, as the task specifies:

```
sudo dpkg -i ~/cri-dockerd_0.3.6.3-0.ubuntu-jammy_amd64.deb
```

Enable and start it in one command:

```
sudo systemctl enable --now cri-docker
```

`enable` makes it start at boot; `--now` also starts it immediately. The task
asks for both, so `--now` saves you a second command.

Verify:

```
systemctl status cri-docker
```

Look for `enabled` on the Loaded line and `active (running)` on the Active line.
Both, not one.

## Part 2 — the four kernel parameters

The task says they must persist **and** be applied to the running system. That
is deliberate: one command does not do both.

Write them to a file under `/etc/sysctl.d/`:

```
sudo vim /etc/sysctl.d/99-k8s.conf
```

```
net.bridge.bridge-nf-call-iptables = 1
net.ipv6.conf.all.forwarding = 1
net.ipv4.ip_forward = 1
net.netfilter.nf_conntrack_max = 131072
```

Then load every sysctl config file into the running kernel:

```
sudo sysctl --system
```

Verify each one really took:

```
sysctl net.bridge.bridge-nf-call-iptables
sysctl net.ipv6.conf.all.forwarding
sysctl net.ipv4.ip_forward
sysctl net.netfilter.nf_conntrack_max
```

---

## Why "persist AND apply" is two jobs

- `sysctl -w net.ipv4.ip_forward=1` changes the **running** kernel only. Reboot
  and it is gone.
- Writing the file under `/etc/sysctl.d/` sets it for **future boots** only. The
  running kernel does not notice until something reloads it.

You need both, which is why the file comes first and `sysctl --system` second.
Doing only one of them is the usual way to half-pass this question.

## If a sysctl says "cannot stat"

`net.bridge.bridge-nf-call-iptables` and `net.netfilter.nf_conntrack_max` only
exist once their kernel modules are loaded:

```
sudo modprobe br_netfilter
sudo modprobe nf_conntrack
```

To make the modules load at boot as well:

```
echo -e "br_netfilter\nnf_conntrack" | sudo tee /etc/modules-load.d/k8s.conf
```

## Why Kubernetes wants these four

Useful to understand rather than memorise:

- **`net.ipv4.ip_forward`** — lets the node route packets between interfaces. Pod
  networking is routing between pod interfaces, so without this almost nothing
  works.
- **`net.bridge.bridge-nf-call-iptables`** — makes traffic crossing a Linux
  bridge pass through iptables. kube-proxy implements Services as iptables
  rules; without this, traffic between Pods on the same node bypasses them, so
  Services silently fail.
- **`net.ipv6.conf.all.forwarding`** — the same as the first, for IPv6.
- **`net.netfilter.nf_conntrack_max`** — the size of the connection tracking
  table. Each tracked connection takes an entry; a busy node exhausts the
  default and starts dropping connections.

## What cri-dockerd actually is

Kubernetes removed built-in Docker support (dockershim) in v1.24. The kubelet
now only talks CRI. `cri-dockerd` is Mirantis's standalone shim that speaks CRI
to the kubelet and the Docker API to Docker. You install it when a node must use
Docker as its runtime on a modern Kubernetes — which is exactly the scenario
this question sets up.
