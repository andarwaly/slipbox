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
check_no_tmp_files "no leftover .tmp files after writes" "$SCRATCH/evergreen"

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
check_match "corrupt links log error names the offending line" '*line 3*' \
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

if [ "$fail" = "0" ]; then
  echo "ALL PASS"
else
  echo "SOME TESTS FAILED"
  exit 1
fi
