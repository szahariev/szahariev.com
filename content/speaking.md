---
title: Speaking
description: Stanislav Zahariev speaks about sovereign cloud control planes, Kubernetes, OpenStack and the distributed-systems problems behind reliable cloud platforms.
wide: true
availabletalks:
  - title: Sovereignty is a control plane property, not a data-residency checkbox
    text: Data residency answers where the bytes are. It says nothing about who controls the keys needed to decrypt them or whether the operator can move the system elsewhere. This talk works through five architectural invariants and a vendor-neutral checklist for testing a sovereignty claim.
    topics:
      - Sovereign cloud
      - Open infrastructure
      - Security
      - Platform engineering
  - title: Why a VM API isn't enough for Kubernetes
    text: Creating a VM is only the beginning. Kubernetes also needs networking, storage, topology and a reliable account of what happened when an operation was interrupted. This talk follows those responsibilities across Cluster API, the cloud controller manager and the CSI driver.
    topics:
      - Kubernetes
      - OpenInfra
      - Platform engineering
  - title: Idempotency is more than "safe to retry"
    text: An idempotency key is easy to add and hard to define. This talk examines provider calls that succeed before the caller sees the result, keys reused with different input and operations that are later compensated. It turns those cases into a practical outcome model and API review checklist.
    topics:
      - Distributed systems
      - APIs
      - Cloud native
      - Platform engineering
  - title: Deleting a cloud resource is a distributed-systems problem
    text: A single DELETE can remove the local record while leaving the provider resource running, along with a child volume that nothing tracks anymore. This talk follows the states hidden behind that request and shows how to make the deletion workflow recoverable.
    topics:
      - SRE
      - Cloud native
      - Distributed systems
      - Platform operations
developingtalks:
  - title: An availability zone is not just a string
    text: Choosing an availability zone when launching a machine is easy. Keeping Kubernetes failure domains, machine placement, root volumes and later disk attachments in the same topology is not. This talk follows one zone choice through the control plane.
  - title: "The network is the cloud: where multi-tenant abstractions break"
    text: Routes, security groups and peering are usually modeled as separate CRUD resources, but together they form the tenant isolation boundary. Publishing a node's pod CIDR into a route table does nothing unless the node's interface is allowed to carry it.
  - title: "Two tenants, one CIDR: multi-tenant DNS when source IP lies to you"
    text: Two tenants can use the same private address range, so source IP alone cannot tell a shared DNS service which tenant a query belongs to. The answer has to come from the network path, not an address that may mean something different in every tenant.
  - title: Can you prove your architecture is still true?
    text: Architecture documents drift away from code. A claim ledger ties each important assertion to a version of the code that demonstrates it, a test that fails when it stops being true, or a clear record that the claim has not yet been proven.
  - title: AI can generate an implementation, but it cannot prove it works
    text: Generated code arrives with generated tests that agree with it. The talk is about what you run to find out whether either one is telling the truth.
---

My talks come from hands-on engineering work and more than twenty years of
building distributed systems. Much of my current work sits between Kubernetes
and the infrastructure underneath it, where both systems can look healthy
while the cloud they form is broken.

To invite me to speak at a conference or meetup, join a panel or podcast,
or run a workshop, email me at [szahariev@szahariev.com](mailto:szahariev@szahariev.com).

## Available talks

{{< talk-list group="availabletalks" >}}

## Talks in development

{{< talk-list group="developingtalks" >}}

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
