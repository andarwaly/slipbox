#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/../.." && pwd)"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT
mkdir -p "$SCRATCH/.slipbox/bin" "$SCRATCH/.slipbox/work"
cp "$REPO_ROOT/skills/setup-slipbox/scripts/slipbox" "$SCRATCH/.slipbox/bin/slipbox"
chmod +x "$SCRATCH/.slipbox/bin/slipbox"
cp "$HERE/fixtures/lazy-migration-note.md" "$SCRATCH/.slipbox/lazy.md"
cp "$HERE/fixtures/lazy-migration-unrelated.md" "$SCRATCH/.slipbox/unrelated.md"
cp "$SCRATCH/.slipbox/unrelated.md" "$SCRATCH/unrelated.before"
printf '%s\n' '{"migrations":{"literature_headings":{"mode":"lazy"}}}' > "$SCRATCH/.slipbox/config.json"
CLI="$SCRATCH/.slipbox/bin/slipbox"
WORK_JSON=$(cd "$SCRATCH/.slipbox" && "$CLI" work create --kind migration --activity lazy-first-access --target lazy.md --affected-path lazy.md)
WORK_ID=$(printf '%s' "$WORK_JSON" | python3 -c 'import json,sys; print(json.load(sys.stdin)["work_id"])')
WORK_DIR="$SCRATCH/.slipbox/work/$WORK_ID"
python3 - "$SCRATCH/.slipbox/lazy.md" "$WORK_DIR/replacement.md" <<'PY'
import pathlib, sys
src, dst = map(pathlib.Path, sys.argv[1:])
text = src.read_text()
assert text.count("## Key Claims") == 1
dst.write_text(text.replace("## Key Claims", "## Source Points", 1))
PY
FP=$(sha256sum "$SCRATCH/.slipbox/lazy.md" | awk '{print $1}')
python3 - "$WORK_DIR/mutations.json" "$FP" <<'PY'
import json, sys
path, fp = sys.argv[1:]
json.dump([{"path":"lazy.md", "expected_fingerprint":"sha256:" + fp, "replacement_path":"replacement.md"}], open(path, "w"))
PY
(cd "$SCRATCH/.slipbox" && "$CLI" work update "$WORK_ID" --status ready-to-finalize >/dev/null)
(cd "$SCRATCH/.slipbox" && "$CLI" work finalize "$WORK_ID" >/dev/null)
grep -Fq '## Source Points' "$SCRATCH/.slipbox/lazy.md"
cmp -s "$SCRATCH/.slipbox/unrelated.md" "$SCRATCH/unrelated.before"
printf '%s\n' 'lazy migration behavioral test: PASS (first-access CAS changed only selected note)'
