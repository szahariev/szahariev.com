---
title: "Sovereignty is a control plane property"
description: "Data residency tells you where bytes are stored. It does not tell you who controls identity, keys, audit evidence and recovery, or whether the operator can move the platform elsewhere."
date: 2026-10-13
lastmod: 2026-10-13
draft: false
---

Suppose a workload runs in Frankfurt and its data stays there. Location alone
does not tell you who can grant administrative access, unwrap a disk key,
replace the software that runs the cloud, alter its audit trail or restore it
when something fails.

Those are control plane questions. A cloud is sovereign only when its operator
has the authority, keys, software and knowledge to keep it running without
asking an outside party for permission. The operator must also be able to move
or retire the platform without losing access to its data, configuration or
control plane state.

Moving a component into the operator's data center does not necessarily move
control with it. It may still depend on an identity issuer, key service,
container registry, certificate authority or recovery process controlled by
someone else. Self-hosting one component often exposes the next dependency.

I find five concrete tests more useful than arguing over whether a cloud
deserves the word sovereign. Together they cover authority, key custody,
evidence, continued operation and exit. They are not a certification scheme.
Each test starts with a specific dependency or failure. Without that, a claim
of independence is too vague to test.

## Follow the control path

A claim of independence should say what the operator needs to do on its own and
what must still work when an outside service is unavailable. Can the operator
patch and restart the platform without help from its supplier? Can it prevent
the infrastructure provider from decrypting a disk? Can it move workloads and
control plane state elsewhere? These are different claims, and they need
different evidence.

Take an ordinary request to create a machine. The user authenticates to an
identity service. An API evaluates policy. A controller calls the infrastructure
provider. A key service may release a key for the disk. An audit service records
what happened. The software running those services came through a build and
release system. Those connections also depend on DNS, certificates and accurate
time.

{{< diagram src="sovereignty-control-path.svg" caption="A deployment can keep its workloads and data in one place while control still passes through systems outside that location." >}}

I follow the request through every system that can authorize it, carry it out or
record what happened. For every system on that path, I want to know who operates
it, who holds its administrative credentials, which keys it can use, and what
happens when it becomes unavailable. I also want to know whether the operator
can replace it without losing access to existing workloads or data.

An external dependency is not automatically a problem. An organization may
deliberately use a federated identity provider or rely on its software supplier
for updates. That is fine, but it sets a limit on what the operator can claim.
The operator is not independent of a service it still needs to administer or
recover the cloud, decrypt its data or verify its evidence.

## 1. An external party cannot grant itself operator authority

Identity comes first because every other control depends on who is allowed to
act. Running an identity service locally does not prove that the operator
controls administrative access. There may still be a vendor support account, a
remote recovery service or another issuer whose tokens the platform accepts for
administrative access.

Scope matters as much as authentication. If an API accepts a tenant or project
identifier from the caller and treats it as fact, a valid credential may be
enough to cross a boundary. The platform has to derive that scope from trusted
identity and resource state, then apply policy to the result.

The exceptions deserve more attention than the normal path. A break-glass
identity may be necessary, but who can activate it? Is its use time-bounded and
recorded? Can the operator disable it without help from the outside party that
controls it? A permanent vendor credential hidden behind the words "support
access" is still an external root of authority.

Start with a credential for an identity that has no permissions and prove that
the requested operation is denied. Grant that identity permission for one
narrow action and prove that it works. Revoke the credential and prove that it
stops working. Then try to cross into another tenant or project by changing the
request data. Finally, inventory every path that can create an administrator,
recover an administrative account or impersonate one.

This does not require every organization to build its own identity provider.
Federation can be a deliberate and sensible dependency. But the operator should
control which issuers are trusted, be able to revoke that trust, and retain a
recovery path that the external issuer cannot override.

## 2. The operator can allow or withhold decryption without surrendering key control

Encryption at rest says that stored data is ciphertext. It does not say who can
turn it back into plaintext.

Many cloud disks use envelope encryption. A data encryption key encrypts
the disk, while another key wraps that data encryption key. The second key is
the one a customer or operator may keep in its own key service. It does not
touch every disk block, but control over it decides whether the platform can
unwrap and use the data encryption key.

This leaves two questions: who holds the wrapping key, and who is allowed to use
it? Keeping the key in an operator-controlled HSM is not enough if one broadly
trusted platform credential can unwrap every disk key. The policy must also bind
each request to the workload and resource it belongs to. An HSM, or hardware
security module, protects the key material. By itself, it does not decide which
workload should be allowed to use which key.

Test this by making the operator-controlled key service unavailable while the
rest of the platform remains healthy. A fresh attempt to open the disk or start
a machine that uses it should fail because the platform cannot unwrap the disk
key, not because the whole control plane has been stopped. Restore access to the
wrapping key, then read the same data from the disk.

The same test also shows where that control ends. Withdrawing access prevents
the platform from obtaining the disk key again. It cannot take back plaintext
or key material already held by a running host. Deleting the key is not a
stronger custody test either. It may only prove that the operator can make its
own data unrecoverable.

## 3. The operator can retain and independently verify evidence

An audit page is useful during normal operation. It is weak evidence when the
same control plane stores the events, answers the query and decides whether its
own answer is valid.

The operator needs to take evidence away from the producer. That usually means
exported events, signed receipts, retained verification keys and a verifier that
can run independently. Signatures make changed events detectable. Linking each
receipt to its predecessor exposes gaps within the sequence. A trusted
checkpoint is also needed to detect events removed from the end.

Failures belong in the evidence too. A trail that records successful
administrative actions but omits denied requests, attempts with revoked
credentials or unauthenticated requests leaves a gap when investigating an
attack or a broken policy rollout. If an unauthenticated request says it came
from Alice, the audit record must not list Alice as a verified user.

Export a short run of events together with the material needed to verify it.
Make three copies. Change a field in the first, alter a link in the second and
remove the final event from the third. An independent verifier should reject
each copy without contacting the original service. Then rotate the signing key
and show that the older evidence remains verifiable.

I use *tamper-evident* rather than *immutable*. A signature does not stop someone
from deleting a file. A hash chain can reveal a missing event only if the
verifier has a later link or a trusted checkpoint to compare against. The design
still has to say who retains that checkpoint, which events are included and how
long the evidence is retained.

## 4. The operator can continue without outside services

Installing software in the operator's data center is not the same as making it
independent. A platform may run happily for months and still fail its first
restart without a public container registry. Certificate renewal may depend on
an external authority. Hosts may depend on public time servers or DNS resolvers.
An upgrade may fetch a chart, package or vulnerability database that was never
included in the delivery bundle.

These dependencies are easy to miss because they sit outside the main request
path. They appear during installation, restart, scaling, certificate rotation,
upgrade and diagnosis. Each of those operations needs its own disconnected
test. "It runs without internet access" is too broad to be useful unless it says
which operations were exercised and for how long.

The operator should already possess the deployment intent, artifacts, trust
roots and instructions needed to recover the platform. Release signatures must
be verifiable without calling the vendor. The artifact inventory has to come
from rendered deployment manifests rather than a handwritten list. Charts
often introduce images that are invisible in the top-level bill of materials.

Provider failure is another useful drill. Remove access to the infrastructure
API and observe what happens to reads, writes, background reconciliation and
health checks. A control plane may correctly keep serving its local view while
refusing new changes. It may also report itself healthy while workers accumulate
requests that can never finish. Both behaviors are invisible in an architecture
diagram.

Writing the operational runbooks is part of this test. A rollback procedure that
says "restore if necessary" has moved the hard question into two words. Write
the commands, inputs, ordering and expected state. Every step that has to be
invented while writing the runbook is unresolved engineering work.

## 5. The operator can recover, move and retire the platform through tested procedures

Portability often stops at an API boundary. Business logic is separated from a
provider adapter, the interface looks clean, and the design is declared
portable. That is useful design evidence. It is not the same as moving a running
system.

An exit carries more than workload disks. The operator may need identity and
policy state, key metadata and recovery material, audit evidence, DNS,
certificates, deployment configuration and the trust roots used to accept a
release. The target platform also has to provide equivalents for the
infrastructure features on which the workload relies. A second provider with a
different storage or network model can satisfy the same API only by making
those differences explicit somewhere.

Recovery exposes a related problem. Suppose the control plane database is
restored to yesterday. Machines and volumes created after that backup may still
exist in the infrastructure provider, but the restored control plane no longer
knows that it owns them. A successful database restore can therefore create
orphaned resources. Unless the platform can rediscover and reconcile them,
backup is only part of the recovery plan.

A serious exit test starts with a clean control plane, imports the required
state and reconciles it with what actually exists. If support for multiple
infrastructure providers is claimed, the test should use a real second adapter
rather than treating the interface itself as proof. The final phase removes
support identities tied to the old platform, removes any former supplier's
signing keys from the trust store and revokes its access to key services. Until
those steps have been run, the exit path is a design, not an operating
capability.

{{< diagram src="sovereignty-five-tests.svg" caption="Each claim has a failure test. Passing it tells us more than the architecture diagram." >}}

## A ten-question sovereignty review

These are the questions I would use to start a technical review:

1. Who can grant administrative access, recover an administrator account or
   impersonate one? Can the operator revoke every external access path?
2. Are tenant, project and resource scope derived from trusted state or accepted
   from the caller?
3. Who can cause a data encryption key to be unwrapped, and which system
   enforces that decision?
4. Can the operator withdraw and restore key access without destroying the key
   or taking the whole platform down?
5. Can audit evidence be exported and verified without asking the system that
   produced it?
6. Can the verifier detect altered or omitted events, and does the evidence
   include failed and denied requests?
7. Which critical operations stop when vendor services or public internet access
   disappear?
8. Can the operator rebuild from artifacts, trust roots and instructions it
   already possesses?
9. Can the operator restore control plane state and reconcile resources created
   outside the restored database's view?
10. Has an exit rehearsal proved that the operator can move its data, keys,
    identity and evidence to another platform? Can it establish the same
    operator authority on the new platform, retire the old one and revoke every
    remaining access path?

Data residency still matters because it tells operators and users where data is
kept. It does not say who controls the systems that can access, move or recover
that data.

Open infrastructure helps because it can be inspected, operated and replaced.
That gives the operator more ways to remain independent, but it does not supply
the skills, artifacts or recovery procedures by itself.

I would not accept any of these claims from a diagram alone. Revoke an
administrator's credential. Withhold access to a key, then restore it. Show that
an altered audit record fails verification. Disconnect the external
dependencies. Rehearse the exit. Until those tests have been run, sovereignty
is still an architectural intention, not an operating property.
