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

fail=0
check() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "ok   - $desc"
  else
    echo "FAIL - $desc"
    fail=1
  fi
}
check_exit() {
  local desc="$1" expected="$2"; shift 2
  set +e
  "$@" >"$SCRATCH/slipbox-test-out" 2>"$SCRATCH/slipbox-test-err"
  local actual=$?
  set -e
  if [ "$actual" = "$expected" ]; then
    echo "ok   - $desc (exit $actual)"
  else
    echo "FAIL - $desc (expected exit $expected, got $actual)"
    cat "$SCRATCH/slipbox-test-err"
    fail=1
  fi
}

assert_contains() {
  local desc="$1" needle="$2" file="$3"
  if grep -Fq "$needle" "$file"; then
    echo "ok   - $desc"
  else
    echo "FAIL - $desc (missing: $needle)"
    fail=1
  fi
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
  then
    echo "ok   - $desc"
  else
    echo "FAIL - $desc"
    fail=1
  fi
}

echo "--- no init/migrate/seeds commands exist ---"
check_exit "seeds is not a recognized command" 2 "$SLIPBOX" seeds find
check_exit "init is not a recognized command" 2 "$SLIPBOX" init
check_exit "migrate is not a recognized command" 2 "$SLIPBOX" migrate

echo "--- evergreen ---"
check "evergreen add" "$SLIPBOX" evergreen add --slug "draft-test-1" --reason "flagged tension"
[ -f "$SCRATCH/evergreen/draft-test-1.md" ] && echo "ok   - evergreen file exists on disk" || { echo "FAIL - evergreen file missing"; fail=1; }
check_exit "evergreen add rejects a duplicate slug" 1 "$SLIPBOX" evergreen add --slug "draft-test-1" --reason "dup"
check "evergreen find" "$SLIPBOX" evergreen find --status to-discuss
COUNT=$("$SLIPBOX" evergreen find --status to-discuss | python3 -c "import json,sys; print(len(json.load(sys.stdin)))")
[ "$COUNT" = "1" ] && echo "ok   - evergreen find returns exactly the inserted row" || { echo "FAIL - evergreen find returned $COUNT rows"; fail=1; }
check "evergreen update (status + iteration)" "$SLIPBOX" evergreen update "draft-test-1" --status discussing --iteration 2
STATUS_AFTER=$("$SLIPBOX" evergreen find | python3 -c "import json,sys; print(json.load(sys.stdin)[0]['status'])")
[ "$STATUS_AFTER" = "discussing" ] && echo "ok   - evergreen update persisted status" || { echo "FAIL - status not updated, got $STATUS_AFTER"; fail=1; }
check "evergreen update (slug rename)" "$SLIPBOX" evergreen update "draft-test-1" --slug "final-test-1"
[ -f "$SCRATCH/evergreen/final-test-1.md" ] && echo "ok   - renamed file exists" || { echo "FAIL - renamed file missing"; fail=1; }
[ ! -f "$SCRATCH/evergreen/draft-test-1.md" ] && echo "ok   - old-slug file removed on rename" || { echo "FAIL - old-slug file still present after rename"; fail=1; }
check_exit "evergreen update on unknown slug fails" 1 "$SLIPBOX" evergreen update "does-not-exist" --status discussed
check_exit "evergreen update with no flags is a usage error" 2 "$SLIPBOX" evergreen update "final-test-1"

echo "--- evergreen atomic write leaves no stray temp files ---"
TMP_COUNT=$(find "$SCRATCH/evergreen" -name '*.tmp' | wc -l | tr -d ' ')
[ "$TMP_COUNT" = "0" ] && echo "ok   - no leftover .tmp files after writes" || { echo "FAIL - $TMP_COUNT stray temp file(s) found"; fail=1; }

echo "--- links ---"
check "links add" "$SLIPBOX" links add --source "final-test-1" --target "some-term" --rel cites
check_exit "links add rejects invalid --rel" 2 "$SLIPBOX" links add --source a --target b --rel bogus
check "links find with no filters returns everything" "$SLIPBOX" links find
LINK_COUNT=$("$SLIPBOX" links find | python3 -c "import json,sys; print(len(json.load(sys.stdin)))")
[ "$LINK_COUNT" = "1" ] && echo "ok   - links find returns the inserted edge" || { echo "FAIL - links find returned $LINK_COUNT rows"; fail=1; }
check "links find filters by --source" "$SLIPBOX" links add --source "other-slug" --target "some-term" --rel extends
FILTERED_COUNT=$("$SLIPBOX" links find --source final-test-1 | python3 -c "import json,sys; print(len(json.load(sys.stdin)))")
[ "$FILTERED_COUNT" = "1" ] && echo "ok   - links find --source filters correctly" || { echo "FAIL - expected 1 row, got $FILTERED_COUNT"; fail=1; }

echo "--- usage errors ---"
check_exit "unknown command exits 2" 2 "$SLIPBOX" bogus
check_exit "evergreen add missing --reason exits 2" 2 "$SLIPBOX" evergreen add --slug x

echo "--- config (unchanged from idea-db) ---"
printf '{"paths":{"literature":"literature"}}' > "$SCRATCH/config.json"
check "config get" "$SLIPBOX" config get paths.literature
check "config set" "$SLIPBOX" config set paths.literature "Literature"
NEW_VAL=$("$SLIPBOX" config get paths.literature | python3 -c "import json,sys; print(json.load(sys.stdin))")
[ "$NEW_VAL" = "Literature" ] && echo "ok   - config set persisted" || { echo "FAIL - config set did not persist, got $NEW_VAL"; fail=1; }

echo "--- error handling: usage errors are never swallowed ---"
check_exit "a flag given without a value exits 2" 2 "$SLIPBOX" evergreen update "final-test-1" --status
check_exit "an unknown flag exits 2 instead of being ignored" 2 "$SLIPBOX" evergreen find --stat to-discuss
check_exit "a stray positional exits 2" 2 "$SLIPBOX" evergreen find to-discuss
check_exit "a non-numeric --iteration exits 2" 2 "$SLIPBOX" evergreen update "final-test-1" --iteration abc
check_exit "an unknown --format exits 2" 2 "$SLIPBOX" evergreen find --format yaml
"$SLIPBOX" evergreen update 'we"ird\slug' --status discussed 2>"$SCRATCH/err.json" >/dev/null || true
if python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$SCRATCH/err.json" 2>/dev/null; then
  echo "ok   - a quote in an error message still leaves stderr valid JSON"
else
  echo "FAIL - stderr was not valid JSON: $(cat "$SCRATCH/err.json")"
  fail=1
fi

echo "--- error handling: bad on-disk state fails loudly, no tracebacks ---"
printf 'not frontmatter at all\n' > "$SCRATCH/evergreen/broken.md"
check_exit "evergreen update on an unparsable file exits 1" 1 "$SLIPBOX" evergreen update "broken" --status discussed
UPDATE_ERR=$("$SLIPBOX" evergreen update "broken" --status discussed 2>&1 >/dev/null || true)
case "$UPDATE_ERR" in
  *Traceback*) echo "FAIL - unparsable frontmatter produced a Python traceback"; fail=1 ;;
  *) echo "ok   - unparsable frontmatter reports a JSON error, not a traceback" ;;
esac
FIND_WARN=$("$SLIPBOX" evergreen find 2>&1 >/dev/null || true)
case "$FIND_WARN" in
  *warning*broken.md*) echo "ok   - evergreen find warns about the file it skipped" ;;
  *) echo "FAIL - evergreen find skipped an unparsable file without a warning"; fail=1 ;;
esac
check "evergreen find still returns the parsable rows" "$SLIPBOX" evergreen find
rm "$SCRATCH/evergreen/broken.md"

printf 'not json\n' >> "$SCRATCH/links.jsonl"
check_exit "links find on a corrupt log exits 1" 1 "$SLIPBOX" links find
LINKS_ERR=$("$SLIPBOX" links find 2>&1 >/dev/null || true)
case "$LINKS_ERR" in
  *"line 3"*) echo "ok   - corrupt links log error names the offending line" ;;
  *) echo "FAIL - corrupt links log error did not name the line: $LINKS_ERR"; fail=1 ;;
esac
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
if [ "$("$SLIPBOX" humanize check "$SCRATCH/two-title-case.md" | python3 -c 'import json,sys; print(json.load(sys.stdin)["flagged"])')" = "True" ]; then
  echo "ok   - two title-case headings pass the cluster threshold"
else
  echo "FAIL - two title-case headings did not flag"
  fail=1
fi

echo "--- dispatch and flag usage ---"
check_exit "--help exits 0" 0 "$SLIPBOX" --help
assert_contains "--help prints the usage block" "Usage:" "$SCRATCH/slipbox-test-out"
check_exit "-h exits 0" 0 "$SLIPBOX" -h
assert_contains "-h prints the usage block" "slipbox — CLI" "$SCRATCH/slipbox-test-out"
check_exit "--version exits 0" 0 "$SLIPBOX" --version
assert_contains "--version prints the CLI version" "slipbox 2.1.0" "$SCRATCH/slipbox-test-out"
check_exit "-v exits 0" 0 "$SLIPBOX" -v
assert_contains "-v prints the CLI version" "slipbox 2.1.0" "$SCRATCH/slipbox-test-out"
check_exit "no arguments prints help and exits 2" 2 "$SLIPBOX"
assert_contains "no arguments prints the usage block" "Usage:" "$SCRATCH/slipbox-test-out"
for group in evergreen links config humanize; do
  check_exit "$group with no action exits 2" 2 "$SLIPBOX" "$group"
  check_exit "$group with a bogus action exits 2" 2 "$SLIPBOX" "$group" bogus
done
check_exit "a final flag without a value exits 2" 2 "$SLIPBOX" evergreen find --status

echo "--- evergreen edge cases ---"
check_exit "evergreen add missing --slug exits 2" 2 "$SLIPBOX" evergreen add --reason reason
mv "$SCRATCH/evergreen" "$SCRATCH/evergreen.saved"
check_exit "evergreen add without its data directory exits 1" 1 "$SLIPBOX" evergreen add --slug no-dir --reason reason
check_exit "evergreen find without its data directory exits 1" 1 "$SLIPBOX" evergreen find
check_exit "evergreen update without its data directory exits 1" 1 "$SLIPBOX" evergreen update no-dir --status discussing
mv "$SCRATCH/evergreen.saved" "$SCRATCH/evergreen"

check_exit "evergreen find with no matching status returns 0" 0 "$SLIPBOX" evergreen find --status no-such-status
if python3 - "$SCRATCH/slipbox-test-out" <<'PY'
import json
import sys
with open(sys.argv[1]) as handle:
    assert json.load(handle) == []
PY
then
  echo "ok   - unmatched evergreen status returns an empty JSON array"
else
  echo "FAIL - unmatched evergreen status did not return an empty JSON array"
  fail=1
fi
TABLE=$("$SLIPBOX" evergreen find --format table)
if printf '%s\n' "$TABLE" | grep -Fq $'slug\t'; then
  echo "ok   - evergreen table output has a tab-separated header"
else
  echo "FAIL - evergreen table output has no tab-separated header"
  fail=1
fi
if [ "$(printf '%s\n' "$TABLE" | tail -n +2 | grep -c .)" -eq 1 ]; then
  echo "ok   - evergreen table output has one line per row"
else
  echo "FAIL - evergreen table output did not include one line per row"
  fail=1
fi
if [ "$("$SLIPBOX" evergreen find --status no-such-status --format table)" = "(no rows)" ]; then
  echo "ok   - evergreen table output marks an empty result"
else
  echo "FAIL - evergreen table output did not mark an empty result"
  fail=1
fi
printf 'this file has no frontmatter\n' > "$SCRATCH/evergreen/no-frontmatter.md"
if "$SLIPBOX" evergreen find 2>"$SCRATCH/no-frontmatter.err" |
  python3 -c 'import json,sys; assert len(json.load(sys.stdin)) >= 1'; then
  echo "ok   - evergreen find skips a file with no frontmatter"
else
  echo "FAIL - evergreen find rejected a file with no frontmatter"
  fail=1
fi
if grep -Fq "warning" "$SCRATCH/no-frontmatter.err" &&
  grep -Fq "no-frontmatter.md" "$SCRATCH/no-frontmatter.err"; then
  echo "ok   - evergreen find warns when it skips an unparsable file"
else
  echo "FAIL - evergreen find did not warn about the skipped file"
  fail=1
fi
rm "$SCRATCH/evergreen/no-frontmatter.md"
cat > "$SCRATCH/evergreen/typed-values.md" <<'EOF'
---
status: plain-status
plain_string: plain
integer_value: 42
empty_value:
created_at: "2099-01-03T00:00:00Z"
---
EOF
if "$SLIPBOX" evergreen find | python3 -c '
import json, sys
row = next(row for row in json.load(sys.stdin) if row["slug"] == "typed-values")
assert row["plain_string"] == "plain" and isinstance(row["plain_string"], str)
assert row["integer_value"] == 42 and isinstance(row["integer_value"], int)
assert row["empty_value"] is None
'; then
  echo "ok   - evergreen frontmatter parses plain strings, integers, and empty values"
else
  echo "FAIL - evergreen frontmatter value types were not preserved"
  fail=1
fi
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
if "$SLIPBOX" evergreen find | python3 -c '
import json, sys
rows = json.load(sys.stdin)
positions = {row["slug"]: index for index, row in enumerate(rows)}
assert positions["newer"] < positions["older"]
'; then
  echo "ok   - evergreen rows sort by created_at descending"
else
  echo "FAIL - evergreen rows are not sorted by created_at descending"
  fail=1
fi
check "evergreen update persists --note-path" "$SLIPBOX" evergreen update final-test-1 --note-path notes/final.md
if grep -Fq 'note_path: "notes/final.md"' "$SCRATCH/evergreen/final-test-1.md"; then
  echo "ok   - evergreen update persisted note_path"
else
  echo "FAIL - evergreen update did not persist note_path"
  fail=1
fi
check "add collision candidate" "$SLIPBOX" evergreen add --slug collision-target --reason collision
cp "$SCRATCH/evergreen/final-test-1.md" "$SCRATCH/final-before-collision.md"
cp "$SCRATCH/evergreen/collision-target.md" "$SCRATCH/collision-before-collision.md"
check_exit "evergreen update rejects a colliding rename" 1 "$SLIPBOX" evergreen update final-test-1 --slug collision-target
if cmp -s "$SCRATCH/evergreen/final-test-1.md" "$SCRATCH/final-before-collision.md" &&
  cmp -s "$SCRATCH/evergreen/collision-target.md" "$SCRATCH/collision-before-collision.md"; then
  echo "ok   - colliding rename leaves both original files untouched"
else
  echo "FAIL - colliding rename changed an original file"
  fail=1
fi

echo "--- links edge cases ---"
if "$SLIPBOX" links find --target some-term | python3 -c 'import json,sys; assert len(json.load(sys.stdin)) == 2'; then
  echo "ok   - links find filters by --target"
else
  echo "FAIL - links find --target did not return both matching rows"
  fail=1
fi
if "$SLIPBOX" links find --rel extends | python3 -c 'import json,sys; rows=json.load(sys.stdin); assert len(rows) == 1 and rows[0]["source_id"] == "other-slug"'; then
  echo "ok   - links find filters by --rel"
else
  echo "FAIL - links find --rel did not return the matching edge"
  fail=1
fi
if "$SLIPBOX" links find --source final-test-1 --rel cites | python3 -c 'import json,sys; assert len(json.load(sys.stdin)) == 1'; then
  echo "ok   - links find combines source and relation filters"
else
  echo "FAIL - links find source+rel filtering failed"
  fail=1
fi
printf '\n' >> "$SCRATCH/links.jsonl"
if "$SLIPBOX" links find | python3 -c 'import json,sys; assert len(json.load(sys.stdin)) == 2'; then
  echo "ok   - links find skips a blank JSONL line"
else
  echo "FAIL - links find did not skip a blank JSONL line"
  fail=1
fi
LINK_TABLE=$("$SLIPBOX" links find --format table)
if printf '%s\n' "$LINK_TABLE" | grep -Fq $'source_id\ttarget_id'; then
  echo "ok   - links table output has a tab-separated header"
else
  echo "FAIL - links table output has no tab-separated header"
  fail=1
fi
if [ "$(printf '%s\n' "$LINK_TABLE" | tail -n +2 | grep -c .)" -eq 2 ]; then
  echo "ok   - links table output has one line per row"
else
  echo "FAIL - links table output did not include one line per row"
  fail=1
fi
if [ "$("$SLIPBOX" links find --target no-such-target --format table)" = "(no rows)" ]; then
  echo "ok   - links table output marks an empty result"
else
  echo "FAIL - links table output did not mark an empty result"
  fail=1
fi
mv "$SCRATCH/links.jsonl" "$SCRATCH/links.saved"
if "$SLIPBOX" links find | python3 -c 'import json,sys; assert json.load(sys.stdin) == []'; then
  echo "ok   - links find without links.jsonl returns an empty array"
else
  echo "FAIL - links find without links.jsonl failed"
  fail=1
fi
mv "$SCRATCH/links.saved" "$SCRATCH/links.jsonl"

echo "--- config edge cases ---"
printf '{"paths":{"literature":"literature"},"settings":{"number":0,"enabled":false}}' > "$SCRATCH/config.json"
if "$SLIPBOX" config get | python3 -c 'import json,sys; data=json.load(sys.stdin); assert data["paths"]["literature"] == "literature"'; then
  echo "ok   - config get without a path prints the whole document"
else
  echo "FAIL - config get without a path did not print the whole document"
  fail=1
fi
check_exit "config get unknown path exits 2" 2 "$SLIPBOX" config get paths.unknown
check_exit "config get through a non-dict exits 2" 2 "$SLIPBOX" config get paths.literature.missing
check_exit "config set unknown intermediate path exits 2" 2 "$SLIPBOX" config set missing.leaf value
check_exit "config set unknown leaf exits 2" 2 "$SLIPBOX" config set paths.unknown value
check "config set stores a JSON number" "$SLIPBOX" config set settings.number 42
check "config set stores a JSON boolean" "$SLIPBOX" config set settings.enabled true
check "config set stores a bare word as a string" "$SLIPBOX" config set paths.literature Literature
if python3 - "$SCRATCH/config.json" <<'PY'
import json
import sys
with open(sys.argv[1]) as handle:
    data = json.load(handle)
assert data["settings"]["number"] == 42 and isinstance(data["settings"]["number"], int)
assert data["settings"]["enabled"] is True
assert data["paths"]["literature"] == "Literature" and isinstance(data["paths"]["literature"], str)
PY
then
  echo "ok   - config set preserves JSON types and bare words as strings"
else
  echo "FAIL - config set stored an unexpected type"
  fail=1
fi

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
CONFIG_ERR=$("$SLIPBOX" config get paths.literature 2>&1 >/dev/null || true)
case "$CONFIG_ERR" in
  *"not valid JSON"*) echo "ok   - unparsable config.json names the problem" ;;
  *) echo "FAIL - unparsable config.json error was unclear: $CONFIG_ERR"; fail=1 ;;
esac
printf '{"paths":{"literature":"Literature"}}' > "$SCRATCH/config.json"
check_exit "config set on an unknown path exits 2" 2 "$SLIPBOX" config set paths.nope value
if python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$SCRATCH/config.json" 2>/dev/null; then
  echo "ok   - a rejected config set left config.json intact"
else
  echo "FAIL - config.json was damaged by a rejected set"
  fail=1
fi

printf '{"detection":{"mechanical":{"signals":[{"id":"bad","type":"regex","pattern":"("}]}}}' > "$SCRATCH/humanize-checklist.json"
check_exit "an uncompilable checklist regex exits 1" 1 "$SLIPBOX" humanize check "$SCRATCH/two-title-case.md"
CHECKLIST_ERR=$("$SLIPBOX" humanize check "$SCRATCH/two-title-case.md" 2>&1 >/dev/null || true)
case "$CHECKLIST_ERR" in
  *bad*) echo "ok   - invalid checklist regex error names the signal" ;;
  *) echo "FAIL - invalid checklist regex error did not name the signal: $CHECKLIST_ERR"; fail=1 ;;
esac

echo "--- error handling: unwritable target ---"
READONLY="$(mktemp -d)"
mkdir -p "$READONLY/bin" "$READONLY/evergreen"
cp "$REPO_ROOT/skills/setup-slipbox/scripts/slipbox" "$READONLY/bin/slipbox"
chmod +x "$READONLY/bin/slipbox"
chmod a-w "$READONLY" "$READONLY/evergreen"
check_exit "links add into an unwritable dir exits 1" 1 "$READONLY/bin/slipbox" links add --source a --target b --rel cites
check_exit "evergreen add into an unwritable dir exits 1" 1 "$READONLY/bin/slipbox" evergreen add --slug s --reason r
WRITE_ERR=$("$READONLY/bin/slipbox" evergreen add --slug s --reason r 2>&1 >/dev/null || true)
case "$WRITE_ERR" in
  *Traceback*) echo "FAIL - an unwritable dir produced a Python traceback"; fail=1 ;;
  *"cannot write"*) echo "ok   - an unwritable dir reports a JSON write error" ;;
  *) echo "FAIL - unclear unwritable-dir error: $WRITE_ERR"; fail=1 ;;
esac
STRAY=$(find "$READONLY/evergreen" -name '*.tmp' | wc -l | tr -d ' ')
if [ "$STRAY" = "0" ]; then
  echo "ok   - a failed write leaves no temp file behind"
else
  echo "FAIL - $STRAY stray temp file(s) after a failed write"
  fail=1
fi
chmod u+w "$READONLY" "$READONLY/evergreen"
rm -rf "$READONLY"

if [ "$fail" = "0" ]; then
  echo "ALL PASS"
else
  echo "SOME TESTS FAILED"
  exit 1
fi
