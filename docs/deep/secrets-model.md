# Secrets model

The goal: every secret is encrypted at rest in the repo, decryptable only by the
hosts (and the operator) that legitimately need it, with no plaintext ever
entering a build log, the Nix store world-readably, or git history.

## Layers

1. **sops-nix** provides the NixOS integration: a host declares which encrypted
   files it consumes, and the activation step decrypts them into a private
   runtime path (not the world-readable store).
2. **age** is the encryption backend. Recipients are age public keys; the
   matching private key lives only on the host or in the operator's key store.
3. **Host identity → age recipient.** A host's existing SSH host key is derived
   into an age recipient. That means provisioning a new host doesn't require
   minting and distributing a separate encryption identity — the identity the
   host already proves over SSH *is* the decryption identity.

## Why derive age keys from SSH host keys

It collapses two problems into one. The host already has an SSH identity that
the rest of the fleet trusts for remote-build and deploy channels. Reusing it as
the decryption identity means:

- No second secret to rotate when a host is rebuilt.
- The set of "who can decrypt this" is exactly the set of hosts you already
  enumerate for deploy.
- Re-keying a secret to add/remove a host is a declarative edit plus a re-key
  pass, not a manual key-handoff.

## Blast radius

Each secret is encrypted to the minimal recipient set: the operator plus the
specific hosts that mount it. A compromised host can decrypt only what was
provisioned to it; it cannot read another host's secrets, because it was never a
recipient. The operator key is the only universal recipient and lives off the
fleet.

## What is intentionally not here

The recipient list, the secret inventory, key fingerprints, and the cache
signing keys are all absent from this public surface by policy — the leak gate
([`scripts/leak-scan.sh`](../../scripts/leak-scan.sh)) fails the publish if any of
them appear.
