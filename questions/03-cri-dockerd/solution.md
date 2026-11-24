# Question 3 — Solution

Two halves: install a package and run a service, then set four kernel
parameters **twice over** — once for now, once for after reboot.

## Part 1 — install and enable cri-dockerd

Check the precondition the task mentions — the OS and Docker:

```
cat /etc/os-release
docker --version
systemctl status docker
```

Install the package with `dpkg`, as the task specifies (it is already in `~`):

```
sudo dpkg -i ~/cri-dockerd_0.4.9.3-0.ubuntu-noble_amd64.deb
```

Enable and start the socket and the service:

```
sudo systemctl enable --now cri-docker.socket
sudo systemctl enable --now cri-docker.service
```

`enable` makes it start at boot; `--now` also starts it immediately. The task
asks for both, so `--now` saves you a second command.

Verify:

```
cri-dockerd --version
systemctl is-active cri-docker.service cri-docker.socket
systemctl is-enabled cri-docker.service cri-docker.socket
```

Expect version `0.4.9`, and `active` and `enabled` for both units. Both, not one.

Optional — check the CRI endpoint answers:

```
crictl --runtime-endpoint unix:///var/run/cri-dockerd.sock info
```

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

## Troubleshooting cri-docker

If the service does not come up, read its log first:

```
journalctl -u cri-docker.service -n 50 --no-pager
```

**`client version 1.42 is too old. Minimum supported API version is 1.44`** —
the cri-dockerd package is too old for this Docker. Docker Engine 29.0 refused
Docker API versions below 1.44 (29.4.1 later lowered the minimum to 1.40), and
old cri-dockerd releases such as v0.3.6 speak 1.42. Do not touch Docker: install
the newer package over the old one, clear the failed state, and start again:

```
sudo dpkg -i ~/cri-dockerd_0.4.9.3-0.ubuntu-noble_amd64.deb
sudo systemctl daemon-reload
sudo systemctl reset-failed cri-docker.service cri-docker.socket
sudo systemctl enable --now cri-docker.socket cri-docker.service
```

`reset-failed` is only needed after a failed start — systemd remembers the
failure until you clear it.

**The log says `conntrack` is missing** — install it and restart:

```
sudo apt-get install -y conntrack
sudo systemctl restart cri-docker.service
```

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
