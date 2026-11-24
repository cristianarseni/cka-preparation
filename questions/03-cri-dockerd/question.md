# Question 3 — cri-dockerd

Your task is to prepare a Linux system for Kubernetes. Docker is already
installed, but you need to preconfigure it for kubeadm.

## Task

Complete the following tasks to prepare the system for Kubernetes:

**Set up cri-dockerd:**

- Install the Debian package
  `~/cri-dockerd_0.3.6.3-0.ubuntu-jammy_amd64.deb`
  (Debian packages are installed using `dpkg`)
- Enable and start the `cri-docker` service

**Configure these system parameters:**

- `net.bridge.bridge-nf-call-iptables` set to `1`
- `net.ipv6.conf.all.forwarding` set to `1`
- `net.ipv4.ip_forward` set to `1`
- `net.netfilter.nf_conntrack_max` set to `131072`

Ensure these system parameters **persist after system reboot** and are
**applied to the running system**.
