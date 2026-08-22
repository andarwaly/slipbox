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
  "$@" >/tmp/slipbox-test-out 2>/tmp/slipbox-test-err
  local actual=$?
  set -e
  if [ "$actual" = "$expected" ]; then
    echo "ok   - $desc (exit $actual)"
  else
    echo "FAIL - $desc (expected exit $expected, got $actual)"
    cat /tmp/slipbox-test-err
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

echo "--- slug validation confines writes to evergreen/ ---"
check_exit "evergreen add rejects a traversal slug" 2 "$SLIPBOX" evergreen add --slug "./../pwned" --reason "traversal"
check_exit "evergreen add rejects an absolute-path slug" 2 "$SLIPBOX" evergreen add --slug "/tmp/pwned" --reason "traversal"
check_exit "evergreen add rejects a dot-segment slug" 2 "$SLIPBOX" evergreen add --slug ".." --reason "traversal"
check_exit "evergreen update rejects a traversal --slug" 2 "$SLIPBOX" evergreen update "final-test-1" --slug "./../pwned"
[ ! -e "$SCRATCH/pwned.md" ] && [ ! -e "$SCRATCH/../pwned.md" ] && echo "ok   - no file written outside evergreen/" || { echo "FAIL - traversal wrote outside evergreen/"; fail=1; }

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
