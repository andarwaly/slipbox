#!/usr/bin/env bash
# Mechanical smoke test for skills/setup-slipbox/scripts/idea-db.
# Not an evals.json case — idea-db is a deterministic CLI, not model behavior,
# so this is a plain pass/fail script, run against a scratch .slipbox/ dir.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/../.." && pwd)"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

mkdir -p "$SCRATCH/bin"
cp "$REPO_ROOT/skills/setup-slipbox/scripts/idea-db" "$SCRATCH/bin/idea-db"
chmod +x "$SCRATCH/bin/idea-db"
IDEA_DB="$SCRATCH/bin/idea-db"

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
  "$@" >/tmp/idea-db-test-out 2>/tmp/idea-db-test-err
  local actual=$?
  set -e
  if [ "$actual" = "$expected" ]; then
    echo "ok   - $desc (exit $actual)"
  else
    echo "FAIL - $desc (expected exit $expected, got $actual)"
    cat /tmp/idea-db-test-err
    fail=1
  fi
}

echo "--- init ---"
check "init creates idea.db" "$IDEA_DB" init
[ -f "$SCRATCH/idea.db" ] && echo "ok   - idea.db file exists" || { echo "FAIL - idea.db missing"; fail=1; }
check "second init is a no-op success" "$IDEA_DB" init

echo "--- init output is pure JSON (regression: PRAGMA result rows leaking to stdout) ---"
rm -f "$SCRATCH/idea.db"
if "$IDEA_DB" init | python3 -c "import json,sys; json.load(sys.stdin)" >/dev/null 2>&1; then
  echo "ok   - init stdout is valid JSON, no leaked PRAGMA output"
else
  echo "FAIL - init stdout is not pure JSON"
  fail=1
fi

echo "--- seeds ---"
check "seeds add" "$IDEA_DB" seeds add --resource "https://example.com" --type raw --target-type term --reason "test tension"
SLUG=$("$IDEA_DB" seeds find --target-type term --status to-discuss | python3 -c "import json,sys; print(json.load(sys.stdin)[0]['slug'])")
[ -n "$SLUG" ] && echo "ok   - seeds find returns the inserted row" || { echo "FAIL - seeds find empty"; fail=1; }
check "seeds update" "$IDEA_DB" seeds update "$SLUG" --status discussed --note-path "term/example.md"
check_exit "seeds add rejects invalid --type" 2 "$IDEA_DB" seeds add --resource x --type bogus --target-type term --reason y

echo "--- evergreen ---"
check "evergreen add" "$IDEA_DB" evergreen add --slug "draft-test-1" --reason "flagged tension"
check "evergreen find" "$IDEA_DB" evergreen find --status to-discuss
check "evergreen update" "$IDEA_DB" evergreen update "draft-test-1" --status discussing --iteration 2

echo "--- links ---"
check "links add" "$IDEA_DB" links add --source "draft-test-1" --target "$SLUG" --rel cites
check_exit "links add rejects invalid --rel" 2 "$IDEA_DB" links add --source a --target b --rel bogus

echo "--- migrate ---"
check "migrate is a no-op at current version" "$IDEA_DB" migrate

echo "--- usage errors ---"
check_exit "unknown command exits 2" 2 "$IDEA_DB" bogus
check_exit "seeds add missing flags exits 2" 2 "$IDEA_DB" seeds add --resource x

if [ "$fail" = "0" ]; then
  echo "ALL PASS"
else
  echo "SOME TESTS FAILED"
  exit 1
fi
