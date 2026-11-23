---
title: "Getting a CSI driver working across Kubernetes distributions"
slug: csi-driver-kubernetes-distributions
description: "Why a CSI driver can run on K3s yet fail to register or mount volumes on another distribution, and how to check the storage path beyond healthy Pods."
date: 2026-11-23
lastmod: 2026-11-23
draft: false
socialImage: images/writing/csi-node-registration.png
socialImageAlt: The registration socket and CSI driver socket connect different components through kubelet's actual root directory
heroImage: images/writing/csi-node-registration.png
heroImageAlt: The node driver registrar creates a registration socket for kubelet, while kubelet uses a separate socket to call the CSI node plugin
heroImageZoom: true
cardImage: images/writing/csi-node-registration.png
---

On k0s I had a CSI node plugin with three running containers and no driver
registered in `CSINode`. The registrar had created its socket successfully. It
was just in a directory kubelet did not watch.

The driver did not need a different implementation of `NodePublishVolume`. It
needed the right kubelet directory in its deployment.

That was one of the problems I worked through, while taking a Linux block
CSI driver across kubeadm, K3s, RKE2, k0s, MicroK8s, Canonical Kubernetes and
Talos Linux. Talos changes the node operating environment as well as the way
Kubernetes is installed. The differences were mostly outside the CSI RPCs:
filesystem paths, mount visibility, admission policy, installed controllers and
how images reached the node.

I checked each installation with a workload, that received a volume, wrote to
it and read the same data after the first Pod was removed.

## CSI leaves deployment work to the operator

The Container Storage Interface (CSI) defines the calls between Kubernetes and
a storage driver. A typical block CSI installation has a controller component
and a node component. The controller provisions volumes and handles operations
such as attachment through the storage or cloud API. The node component
discovers the device and makes it available inside a workload, including
formatting and mounting, when a filesystem is requested.

Those components depend on different parts of the environment. The controller
needs credentials and a working path to the API. The node plugin needs access
to host devices, kubelet's paths and the mount operations its driver performs.
The upstream [deployment guide](https://kubernetes-csi.github.io/docs/deploying.html)
describes the controller and node layouts separately.

A passing controller check therefore says little about whether kubelet can
reach the node plugin. A PVC can even be `Bound`, while its Pod cannot mount the
volume. With delayed binding and topology-aware provisioning, the failure may
instead appear, while the PVC is still `Pending`.

I investigate registration, provisioning, attachment and mounting separately.
Each has its own logs and failure modes.

## Kubelet registration uses two sockets

The `node-driver-registrar` runs beside the CSI node plugin, but it is not the
plugin. There are two socket paths to follow:

| Socket | Who creates it | What it does |
|---|---|---|
| Registration socket | Node driver registrar | Lets kubelet discover the driver and its endpoint |
| CSI driver socket | CSI node plugin | Receives CSI calls from kubelet |

In a conventional layout, the registration socket is under
`<kubelet-root>/plugins_registry/`, while the driver socket is under
`<kubelet-root>/plugins/<driver-name>/`. Inside the Pod, that second socket may
be mounted at a short path such as `/csi/csi.sock`.

The registrar's `--csi-address` identifies the socket as the registrar sees it
inside its container. Its `--kubelet-registration-path` identifies the same CSI
socket as kubelet sees it on the host. Despite its name, the latter is not the
registration socket. The [registrar documentation](https://github.com/kubernetes-csi/node-driver-registrar#usage)
explains this distinction.

The registrar can talk to the plugin inside the Pod, while kubelet cannot find
either the registration socket or the advertised driver endpoint on the host.

For the k0s failure, the chart was using `/var/lib/kubelet`, but kubelet was
using `/var/lib/k0s/kubelet`. A directory existed at the first path, and the
deployment could create its registration subdirectory there. Neither fact made
it the right place to register.

Using `Directory` instead of `DirectoryOrCreate` catches a missing directory.
An existing, but unused directory still passes that check.

The first Kubernetes-side check is the driver entry on the affected node:

```sh
kubectl get csinode worker-1 -o yaml
```

Look for the expected driver under `spec.drivers`, including its `nodeID`.
That is the node's registration record. The separate `CSIDriver` object
describes the driver at cluster scope.

The CSI [liveness sidecar](https://kubernetes-csi.github.io/docs/livenessprobe.html)
checks the driver's CSI endpoint, independently of kubelet registration and
workload mounting. A driver can pass that check in the wrong directory.

If the entry is absent, read the registrar, plugin and kubelet logs together.
A wrong path, failed `NodeGetInfo`, permissions problem or rejected registration
can all prevent the entry from appearing.

## Find the effective kubelet directory

These were the paths in the configurations I worked with:

| Installation | Kubelet root |
|---|---|
| kubeadm | `/var/lib/kubelet` |
| K3s | `/var/lib/kubelet` |
| RKE2 | `/var/lib/kubelet` |
| k0s | `/var/lib/k0s/kubelet` |
| MicroK8s | `/var/snap/microk8s/common/var/lib/kubelet` |
| Canonical Kubernetes, the `k8s` snap | `/var/lib/kubelet` |
| Talos Linux | `/var/lib/kubelet` |

Check the actual node before using a value from this table. Install flags and
custom configuration can change the path. k0s documents its
[different default and the CSI implications](https://docs.k0sproject.io/stable/storage/).
Canonical's [MicroK8s CSI example](https://canonical.com/microk8s/docs/how-to-nfs)
also configures the snap-specific kubelet directory explicitly.

On a node with a shell, inspect the process arguments and the configuration
used by the installer. For example:

```sh
ps aux | grep -E 'kubelet|kubelite'
sudo readlink -f /var/lib/kubelet
```

The first command may not show the effective root. Some distributions embed
kubelet or put its arguments in a file. An empty result is not evidence, that
the default applies. On MicroK8s, inspect its component arguments as well:

```sh
sudo sed -n '/--root-dir/p' /var/snap/microk8s/current/args/kubelet
```

The [MicroK8s troubleshooting guide](https://canonical.com/microk8s/docs/troubleshooting#examining-the-configuration)
describes where those argument files live. On an API-managed operating system,
use its configuration and inspection tools instead of assuming SSH is
available.

Long roots also leave less room for the driver name in a Unix socket path.
Linux normally has space for 107 pathname bytes plus the terminating null
byte. Check both host-visible socket paths, including the endpoint passed to
`--kubelet-registration-path`. A short `/csi/csi.sock` inside the Pod does not
shorten the path kubelet uses to connect. The [Linux socket documentation](https://man7.org/linux/man-pages/man7/unix.7.html)
describes the limit.

Do not change the kubelet root of an existing node merely to fit a chart's
default. Existing Pod and volume state lives under that directory. Configure
the driver for the node's layout, or plan a node migration separately.

## Registration and mounting need different path checks

MicroK8s exposed another reason not to stop at registration. In the setup I
used, `/var/lib/kubelet` resolved to the snap-specific directory on the host.
That made the short path look plausible.

But kubelet sends absolute staging and publishing paths to the driver. A
target under `/var/snap/microk8s/common/var/lib/kubelet/` must be usable inside
the plugin container too. A host symlink does not automatically make that
absolute path resolve in another mount namespace.

For a plugin that uses kubelet's target paths directly, a straightforward layout
mounts the effective kubelet root at the same absolute path inside the plugin.
The socket directory can still be mounted separately at `/csi`. These are
different mounts with different purposes.

Here is a manifest fragment illustrating that layout for k0s. It is not a
complete DaemonSet or an installation command:

```yaml
# Under spec.template.spec.containers, on the CSI node plugin:
securityContext:
  privileged: true
volumeMounts:
  - name: kubelet-root
    mountPath: /var/lib/k0s/kubelet
    mountPropagation: Bidirectional

# Under spec.template.spec:
volumes:
  - name: kubelet-root
    hostPath:
      path: /var/lib/k0s/kubelet
      type: Directory
```

A bind mount can make files visible without propagating a new filesystem mount
created by the plugin.
The [CSI deployment examples](https://kubernetes-csi.github.io/docs/deploying.html#driver-volume-mounts)
use bidirectional propagation for the mount path. Kubernetes permits
`Bidirectional` only in privileged containers. The example sets that on the
CSI node plugin, not on application Pods. Admission policy must also permit
it. See the [host requirements and security implications](https://kubernetes.io/docs/concepts/storage/volumes/#mount-propagation).

If kubelet itself runs inside a container, there is another mount namespace in
the path. Check that boundary as well. A mount visible in the plugin but not to
kubelet is not fixed by changing the volume API or extending a provisioning
timeout.

For a read-only host inspection, `findmnt` can show the mount containing the
effective root and its propagation mode:

```sh
sudo findmnt -T /var/lib/k0s/kubelet -o TARGET,SOURCE,FSTYPE,PROPAGATION
```

That is one part of the check. Compare it with the actual Pod mounts and any
containerized kubelet configuration. Inspect the rendered DaemonSet, not only
the Helm values you intended to set.

## Check admission and scheduling before debugging storage

A node plugin that mounts host devices is an infrastructure component with
privileges an application should not have. The [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
restrict host paths, privileged containers and host namespaces in the Baseline
and Restricted profiles. A chart that installs in a permissive cluster may be
rejected in a hardened one.

Check events before changing the driver. A rejected Pod has not reached device
discovery or mounting. Increasing a CSI timeout cannot fix its admission
policy.

Give the required component an explicit, narrowly administered exception. Do
not disable Pod Security across the cluster. If the exception is a dedicated
namespace, restrict who can create workloads there. An unrestricted namespace
is a privileged deployment surface, not just a label needed to finish Helm.

Keep scheduling separate from admission too. A controller Deployment may be
unschedulable on a cluster made entirely of tainted control plane nodes. The
node DaemonSet has a different placement requirement. Check each workload's
tolerations and affinity instead of adding every toleration to both.

The cloud controller manager (CCM) adds another dependency, when the cluster uses
an external cloud provider. Nodes can remain uninitialized until CCM identifies
them. Whether a CSI component should tolerate that taint depends on its role
and the bootstrap order. The cloud controller must be able to initialize the
node. Making the storage controller ignore the taint does not perform that
initialization.

## Match volume placement to the node

Moving to another installation can also change, which zones the nodes and
storage can reach. A driver can register correctly and still provision a
volume in the wrong place for a workload.

With CSI topology enabled, `NodeGetInfo` reports the node's accessible topology.
Kubelet records the driver's topology keys in `CSINode` and the corresponding
labels on the Node. The provisioner passes placement requirements to
`CreateVolume`. The driver's returned volume topology becomes the PV's node
affinity. Those values need to agree with where the storage is actually
accessible. The upstream [CSI topology guide](https://kubernetes-csi.github.io/docs/topology.html)
follows that exchange.

I compare the StorageClass's `volumeBindingMode` and `allowedTopologies` with
the driver's keys under `CSINode.spec.drivers[].topologyKeys` and the Node's
labels. For a bound claim, I also inspect the PV's `spec.nodeAffinity`.
`WaitForFirstConsumer` delays provisioning until the scheduler has selected a
node. A PVC waiting for that selection may be behaving correctly. Check its
events and any `volume.kubernetes.io/selected-node` annotation before treating
`Pending` as a provisioning failure.

## Snapshot support is more than one sidecar

The tested RKE2 configuration supplied the common snapshot controller and CRDs.
The initial K3s fixture did not, so I left the driver's snapshotter sidecar
disabled until those components were installed. The driver's snapshot RPCs did
not change. The cluster prerequisites did.

Kubernetes CSI snapshots involve three distinct parts:

- the snapshot CRDs, which define the API objects
- a common snapshot controller, managed at cluster scope
- the external-snapshotter sidecar for the CSI driver

The upstream [snapshot controller documentation](https://kubernetes-csi.github.io/docs/snapshot-controller.html)
assigns the common controller and CRDs to the cluster rather than to each
driver installation. RKE2 lists snapshot components among its
[packaged charts](https://docs.rke2.io/advanced#disabling-server-charts), which
can also be disabled. Check what is actually installed instead of treating the
distribution name as proof.

```sh
kubectl get crd volumesnapshots.snapshot.storage.k8s.io \
  volumesnapshotcontents.snapshot.storage.k8s.io \
  volumesnapshotclasses.snapshot.storage.k8s.io
kubectl get deployments -A
```

After checking the CRDs, inspect the relevant Deployment and sidecar. Then
create a snapshot, restore it to a separate PVC and read back the data.

If snapshots are outside an installation's intended scope, disable the relevant
driver sidecar where its chart supports that choice. Record that scope. A
basic volume readback and a snapshot restore are separate tests.

## The node pulls the images

Talos kept the usual kubelet root in this setup, but it invalidated a different
assumption in my harness: copying an image archive over SSH and importing it
with `ctr`.

Talos has no general-purpose SSH shell. Its [operating model](https://docs.siderolabs.com/talos/v1.14/overview/what-is-talos)
uses an API. For this fixture, the driver image had to be available through a
registry the node could reach, with the registry configuration delivered through
the machine configuration.

That is also a cloud layout question. Check the node's path to the registry,
the controller's path to the cloud API and the node plugin's path to any
metadata service it requires. Run each check from the component that uses it.

For image pulls, follow node DNS, network reachability, TLS trust and registry
authentication. An `imagePullSecret` cannot repair a name that does not resolve
or a registry certificate the runtime does not trust. Kubernetes explains how
the [kubelet uses image pull credentials](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod).

Inventory the sidecars as well as the main driver image. In a restricted
network, mirroring the plugin but forgetting the registrar, provisioner,
attacher or test workload leaves an incomplete installation. A registry mirror
or supported image cache can solve delivery without changing the CSI protocol.

A driver using a guest-visible virtual block device has different host
requirements from one that opens an iSCSI session or uses NFS. Check the
transport and host services for the driver you are installing.

## The formatter and node kernel must agree

The node plugin image brings userspace tools, but the node's kernel mounts
the filesystem. I hit this with XFS: a newer `mkfs.xfs` in the image enabled
on-disk features that an older node kernel rejected. Formatting succeeded,
then mounting failed with an incompatible-feature error in the kernel log.

I set compatible format defaults for new XFS volumes. The important check was
the filesystem those defaults produced, not just whether the image included
`mkfs.xfs`. XFS documents [features that prevent mounting on older kernels](https://man7.org/linux/man-pages/man8/xfs_admin.8.html).

Record the formatter version and the target nodes' kernels. If a volume may
move between nodes, its filesystem must work on every intended destination.
Changing the formatter defaults affects newly formatted volumes. Do not
reformat an existing data volume to try to fix a mount failure.

## Test the volume from a workload

I use a short sequence before expanding the feature matrix:

1. Confirm the node has registered the expected CSI driver.
2. Create a small PVC using an explicitly named StorageClass.
3. Start a writer Pod that mounts it and writes a known marker.
4. Flush the write, record a checksum and wait for the writer Pod to terminate.
5. Start a reader Pod using the same PVC and compare the data and checksum.

An explicit StorageClass matters. An existing default can make a PVC bind to a
different provisioner and produce a convincing test of the wrong storage. Check
the bound PV's `spec.csi.driver` and volume handle, not just the claim status.
The [StorageClass documentation](https://kubernetes.io/docs/concepts/storage/storage-classes/)
explains default selection.

Use the application's intended `runAsUser`, `runAsGroup` and `fsGroup` for the
writer and reader too. A root-only check can pass while the real application
gets a permission error on the same mounted volume. Inspect
`CSIDriver.spec.fsGroupPolicy`, when investigating ownership. Kubernetes may
apply the ownership changes itself or delegate them to a driver, that supports
`VOLUME_MOUNT_GROUP`. The [CSI fsGroup guide](https://kubernetes-csi.github.io/docs/support-fsgroup.html)
explains the distinction.

These are the relevant writer and reader commands inside a disposable test
Pod. Both Pods must mount the same PVC at `/data`:

```sh
# Writer
echo csi-portability-check > /data/probe.txt
sync
sha256sum /data/probe.txt
```

```sh
# Reader, after the writer Pod has been removed
cat /data/probe.txt
sha256sum /data/probe.txt
```

Run this with a new test volume, not application data. Creating the PVC may
allocate billable storage. Inspect its reclaim policy before cleanup, because
deleting a claim with a `Delete` policy can delete the backing volume.

Matching readback checks persistence through Pod replacement. A volume can
remain attached to the same node between Pods. To test detach and reattach
with a driver that uses controller attachment, follow the `VolumeAttachment`
lifecycle and the backend's attachment state as well.

A cross-node test needs a second node and deliberate scheduling to it.
Expansion, snapshots, raw block, failure recovery and concurrent operations
each need their own cases too.

A separate run of the configured Linux profile on K3s on 30 October passed
88 cases with 126 runtime skips. It used a single-node K3s v1.31.5 fixture with
Kubernetes e2e v1.31.14, excluding Disruptive, Serial, Flaky and Windows cases.
That result does not extend snapshot, expansion or failure coverage to all the
other distributions.

## A short investigation order

When moving the driver to another installation, I check these in order:

| Observation | Next check |
|---|---|
| Node plugin is Pending or absent | Admission events, node placement and taints |
| Images cannot be pulled | The node's registry DNS, connectivity, trust and credentials |
| Plugin is running but missing from CSINode | Registrar logs, kubelet root and both socket paths |
| PVC stays Pending | Selected provisioner, controller events, topology and binding mode |
| PVC is Bound but Pod cannot start | Volume placement, attachment, guest device discovery, target paths and mount propagation |
| Formatting succeeds but mounting fails | Node kernel logs and the filesystem features enabled by the formatter |
| Volume mounts but the application cannot write | Workload UID/GID, fsGroup handling and filesystem permissions |
| Snapshots fail while volumes work | Snapshot CRDs, common controller, sidecar and a real restore |

I use these checks to find the failing component before changing a timeout or
retrying the installation.

The distribution name tells me where to start looking. The actual paths,
kernel, placement and permissions decide whether the volume works. I finish
with a workload reading back what it wrote.
