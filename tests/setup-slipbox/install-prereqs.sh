#!/usr/bin/env bash
# Mechanical smoke test for skills/setup-slipbox/scripts/install-prereqs.sh.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/../.." && pwd)"
SCRIPT="$REPO_ROOT/skills/setup-slipbox/scripts/install-prereqs.sh"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

BIN="$SCRATCH/bin"
LOG="$SCRATCH/argv.log"
mkdir -p "$BIN"
cat > "$BIN/pip" <<EOF
#!/usr/bin/env bash
printf 'pip' >> "$LOG"
printf ' <%s>' "\$@" >> "$LOG"
printf '\\n' >> "$LOG"
EOF
cat > "$BIN/npm" <<EOF
#!/usr/bin/env bash
printf 'npm' >> "$LOG"
printf ' <%s>' "\$@" >> "$LOG"
printf '\\n' >> "$LOG"
EOF
chmod +x "$BIN/pip" "$BIN/npm"

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
  "$@" >"$SCRATCH/out" 2>"$SCRATCH/err"
  local actual=$?
  set -e
  if [ "$actual" = "$expected" ]; then
    echo "ok   - $desc (exit $actual)"
  else
    echo "FAIL - $desc (expected exit $expected, got $actual)"
    cat "$SCRATCH/out" "$SCRATCH/err"
    fail=1
  fi
}

echo "--- documented dispatch ---"
: > "$LOG"
check "youtube-transcript-api dispatches to pip" env PATH="$BIN:$PATH" "$SCRIPT" youtube-transcript-api
check "defuddle dispatches to npm" env PATH="$BIN:$PATH" "$SCRIPT" defuddle
check "firecrawl dispatches to npm" env PATH="$BIN:$PATH" "$SCRIPT" firecrawl
if [ "$(cat "$LOG")" = $'pip <install> <youtube-transcript-api>\nnpm <install> <-g> <defuddle>\nnpm <install> <-g> <firecrawl-cli>' ]; then
  echo "ok   - each dependency uses exactly its documented install command"
else
  echo "FAIL - dependency install argv differed from the documented commands"
  cat "$LOG"
  fail=1
fi

echo "--- usage errors ---"
: > "$LOG"
check_exit "no dependency exits 1" 1 env PATH="$BIN:$PATH" "$SCRIPT"
if grep -Fq "Usage:" "$SCRATCH/err"; then
  echo "ok   - no dependency prints the usage message"
else
  echo "FAIL - no dependency did not print the usage message"
  fail=1
fi
check_exit "unknown dependency exits 1" 1 env PATH="$BIN:$PATH" "$SCRIPT" unknown
if grep -Fq "Usage:" "$SCRATCH/err"; then
  echo "ok   - unknown dependency prints the usage message"
else
  echo "FAIL - unknown dependency did not print the usage message"
  fail=1
fi
if [ ! -s "$LOG" ]; then
  echo "ok   - usage errors do not invoke package managers"
else
  echo "FAIL - usage errors invoked a package manager"
  cat "$LOG"
  fail=1
fi

if [ "$fail" = "0" ]; then
  echo "ALL PASS"
else
  echo "SOME TESTS FAILED"
  exit 1
fi
