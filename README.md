# nixify-docs

Public documentation surface for **nixify** — a private, declaratively-managed
NixOS fleet built on [divnix/std](https://github.com/divnix/std) +
[divnix/hive](https://github.com/divnix/hive). The source monorepo is private;
this repository is the curated, scrubbed view of how it is designed and
operated.

> **Read it as a wiki (no login):**
> **<https://deepwiki.com/RyzeNGrind/nixify-docs>**
>
> Rendered site (Phase B): **<https://nixify-docs.pages.nixify.dev>**
>
> Or read [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) (overview) and
> [`docs/deep/`](docs/deep/index.md) (subsystem deep dives) directly on GitHub.

## What this is

A hiring-audience overview of a real, multi-host NixOS infrastructure: the cell
layout, the deploy-and-validate pipeline, the secrets model, and the
multi-agent engineering workflow that drives it. It is written to show *how the
system is reasoned about*, not to expose the system itself.

## What this deliberately is **not**

No host addresses, no Tailscale ACLs, no secret material, no binary-cache keys,
no host inventory. Topology is described by **role**, never by address. A
[`scripts/leak-scan.sh`](scripts/leak-scan.sh) gate runs on every push (and via
`nix flake check`) and refuses to publish if any of that slips in.

## Layout

| Path | Purpose |
|------|---------|
| `docs/` | Recruiter-safe overview + the mdBook / DeepWiki source. |
| `docs/deep/` | Subsystem deep dives for technical interviewers (secrets, deploy pipeline, CI gates, multi-agent branching). |
| `docs/CNAME` | Custom domain for Pages: `nixify-docs.pages.nixify.dev`. |
| `flake.nix` | Sub-flake: `nix develop` for a preview shell, `nix build .#docs` to render the site, `nix flake check` to run the leak gate. |
| `book.toml` | mdBook config (Phase B). |
| `scripts/leak-scan.sh` | Secret/topology leak gate. |
| `.github/workflows/pages.yml` | Phase B Pages deploy — `workflow_dispatch` only (no auto-run, no wasted Actions quota). |

The overview stays recruiter-safe; the deep dives are kept published-but-quiet —
a hiring-manager-ready signal left dangling for technical interviewers, never
required reading for a first-pass recruiter.

## Local preview

```bash
nix develop          # mdbook + git
mdbook serve docs    # http://localhost:3000
scripts/leak-scan.sh # must pass before pushing
```

Activate the leak gate as a hook once per clone:

```bash
git config core.hooksPath .githooks
```

## Relationship to the private repo

`nixify-docs` is wired into the private `nixify` monorepo as a git submodule at
`docs/public/`, so the curated docs are authored alongside the source they
describe while this repository remains the public source of truth.

---

*Provenance: generated from `nixify master @ 0d8ff78` (approved baseline);
latest linear chain `@ cd41d79`; 2026-06-21.*
