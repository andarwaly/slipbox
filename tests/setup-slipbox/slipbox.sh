#!/usr/bin/env bash
# Mechanical smoke test for skills/setup-slipbox/scripts/slipbox.
# Not an evals.json case -- slipbox is a deterministic CLI, not model behavior,
# so this is a plain pass/fail script, run against a scratch .slipbox/ dir.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/../.." && pwd)"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

mkdir -p "$SCRATCH/bin" "$SCRATCH/evergreen"
cp "$REPO_ROOT/skills/setup-slipbox/scripts/slipbox" "$SCRATCH/bin/slipbox"
chmod +x "$SCRATCH/bin/slipbox"
SLIPBOX="$SCRATCH/bin/slipbox"
CLI_VERSION=$(grep -m1 '^CLI_VERSION=' "$SLIPBOX" | cut -d'"' -f2)

fail=0
pass() { echo "ok   - $1"; }
failed() { echo "FAIL - $1"; fail=1; }

check() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then pass "$desc"; else failed "$desc"; fi
}
check_exit() {
  local desc="$1" expected="$2"; shift 2
  set +e
  "$@" >/tmp/slipbox-test-out 2>/tmp/slipbox-test-err
  local actual=$?
  set -e
  if [ "$actual" = "$expected" ]; then
    pass "$desc (exit $actual)"
  else
    failed "$desc (expected exit $expected, got $actual)"
    cat /tmp/slipbox-test-err
  fi
}
check_eq() {
  if [ "$3" = "$2" ]; then pass "$1"; else failed "$1 (expected $2, got $3)"; fi
}
check_file() { [ -f "$2" ] && pass "$1" || failed "$1 ($2 missing)"; }
check_no_file() { [ ! -f "$2" ] && pass "$1" || failed "$1 ($2 still present)"; }
check_valid_json() {
  if python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$2" 2>/dev/null; then
    pass "$1"
  else
    failed "$1 (not valid JSON: $(cat "$2"))"
  fi
}
# check_match/check_no_match <desc> <glob> <text> -- the same assertion every
# stderr check in this file was open-coding.
check_match() {
  case "$3" in $2) pass "$1" ;; *) failed "$1 (got: $3)" ;; esac
}
check_no_match() {
  case "$3" in $2) failed "$1 (got: $3)" ;; *) pass "$1" ;; esac
}
check_no_tmp_files() {
  check_eq "$1" 0 "$(find "$2" -name '*.tmp' | wc -l | tr -d ' ')"
}

# stderr_of <cmd...> -- the command's stderr alone, whatever its exit status.
stderr_of() { "$@" 2>&1 >/dev/null || true; }
# json_len / json_at -- read the CLI's JSON output from stdin.
json_len() { python3 -c "import json,sys; print(len(json.load(sys.stdin)))"; }
json_at() { python3 -c "import json,sys; print(json.load(sys.stdin)$1)"; }

assert_contains() {
  local desc="$1" needle="$2" file="$3"
  if grep -Fq "$needle" "$file"; then pass "$desc"; else failed "$desc (missing: $needle)"; fi
}
# check_json <desc> <python body> -- asserts against the JSON on stdin, bound as `data`.
check_json() {
  if python3 -c "import json, sys
data = json.load(sys.stdin)
$2"; then pass "$1"; else failed "$1"; fi
}
# check_json_file <desc> <python body> <path> -- same, against a file's JSON.
check_json_file() {
  if python3 -c "import json, sys
data = json.load(open(sys.argv[1]))
$2" "$3"; then pass "$1"; else failed "$1"; fi
}

echo "--- setup config schema: git/cache contract ---"
SCHEMA="$REPO_ROOT/skills/setup-slipbox/assets/config.schema.json"
python3 - "$SCHEMA" <<'PY'
import copy, json, sys
try:
    from jsonschema import Draft7Validator
except ImportError:
    Draft7Validator = None

schema = json.load(open(sys.argv[1]))
base = {
    "paths": {"resources":"resources", "literature":"literature", "evergreen":"evergreen", "reference":"reference"},
    "filenames": {"literature":"kebab-case", "reference":"kebab-case", "evergreen":"kebab-case"},
    "frontmatter": {"literature":{}, "reference":{}, "evergreen":{}},
    "links": {"style":"wikilink"},
    "templates": {k:"templates/" + k + ".md" for k in ("literature_path","reference_path","evergreen_path","article_path","news_path","social_path","video_path")},
    "transcript_languages": ["en"],
    "prefixes": {"literature":False, "reference":False, "evergreen":False},
    "git": {"mode":"ask", "commit_style":{"mode":"detected"}, "activity_trailers":True},
    "cache": {"source_maps":{"persistence":"local"}},
}
if Draft7Validator:
    Draft7Validator(schema).validate(base)
    valid = lambda candidate: Draft7Validator(schema).is_valid(candidate)
else:
    # jsonschema is not a setup prerequisite. Keep a structural fallback
    # equivalent for every contract constraint exercised here.
    def valid(candidate):
        required = {"paths","filenames","frontmatter","links","templates","transcript_languages","prefixes","git","cache"}
        if not isinstance(candidate, dict) or not required.issubset(candidate) or set(candidate) - required - {"migrations"}: return False
        if set(candidate["paths"]) != {"resources","literature","evergreen","reference"} or not all(isinstance(v,str) for v in candidate["paths"].values()): return False
        casing = {"kebab-case","Title Case","snake_case","Sentence case","verbatim","other"}
        if set(candidate["filenames"]) != {"literature","reference","evergreen"} or not all(v in casing for v in candidate["filenames"].values()): return False
        if set(candidate["frontmatter"]) != {"literature","reference","evergreen"} or not all(isinstance(v,dict) for v in candidate["frontmatter"].values()): return False
        if set(candidate["links"]) != {"style"} or candidate["links"]["style"] not in {"wikilink","markdown"}: return False
        template_keys = {"literature_path","reference_path","evergreen_path","article_path","news_path","social_path","video_path"}
        if set(candidate["templates"]) != template_keys or not all(isinstance(v,str) for v in candidate["templates"].values()): return False
        if not isinstance(candidate["transcript_languages"],list) or not candidate["transcript_languages"] or not all(isinstance(v,str) for v in candidate["transcript_languages"]): return False
        if set(candidate["prefixes"]) != {"literature","reference","evergreen"} or not all(isinstance(v,str) or v is False for v in candidate["prefixes"].values()): return False
        git = candidate["git"]
        if set(git) != {"mode","commit_style","activity_trailers"} or git["mode"] not in {"off","ask","auto"} or set(git["commit_style"]) != {"mode"} or git["commit_style"]["mode"] not in {"detected","fallback"} or not isinstance(git["activity_trailers"],bool): return False
        cache = candidate["cache"]
        if not (set(cache) == {"source_maps"} and set(cache["source_maps"]) == {"persistence"} and cache["source_maps"]["persistence"] in {"local","tracked"}): return False
        migrations = candidate.get("migrations", {})
        if not isinstance(migrations, dict): return False
        reference = migrations.get("reference")
        if reference is not None and not isinstance(reference, dict): return False
        if reference is not None and (set(reference) - {"mode", "selected"} or reference.get("mode") not in {"all","selected","lazy","defer"}): return False
        if reference and reference["mode"] == "selected" and (not isinstance(reference.get("selected"), list) or not reference["selected"]): return False
        if reference and reference.get("selected"):
            import re
            if any(not isinstance(path, str) or not path or path.startswith("/") or any(part in {".", ".."} for part in path.split("/")) for path in reference["selected"]): return False
        if reference and reference["mode"] != "selected" and "selected" in reference: return False
        return True
assert valid({**base, "git": {**base["git"], "mode":"never"}}) is False
assert valid({**base, "cache": {"source_maps":{}}}) is False
tracked_work = copy.deepcopy(base)
tracked_work["cache"]["work"] = {"persistence":"tracked"}
assert valid(tracked_work) is False
reference_migration = copy.deepcopy(base)
reference_migration["migrations"] = {"reference": {"mode":"selected", "selected":["reference/legacy-note.md"]}}
assert valid(reference_migration) is True
reference_migration["migrations"]["reference"] = {"mode":"selected"}
assert valid(reference_migration) is False
reference_migration["migrations"]["reference"] = "selected"
assert valid(reference_migration) is False
reference_migration["migrations"]["reference"] = []
assert valid(reference_migration) is False
PY
pass "schema accepts exact git/cache configuration and rejects invalid modes, missing persistence, and tracked work"

echo "--- setup bootstrap contract ---"
SETUP_SKILL="$REPO_ROOT/skills/setup-slipbox/SKILL.md"
check_match "setup creates work and source-map cache directories" '* .slipbox/work .slipbox/cache/source-maps*' "$(grep -F 'mkdir -p .slipbox/bin .slipbox/evergreen .slipbox/work .slipbox/cache/source-maps' "$SETUP_SKILL")"
AGENTS_LINE=$(grep -n 'Copy `assets/AGENTS.md`' "$SETUP_SKILL" | head -1 | cut -d: -f1)
CONFIG_LINE=$(grep -n 'config.json` is written' "$SETUP_SKILL" | head -1 | cut -d: -f1)
if [ "$AGENTS_LINE" -gt "$CONFIG_LINE" ]; then pass "completion sentinel is ordered after config"; else failed "completion sentinel ordering"; fi
for category in compatible missing incompatible older-compatible unresolved-source orphaned; do
  assert_contains "migration inventory names $category" "$category" "$SETUP_SKILL"
done
for choice in 'missing + incompatible' 'chosen scope' 'refresh all' 'defer'; do
  assert_contains "migration inventory offers $choice" "$choice" "$SETUP_SKILL"
done
assert_contains "cache and note-format authorization stay separate" "separate" "$SETUP_SKILL"
assert_contains "local cache ignore is conditional" 'when cache persistence is `local`' "$SETUP_SKILL"
assert_contains "tracked source-map cache omits ignore" "Never add an ignore rule for tracked source maps" "$SETUP_SKILL"
assert_contains "reference migration authorization is schema-backed" 'reference: {mode: all|all-valid|selected|lazy|defer' "$SETUP_SKILL"
assert_contains "setup detects legacy prefixed H1s across note types" "prefixed H1s in Reference and Evergreen" "$SETUP_SKILL"
assert_contains "setup offers all-valid migration" "all-valid" "$SETUP_SKILL"
assert_contains "setup skips unusual note structures" "unusual or incompatible structures" "$SETUP_SKILL"
assert_contains "runtime asset keeps H1s clean" "H1 headings remain clean/unprefixed" "$REPO_ROOT/skills/setup-slipbox/assets/AGENTS.md"
# check_table <subject> <header glob> <expected data rows> <output>
check_table() {
  check_match "$1 table output has a tab-separated header" "$2" "$(printf '%s\n' "$4" | head -1)"
  check_eq "$1 table output has one line per row" "$3" "$(printf '%s\n' "$4" | tail -n +2 | grep -c .)"
}
assert_humanize_signal() {
  local desc="$1" file="$2" expected_id="$3"
  if EXPECTED_ID="$expected_id" python3 - "$file" <<'PY'
import json
import os
import sys

with open(sys.argv[1]) as handle:
    result = json.load(handle)
expected = os.environ["EXPECTED_ID"]
assert result["flagged"] is True
assert expected in result["signals_passed"]
PY
  then pass "$desc"; else failed "$desc"; fi
}

echo "--- no init/migrate/seeds commands exist ---"
check_exit "seeds is not a recognized command" 2 "$SLIPBOX" seeds find
check_exit "init is not a recognized command" 2 "$SLIPBOX" init
check_exit "migrate is not a recognized command" 2 "$SLIPBOX" migrate

echo "--- evergreen ---"
check "evergreen add" "$SLIPBOX" evergreen add --slug "draft-test-1" --reason "flagged tension"
check_file "evergreen file exists on disk" "$SCRATCH/evergreen/draft-test-1.md"
check_exit "evergreen add rejects a duplicate slug" 1 "$SLIPBOX" evergreen add --slug "draft-test-1" --reason "dup"
check "evergreen find" "$SLIPBOX" evergreen find --status to-discuss
check_eq "evergreen find returns exactly the inserted row" 1 "$("$SLIPBOX" evergreen find --status to-discuss | json_len)"
check "evergreen update (status + iteration)" "$SLIPBOX" evergreen update "draft-test-1" --status discussing --iteration 2
check_eq "evergreen update persisted status" discussing "$("$SLIPBOX" evergreen find | json_at "[0]['status']")"
check "evergreen update (slug rename)" "$SLIPBOX" evergreen update "draft-test-1" --slug "final-test-1"
check_file "renamed file exists" "$SCRATCH/evergreen/final-test-1.md"
check_no_file "old-slug file removed on rename" "$SCRATCH/evergreen/draft-test-1.md"
check_exit "evergreen update on unknown slug fails" 1 "$SLIPBOX" evergreen update "does-not-exist" --status discussed
check_exit "evergreen update with no flags is a usage error" 2 "$SLIPBOX" evergreen update "final-test-1"

echo "--- slug validation confines writes to evergreen/ ---"
check_exit "evergreen add rejects a traversal slug" 2 "$SLIPBOX" evergreen add --slug "../../etc/pwned" --reason "x"
check_exit "evergreen add rejects an absolute-path slug" 2 "$SLIPBOX" evergreen add --slug "/etc/pwned" --reason "x"
check_exit "evergreen add rejects a dot-segment slug" 2 "$SLIPBOX" evergreen add --slug "foo..bar" --reason "x"
check_exit "evergreen update rejects a traversal --slug" 2 "$SLIPBOX" evergreen update "final-test-1" --slug "../pwned"
check_exit "evergreen update rejects a non-numeric --iteration" 2 "$SLIPBOX" evergreen update "final-test-1" --iteration abc
find "$SCRATCH" -mindepth 1 -maxdepth 1 ! -name bin ! -name evergreen ! -name config.json ! -name style-profile.json ! -name humanize-checklist.json | grep -q . \
  && failed "unexpected file written outside evergreen/" \
  || pass "no file written outside evergreen/"

echo "--- evergreen atomic write leaves no stray temp files ---"
check_no_tmp_files "no leftover .tmp files after writes" "$SCRATCH/evergreen"

echo "--- links ---"
check "links add" "$SLIPBOX" links add --source "final-test-1" --target "some-term" --rel cites
check_exit "links add rejects invalid --rel" 2 "$SLIPBOX" links add --source a --target b --rel bogus
check "links find with no filters returns everything" "$SLIPBOX" links find
check_eq "links find returns the inserted edge" 1 "$("$SLIPBOX" links find | json_len)"
check "links find filters by --source" "$SLIPBOX" links add --source "other-slug" --target "some-term" --rel extends
check_eq "links find --source filters correctly" 1 "$("$SLIPBOX" links find --source final-test-1 | json_len)"

echo "--- links append-only fold and tombstones ---"
printf '%s\n' '{"source_id":"legacy-source","target_id":"legacy-target","rel_type":"cites"}' >> "$SCRATCH/links.jsonl"
"$SLIPBOX" links find --source legacy-source | check_json "legacy rows are active adds" 'assert len(data) == 1 and data[0]["target_id"] == "legacy-target"'
check "links remove appends a tombstone" "$SLIPBOX" links remove --source final-test-1 --target some-term --rel cites
check_eq "removed edge is absent" 0 "$("$SLIPBOX" links find --source final-test-1 | json_len)"
check "links remove is idempotent" "$SLIPBOX" links remove --source final-test-1 --target some-term --rel cites
check "add after remove restores edge" "$SLIPBOX" links add --source final-test-1 --target some-term --rel cites
check_eq "re-added edge is active" 1 "$("$SLIPBOX" links find --source final-test-1 | json_len)"
printf '%s\n' '{"op":"remove","source_slug":"exact","target_slug":"exact","rel_type":"extends"}' >> "$SCRATCH/links.jsonl"
check_eq "relationship identity remains exact" 0 "$("$SLIPBOX" links find --source exact --target exact --rel cites | json_len)"
printf '%s\n' '{"op":"bogus","source_slug":"bad","target_slug":"bad","rel_type":"cites"}' >> "$SCRATCH/links.jsonl"
check_exit "invalid link event reports failure" 1 "$SLIPBOX" links find
check_match "invalid event error identifies line" '*line 8*' "$(stderr_of "$SLIPBOX" links find)"
sed -i '' '$d' "$SCRATCH/links.jsonl"

echo "--- usage errors ---"
check_exit "unknown command exits 2" 2 "$SLIPBOX" bogus
check_exit "evergreen add missing --reason exits 2" 2 "$SLIPBOX" evergreen add --slug x

echo "--- recoverable work lifecycle ---"
# Resource clipping is required to use the shared transaction boundary rather
# than writing a fetched response directly to its frozen target.
RESOURCE_SKILL="$REPO_ROOT/skills/clip-resource/SKILL.md"
RESOURCE_DOC="$REPO_ROOT/docs/clip-resource.md"
LIFECYCLE="$REPO_ROOT/skills/using-slipbox/references/work-lifecycle.md"
for phrase in 'kind: resource' 'activity: clip' 'create-only' 'manifest.json' 'extraction.json' 'draft.md' 'work finalize' 'target collision' 'permanent extraction cache'; do
  assert_contains "Resource lifecycle names $phrase" "$phrase" "$RESOURCE_SKILL"
done
assert_contains "Resource docs describe independent work" 'one `resource`/`clip` work item per URL' "$RESOURCE_DOC"
assert_contains "Resource lifecycle reference defines extraction staging" "extraction.json" "$LIFECYCLE"
assert_contains "Resource lifecycle reference forbids permanent extraction cache" "not a permanent extraction cache" "$LIFECYCLE"
assert_contains "Resource lifecycle reference preserves failed work" "preserve failed state for repair" "$LIFECYCLE"

result=$("$SLIPBOX" work create --kind literature --activity create --source resources/a.md --target literature/a.md)
check_json "work create returns a ULID-shaped id" 'import re; assert re.fullmatch(r"[0-9A-HJKMNP-TV-Z]{26}", data["work_id"])' <<<"$result"
work_id=$(printf '%s' "$result" | json_at '["work_id"]')
check_file "work create creates one work directory" "$SCRATCH/work/$work_id/manifest.json"
check_json "work create records UTC timestamps and identity" 'assert data["created_at"].endswith("Z") and data["updated_at"].endswith("Z"); assert data["source_identity"] == "resources/a.md"; assert data["target_identity"] == "literature/a.md"' <<<"$result"
check_json "work list defaults to JSON" 'assert isinstance(data, list) and any(row["work_id"] == "'"$work_id"'" for row in data)' <<<"$("$SLIPBOX" work list)"
check_match "work list table has a header" '*work_id*' "$("$SLIPBOX" work list --format table | head -1)"
check_eq "work inspect defaults to JSON" "$work_id" "$("$SLIPBOX" work inspect "$work_id" | json_at '["work_id"]')"
check_match "work inspect table has a header" '*work_id*' "$("$SLIPBOX" work inspect "$work_id" --format table | head -1)"
for action in create list inspect update resume discard; do
  check_exit "work $action --help exits 0" 0 "$SLIPBOX" work "$action" --help
done
check_exit "work rejects unknown status" 2 "$SLIPBOX" work update "$work_id" --status nope
check_exit "work rejects unknown flag" 2 "$SLIPBOX" work list --bogus
check_exit "work discard requires explicit confirmation" 2 "$SLIPBOX" work discard "$work_id" --no-input
check_file "work remains after unconfirmed discard" "$SCRATCH/work/$work_id/manifest.json"
check "work update changes status" "$SLIPBOX" work update "$work_id" --status blocked
check_json "work update keeps affected paths consistent" 'assert data["source_identity"] in data["affected_paths"] and data["target_identity"] in data["affected_paths"]' <<<"$("$SLIPBOX" work update "$work_id" --source resources/changed.md)"
check_json "work resume returns state" 'assert data["work_id"] == "'"$work_id"'" and data["status"] == "blocked"' <<<"$("$SLIPBOX" work resume "$work_id")"
check "work discard accepts --yes" "$SLIPBOX" work discard "$work_id" --yes --no-input
check_no_file "discard removes selected work only" "$SCRATCH/work/$work_id/manifest.json"
check_exit "work discard does not age-delete anything" 0 "$SLIPBOX" work list

echo "--- staged publication and compensation ---"
printf 'before\n' > "$SCRATCH/publish-target.md"
result=$("$SLIPBOX" work create --kind literature --activity publish --target publish-target.md)
publish_id=$(printf '%s' "$result" | json_at '["work_id"]')
printf 'after\n' > "$SCRATCH/work/$publish_id/replacement.md"
python3 - "$SCRATCH/work/$publish_id/manifest.json" "$SCRATCH/work/$publish_id/mutations.json" <<'PY'
import json, hashlib, sys
manifest_path, mutations_path = sys.argv[1:]
manifest = json.load(open(manifest_path))
manifest["status"] = "ready-to-finalize"
fp = manifest["target_starting_fingerprint"]
manifest["mutations"] = [{"path":"publish-target.md", "expected_fingerprint":fp, "replacement_path":"replacement.md", "kind":"artifact"}]
json.dump(manifest, open(manifest_path, "w")); json.dump(manifest["mutations"], open(mutations_path, "w"))
PY
check_json "work finalize atomically publishes replacement" 'assert data["status"] == "published"' <<<"$("$SLIPBOX" work finalize "$publish_id")"
check_match "published replacement is present" '*after*' "$(<"$SCRATCH/publish-target.md")"

result=$("$SLIPBOX" work create --kind literature --activity rollback --target publish-target.md)
rollback_id=$(printf '%s' "$result" | json_at '["work_id"]')
printf 'first\n' > "$SCRATCH/work/$rollback_id/first.md"
printf 'second\n' > "$SCRATCH/work/$rollback_id/second.md"
python3 - "$SCRATCH/work/$rollback_id/manifest.json" <<'PY'
import json, sys
p=sys.argv[1]; m=json.load(open(p)); m["status"]="ready-to-finalize"; fp=m["target_starting_fingerprint"]
m["mutations"]=[{"path":"publish-target.md","expected_fingerprint":fp,"replacement_path":"first.md","kind":"artifact"},{"path":"publish-second.md","expected_fingerprint":None,"replacement_path":"second.md","kind":"artifact"}]; json.dump(m,open(p,"w"))
PY
check_exit "failed second mutation rolls back first" 1 env SLIPBOX_TEST_FAIL_MUTATION=1 "$SLIPBOX" work finalize "$rollback_id"
check_match "rollback restores first target" '*after*' "$(<"$SCRATCH/publish-target.md")"
check_json "rollback records terminal failure state" 'assert data["status"] == "failed"' <<<"$("$SLIPBOX" work inspect "$rollback_id")"
check_no_file "rolled-back new target is absent" "$SCRATCH/publish-second.md"

result=$("$SLIPBOX" work create --kind literature --activity collision)
collision_id=$(printf '%s' "$result" | json_at '["work_id"]')
printf 'collision\n' > "$SCRATCH/work/$collision_id/replacement.md"
printf 'already here\n' > "$SCRATCH/collision.md"
python3 - "$SCRATCH/work/$collision_id/manifest.json" <<'PY'
import json,sys
p=sys.argv[1];m=json.load(open(p));m['status']='ready-to-finalize';m['mutations']=[{'path':'collision.md','expected_fingerprint':None,'replacement_path':'replacement.md','kind':'artifact'}];json.dump(m,open(p,'w'))
PY
check_exit "new-file collision is rejected" 1 "$SLIPBOX" work finalize "$collision_id"
check_match "collision target is untouched" '*already here*' "$(<"$SCRATCH/collision.md")"

result=$("$SLIPBOX" work create --kind resource --activity clip --target existing-resource.md)
resource_collision_id=$(printf '%s' "$result" | json_at '["work_id"]')
printf 'resource replacement\n' > "$SCRATCH/work/$resource_collision_id/draft.md"
printf 'existing resource\n' > "$SCRATCH/existing-resource.md"
python3 - "$SCRATCH/work/$resource_collision_id/manifest.json" "$SCRATCH/existing-resource.md" <<'PY'
import hashlib, json, sys
manifest_path, target_path = sys.argv[1:]
manifest = json.load(open(manifest_path))
fingerprint = "sha256:" + hashlib.sha256(open(target_path, "rb").read()).hexdigest()
manifest["status"] = "ready-to-finalize"
manifest["mutations"] = [{"path":"existing-resource.md", "expected_fingerprint":fingerprint, "replacement_path":"draft.md", "kind":"artifact"}]
json.dump(manifest, open(manifest_path, "w"))
PY
check_exit "Resource rejects an existing target despite matching fingerprint" 1 "$SLIPBOX" work finalize "$resource_collision_id"
check_match "Resource collision leaves existing target untouched" '*existing resource*' "$(<"$SCRATCH/existing-resource.md")"

result=$("$SLIPBOX" work create --kind literature --activity changed --target publish-target.md)
changed_id=$(printf '%s' "$result" | json_at '["work_id"]')
printf 'changed\n' > "$SCRATCH/work/$changed_id/replacement.md"
python3 - "$SCRATCH/work/$changed_id/manifest.json" <<'PY'
import json,sys
p=sys.argv[1];m=json.load(open(p));m['status']='ready-to-finalize';m['mutations']=[{'path':'publish-target.md','expected_fingerprint':m['target_starting_fingerprint'],'replacement_path':'replacement.md','kind':'artifact'}];json.dump(m,open(p,'w'))
PY
printf 'concurrent\n' > "$SCRATCH/publish-target.md"
check_exit "changed target CAS is rejected" 1 "$SLIPBOX" work finalize "$changed_id"

result=$("$SLIPBOX" work create --kind literature --activity savefail)
savefail_id=$(printf '%s' "$result" | json_at '["work_id"]')
printf 'saved\n' > "$SCRATCH/work/$savefail_id/replacement.md"
python3 - "$SCRATCH/work/$savefail_id/manifest.json" <<'PY'
import json,sys
p=sys.argv[1];m=json.load(open(p));m['status']='ready-to-finalize';m['mutations']=[{'path':'savefail.md','expected_fingerprint':None,'replacement_path':'replacement.md','kind':'artifact'}];json.dump(m,open(p,'w'))
PY
check_exit "manifest save failure is terminal" 1 env SLIPBOX_TEST_FAIL_MANIFEST_SAVE=1 "$SLIPBOX" work finalize "$savefail_id"
check_json "manifest save failure records repair" 'assert data["status"] == "repair-required"' <<<"$("$SLIPBOX" work inspect "$savefail_id")"
cp "$SCRATCH/links.jsonl" "$SCRATCH/links-before-publication-tests.jsonl"

result=$("$SLIPBOX" work create --kind migration --activity ledger-compensation)
ledger_id=$(printf '%s' "$result" | json_at '["work_id"]')
printf '%s\n' '{"op":"add","source_slug":"ledger-source","target_slug":"ledger-target","rel_type":"cites"}' > "$SCRATCH/work/$ledger_id/link.jsonl"
printf 'never-published\n' > "$SCRATCH/work/$ledger_id/after.md"
python3 - "$SCRATCH/work/$ledger_id/manifest.json" <<'PY'
import json, sys
p = sys.argv[1]
m = json.load(open(p))
m["status"] = "ready-to-finalize"
m["mutations"] = [
    {"path":"links.jsonl", "expected_fingerprint":"sha256:" + __import__("hashlib").sha256(open(__import__("os").path.join(__import__("os").path.dirname(p), "..", "..", "links.jsonl"), "rb").read()).hexdigest(), "replacement_path":"link.jsonl", "kind":"ledger-add", "source_slug":"ledger-source", "target_slug":"ledger-target", "rel_type":"cites"},
    {"path":"ledger-after.md", "expected_fingerprint":None, "replacement_path":"after.md", "kind":"artifact"},
]
json.dump(m, open(p, "w"))
PY
check_exit "ledger compensation failure rolls back with tombstone" 1 env SLIPBOX_TEST_FAIL_MUTATION=1 "$SLIPBOX" work finalize "$ledger_id"
check_json "ledger compensation records failed state" 'assert data["status"] == "failed"' <<<"$("$SLIPBOX" work inspect "$ledger_id")"
check_json "ledger compensation appends tombstone" 'assert len(data) == 0' <<<"$("$SLIPBOX" links find --source ledger-source --target ledger-target --rel cites)"
check_match "ledger compensation preserves append-only history" '*"op": "add"*"op": "remove"*' "$(<"$SCRATCH/links.jsonl")"

result=$("$SLIPBOX" work create --kind migration --activity ledger-repair)
repair_id=$(printf '%s' "$result" | json_at '["work_id"]')
printf '%s\n' '{"op":"add","source_slug":"repair-source","target_slug":"repair-target","rel_type":"extends"}' > "$SCRATCH/work/$repair_id/link.jsonl"
printf 'repair-target\n' > "$SCRATCH/work/$repair_id/after.md"
python3 - "$SCRATCH/work/$repair_id/manifest.json" <<'PY'
import json, sys
p = sys.argv[1]
m = json.load(open(p))
m["status"] = "ready-to-finalize"
m["mutations"] = [
    {"path":"links.jsonl", "expected_fingerprint":"sha256:" + __import__("hashlib").sha256(open(__import__("os").path.join(__import__("os").path.dirname(p), "..", "..", "links.jsonl"), "rb").read()).hexdigest(), "replacement_path":"link.jsonl", "kind":"ledger-add", "source_slug":"repair-source", "target_slug":"repair-target", "rel_type":"extends"},
    {"path":"repair-after.md", "expected_fingerprint":None, "replacement_path":"after.md", "kind":"artifact"},
]
json.dump(m, open(p, "w"))
PY
check_exit "failed ledger compensation requires repair" 1 env SLIPBOX_TEST_FAIL_MUTATION=1 SLIPBOX_TEST_FAIL_COMPENSATION=1 "$SLIPBOX" work finalize "$repair_id"
check_json "compensation failure records repair-required diagnostics" 'assert data["status"] == "repair-required" and data["repair_errors"]' <<<"$("$SLIPBOX" work inspect "$repair_id")"
check_json "uncompensated ledger addition remains visible" 'assert len(data) == 1 and data[0]["source_slug"] == "repair-source"' <<<"$("$SLIPBOX" links find --source repair-source --target repair-target --rel extends)"
printf '%s\n' '{"op":"add","source_slug":"legacy-literature","target_slug":"reference-target","rel_type":"extends"}' >> "$SCRATCH/links.jsonl"
result=$("$SLIPBOX" work create --kind migration --activity reference-ledger-normalize)
normalize_id=$(printf '%s' "$result" | json_at '["work_id"]')
printf '%s\n' '{"op":"remove","source_slug":"legacy-literature","target_slug":"reference-target","rel_type":"extends"}' '{"op":"add","source_slug":"resource-source","target_slug":"reference-target","rel_type":"extends"}' > "$SCRATCH/work/$normalize_id/events.jsonl"
python3 - "$SCRATCH/work/$normalize_id/manifest.json" "$SCRATCH/links.jsonl" <<'PY'
import hashlib, json, sys
p, links = sys.argv[1:]
m = json.load(open(p)); m["status"] = "ready-to-finalize"
m["mutations"] = [{"path":"links.jsonl", "expected_fingerprint":"sha256:" + hashlib.sha256(open(links, "rb").read()).hexdigest(), "replacement_path":"events.jsonl", "kind":"ledger-events", "events":[{"op":"remove","source_slug":"legacy-literature","target_slug":"reference-target","rel_type":"extends"},{"op":"add","source_slug":"resource-source","target_slug":"reference-target","rel_type":"extends"}]}]
json.dump(m, open(p, "w"))
PY
check "ledger migration events finalize transactionally" "$SLIPBOX" work finalize "$normalize_id"
check_json "ledger migration tombstone and replacement fold in order" 'assert len(data) == 1 and data[0]["source_slug"] == "resource-source"' <<<"$("$SLIPBOX" links find --target reference-target --rel extends)"
cp "$SCRATCH/links-before-publication-tests.jsonl" "$SCRATCH/links.jsonl"

result=$("$SLIPBOX" work create --kind literature --activity lock-contention)
lock_id=$(printf '%s' "$result" | json_at '["work_id"]')
printf 'locked replacement\n' > "$SCRATCH/work/$lock_id/replacement.md"
printf 'second replacement\n' > "$SCRATCH/work/$lock_id/second.md"
python3 - "$SCRATCH/work/$lock_id/manifest.json" <<'PY'
import json, sys
p = sys.argv[1]
m = json.load(open(p))
m["status"] = "ready-to-finalize"
m["mutations"] = [
    {"path":"z-ordered-lock-target.md", "expected_fingerprint":None, "replacement_path":"replacement.md", "kind":"artifact"},
    {"path":"a-ordered-lock-target.md", "expected_fingerprint":None, "replacement_path":"second.md", "kind":"artifact"},
]
json.dump(m, open(p, "w"))
PY
LOCK_PATH=$(python3 - "$SCRATCH" <<'PY'
import hashlib, pathlib, sys
root = pathlib.Path(sys.argv[1])
target = root / "a-ordered-lock-target.md"
print(root / "work" / ".locks" / (hashlib.sha256(str(target).encode()).hexdigest() + ".lock"))
PY
)
mkdir -p "$(dirname "$LOCK_PATH")"
LOCK_READY="$SCRATCH/lock-ready"
python3 - "$LOCK_PATH" "$LOCK_READY" <<'PY' &
import fcntl, sys, time
with open(sys.argv[1], "a+") as handle:
    fcntl.flock(handle.fileno(), fcntl.LOCK_EX)
    open(sys.argv[2], "w").close()
    time.sleep(2)
PY
holder=$!
for _ in $(seq 1 40); do [ -f "$LOCK_READY" ] && break; sleep 0.05; done
check_exit "contended lock prevents publication" 1 "$SLIPBOX" work finalize "$lock_id"
assert_contains "locks are acquired in deterministic path order" "a-ordered-lock-target.md" /tmp/slipbox-test-err
wait "$holder"
check_json "contended work remains ready" 'assert data["status"] == "ready-to-finalize"' <<<"$("$SLIPBOX" work inspect "$lock_id")"
check_no_file "contended target is untouched" "$SCRATCH/a-ordered-lock-target.md"
check_no_file "later target is untouched after contention" "$SCRATCH/z-ordered-lock-target.md"

echo "--- config (unchanged from idea-db) ---"
printf '{"paths":{"literature":"literature"}}' > "$SCRATCH/config.json"
check "config get" "$SLIPBOX" config get paths.literature
check "config set" "$SLIPBOX" config set paths.literature "Literature"
check_eq "config set persisted" Literature "$("$SLIPBOX" config get paths.literature | json_at "")"

echo "--- dispatch and flag usage ---"
check_exit "--help exits 0" 0 "$SLIPBOX" --help
assert_contains "--help prints the usage block" "Usage:" /tmp/slipbox-test-out
check_exit "-h exits 0" 0 "$SLIPBOX" -h
assert_contains "-h prints the usage block" "slipbox — CLI" /tmp/slipbox-test-out
check_exit "--version exits 0" 0 "$SLIPBOX" --version
assert_contains "--version prints the CLI version" "slipbox $CLI_VERSION" /tmp/slipbox-test-out
check_exit "-v exits 0" 0 "$SLIPBOX" -v
assert_contains "-v prints the CLI version" "slipbox $CLI_VERSION" /tmp/slipbox-test-out
check_exit "no arguments prints help and exits 2" 2 "$SLIPBOX"
assert_contains "no arguments prints the usage block" "Usage:" /tmp/slipbox-test-out
for group in evergreen links config humanize; do
  check_exit "$group with no action exits 2" 2 "$SLIPBOX" "$group"
  check_exit "$group with a bogus action exits 2" 2 "$SLIPBOX" "$group" bogus
done
check_exit "a final flag without a value exits 2" 2 "$SLIPBOX" evergreen find --status

echo "--- deterministic filename formatting ---"
cat > "$SCRATCH/config.json" <<'EOF'
{"filenames":{"literature":"Sentence case","reference":"kebab-case","evergreen":"Sentence case"},"prefixes":{"literature":"§","reference":"※","evergreen":false}}
EOF
check_eq "Sentence case preserves proper name and prefixes after casing" "§ Software fundamentals matter more than ever: Matt Pocock" \
  "$("$SLIPBOX" filename format --type literature --title 'Software Fundamentals Matter More Than Ever: Matt Pocock' --preserve 'Matt Pocock')"
check_eq "Sentence case preserves acronyms" "§ API design for NASA teams" \
  "$("$SLIPBOX" filename format --type literature --title 'API Design for NASA Teams')"

echo "--- universal note prefix/link/H1 contract ---"
for contract in \
  'File: § Literature.md   Link: [[§ Literature|Literature]]   H1: # Literature' \
  'File: ※ Reference.md    Link: [[※ Reference|Reference]]     H1: # Reference' \
  'File: ✱ Evergreen.md     Link: [[✱ Evergreen|Evergreen]]     H1: # Evergreen'; do
  assert_contains "cross-type prefix contract is documented: $contract" "$contract" \
    "$REPO_ROOT/skills/write-checks/SKILL.md"
done
assert_contains "validator rejects an unprefixed target for prefixed notes" "Reject unprefixed targets for prefixed files" \
  "$REPO_ROOT/skills/write-checks/SKILL.md"
assert_contains "validator rejects prefixes in note H1 headings" "reject prefix in any H1" \
  "$REPO_ROOT/skills/write-checks/SKILL.md"

echo "--- whole-artifact validation ---"
cat > "$SCRATCH/config.json" <<'EOF'
{
  "filenames": {"literature":"Sentence case","reference":"kebab-case","evergreen":"Sentence case"},
  "prefixes": {"literature":"§","reference":"※","evergreen":false},
  "frontmatter": {"literature": {"type":{"name":"type","type":"text","zone":"top"},"created":{"name":"created","type":"date","zone":"top"},"source":{"name":"source","type":"text","zone":"bottom"}}}
}
EOF
cat > "$SCRATCH/§ Exact source title.md" <<'EOF'
---
type: "literature"
created: 2026-08-24
source: "[[A resource]]"
---
# Exact source title
One compact paragraph.
EOF
check "note validate accepts a complete artifact" "$SLIPBOX" note validate --type literature --path "$SCRATCH/§ Exact source title.md" --basename "§ Exact source title.md" --title "Exact source title"
sed 's/type: "literature"/type: literature/' "$SCRATCH/§ Exact source title.md" > "$SCRATCH/§ Bare text.md"
check "note validate accepts bare mapped text" "$SLIPBOX" note validate --type literature --path "$SCRATCH/§ Bare text.md" --basename "§ Bare text.md" --title "Exact source title"
cat > "$SCRATCH/§ Backtick comment.md" <<'EOF'
---
type: literature
created: 2026-08-24
source: "[[A resource]]"
---
# Exact source title
```sh
# Shell comment
echo "ok"
```
EOF
check "note validate ignores H1-like lines in backtick fences" "$SLIPBOX" note validate --type literature --path "$SCRATCH/§ Backtick comment.md" --basename "§ Backtick comment.md" --title "Exact source title"
cat > "$SCRATCH/§ Tilde comment.md" <<'EOF'
---
type: literature
created: 2026-08-24
source: "[[A resource]]"
---
# Exact source title
~~~sh
# Shell comment
echo "ok"
~~~
EOF
check "note validate ignores H1-like lines in tilde fences" "$SLIPBOX" note validate --type literature --path "$SCRATCH/§ Tilde comment.md" --basename "§ Tilde comment.md" --title "Exact source title"
cat > "$SCRATCH/§ Multiple real H1.md" <<'EOF'
---
type: literature
created: 2026-08-24
source: "[[A resource]]"
---
# Exact source title
## A section
# Another real heading
EOF
check_exit "note validate rejects multiple real H1s" 1 "$SLIPBOX" note validate --type literature --path "$SCRATCH/§ Multiple real H1.md" --basename "§ Multiple real H1.md" --title "Exact source title"
check_exit "note validate rejects a basename mismatch" 1 "$SLIPBOX" note validate --type literature --path "$SCRATCH/§ Exact source title.md" --basename "§ Other title.md" --title "Exact source title"
cat > "$SCRATCH/config.json" <<'EOF'
{
  "filenames": {"literature":"Sentence case","reference":"kebab-case","evergreen":"Sentence case"},
  "prefixes": {"literature":"§","reference":"※","evergreen":false},
  "frontmatter": {"reference": {"type":{"name":"type","type":"text","zone":"top"},"created":{"name":"created","type":"date","zone":"top"},"sources":{"name":"sources","type":"list","zone":"bottom"}}}
}
EOF
cat > "$SCRATCH/※ Reference.md" <<'EOF'
---
type: "reference"
created: 2026-08-24
sources: ["[[A resource]]"]
---
# Reference
Definition.
EOF
check "note validate accepts a parsed list" "$SLIPBOX" note validate --type reference --path "$SCRATCH/※ Reference.md" --basename "※ Reference.md" --title "Reference"
cat > "$SCRATCH/※ block-list.md" <<'EOF'
---
type: reference
created: 2026-08-24
sources:
  - "[[A resource]]"
  - "[[Another resource]]"
---
# Reference
Definition.
EOF
check "note validate accepts a block YAML list" "$SLIPBOX" note validate --type reference --path "$SCRATCH/※ block-list.md" --basename "※ block-list.md" --title "Reference"
sed 's/sources: \[.*/sources: [not valid/' "$SCRATCH/※ Reference.md" > "$SCRATCH/malformed-list.md"
check_exit "note validate rejects malformed list serialization" 1 "$SLIPBOX" note validate --type reference --path "$SCRATCH/malformed-list.md" --basename "malformed-list.md" --title "Reference"
sed 's/created: 2026-08-24/created: "2026-08-24"/' "$SCRATCH/※ Reference.md" > "$SCRATCH/quoted-date.md"
check_exit "note validate rejects quoted date" 1 "$SLIPBOX" note validate --type reference --path "$SCRATCH/quoted-date.md" --basename "quoted-date.md" --title "Reference"
cat > "$SCRATCH/config.json" <<'EOF'
{
  "filenames": {"literature":"Sentence case","reference":"kebab-case","evergreen":"Sentence case"},
  "prefixes": {"literature":"§","reference":"※","evergreen":false},
  "frontmatter": {"evergreen": {"type":{"name":"type","type":"text","zone":"top"},"score":{"name":"score","type":"number","zone":"top"},"enabled":{"name":"enabled","type":"checkbox","zone":"top"},"created":{"name":"created","type":"date","zone":"top"},"updated":{"name":"updated","type":"datetime","zone":"bottom"}}}
}
EOF
cat > "$SCRATCH/kinds.md" <<'EOF'
---
type: evergreen
score: 3.5
enabled: true
created: 2026-08-24
updated: 2026-08-24T12:34:56Z
---
# Kinds
Definition.
EOF
check "note validate accepts number checkbox date and datetime" "$SLIPBOX" note validate --type evergreen --path "$SCRATCH/kinds.md" --basename "kinds.md" --title "Kinds"
sed 's/score: 3.5/score: "not a number"/' "$SCRATCH/kinds.md" > "$SCRATCH/bad-number.md"
check_exit "note validate rejects a non-number" 1 "$SLIPBOX" note validate --type evergreen --path "$SCRATCH/bad-number.md" --basename "bad-number.md" --title "Kinds"
sed 's/enabled: true/enabled: yes/' "$SCRATCH/kinds.md" > "$SCRATCH/bad-checkbox.md"
check_exit "note validate rejects a non-checkbox" 1 "$SLIPBOX" note validate --type evergreen --path "$SCRATCH/bad-checkbox.md" --basename "bad-checkbox.md" --title "Kinds"
sed 's/updated: 2026-08-24T12:34:56Z/updated: "2026-08-24T12:34:56Z"/' "$SCRATCH/kinds.md" > "$SCRATCH/quoted-datetime.md"
check_exit "note validate rejects quoted datetime" 1 "$SLIPBOX" note validate --type evergreen --path "$SCRATCH/quoted-datetime.md" --basename "quoted-datetime.md" --title "Kinds"
check_eq "unsafe filename characters are sanitized" "§ A title-with-unsafe-chars-yes" \
  "$("$SLIPBOX" filename format --type literature --title 'A Title/With: Unsafe*Chars? Yes')"
check_eq "no prefix returns the complete unprefixed basename" "An evergreen idea" \
  "$("$SLIPBOX" filename format --type evergreen --title 'An Evergreen Idea')"
check_eq "multiple protected spans survive casing" "§ Design with Matt Pocock and OpenAI" \
  "$("$SLIPBOX" filename format --type literature --title 'Design With Matt Pocock and OpenAI' --preserve 'Matt Pocock' --preserve 'OpenAI')"
check_eq "protected substring does not alter an unrelated word in Sentence case" "§ AI and PAIR" \
  "$($SLIPBOX filename format --type literature --title 'AI and PAIR' --preserve 'AI')"
check_eq "protected substring does not alter a mixed-case word" "§ AI and pairwise" \
  "$($SLIPBOX filename format --type literature --title 'AI and PAIRwise' --preserve 'AI')"
check_eq "protected span survives kebab-case" "※ guide-by-OpenAI" \
  "$($SLIPBOX filename format --type reference --title 'Guide By OpenAI' --preserve 'OpenAI')"
check_eq "multiword protected span uses kebab separators" "※ guide-by-Matt-Pocock" \
  "$($SLIPBOX filename format --type reference --title 'Guide By Matt Pocock' --preserve 'Matt Pocock')"
cat > "$SCRATCH/config.json" <<'EOF'
{"filenames":{"literature":"Sentence case","reference":"snake_case","evergreen":"Sentence case"},"prefixes":{"literature":"§","reference":"※","evergreen":false}}
EOF
check_eq "protected span survives snake_case" "※ guide_by_OpenAI" \
  "$($SLIPBOX filename format --type reference --title 'Guide By OpenAI' --preserve 'OpenAI')"
check_eq "multiword protected span uses snake separators" "※ guide_by_Matt_Pocock" \
  "$($SLIPBOX filename format --type reference --title 'Guide By Matt Pocock' --preserve 'Matt Pocock')"
cat > "$SCRATCH/config.json" <<'EOF'
{"filenames":{"literature":"Sentence case","reference":"kebab-case","evergreen":"Sentence case"},"prefixes":{"literature":"§","reference":"※","evergreen":false}}
EOF
check_eq "mixed-case hyphenated words are not treated as acronyms" "§ AI-assisted coding" \
  "$($SLIPBOX filename format --type literature --title 'AI-Assisted Coding')"
check_match "unmatched protected names are surfaced" '*not found*preview*' \
  "$(stderr_of "$SLIPBOX" filename format --type literature --title 'A Title' --preserve 'Missing Name')"
check_match "ambiguous protected names are surfaced" '*ambiguous*preview*' \
  "$(stderr_of "$SLIPBOX" filename format --type literature --title 'OpenAI and OpenAI' --preserve 'OpenAI')"
check_eq "only the protected-name subtitle colon is preserved" "§ First: Matt Pocock-second title" \
  "$($SLIPBOX filename format --type literature --title 'First: Matt Pocock: Second Title' --preserve 'Matt Pocock')"
check_eq "auto-detected acronyms do not preserve subtitle colons" "§ API-NASA teams" \
  "$($SLIPBOX filename format --type literature --title 'API: NASA Teams')"
check_match "uncertain protected names are surfaced on stderr" '*uncertain*preview*' \
  "$(stderr_of "$SLIPBOX" filename format --type literature --title 'A Title' --uncertain 'Title')"
check_exit "filename format missing title is a usage error" 2 "$SLIPBOX" filename format --type literature
check_exit "filename format unknown type is a usage error" 2 "$SLIPBOX" filename format --type article --title Title
check_exit "filename format help exits 0" 0 "$SLIPBOX" filename format --help

echo "--- evergreen edge cases ---"
check_exit "evergreen add missing --slug exits 2" 2 "$SLIPBOX" evergreen add --reason reason
mv "$SCRATCH/evergreen" "$SCRATCH/evergreen.saved"
check_exit "evergreen add without its data directory exits 1" 1 "$SLIPBOX" evergreen add --slug no-dir --reason reason
check_exit "evergreen find without its data directory exits 1" 1 "$SLIPBOX" evergreen find
check_exit "evergreen update without its data directory exits 1" 1 "$SLIPBOX" evergreen update no-dir --status discussing
mv "$SCRATCH/evergreen.saved" "$SCRATCH/evergreen"

check_exit "evergreen find with no matching status returns 0" 0 "$SLIPBOX" evergreen find --status no-such-status
check_json_file "unmatched evergreen status returns an empty JSON array" "assert data == []" /tmp/slipbox-test-out
check_table evergreen $'slug\t*' 1 "$("$SLIPBOX" evergreen find --format table)"
check_eq "evergreen table output marks an empty result" "(no rows)" "$("$SLIPBOX" evergreen find --status no-such-status --format table)"
printf 'this file has no frontmatter\n' > "$SCRATCH/evergreen/no-frontmatter.md"
"$SLIPBOX" evergreen find | check_json "evergreen find skips a file with no frontmatter" "assert len(data) >= 1"
cat > "$SCRATCH/evergreen/typed-values.md" <<'EOF'
---
status: plain-status
plain_string: plain
integer_value: 42
empty_value:
created_at: "2099-01-03T00:00:00Z"
---
EOF
"$SLIPBOX" evergreen find | check_json "evergreen frontmatter parses plain strings, integers, and empty values" '
row = next(row for row in data if row["slug"] == "typed-values")
assert row["plain_string"] == "plain" and isinstance(row["plain_string"], str)
assert row["integer_value"] == 42 and isinstance(row["integer_value"], int)
assert row["empty_value"] is None
'
cat > "$SCRATCH/evergreen/older.md" <<'EOF'
---
status: to-discuss
created_at: "2020-01-01T00:00:00Z"
---
EOF
cat > "$SCRATCH/evergreen/newer.md" <<'EOF'
---
status: to-discuss
created_at: "2099-01-02T00:00:00Z"
---
EOF
"$SLIPBOX" evergreen find | check_json "evergreen rows sort by created_at descending" '
positions = {row["slug"]: index for index, row in enumerate(data)}
assert positions["newer"] < positions["older"]
'
check "evergreen update persists --note-path" "$SLIPBOX" evergreen update final-test-1 --note-path notes/final.md
assert_contains "evergreen update persisted note_path" 'note_path: "notes/final.md"' "$SCRATCH/evergreen/final-test-1.md"
check "add collision candidate" "$SLIPBOX" evergreen add --slug collision-target --reason collision
cp "$SCRATCH/evergreen/final-test-1.md" "$SCRATCH/final-before-collision.md"
cp "$SCRATCH/evergreen/collision-target.md" "$SCRATCH/collision-before-collision.md"
check_exit "evergreen update rejects a colliding rename" 1 "$SLIPBOX" evergreen update final-test-1 --slug collision-target
if cmp -s "$SCRATCH/evergreen/final-test-1.md" "$SCRATCH/final-before-collision.md" &&
  cmp -s "$SCRATCH/evergreen/collision-target.md" "$SCRATCH/collision-before-collision.md"; then
  pass "colliding rename leaves both original files untouched"
else
  failed "colliding rename changed an original file"
fi

echo "--- links edge cases ---"
"$SLIPBOX" links find --target some-term | check_json "links find filters by --target" "assert len(data) == 2"
"$SLIPBOX" links find --rel extends | check_json "links find filters by --rel" 'assert len(data) == 1 and data[0]["source_id"] == "other-slug"'
"$SLIPBOX" links find --source final-test-1 --rel cites | check_json "links find combines source and relation filters" "assert len(data) == 1"
cp "$SCRATCH/links.jsonl" "$SCRATCH/links.jsonl.before-blank-line"
printf '\n' >> "$SCRATCH/links.jsonl"
"$SLIPBOX" links find | check_json "links find skips a blank JSONL line" "assert len(data) == 3"
mv "$SCRATCH/links.jsonl.before-blank-line" "$SCRATCH/links.jsonl"
check_table links $'source_id\ttarget_id*' 3 "$("$SLIPBOX" links find --format table)"
check_eq "links table output marks an empty result" "(no rows)" "$("$SLIPBOX" links find --target no-such-target --format table)"
mv "$SCRATCH/links.jsonl" "$SCRATCH/links.saved"
"$SLIPBOX" links find | check_json "links find without links.jsonl returns an empty array" "assert data == []"
mv "$SCRATCH/links.saved" "$SCRATCH/links.jsonl"

echo "--- config edge cases ---"
printf '{"paths":{"literature":"literature"},"settings":{"number":0,"enabled":false}}' > "$SCRATCH/config.json"
"$SLIPBOX" config get | check_json "config get without a path prints the whole document" 'assert data["paths"]["literature"] == "literature"'
check_exit "config get unknown path exits 2" 2 "$SLIPBOX" config get paths.unknown
check_exit "config get through a non-dict exits 2" 2 "$SLIPBOX" config get paths.literature.missing
check_exit "config set unknown intermediate path exits 2" 2 "$SLIPBOX" config set missing.leaf value
check_exit "config set unknown leaf exits 2" 2 "$SLIPBOX" config set paths.unknown value
check "config set stores a JSON number" "$SLIPBOX" config set settings.number 42
check "config set stores a JSON boolean" "$SLIPBOX" config set settings.enabled true
check "config set stores a bare word as a string" "$SLIPBOX" config set paths.literature Literature
check_json_file "config set preserves JSON types and bare words as strings" '
assert data["settings"]["number"] == 42 and isinstance(data["settings"]["number"], int)
assert data["settings"]["enabled"] is True
assert data["paths"]["literature"] == "Literature" and isinstance(data["paths"]["literature"], str)
' "$SCRATCH/config.json"

echo "--- error handling: usage errors are never swallowed ---"
check_exit "a flag given without a value exits 2" 2 "$SLIPBOX" evergreen update "final-test-1" --status
check_exit "an unknown flag exits 2 instead of being ignored" 2 "$SLIPBOX" evergreen find --stat to-discuss
check_exit "a stray positional exits 2" 2 "$SLIPBOX" evergreen find to-discuss
check_exit "a non-numeric --iteration exits 2" 2 "$SLIPBOX" evergreen update "final-test-1" --iteration abc
check_exit "an unknown --format exits 2" 2 "$SLIPBOX" evergreen find --format yaml
"$SLIPBOX" evergreen update 'we"ird\slug' --status discussed 2>"$SCRATCH/err.json" >/dev/null || true
check_valid_json "a quote in an error message still leaves stderr valid JSON" "$SCRATCH/err.json"

echo "--- error handling: bad on-disk state fails loudly, no tracebacks ---"
printf 'not frontmatter at all\n' > "$SCRATCH/evergreen/broken.md"
check_exit "evergreen update on an unparsable file exits 1" 1 "$SLIPBOX" evergreen update "broken" --status discussed
check_no_match "unparsable frontmatter reports a JSON error, not a traceback" '*Traceback*' \
  "$(stderr_of "$SLIPBOX" evergreen update "broken" --status discussed)"
check_match "evergreen find warns about the file it skipped" '*warning*broken.md*' \
  "$(stderr_of "$SLIPBOX" evergreen find)"
check "evergreen find still returns the parsable rows" "$SLIPBOX" evergreen find
rm "$SCRATCH/evergreen/broken.md"

printf 'not json\n' >> "$SCRATCH/links.jsonl"
check_exit "links find on a corrupt log exits 1" 1 "$SLIPBOX" links find
check_match "corrupt links log error names the offending line" '*line 8*' \
  "$(stderr_of "$SLIPBOX" links find)"
python3 -c "
import sys
path = sys.argv[1]
lines = [l for l in open(path).read().splitlines() if l.strip() and l != 'not json']
open(path, 'w').write('\n'.join(lines) + '\n')
" "$SCRATCH/links.jsonl"
check "links find works again once the log is clean" "$SLIPBOX" links find

echo "--- humanize (unchanged from idea-db) ---"
cp "$REPO_ROOT/skills/setup-slipbox/assets/humanize-checklist.json" "$SCRATCH/humanize-checklist.json"
cat > "$SCRATCH/style-profile.json" <<'EOF'
{"language":{"primary":"English","secondary":"Indonesian","technical_terms":"English","code_switching":"natural"}}
EOF
printf '# Strategic Negotiations And Partnerships\n# Another Important Heading\n' > "$SCRATCH/two-title-case.md"
check_eq "two title-case headings pass the cluster threshold" True \
  "$("$SLIPBOX" humanize check "$SCRATCH/two-title-case.md" | json_at '["flagged"]')"

echo "--- humanize edge cases ---"
printf 'plain prose with no mechanical signals.\n' > "$SCRATCH/clean.md"
if "$SLIPBOX" humanize check "$SCRATCH/clean.md" > "$SCRATCH/clean-result.json" &&
  python3 -c 'import json,sys; assert json.load(open(sys.argv[1]))["flagged"] is False' "$SCRATCH/clean-result.json"; then
  echo "ok   - clean prose is not flagged"
else
  echo "FAIL - clean prose was flagged"
  fail=1
fi
check_exit "humanize check on a nonexistent file exits 1" 1 "$SLIPBOX" humanize check "$SCRATCH/missing.md"
mv "$SCRATCH/config.json" "$SCRATCH/config.saved"
check_exit "humanize check without config.json exits 1" 1 "$SLIPBOX" humanize check "$SCRATCH/clean.md"
mv "$SCRATCH/config.saved" "$SCRATCH/config.json"
mv "$SCRATCH/humanize-checklist.json" "$SCRATCH/humanize-checklist.saved"
check_exit "humanize check without humanize-checklist.json exits 1" 1 "$SLIPBOX" humanize check "$SCRATCH/clean.md"
mv "$SCRATCH/humanize-checklist.saved" "$SCRATCH/humanize-checklist.json"
mv "$SCRATCH/style-profile.json" "$SCRATCH/style-profile.saved"
check_exit "humanize check without style-profile.json exits 1" 1 "$SLIPBOX" humanize check "$SCRATCH/clean.md"
mv "$SCRATCH/style-profile.saved" "$SCRATCH/style-profile.json"
check_exit "humanize check rejects an extra argument" 2 "$SLIPBOX" humanize check "$SCRATCH/clean.md" extra
check_exit "humanize check rejects --language without a value" 2 "$SLIPBOX" humanize check "$SCRATCH/clean.md" --language
cat > "$SCRATCH/french.md" <<'EOF'
Let's dive in.
EOF
if "$SLIPBOX" humanize check "$SCRATCH/french.md" --language French > "$SCRATCH/french-result.json" &&
  python3 - "$SCRATCH/french-result.json" <<'PY'
import json
import sys
with open(sys.argv[1]) as handle:
    result = json.load(handle)
assert any(signal.get("skipped") == "language_scope" for signal in result["signals"])
PY
then
  echo "ok   - out-of-profile language skips en-scoped signals"
else
  echo "FAIL - out-of-profile language did not skip en-scoped signals"
  fail=1
fi
printf '# One\n' > "$SCRATCH/one-heading.md"
if "$SLIPBOX" humanize check "$SCRATCH/one-heading.md" > "$SCRATCH/one-heading-result.json" &&
  python3 -c 'import json,sys; assert json.load(open(sys.argv[1]))["flagged"] is False' "$SCRATCH/one-heading-result.json"; then
  echo "ok   - a single-significant-word title-case heading is not flagged"
else
  echo "FAIL - a single-significant-word title-case heading was flagged"
  fail=1
fi

CHECKLIST="$REPO_ROOT/skills/setup-slipbox/assets/humanize-checklist.json"
read_signal_value() {
  local signal_id="$1" expected_type="$2" field="$3"
  python3 - "$CHECKLIST" "$signal_id" "$expected_type" "$field" <<'PY'
import json
import sys

checklist_path, expected_id, expected_type, field = sys.argv[1:]
with open(checklist_path) as handle:
    signals = json.load(handle)["detection"]["mechanical"]["signals"]
matches = [signal for signal in signals if signal.get("id") == expected_id]
if not matches:
    raise SystemExit(
        f"FAIL - checklist is missing expected signal id {expected_id!r}"
    )
signal = matches[0]
if signal.get("type") != expected_type:
    raise SystemExit(
        f"FAIL - checklist signal {expected_id!r} has type "
        f"{signal.get('type')!r}, expected {expected_type!r}"
    )
value = signal.get(field)
if not value:
    raise SystemExit(
        f"FAIL - checklist signal {expected_id!r} has no usable {field}"
    )
if isinstance(value, list):
    print(value[0])
else:
    print(value)
PY
}

WORD_ID="ai_vocabulary"
WORD=$(read_signal_value "$WORD_ID" word_list words)
printf '%s %s\n' "$WORD" "$WORD" > "$SCRATCH/word-list.md"
"$SLIPBOX" humanize check "$SCRATCH/word-list.md" > "$SCRATCH/word-list-result.json"
assert_humanize_signal "word_list signal is detected from the checklist" "$SCRATCH/word-list-result.json" "$WORD_ID"

PHRASE_ID="filler_phrases"
PHRASE=$(read_signal_value "$PHRASE_ID" phrase_list phrases)
printf '%s.\n' "$PHRASE" > "$SCRATCH/phrase-list.md"
"$SLIPBOX" humanize check "$SCRATCH/phrase-list.md" > "$SCRATCH/phrase-list-result.json"
assert_humanize_signal "phrase_list signal is detected from the checklist" "$SCRATCH/phrase-list-result.json" "$PHRASE_ID"

ANNOUNCEMENT_ID="signposting_announcements"
ANNOUNCEMENT=$(read_signal_value "$ANNOUNCEMENT_ID" announcement_opener phrases)
printf '%s.\n' "$ANNOUNCEMENT" > "$SCRATCH/announcement-opener.md"
"$SLIPBOX" humanize check "$SCRATCH/announcement-opener.md" > "$SCRATCH/announcement-opener-result.json"
assert_humanize_signal "announcement_opener signal is detected from the checklist" "$SCRATCH/announcement-opener-result.json" "$ANNOUNCEMENT_ID"

REGEX_ID="em_dash"
REGEX_PATTERN=$(read_signal_value "$REGEX_ID" regex pattern)
if [ "$REGEX_PATTERN" != "—|–|--" ]; then
  echo "FAIL - checklist signal $REGEX_ID pattern changed: $REGEX_PATTERN"
  fail=1
else
  printf '%s\n' '— —' > "$SCRATCH/regex.md"
fi
"$SLIPBOX" humanize check "$SCRATCH/regex.md" > "$SCRATCH/regex-result.json"
assert_humanize_signal "regex signal is detected from the checklist pattern" "$SCRATCH/regex-result.json" "$REGEX_ID"

echo "--- error handling: corrupt JSON inputs ---"
printf '{"paths":{"literature":"Literature"' > "$SCRATCH/config.json"
check_exit "config get on an unparsable config.json exits 1" 1 "$SLIPBOX" config get paths.literature
check_match "unparsable config.json names the problem" '*not valid JSON*' \
  "$(stderr_of "$SLIPBOX" config get paths.literature)"
printf '{"paths":{"literature":"Literature"}}' > "$SCRATCH/config.json"
check_exit "config set on an unknown path exits 2" 2 "$SLIPBOX" config set paths.nope value
check_valid_json "a rejected config set left config.json intact" "$SCRATCH/config.json"

printf '{"detection":{"mechanical":{"signals":[{"id":"bad","type":"regex","pattern":"("}]}}}' > "$SCRATCH/humanize-checklist.json"
check_exit "an uncompilable checklist regex exits 1" 1 "$SLIPBOX" humanize check "$SCRATCH/two-title-case.md"
check_match "invalid checklist regex error names the signal" '*bad*' \
  "$(stderr_of "$SLIPBOX" humanize check "$SCRATCH/two-title-case.md")"

echo "--- error handling: unwritable target ---"
READONLY="$(mktemp -d)"
mkdir -p "$READONLY/bin" "$READONLY/evergreen"
cp "$REPO_ROOT/skills/setup-slipbox/scripts/slipbox" "$READONLY/bin/slipbox"
chmod +x "$READONLY/bin/slipbox"
chmod a-w "$READONLY" "$READONLY/evergreen"
check_exit "links add into an unwritable dir exits 1" 1 "$READONLY/bin/slipbox" links add --source a --target b --rel cites
check_exit "evergreen add into an unwritable dir exits 1" 1 "$READONLY/bin/slipbox" evergreen add --slug s --reason r
WRITE_ERR=$(stderr_of "$READONLY/bin/slipbox" evergreen add --slug s --reason r)
check_no_match "an unwritable dir produces no Python traceback" '*Traceback*' "$WRITE_ERR"
check_match "an unwritable dir reports a JSON write error" '*cannot write*' "$WRITE_ERR"
check_no_tmp_files "a failed write leaves no temp file behind" "$READONLY/evergreen"
chmod u+w "$READONLY" "$READONLY/evergreen"
rm -rf "$READONLY"

echo "--- source-map cache ---"
printf 'frozen resource bytes\n' > "$SCRATCH/resources.md"
RESOURCE_FP="sha256:$(shasum -a 256 "$SCRATCH/resources.md" | cut -d' ' -f1)"
python3 - "$SCRATCH/map.json" "$RESOURCE_FP" <<'PY'
import json, sys
data = {"schema_version":"1", "map_contract_version":"1", "producer_version":"1",
        "source":{"fingerprint":sys.argv[2],"known_paths":[]}, "contract":{}, "posture":{},
        "source_spine":[], "source_units":[], "relations":[], "core_idea_candidates":[],
        "integrity_flags":[], "concept_candidates":[], "referent_candidates":[],
        "created_at":"2026-08-30T00:00:00Z", "updated_at":"2026-08-30T00:00:00Z"}
json.dump(data, open(sys.argv[1], "w"))
PY
check "cache store validates and writes by Resource fingerprint" "$SLIPBOX" cache store --source resources.md --file "$SCRATCH/map.json"
check_eq "cache status reports one compatible entry" compatible "$($SLIPBOX cache status | json_at '[0]["state"]')"
check_exit "cache build is not a semantic command" 2 "$SLIPBOX" cache build
check_exit "cache remove requires explicit confirmation" 2 "$SLIPBOX" cache remove "$RESOURCE_FP" --no-input
check "cache remove accepts explicit confirmation" "$SLIPBOX" cache remove "$RESOURCE_FP" --yes
mkdir -p "$SCRATCH/resources"
printf 'uncached resource\n' > "$SCRATCH/resources/missing.md"
check_json "cache status reports missing resources" 'assert any(row["state"] == "missing" for row in data)' <<<"$($SLIPBOX cache status)"
printf '{"not":"a cache"}\n' > "$SCRATCH/cache/source-maps/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.json"
check_json "cache status classifies malformed entries as incompatible" 'assert any(row["state"] == "incompatible" and row["fingerprint"].endswith("a" * 64) for row in data)' <<<"$($SLIPBOX cache status)"
check_exit "cache store rejects absolute source paths" 2 "$SLIPBOX" cache store --source /etc/passwd --file "$SCRATCH/map.json"

echo "--- isolated Git finalization ---"
GIT_SCRATCH="$SCRATCH/git-repo"
mkdir -p "$GIT_SCRATCH/.slipbox/bin" "$GIT_SCRATCH/.slipbox/work" "$GIT_SCRATCH/.slipbox/evergreen"
cp "$REPO_ROOT/skills/setup-slipbox/scripts/slipbox" "$GIT_SCRATCH/.slipbox/bin/slipbox"
chmod +x "$GIT_SCRATCH/.slipbox/bin/slipbox"
printf '%s\n' '{"git":{"mode":"auto","commit_style":{"mode":"fallback"},"activity_trailers":true}}' > "$GIT_SCRATCH/.slipbox/config.json"
printf 'base\n' > "$GIT_SCRATCH/.slipbox/target.md"
printf 'unrelated\n' > "$GIT_SCRATCH/unrelated.md"
git -C "$GIT_SCRATCH" init -q
git -C "$GIT_SCRATCH" config user.email test@example.com
git -C "$GIT_SCRATCH" config user.name Test
git -C "$GIT_SCRATCH" add .
git -C "$GIT_SCRATCH" commit -qm baseline
printf 'unrelated staged\n' >> "$GIT_SCRATCH/unrelated.md"
git -C "$GIT_SCRATCH" add unrelated.md
INDEX_BEFORE=$(git -C "$GIT_SCRATCH" write-tree)
commit_result=$(cd "$GIT_SCRATCH/.slipbox" && bin/slipbox work create --kind literature --activity create --affected-path target.md)
git_id=$(printf '%s' "$commit_result" | json_at '["work_id"]')
printf 'updated\n' > "$GIT_SCRATCH/.slipbox/target.md"
python3 - "$GIT_SCRATCH/.slipbox/work/$git_id/manifest.json" <<'PY'
import json, sys
p=sys.argv[1]; m=json.load(open(p)); m.update(status="published", published_paths=["target.md"]); json.dump(m, open(p, "w"))
PY
check "work commit preserves unrelated index" bash -c "cd '$GIT_SCRATCH/.slipbox' && bin/slipbox work commit '$git_id' --yes"
check_eq "unrelated index remains staged" "$INDEX_BEFORE" "$(git -C "$GIT_SCRATCH" write-tree)"
check_json "commit records committed state" 'assert data["git_commit_status"] == "committed"' <<<"$(cd "$GIT_SCRATCH/.slipbox" && bin/slipbox work inspect "$git_id")"
check_match "commit includes work trailer" '*Slipbox-Work-ID:*' "$(git -C "$GIT_SCRATCH" show -1 --format=%B)"
printf '%s\n' '{"git":{"mode":"auto","commit_style":{"mode":"fallback"},"activity_trailers":true}}' > "$GIT_SCRATCH/.slipbox/config.json"
AUTO_ID=$(printf '%s' "$(cd "$GIT_SCRATCH/.slipbox" && bin/slipbox work create --kind literature --activity auto --affected-path auto.md)" | json_at '["work_id"]')
printf 'auto\n' > "$GIT_SCRATCH/.slipbox/auto.md"
python3 - "$GIT_SCRATCH/.slipbox/work/$AUTO_ID/manifest.json" <<'PY'
import json,sys
p=sys.argv[1];m=json.load(open(p));m.update(status="published",published_paths=["auto.md"]);json.dump(m,open(p,"w"))
PY
check_json "auto mode commits without confirmation" 'assert data["git_commit_status"] == "committed"' <<<"$(cd "$GIT_SCRATCH/.slipbox" && bin/slipbox work commit "$AUTO_ID")"

RACE_ID=$(printf '%s' "$(cd "$GIT_SCRATCH/.slipbox" && bin/slipbox work create --kind literature --activity race --affected-path race.md)" | json_at '["work_id"]')
printf 'race\n' > "$GIT_SCRATCH/.slipbox/race.md"
python3 - "$GIT_SCRATCH/.slipbox/work/$RACE_ID/manifest.json" <<'PY'
import json,sys
p=sys.argv[1];m=json.load(open(p));m.update(status="published",published_paths=["race.md"]);json.dump(m,open(p,"w"))
PY
check_exit "concurrent HEAD movement is a persisted commit failure" 1 env SLIPBOX_TEST_HEAD_MOVE=1 bash -c "cd '$GIT_SCRATCH/.slipbox' && bin/slipbox work commit '$RACE_ID'"
check_json "race failure remains retryable" 'assert data["status"] == "commit-failed" and "HEAD moved concurrently" in data["commit_error"]' <<<"$(cd "$GIT_SCRATCH/.slipbox" && bin/slipbox work inspect "$RACE_ID")"

NO_REPO_ID=$(printf '%s' "$($SLIPBOX work create --kind literature --activity no-repo --affected-path no-repo.md)" | json_at '["work_id"]')
printf 'no repo\n' > "$SCRATCH/no-repo.md"
python3 - "$SCRATCH/work/$NO_REPO_ID/manifest.json" <<'PY'
import json,sys
p=sys.argv[1];m=json.load(open(p));m.update(status="published",published_paths=["no-repo.md"]);json.dump(m,open(p,"w"))
PY
check_json "no repository is treated as Git off" 'assert data["git_commit_status"] == "off"' <<<"$($SLIPBOX work commit "$NO_REPO_ID" --yes)"

printf '%s\n' '{"git":{"mode":"ask","commit_style":{"mode":"fallback"},"activity_trailers":true}}' > "$GIT_SCRATCH/.slipbox/config.json"
ASK_ID=$(printf '%s' "$(cd "$GIT_SCRATCH/.slipbox" && bin/slipbox work create --kind literature --activity ask --affected-path ask.md)" | json_at '["work_id"]')
printf 'ask\n' > "$GIT_SCRATCH/.slipbox/ask.md"
python3 - "$GIT_SCRATCH/.slipbox/work/$ASK_ID/manifest.json" <<'PY'
import json,sys
p=sys.argv[1];m=json.load(open(p));m.update(status="published",published_paths=["ask.md"]);json.dump(m,open(p,"w"))
PY
check_json "ask mode requires confirmation" 'assert data["status"] == "confirmation-required"' <<<"$(cd "$GIT_SCRATCH/.slipbox" && bin/slipbox work commit "$ASK_ID")"

if [ "$fail" = "0" ]; then
  echo "ALL PASS"
else
  echo "SOME TESTS FAILED"
  exit 1
fi
