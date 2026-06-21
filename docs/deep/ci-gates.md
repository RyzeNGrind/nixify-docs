# CI gates

The repo deliberately runs **one** validation gate, implemented as inline-Nix
git hooks rather than an external framework. The history here is instructive:
earlier iterations layered a third-party pre-commit framework and a separate
hook runner on top of each other, which drifted out of sync and produced
confusing failures. That was collapsed into a single inline-Nix gate so there is
exactly one source of truth for "what must pass."

## At commit time

- **Branch-policy guard.** A pure-bash guard refuses commits that violate the
  branch convention or target a protected branch directly (see
  [multi-agent branching](multi-agent-branching.md)). No dependencies, so it
  runs identically for humans and agents on every host.
- **Conventional-commit shape.** Commits are `type(scope): summary`; fixes amend
  the introducing commit so history stays linear.

## At push time

- **Heavy validation is opt-out-by-design on constrained hosts.** The push-time
  Nix evaluation/build routes through a remote builder; a constrained host does
  not run it locally. Where a host genuinely cannot reach the builder (e.g. a
  tunnel is down), the gate is skipped *explicitly and visibly*, not silently.
- **No `--no-verify`.** Bypassing the gate is not part of the workflow. The
  documented escape hatches are narrow and named (for example, the upstream
  tool's own "no config present" flag), and they preserve the real checks rather
  than skipping them.

## In GitHub Actions

CI builds the fleet and, as a side effect of validation, populates the shared
binary cache — so a closure proven in CI is fetched rather than rebuilt by the
hosts. Actions usage is rationed deliberately: workflows that don't need CI
carry `[skip ci]`, chronic-failing workflows are disabled until fixed rather
than left to burn minutes, and a red run is reproduced locally before it is
pushed again.

## Why hooks over a hosted-only gate

Putting the gate in git hooks means the policy is enforced at the point of
action, on every machine, before anything reaches the network — not only after a
push when CI minutes are already spent. CI is the backstop, not the front line.
