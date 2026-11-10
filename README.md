# CKA Practice — my own questions

My own CKA exercises, taken from the questions I saw. Each one sets itself up
in a real cluster, and a check script tells me PASS or FAIL per requirement.

## Use it on KillerCoda

1. Open the CKA playground: https://killercoda.com/playgrounds/scenario/cka
2. In the terminal:

```
git clone https://github.com/<my-user>/cka-prep.git ~/cka-prep
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

| #  | Topic                           | Built |
| -- | ------------------------------- | ----- |
| 1  | HPA                             | yes   |
| 2  | Ingress                         | —     |
| 3  | cri-dockerd                     | —     |
| 4  | Resource allocation CPU/memory  | —     |
| 5  | Sidecar                         | —     |
| 6  | CNI Calico                      | —     |
| 7  | StorageClass                    | —     |
| 8  | Service                         | —     |
| 9  | PriorityClass                   | —     |
| 10 | Argo CD                         | —     |
| 11 | PVC MariaDB                     | —     |
| 12 | Migrate Ingress to Gateway API  | —     |
| 13 | NetworkPolicy                   | —     |
| 14 | etcd                            | —     |
| 15 | CRDs                            | —     |
| 16 | ConfigMap                       | —     |

## Two warnings

- **Questions 6 (CNI) and 14 (etcd) break the cluster on purpose.** Run them
  last in a session, or on a fresh playground of their own.
- Some questions need extra things installed first (an ingress controller,
  Gateway API CRDs, cert-manager, Helm, the cri-dockerd .deb). Their `setup.sh`
  installs them, so those take longer to start.
