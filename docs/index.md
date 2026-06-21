# nixify — architecture & engineering practices

This is the public documentation surface for **nixify**, a private NixOS fleet
managed declaratively with [divnix/std](https://github.com/divnix/std) +
[divnix/hive](https://github.com/divnix/hive). The infrastructure source is
private; what follows is a curated, secret-free description of how it is built,
deployed, validated, and operated.

It is written for a technical hiring audience: the goal is to show how a
non-trivial system is *reasoned about and kept reproducible*, not to expose the
system itself. Every host is referred to by **role**, never by address, and a
leak gate enforces that on every change.

## Start here

- **[Architecture overview](ARCHITECTURE.md)** — the cell layout, the host
  fleet by role, the deploy-and-validate pipeline, the secrets model, and the
  multi-agent engineering workflow.
- **[Deep dive](deep/index.md)** — per-subsystem mechanics for a technical
  interviewer: [secrets model](deep/secrets-model.md),
  [deploy & validate pipeline](deep/deploy-pipeline.md),
  [CI gates](deep/ci-gates.md), and
  [multi-agent branching](deep/multi-agent-branching.md).

## At a glance

- **One typed monorepo.** Every host, home profile, module, and CI shell is a
  cell in a single std/hive tree — discovered structurally, not by hand-wired
  imports.
- **Reproducible by construction.** Flake-pinned inputs; the same closure
  builds locally, in CI, and on the deploy target.
- **Validated before it switches.** A deploy is not "done" at build — it passes
  remote build, closure diff/RCA, dry-activate, and a switch test before it's
  marked as a known-good point.
- **Agent-operated, operator-gated.** Linear, convention-named branches; AI
  agents propose, the operator merges fast-forward only; protected branches
  never take a direct push.

---

*Provenance: generated from `nixify master @ 0d8ff78` (approved baseline);
latest linear chain `@ cd41d79`; 2026-06-21.*
