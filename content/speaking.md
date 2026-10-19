---
title: Speaking
description: Stanislav Zahariev speaks about sovereign cloud control planes, Kubernetes, OpenStack and the distributed-systems problems behind reliable cloud platforms.
---

My talks come from hands-on engineering work and more than twenty years of
building distributed systems. Much of my current work sits between Kubernetes
and the infrastructure underneath it, where both systems can look healthy
while the cloud they form is broken.

To invite me to speak at a conference or meetup, join a panel or podcast,
or run a workshop, email me at [szahariev@szahariev.com](mailto:szahariev@szahariev.com).

## Available talks

### Sovereignty is a control plane property, not a data-residency checkbox

Data residency answers where the bytes are. It says nothing about who controls
the keys needed to decrypt them or whether the operator can move the system
elsewhere. This talk works through five architectural invariants and a
vendor-neutral checklist for testing a sovereignty claim.

**Best fit:** sovereign cloud · open infrastructure · security · platform engineering

### Why a VM API isn't enough for Kubernetes

Creating a VM is only the beginning. Kubernetes also needs networking, storage,
topology and a reliable account of what happened when an operation was interrupted.
This talk follows those responsibilities across Cluster API, the cloud controller
manager and the CSI driver, and shows which component owns each part of the node
lifecycle.

**Best fit:** Kubernetes · OpenInfra · platform engineering

### Idempotency is more than "safe to retry"

An idempotency key is easy to add and hard to define. This talk examines
provider calls that succeed before the caller sees the result, keys
reused with different input and operations that are later compensated.
It turns those cases into a practical outcome model and API review checklist.

**Best fit:** distributed systems · APIs · cloud native · platform engineering

### Deleting a cloud resource is a distributed-systems problem

A single `DELETE` can remove the local record while leaving the provider resource
running, along with a child volume that nothing tracks anymore. This talk follows
the states hidden behind that request and shows how to make the deletion workflow
recoverable.

**Best fit:** SRE · cloud native · distributed systems · platform operations

## Talks in development

### An availability zone is not just a string

Choosing an availability zone when launching a machine is easy. Keeping Kubernetes
failure domains, machine placement, root volumes and later disk attachments in the
same topology is not. This talk follows one zone choice through the control plane and
shows what breaks when any service treats it as optional metadata.

### The network is the cloud: where multi-tenant abstractions break

Routes, security groups and peering are usually modeled as separate CRUD resources,
but together they form the tenant isolation boundary. Publishing a node's pod CIDR
into a route table, for example, does nothing unless the node's interface is allowed
to carry it.

### Two tenants, one CIDR: multi-tenant DNS when source IP lies to you

Two tenants can use the same private address range, so source IP alone cannot tell
a shared DNS service which tenant a query belongs to. The answer has to come from
the network path, not an address that may mean something different in every tenant.

### Can you prove your architecture is still true?

Architecture documents drift away from code. A claim ledger ties each important
assertion to a version of the code that demonstrates it, a test that fails when
it stops being true, or a clear record that the claim has not yet been proven.

### AI can generate an implementation, but it cannot prove it works

Generated code arrives with generated tests that agree with it. The talk is
about what you run to find out whether either one is telling the truth.

## Speaker biography

Stanislav Zahariev is a distributed systems engineer working on sovereign cloud
control planes and open infrastructure. For more than twenty years, he has built
distributed systems across carrier-grade telephony, fintech and AI. He writes and
speaks about Kubernetes, OpenStack and what happens when cloud architecture meets
real systems and real failures.

[Download portrait headshot]({{< static-url "images/headshot-portrait.jpeg" >}}) ·
[Download square headshot]({{< static-url "images/headshot-square.jpeg" >}}) ·
[LinkedIn](https://www.linkedin.com/in/stanislav-zahariev/) ·
[Bluesky](https://bsky.app/profile/szahariev.bsky.social)
