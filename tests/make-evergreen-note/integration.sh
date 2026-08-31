#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
skill="$repo_root/skills/make-evergreen-note/SKILL.md"
lifecycle="$repo_root/skills/using-slipbox/references/work-lifecycle.md"
candidates="$repo_root/skills/using-slipbox/references/evergreen-candidates.md"
evals="$repo_root/tests/make-evergreen-note/evals.json"

python3 -m json.tool "$evals" >/dev/null
rg -q 'activity `create`.*`revise`' "$skill"
rg -q 'synthesis-map\.json' "$skill"
rg -q 'exactly one `ledger-events`' "$skill"
rg -q 'all `cites` events' "$skill"
rg -q 'create-new-row' "$skill"
rg -q 'tombstone/removal' "$skill"
rg -q 'status: "pending"' "$skill"
rg -q 'every mutation fingerprint' "$skill"
rg -q 'atomic backlog mutation' "$lifecycle" "$candidates"
rg -q 'create-new-row plus remove/tombstone-old-row' "$lifecycle"
rg -q 'compensated' "$lifecycle"
rg -q 'multi-citation|two citations' "$evals"
rg -q 'mutations\.json|backlog update' "$evals"
rg -qi 'compensat' "$evals"

echo "Evergreen integration contract: PASS"
