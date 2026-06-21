#!/usr/bin/env bash
# leak-scan.sh — refuse to publish if secret material or infra addresses leak
# into the docs. Topology is documented by ROLE; concrete addresses/keys are not.
# Runs as a pre-push hook and as `nix flake check` (checks.leak-scan).
set -euo pipefail

root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$root"

# Tracked text under docs/ and deep/ (binary assets skipped). When run inside
# the nix sandbox there is no git index, so fall back to a find.
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  mapfile -t files < <(git ls-files docs deep 2>/dev/null)
else
  mapfile -t files < <(find docs deep -type f 2>/dev/null)
fi
files=("${files[@]/#/}")
filtered=()
for f in "${files[@]}"; do
  [[ -z "$f" ]] && continue
  [[ "$f" =~ \.(png|jpe?g|gif|pdf|ico|woff2?)$ ]] && continue
  filtered+=("$f")
done

if [[ ${#filtered[@]} -eq 0 ]]; then
  echo "leak-scan: no docs to scan"
  exit 0
fi

# Real-leak patterns only (kept tight to avoid false positives on prose).
patterns=(
  '\b10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\b'                                   # RFC1918 10/8
  '\b192\.168\.[0-9]{1,3}\.[0-9]{1,3}\b'                                         # RFC1918 192.168/16
  '\b172\.(1[6-9]|2[0-9]|3[01])\.[0-9]{1,3}\.[0-9]{1,3}\b'                       # RFC1918 172.16/12
  '\b100\.(6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])\.[0-9]{1,3}\.[0-9]{1,3}\b'      # tailscale CGNAT 100.64/10
  'age1[0-9a-z]{25,}'                                                            # age recipient
  'ssh-(ed25519|rsa) AAAA[0-9A-Za-z+/]+'                                         # ssh public key blob
  '-----BEGIN [A-Z ]*PRIVATE KEY-----'                                          # private key block
)

fail=0
for f in "${filtered[@]}"; do
  for p in "${patterns[@]}"; do
    if grep -nEH "$p" "$f" >/dev/null 2>&1; then
      echo "LEAK: /$p/"
      grep -nEH "$p" "$f" | sed 's/^/  /'
      fail=1
    fi
  done
done

if [[ "$fail" -ne 0 ]]; then
  echo "leak-scan: FAILED — scrub the matches above before publishing." >&2
  exit 1
fi
echo "leak-scan: clean (${#filtered[@]} files)"
