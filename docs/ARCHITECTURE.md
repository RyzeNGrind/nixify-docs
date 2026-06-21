# Architecture overview

`nixify` is a single NixOS monorepo that defines an entire multi-host fleet —
laptops, WSL dev boxes, a NAS, dedicated build machines, an edge ML node, and
cloud burst capacity — as one typed, reproducible tree. It is built on
[divnix/std](https://github.com/divnix/std) (a cell framework for organising
Nix code) and [divnix/hive](https://github.com/divnix/hive) (std's NixOS fleet
layer), and deployed with [colmena](https://github.com/zhaofengli/colmena).

This page describes the design at a level useful to an engineer evaluating the
work. It contains no addresses, keys, or secrets — see
[the leak gate](#safety-the-leak-gate) for why.

## Why a monorepo of cells

Most personal infra grows into a pile of per-host config files that drift apart.
`nixify` instead treats every concern as a **cell** — a self-describing unit
that std discovers structurally. There are no hand-maintained import lists; you
add a cell, and the framework wires it into the right outputs.

```
cells/
├── hosts/      nixosConfigurations  — one entry per machine in the fleet
├── cluster/    colmenaConfig        — fleet-wide deploy topology (by role)
├── nixos/      nixosProfiles        — composable system-level building blocks
├── home/       profiles             — home-manager user environments
├── modules/    reusable NixOS modules shared across hosts
├── users/      user identity / account definitions
├── agents/     AI-agent tooling: profiles, packages, scripts, skills
└── repo/       devshells            — the developer & CI entry shell
```

The payoff: a new host is a small composition of existing profiles, not a
copy-paste of another host's config. Shared behaviour lives in one module and
every consumer gets fixes at once.

## The fleet, by role

The fleet is ~15 hosts. They are documented here by **role**, never by hostname
or address:

| Role | What it does |
|------|--------------|
| WSL dev hosts | Day-to-day development on Windows machines via NixOS-WSL. Build nothing heavy locally — they delegate to remote builders. |
| Remote builder | The workhorse that performs real Nix builds on behalf of constrained hosts. |
| Cloud burst builder | On-demand additional build/CI capacity. |
| NAS | Storage and service host. |
| Edge ML node | A Jetson-class device for on-device inference workloads. |
| Operator workstation(s) | Where deploys are authorised and merged. |

A recurring design constraint shapes the whole system: **resource-constrained
hosts must never run heavy Nix evaluation or builds locally.** They are
configured with zero local build jobs and offload to a remote builder over a
trusted channel. This keeps a laptop or WSL box responsive while still getting
fully reproducible system closures.

## The deploy-and-validate pipeline

A build succeeding is *not* the bar for "deployed." `nixify` treats a build as
the first of several gates, because a closure that builds can still fail to
activate. The pipeline:

1. **Remote evaluate + build.** The target closure is built on a dedicated
   builder, not on the (often constrained) host being deployed.
2. **Closure diff / RCA.** The new closure is compared against the currently
   running one (package-version diff + structural diff) so every change is
   accounted for *before* it lands — no silent drift.
3. **Dry-activate.** The activation script is run in dry mode to surface
   problems that only appear at switch time.
4. **Switch test.** The configuration is actually switched in a test context to
   prove it activates, not merely builds.
5. **Mark known-good.** On success the working closure is recorded as a
   garbage-collection-rooted, tagged "last-known-good" point that can be
   redeployed deterministically.

Rollback is *redeploy the previous known-good closure* — never "revert
unvalidated history and hope." This mirrors a release-pointer discipline: a
release is an annotated tag on an exact validated commit, and a per-target
pointer fast-forwards to it.

## Secrets model

Secrets are managed declaratively and encrypted at rest, layered over
[sops-nix](https://github.com/Mic92/sops-nix) and an age/agenix-based flow.
Host SSH identities are derived into age recipients, so a host can decrypt
exactly the secrets provisioned for it and nothing else. No plaintext secret
ever enters the repo or a build log. (Concrete recipients, key material, and the
secret inventory are intentionally absent from this public surface.)

## Engineering workflow: agent-operated, operator-gated

`nixify` is developed by a mix of a human operator and several AI coding agents
working in parallel. The discipline that keeps that safe:

- **Convention-named, linear branches.** Branches follow
  `<owner>/<type>/<topic>` (owner ∈ claude, gemini, copilot, codex; type ∈
  feat, fix, refactor, docs, chore, ci, test). History stays linear — fixes
  *amend* the commit that introduced the problem rather than stacking
  forward-patches.
- **Protected baselines.** The mainline and operator branches never take a
  direct agent push. Agents propose; the operator integrates **fast-forward
  only**. An explicit, quoted operator grant is the only override, and it is
  recorded in the merge itself.
- **Parallel chains, isolated worktrees.** Each agent works its own branches in
  its own git worktree, forked from the operator branch the work was authored
  on. Agents never touch another agent's branches; coordination happens through
  in-repo handoff notes.
- **Mechanical gates, not vibes.** Native git hooks enforce the branch policy
  and a single inline-Nix gate runs the validation hooks. The rule is simple:
  no green, no merge.

## Reproducibility & caching

All inputs are flake-pinned, so the same revision evaluates to the same closure
everywhere. A binary cache shared across the fleet means a closure built once —
in CI or on the builder — is fetched, not rebuilt, by every other host. CI
builds the fleet and populates that cache as a side effect of validation.

## Safety: the leak gate

Because this repository is public and describes private infrastructure, a
`scripts/leak-scan.sh` gate runs on every push and as part of `nix flake check`.
It fails the publish if it finds host addresses (RFC1918 or Tailscale-range),
age recipients, SSH public-key blobs, or private-key blocks anywhere in the
docs. Topology is expressed by role precisely so this gate can stay strict.

---

*Provenance: generated from `nixify master @ 0d8ff78` (approved baseline);
latest linear chain `@ cd41d79`; 2026-06-21. This is a curated overview; a
deeper per-subsystem wiki exists and is shared on request.*
