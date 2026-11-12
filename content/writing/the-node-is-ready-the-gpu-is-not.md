---
title: "The node is Ready. The GPU is not."
slug: the-node-is-ready-the-gpu-is-not
description: "A Kubernetes node, its host driver and its device plugin can each look healthy while a Pod still cannot receive a GPU. Six controlled runs show where those signals disagree."
date: 2026-11-12
lastmod: 2026-11-12
draft: false
socialImage: images/writing/gpu-readiness-boundaries.png
socialImageAlt: Node readiness and GPU allocation signals recover at different times
heroImage: images/writing/gpu-readiness-boundaries.png
heroImageAlt: Node readiness and host driver health stay green while the device plugin, allocatable GPU and CUDA qualification recover at different times
cardImage: images/writing/gpu-readiness-boundaries.png
---

Kubernetes reported the node `Ready`. The NVIDIA driver answered normally. The
node still advertised one GPU in its capacity. A Pod requested that GPU, but
could not start.

None of those observations was wrong. They answered different questions.

This matters, when a GPU node starts, when its device plugin restarts and when a
platform decides, that recovery is complete. If one healthy signal stands in for
the whole allocation path, an operator can call the node recovered, while the
GPU is still unavailable to workloads.

I ran the same device-plugin removal and recovery sequence six times on a
single-GPU Kubernetes node. The last three runs used a monotonic clock and a
state recorder. The order stayed the same every time.

## Ready for what?

Kubernetes defines [`Ready=True`](https://kubernetes.io/docs/reference/node/node-status/)
as a healthy node, that is ready to accept Pods. It does not execute a CUDA
operation and it does not prove, that every extended resource on the node can be
allocated.

A successful host-level `nvidia-smi` check answers a narrower question. It
proves, that the host can talk to the driver and see the GPU. It says nothing
about device-plugin registration, the resource published through the kubelet,
container device injection or a CUDA process inside a Pod.

The NVIDIA device plugin adds another signal. Kubernetes documents the
[registration path](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/device-plugins/)
as the plugin reporting devices to the kubelet, followed by the kubelet
publishing them in Node status. Its DaemonSet can therefore be ready, while the
kubelet is still publishing the previous resource state.

I find it useful to keep four questions separate:

1. Is the machine healthy enough for Kubernetes to use?
2. Can the host see and communicate with the GPU?
3. Is Kubernetes advertising the GPU as allocatable?
4. Can a real Pod receive the device and execute CUDA?

Only the fourth question exercises the path, that a workload actually needs.

## The experiment

The test used one Linux host with an RTX 4090, K3s v1.37.1, NVIDIA driver
595.99.02 and NVIDIA k8s-device-plugin 0.20.1. It used the classic device-plugin
path, not Dynamic Resource Allocation.

Each run started from the same baseline:

- node `Ready=True`
- host `nvidia-smi` successful
- device-plugin DaemonSet at 1/1
- GPU capacity and allocatable both equal to one
- no active CUDA process

I made the device-plugin DaemonSet match no node. This removed only the plugin
Pod. It did not stop the kubelet, container runtime or host driver.

After the plugin disappeared, I submitted a Job that requested
`nvidia.com/gpu: 1` and ran NVIDIA's pinned
[vector-add CUDA sample](https://github.com/NVIDIA/k8s-device-plugin#running-gpu-jobs).
Then I restored the DaemonSet and let the same pending Job continue. The recorder
sampled Node readiness, driver health, GPU capacity and allocatable, plugin
state, Pod state and host GPU processes. Elapsed-time observations used
`/proc/uptime`, rather than wall time.

The qualification Job was deliberately small:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: cuda-qualification
spec:
  backoffLimit: 0
  activeDeadlineSeconds: 120
  template:
    spec:
      restartPolicy: Never
      runtimeClassName: nvidia
      containers:
        - name: vectoradd
          image: nvcr.io/nvidia/k8s/cuda-sample:vectoradd-cuda12.5.0@sha256:7c7540bdf1f942d4fb6db97069fd6c289471b54ac29e3c7fcdf914cf77af7d41
          resources:
            requests:
              nvidia.com/gpu: 1
            limits:
              nvidia.com/gpu: 1
```

## What happened

All six runs followed this order:

1. The plugin disappeared.
2. Node `Ready`, the host driver check, GPU capacity and allocatable still
   looked healthy.
3. Allocatable later changed from one to zero. Capacity remained one.
4. The qualification Pod stayed Pending with `Insufficient nvidia.com/gpu`.
5. The replacement plugin became ready, while allocatable was still zero.
6. Allocatable later returned to one.
7. The existing pending Pod scheduled and passed CUDA without being recreated.

The last three runs produced these monotonic observations:

| Run | Plugin absent to first allocatable 0 | Plugin ready to first allocatable 1 |
|---|---:|---:|
| R1-04 | 5.35 s | 7.10 s |
| R1-05 | 7.02 s | 8.72 s |
| R1-06 | 8.02 s | 9.87 s |

These are not component timeout constants. They measure from one recorder
observation to another on this host. The actual transition occurred between
adjacent samples, normally about half a second apart.

Across the 273 monotonic samples, Node `Ready` never became false, the host
driver check never failed and GPU capacity never changed from one.

The important result is the order, not whether one run took five seconds and
another took eight. Plugin presence, published allocatable state and successful
workload admission changed at different times.

## Capacity is not current availability

The Node object exposes both
[capacity and allocatable](https://kubernetes.io/docs/reference/node/node-status/#capacity).
During these runs, capacity stayed at one while allocatable fell to zero.

That distinction is useful. Capacity kept the previously published GPU
resource. Allocatable reflected whether Kubernetes could currently offer it to
new workloads. Neither value told me whether an already allocated process was
healthy and neither executed CUDA.

The scheduler behaved correctly, when allocatable reached zero. It kept the
qualification Pod pending and reported `Insufficient nvidia.com/gpu`. When
allocatable returned, it scheduled the same Pod and the CUDA check passed.

The confusing interval was on either side of that update. After plugin removal,
the Node object briefly retained the old allocatable value. After plugin
recovery, the DaemonSet was ready before the Node object published the GPU as
allocatable again.

## A plugin Pod being ready is not recovery

A DaemonSet at 1/1 proves that its Pod passed Kubernetes readiness. It does not
prove that every downstream consumer has observed and acted on the new state.

In this test, the replacement plugin became ready first. The kubelet published
allocatable one later. Only then could the scheduler place the qualification
Pod and only the completed CUDA calculation proved the container path.

This is a normal distributed-systems boundary. The mistake is not, that the
states change asynchronously. The mistake is treating one of them as a
transactional statement about all the others.

## A better admission rule

I would not replace generic Node readiness with a GPU-specific CUDA check. A
node can run ordinary workloads while its accelerator path is recovering.
Instead, GPU admission should have its own state.

One practical sequence is:

1. keep new GPU workloads away from the node during bootstrap or recovery
2. require the host driver check to pass
3. require the device plugin to be ready
4. require the expected GPU capacity and allocatable values
5. run a small pinned Pod, that requests the GPU and executes CUDA
6. open the node to ordinary GPU workloads only after that Pod succeeds

A taint can hold ordinary GPU work back, while a controlled qualification Pod
uses an explicit toleration. That mechanism is only as strong as the surrounding
policy. If tenants can add that toleration or remove the taint, they can bypass
the restriction.

The qualification workload should be small, pinned and deterministic. It
should not download a model or dataset during the test. It should print enough
information to diagnose device injection and return a clear pass or failure.
It also should not run continuously. A useful time to qualify is after node
bootstrap, plugin recovery or another change to the GPU allocation path.

## What this experiment does not show

This was a component-boundary test on one node and one GPU. The plugin was
removed through its DaemonSet scheduling rule rather than by a crash. Kubelet,
containerd and the host driver stayed healthy.

The result does not cover DRA, MIG, MPS, time-slicing or a multi-node GPU pool.
It also does not show, that every plugin restart creates a long admission gap.
A quick restart during an active allocation behaved differently in a separate
test: the running CUDA process continued, capacity and allocatable stayed at
one and a second request remained pending until the owner terminated.

That difference is another reason to name the state being tested. Plugin
absence, plugin replacement, resource advertisement, workload ownership and
successful CUDA execution are related, but they are not the same event.

## The useful question

"Is the node ready?" is too broad, when a platform has to decide whether to
admit GPU work.

Ask which layer is ready. Then test the last layer, that matters to the
workload.
