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
rg -U -q 'atomic backlog[[:space:]]+mutation' "$lifecycle" "$candidates"
rg -q 'create-new-row plus remove/tombstone-old-row' "$lifecycle"
rg -q 'compensated' "$lifecycle"
rg -q 'multi-citation|two citations' "$evals"
rg -q 'mutations\.json|backlog update' "$evals"
rg -qi 'compensat' "$evals"
rg -q 'tensions.*pending' "$skill"

# Execute the transactional CLI against a fresh fixture.
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/bin" "$scratch/evergreen" "$scratch/work" "$scratch/notes"
cp "$repo_root/skills/setup-slipbox/scripts/slipbox" "$scratch/bin/slipbox"
chmod +x "$scratch/bin/slipbox"
cli="$scratch/bin/slipbox"
: > "$scratch/links.jsonl"
field() { python3 -c 'import json,sys; print(json.load(sys.stdin)[sys.argv[1]])' "$1"; }
start() { "$cli" work create --kind evergreen --activity create --target "$1" --affected-path "$2" | field work_id; }
ready() { python3 - "$scratch/work/$1/manifest.json" "$scratch/work/$1/mutations.json" <<'PY'
import json,sys
p,q=sys.argv[1:]; m=json.load(open(p)); m['status']='ready-to-finalize'; m['mutations']=json.load(open(q)); json.dump(m,open(p,'w'))
PY
}

# Multi-citation finalize: all events share one ledger-events mutation.
w=$(start notes/take.md links.jsonl)
printf '# Take\n' > "$scratch/work/$w/draft.md"
printf '%s\n%s\n' '{"op":"add","source_slug":"take","target_slug":"a","rel_type":"cites"}' '{"op":"add","source_slug":"take","target_slug":"b","rel_type":"cites"}' > "$scratch/work/$w/cites.jsonl"
python3 - "$scratch/work/$w/mutations.json" <<'PY'
import json,sys
e=[{'op':'add','source_slug':'take','target_slug':x,'rel_type':'cites'} for x in ('a','b')]
json.dump([{'path':'notes/take.md','expected_fingerprint':None,'replacement_path':'draft.md','kind':'artifact'},{'path':'links.jsonl','expected_fingerprint':'sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855','replacement_path':'cites.jsonl','kind':'ledger-events','events':e}],open(sys.argv[1],'w'))
PY
ready "$w"; "$cli" work finalize "$w" >/dev/null
test "$(wc -l < "$scratch/links.jsonl" | tr -d ' ')" = 2

# Atomic backlog rename.
printf '%s\n' '---' 'status: to-discuss' 'reason: tension' '---' > "$scratch/evergreen/old.md"
w=$(start notes/unused.md evergreen/old.md); printf '%s\n' '---' 'status: discussed' 'reason: tension' '---' > "$scratch/work/$w/new.md"
python3 - "$scratch/work/$w/mutations.json" "$scratch/evergreen/old.md" <<'PY'
import hashlib,json,sys
fp='sha256:'+hashlib.sha256(open(sys.argv[2],'rb').read()).hexdigest()
json.dump([{'path':'evergreen/old.md','new_path':'evergreen/take.md','expected_fingerprint':fp,'replacement_path':'new.md','kind':'backlog-events','operation':'rename'}],open(sys.argv[1],'w'))
PY
ready "$w"; "$cli" work finalize "$w" >/dev/null; test -f "$scratch/evergreen/take.md"; test ! -e "$scratch/evergreen/old.md"

# A changed affected input blocks resume.
w=$(start notes/resume.md notes/contributing.md); printf changed > "$scratch/notes/contributing.md"
test "$(field resumable <<<"$("$cli" work resume "$w")")" = False

# Later mutation failure compensates the earlier artifact.
w=$(start notes/rollback.md links.jsonl); printf rollback > "$scratch/work/$w/draft.md"
printf '%s\n' '{"op":"add","source_slug":"rollback","target_slug":"c","rel_type":"cites"}' > "$scratch/work/$w/cites.jsonl"
python3 - "$scratch/work/$w/mutations.json" "$scratch/links.jsonl" <<'PY'
import hashlib,json,sys
e=[{'op':'add','source_slug':'rollback','target_slug':'c','rel_type':'cites'}]
fp='sha256:'+hashlib.sha256(open(sys.argv[2],'rb').read()).hexdigest()
json.dump([{'path':'notes/rollback.md','expected_fingerprint':None,'replacement_path':'draft.md','kind':'artifact'},{'path':'links.jsonl','expected_fingerprint':fp,'replacement_path':'cites.jsonl','kind':'ledger-events','events':e}],open(sys.argv[1],'w'))
PY
ready "$w"; if SLIPBOX_TEST_FAIL_MUTATION=1 "$cli" work finalize "$w" >/dev/null 2>&1; then exit 1; fi
test ! -e "$scratch/notes/rollback.md"

echo "Evergreen integration contract: PASS"
