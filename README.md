# CKA Practice — my own questions

My own CKA exercises, taken from the questions I saw on the exam. Each one sets
itself up in a real cluster, and a check script tells me PASS or FAIL for every
individual requirement.

## Use it on KillerCoda

1. Open the CKA playground: https://killercoda.com/playgrounds/scenario/cka
2. In the terminal:

```
git clone https://github.com/cristianarseni/cka-preparation.git ~/cka-prep
cd ~/cka-prep
```

3. Start a question:

```
./run.sh 1
```

4. Solve it yourself in the terminal.
5. Check your answer:

```
./check.sh 1
```

6. Stuck? Only then:

```
cat questions/01-hpa/solution.md
```

7. Clean up before moving on:

```
./cleanup.sh 1
```

## Other commands

```
./run.sh list      list every question
./check.sh all     check everything at once
```

## Each question folder holds

| File          | What it does                                      |
| ------------- | ------------------------------------------------- |
| `setup.sh`    | builds what the question needs in the cluster     |
| `question.md` | the task, exactly as worded                       |
| `solution.md` | step-by-step answer, read only when stuck         |
| `validate.sh` | PASS / FAIL per requirement                       |
| `cleanup.sh`  | removes what the question created                 |

## Questions

| #  | Topic                           | Setup time | Notes                              |
| -- | ------------------------------- | ---------- | ---------------------------------- |
| 1  | HPA                             | fast       |                                    |
| 2  | Ingress                         | **slow**   | installs an ingress controller     |
| 3  | cri-dockerd                     | **slow**   | needs root; installs docker + .deb |
| 4  | Resource allocation CPU/memory  | fast       |                                    |
| 5  | Sidecar                         | fast       |                                    |
| 6  | CNI Calico                      | **slow**   | **breaks the cluster**             |
| 7  | StorageClass                    | fast       |                                    |
| 8  | Service                         | fast       |                                    |
| 9  | PriorityClass                   | fast       |                                    |
| 10 | Argo CD                         | **slow**   | installs helm + Argo CD            |
| 11 | PVC MariaDB                     | fast       |                                    |
| 12 | Migrate Ingress to Gateway API  | medium     | installs the Gateway API CRDs      |
| 13 | NetworkPolicy                   | fast       | needs a policy-enforcing CNI       |
| 14 | etcd / control plane repair     | fast       | **breaks the cluster**; needs root |
| 15 | CRDs                            | medium     | installs the cert-manager CRDs     |
| 16 | ConfigMap (TLS)                 | medium     | needs openssl; binds port 443      |

## A suggested session order

Questions 6 and 14 destroy the cluster on purpose, so they go last — or on a
playground of their own. Everything else can share one session:

```
1  4  5  7  8  9  11  15  →  13  2  12  16  →  10  →  3  →  6  →  14
```

Both destructive questions refuse to run unless you confirm. If you want to run
one non-interactively:

```
CKA_CONFIRM=yes ./run.sh 6
```

## Two things that clash

- **Questions 2 and 16 both want port 443 on the node.** Question 16's setup
  scales the ingress controller down, and question 2's setup scales it back up.
  So just re-run `./run.sh 2` if you go back to it after 16.
- **Question 13 needs a CNI that enforces NetworkPolicy.** If its check warns
  that a blocked Pod got through, the playground is probably running Flannel,
  which ignores policies. Do question 6 (install Calico) first.

## Requirements in the playground

`kubectl`, `python3`, `curl` — all present by default. Questions 3, 14 and 16
also need `root`, and 16 needs `openssl`. Questions 2, 3, 6, 10, 12 and 15
download things, so the cluster needs internet access.
