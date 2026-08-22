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
pass() { echo "ok   - $1"; }
failed() { echo "FAIL - $1"; fail=1; }

check() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then
    pass "$desc"
  else
    failed "$desc"
  fi
}
# check_eq <desc> <expected> <actual>
check_eq() {
  if [ "$3" = "$2" ]; then
    pass "$1"
  else
    failed "$1 (expected $2, got $3)"
  fi
}
# check_file <desc> <path> — and check_no_file, its negation
check_file() { [ -f "$2" ] && pass "$1" || failed "$1 ($2 missing)"; }
check_no_file() { [ ! -f "$2" ] && pass "$1" || failed "$1 ($2 still present)"; }
# json_len / json_at <python-suffix> — read one JSON doc off stdin
json_len() { python3 -c "import json,sys; print(len(json.load(sys.stdin)))"; }
json_at() { python3 -c "import json,sys; print(json.load(sys.stdin)$1)"; }
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

echo "--- evergreen atomic write leaves no stray temp files ---"
check_eq "no leftover .tmp files after writes" 0 "$(find "$SCRATCH/evergreen" -name '*.tmp' | wc -l | tr -d ' ')"

echo "--- links ---"
check "links add" "$SLIPBOX" links add --source "final-test-1" --target "some-term" --rel cites
check_exit "links add rejects invalid --rel" 2 "$SLIPBOX" links add --source a --target b --rel bogus
check "links find with no filters returns everything" "$SLIPBOX" links find
check_eq "links find returns the inserted edge" 1 "$("$SLIPBOX" links find | json_len)"
check "links find filters by --source" "$SLIPBOX" links add --source "other-slug" --target "some-term" --rel extends
check_eq "links find --source filters correctly" 1 "$("$SLIPBOX" links find --source final-test-1 | json_len)"

echo "--- usage errors ---"
check_exit "unknown command exits 2" 2 "$SLIPBOX" bogus
check_exit "evergreen add missing --reason exits 2" 2 "$SLIPBOX" evergreen add --slug x

echo "--- config (unchanged from idea-db) ---"
printf '{"paths":{"literature":"literature"}}' > "$SCRATCH/config.json"
check "config get" "$SLIPBOX" config get paths.literature
check "config set" "$SLIPBOX" config set paths.literature "Literature"
check_eq "config set persisted" Literature "$("$SLIPBOX" config get paths.literature | json_at "")"

echo "--- humanize (unchanged from idea-db) ---"
cp "$REPO_ROOT/skills/setup-slipbox/assets/humanize-checklist.json" "$SCRATCH/humanize-checklist.json"
cat > "$SCRATCH/style-profile.json" <<'EOF'
{"language":{"primary":"English","secondary":"Indonesian","technical_terms":"English","code_switching":"natural"}}
EOF
printf '# Strategic Negotiations And Partnerships\n# Another Important Heading\n' > "$SCRATCH/two-title-case.md"
check_eq "two title-case headings pass the cluster threshold" True "$("$SLIPBOX" humanize check "$SCRATCH/two-title-case.md" | json_at "['flagged']")"

if [ "$fail" = "0" ]; then
  echo "ALL PASS"
else
  echo "SOME TESTS FAILED"
  exit 1
fi
