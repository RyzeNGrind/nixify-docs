# Deploy & validate pipeline

The governing belief: **a closure that builds is not a closure that works.**
Activation can fail for reasons a build never surfaces — a service that won't
restart, a migration that errors, an ordering problem between units. So a deploy
is a sequence of gates, and only the last one earns the "known-good" label.

## The gates

### 1. Remote evaluate + build
The target closure is evaluated and built on a dedicated builder, never on a
constrained host. Constrained hosts (WSL boxes, laptops) are configured with
zero local build jobs and offload everything. This keeps the dev machine
responsive and makes the build environment consistent regardless of which host
the closure is *for*.

### 2. Closure diff / RCA
Before anything switches, the candidate closure is diffed against the one
currently running on the target:

- a **package-version diff** (what moved, what was added/removed), and
- a **structural / derivation diff** for changes that don't show up as a version
  bump.

This is the root-cause-analysis step: every change in the new system is
explained *before* it lands. It catches accidental input drift — an unrelated
flake input bumping a dependency you didn't mean to touch.

### 3. Dry-activate
The activation script runs in dry mode. This surfaces switch-time problems
(restart ordering, would-be-failed units) without committing to the change.

### 4. Switch test
The configuration is actually switched in a test context — proving activation,
not just evaluation. Where the host model supports it, this exercises the real
`switch-to-configuration` path so the "it activates" claim is earned, not
assumed.

### 5. Mark known-good
On success, the working closure is pinned as a **garbage-collection-rooted**,
**tagged** last-known-good point. Because it's GC-rooted, it survives a `nix
store gc`; because it's tagged, it's addressable for redeploy.

## Rollback

Rollback is **redeploy the previous known-good closure**, not "revert
unvalidated history." The known-good tag is an exact, reproducible target, so
recovery is deterministic and doesn't depend on rebuilding from a possibly-dirty
intermediate state.

## Release pointers

The same idea scales to releases: a release is an annotated tag
(`release/<target>/<UTC>-<shortrev>`) on the exact validated commit, recording
what was built and the verification evidence. A per-target `release/<target>`
branch fast-forwards to that tag — a moving pointer to the latest proven-working
state. Non-fast-forward updates are refused.
