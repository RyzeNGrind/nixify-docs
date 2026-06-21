# Multi-agent branching

`nixify` is worked on by several AI coding agents and one human operator,
sometimes concurrently. The branching model exists to let that happen without
agents corrupting each other's work or the mainline — while keeping a strictly
linear history.

## Namespace

Branches are `<owner>/<type>/<topic>`:

- **owner** ∈ `claude`, `gemini`, `copilot`, `codex` — which agent (or the
  human) owns the branch.
- **type** ∈ `feat`, `fix`, `refactor`, `docs`, `chore`, `ci`, `test`.
- **topic** — the unit of work.

Protected refs (mainline, operator branches, and personal namespaces) are
**operator-only**. Agents never commit, merge, or push there.

## Parallel chains, one topic per root

Each agent works its own branches in its own **git worktree**, forked from the
HEAD of the operator branch the work was authored on. One linear chain per
topic; topics are never mixed across roots. Worktrees give each agent an
isolated checkout sharing one object store, so parallel work doesn't collide on
a single working tree.

Agents do not touch another agent's branches or worktrees. Cross-agent
coordination happens through in-repo notes (handoff / session files at
teardown), not by reaching into someone else's checkout.

## Integration is fast-forward only

Agents **propose**; the operator **integrates**. Merges into operator branches
are fast-forward only, so the graph never grows a merge bubble and `master`
stays a straight line. The only override is an explicit operator grant, and the
rule is that the grant is *quoted* — its date, exact wording, and scope are
recorded in the commit or merge body. (CLI merges that bypass local hooks make
that quoting rule matter more, not less.)

## Linear history, amend-at-source

A wrong commit is fixed where it was introduced — by amending that commit —
rather than by stacking a forward-fix on top. The result is a history that reads
as a sequence of correct, self-contained changes, which is far easier to bisect,
review, and cherry-pick across the parallel chains.

## Why this shape

Three properties fall out of it:

1. **Safety** — protected branches can only move through the operator, so an
   agent mistake is contained to its own branch.
2. **Reviewability** — linear, convention-named history makes "what changed and
   who changed it" obvious.
3. **Parallelism** — isolated worktrees plus per-topic chains let multiple
   agents make progress at once without a shared-state bottleneck.
