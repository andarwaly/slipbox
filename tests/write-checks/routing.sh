#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
write_checks="$root/skills/write-checks/SKILL.md"
clip_resource="$root/skills/clip-resource/SKILL.md"
literature_note="$root/skills/make-literature-note/SKILL.md"
reference_note="$root/skills/make-reference-note/SKILL.md"
evergreen_note="$root/skills/make-evergreen-note/SKILL.md"
cli="$root/skills/setup-slipbox/scripts/slipbox"

grep -Fq 'artifact-kind: note' "$write_checks"
grep -Fq 'artifact-kind: resource' "$write_checks"
grep -Fq 'note-type: literature' "$write_checks"
grep -Fq 'note-type: reference' "$write_checks"
grep -Fq 'note-type: evergreen' "$write_checks"
grep -Fq 'artifact-kind: resource' "$clip_resource"
for caller in "$literature_note" "$reference_note" "$evergreen_note"; do
  grep -Fq 'artifact-kind: note' "$caller"
done
grep -Fq 'artifact-kind: note' "$literature_note"
grep -Fq 'note-type: literature' "$literature_note"
grep -Fq 'artifact-kind: note' "$reference_note"
grep -Fq 'note-type: reference' "$reference_note"
grep -Fq 'artifact-kind: note' "$evergreen_note"
grep -Fq 'note-type: evergreen' "$evergreen_note"
grep -Fq '.slipbox/bin/slipbox note validate --type literature' "$literature_note"
grep -Fq 'slipbox note validate --type reference' "$reference_note"
grep -Fq 'slipbox note validate    --type literature|reference|evergreen' "$cli"

python3 - "$write_checks" <<'PY'
import sys
text = open(sys.argv[1], encoding="utf-8").read()
section = text.split("- **Resource mode**", 1)[1].split("## Artifact validation", 1)[0]
assert "field resolution" not in section
assert "does not resolve fields, place zones, or invoke" in section
assert "artifact-kind: resource" in section
assert ".slipbox/bin/slipbox note validate" not in section
assert "whole-artifact validation" in text
assert "artifact-kind: note" in text
PY

printf '%s\n' 'routing contract: PASS'
