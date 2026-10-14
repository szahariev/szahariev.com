---
title: Stanislav Zahariev
description: Stanislav Zahariev builds sovereign cloud control planes on open infrastructure. His work spans Kubernetes, OpenStack and distributed systems.
heroTitle: Solving the hard parts of cloud control planes
heroIntro: Kubernetes and the infrastructure beneath it often operate as separate systems. I'm building the control plane that connects them into a working cloud platform.
soveritaIntro: Soverita is a European sovereign cloud governance platform. It lets organizations use their existing infrastructure as a self-service cloud while keeping control over the systems that operate it.
soveritaWork: I design and implement the APIs and workflows connecting Kubernetes to infrastructure platforms. The work involves provisioning machines, attaching storage, configuring routes and handling resources left behind when operations are interrupted.
writingTitle: How the pieces fit and where they fail
firstEssayTitle: What makes a cloud sovereign?
firstEssayText: The first essay examines five architectural invariants behind operator independence, with practical ways to verify each one in a running system.
focus:
  - title: Who actually controls the cloud?
    text: Keeping data in Frankfurt means little if someone outside your jurisdiction controls the keys needed to decrypt it.
  - title: From machines to Kubernetes nodes
    text: Kubernetes expects a node. An infrastructure platform provides a machine, network interfaces, volumes and routes. Making those resources work together as one Kubernetes node is the hard part.
  - title: When an operation times out
    text: A missing response doesn't tell you whether the operation failed or completed successfully. Retry a machine creation request without checking, and you might end up with two machines instead of one.
selectedTalks:
  - Sovereignty is a control plane property, not a data-residency checkbox
  - Why a VM API isn't enough for Kubernetes
  - Idempotency is more than "safe to retry"
---
