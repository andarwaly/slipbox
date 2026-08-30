#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
checker="$root/tests/using-slipbox/check-operative-callers.py"

python3 "$checker" "$root"

fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT
mkdir -p "$fixture/skills/using-slipbox"
cp "$root/skills/using-slipbox/SKILL.md" "$fixture/skills/using-slipbox/SKILL.md"
printf '\nA caller may Run `/using-slipbox` directly.\n' >> "$fixture/skills/using-slipbox/SKILL.md"
if python3 "$checker" "$fixture" >/dev/null 2>&1; then
  echo "checker failed to reject an operative forbidden caller form" >&2
  exit 1
fi
echo "operative caller audit: PASS"
