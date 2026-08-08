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

if [ "$fail" = "0" ]; then
  echo "ALL PASS"
else
  echo "SOME TESTS FAILED"
  exit 1
fi
