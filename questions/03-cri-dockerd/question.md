# Question 3 — cri-dockerd

Your task is to prepare a Linux system for Kubernetes. Docker is already
installed, but you need to preconfigure it for kubeadm.

## Task

Complete the following tasks to prepare the system for Kubernetes:

**Set up cri-dockerd:**

- Install the Debian package
  `~/cri-dockerd_0.4.9.3-0.ubuntu-noble_amd64.deb`
  (Debian packages are installed using `dpkg`)
- Enable and start the `cri-docker` service

**Configure these system parameters:**

- `net.bridge.bridge-nf-call-iptables` set to `1`
- `net.ipv6.conf.all.forwarding` set to `1`
- `net.ipv4.ip_forward` set to `1`
- `net.netfilter.nf_conntrack_max` set to `131072`

Ensure these system parameters **persist after system reboot** and are
**applied to the running system**.

> **Practice note:** the exam names an older package. It is updated here to
> v0.4.9 for Ubuntu 24.04 because older cri-dockerd versions cannot talk to the
> Docker Engine 29 on the playground. The steps are the same.
