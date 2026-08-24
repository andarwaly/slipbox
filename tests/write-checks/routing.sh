#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
write_checks="$root/skills/write-checks/SKILL.md"
clip_resource="$root/skills/clip-resource/SKILL.md"
reference_note="$root/skills/make-reference-note/SKILL.md"
cli="$root/skills/setup-slipbox/scripts/slipbox"

grep -Fq 'artifact-kind: note' "$write_checks"
grep -Fq 'artifact-kind: resource' "$write_checks"
grep -Fq 'note-type: literature' "$write_checks"
grep -Fq 'note-type: reference' "$write_checks"
grep -Fq 'note-type: evergreen' "$write_checks"
grep -Fq 'artifact-kind: resource' "$clip_resource"
grep -Fq 'artifact-kind: note` and `note-type: reference' "$reference_note"
grep -Fq 'slipbox note validate    --type literature|reference|evergreen' "$cli"

python3 - "$write_checks" <<'PY'
import sys
text = open(sys.argv[1], encoding="utf-8").read()
section = text.split("- **Resource mode**", 1)[1].split("## Artifact validation", 1)[0]
assert "field resolution" not in section
assert "does not resolve fields, place zones, or invoke" in section
assert "artifact-kind: resource" in section
PY

printf '%s\n' 'routing contract: PASS'
