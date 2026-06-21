# Deep dive (hiring-manager handover)

These pages go a layer below the [architecture overview](../docs/ARCHITECTURE.md)
into the subsystems an interviewer is likely to probe. They are still scrubbed —
no addresses, keys, or secret inventory — but they assume a reader who wants the
*mechanics*, not the summary.

> This `deep/` set lives on an unmerged branch and is shared on request. It
> stays out of the default branch (and therefore out of the auto-generated
> public wiki) until that's intended.

## Contents

- [Secrets model](secrets-model.md) — how sops-nix + age give each host
  exactly the secrets it needs and nothing else.
- [Deploy & validate pipeline](deploy-pipeline.md) — the gates between "it
  builds" and "it's known-good," and why each exists.
- [CI gates](ci-gates.md) — the single inline-Nix git-hook gate and what it
  enforces at commit and push time.
- [Multi-agent branching](multi-agent-branching.md) — how several AI agents and
  one operator share a linear history without stepping on each other.

---

*Provenance: nixify master @ 0d8ff78 (approved baseline); chain @ cd41d79; 2026-06-21.*
