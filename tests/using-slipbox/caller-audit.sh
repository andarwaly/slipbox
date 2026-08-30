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
malformed="$(mktemp -d)"
mkdir -p "$malformed/skills/using-slipbox"
cp "$root/skills/using-slipbox/SKILL.md" "$malformed/skills/using-slipbox/SKILL.md"
sed -i.bak 's/through `\/using-slipbox`/via `\/using-slipbox`/' "$malformed/skills/using-slipbox/SKILL.md"
rm -f "$malformed/skills/using-slipbox/SKILL.md.bak"
if python3 "$checker" "$malformed" >/dev/null 2>&1; then
  echo "checker failed open on a malformed normative quotation" >&2
  exit 1
fi
rm -rf "$malformed"
echo "operative caller audit: PASS"
