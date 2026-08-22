#!/usr/bin/env bash
# Mechanical smoke test for skills/setup-slipbox/scripts/install-prereqs.sh.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/../.." && pwd)"
SCRIPT="$REPO_ROOT/skills/setup-slipbox/scripts/install-prereqs.sh"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

BIN="$SCRATCH/bin"
EMPTY_BIN="$SCRATCH/empty-bin"
LOG="$SCRATCH/argv.log"
PYTHON_USABLE="$SCRATCH/python-usable"
mkdir -p "$BIN" "$EMPTY_BIN"

cat > "$BIN/python3" <<EOF
#!/usr/bin/env bash
printf 'python3' >> "$LOG"
printf ' <%s>' "\$@" >> "$LOG"
printf '\\n' >> "$LOG"
if [ "\${1:-}" = "-m" ] && [ "\${2:-}" = "pip" ]; then
  case "\${3:-}" in
    --version)
      exit 0
      ;;
    install)
      if [ "\${PYTHON_MODE:-success}" = "failed" ]; then
        exit 1
      fi
      if [ "\${PYTHON_MODE:-success}" = "success" ]; then
        : > "$PYTHON_USABLE"
      fi
      exit 0
      ;;
  esac
fi
if [ "\${1:-}" = "-c" ]; then
  [ -f "$PYTHON_USABLE" ] && exit 0
  exit 1
fi
exit 1
EOF
cat > "$BIN/npm" <<EOF
#!/usr/bin/env bash
printf 'npm' >> "$LOG"
printf ' <%s>' "\$@" >> "$LOG"
printf '\\n' >> "$LOG"
if [ "\${1:-}" = "install" ]; then
  if [ "\${NPM_MODE:-success}" = "failed" ]; then
    exit 1
  fi
  if [ "\${NPM_MODE:-success}" = "success" ]; then
    case "\${3:-}" in
      defuddle)
        printf '#!/usr/bin/env bash\\n' > "$BIN/defuddle"
        printf 'exit 0\\n' >> "$BIN/defuddle"
        chmod +x "$BIN/defuddle"
        ;;
      firecrawl-cli)
        printf '#!/usr/bin/env bash\\n' > "$BIN/firecrawl"
        printf 'exit 0\\n' >> "$BIN/firecrawl"
        chmod +x "$BIN/firecrawl"
        ;;
    esac
  fi
  exit 0
fi
exit 1
EOF
chmod +x "$BIN/python3" "$BIN/npm"

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
assert_log() {
  local desc="$1" text="$2"
  if grep -Fq "$text" "$LOG"; then
    echo "ok   - $desc"
  else
    echo "FAIL - $desc (missing: $text)"
    cat "$LOG"
    fail=1
  fi
}
assert_error() {
  local desc="$1" text="$2"
  if grep -Fq "$text" "$SCRATCH/err"; then
    echo "ok   - $desc"
  else
    echo "FAIL - $desc (missing: $text)"
    cat "$SCRATCH/err"
    fail=1
  fi
}

echo "--- documented dispatch ---"
: > "$LOG"
rm -f "$PYTHON_USABLE" "$BIN/defuddle" "$BIN/firecrawl"
check "youtube-transcript-api dispatches through python3 pip" \
  env PATH="$BIN:$PATH" PYTHON_MODE=success "$SCRIPT" youtube-transcript-api
check "defuddle dispatches to npm" \
  env PATH="$BIN:$PATH" NPM_MODE=success "$SCRIPT" defuddle
check "firecrawl dispatches to npm" \
  env PATH="$BIN:$PATH" NPM_MODE=success "$SCRIPT" firecrawl
assert_log "pip version check uses python3 -m pip" "python3 <-m> <pip> <--version>"
assert_log "pip install uses python3 -m pip" \
  "python3 <-m> <pip> <install> <youtube-transcript-api>"
assert_log "defuddle uses npm install -g" "npm <install> <-g> <defuddle>"
assert_log "firecrawl uses npm install -g" "npm <install> <-g> <firecrawl-cli>"

echo "--- installer failures ---"
rm -f "$PYTHON_USABLE"
check_exit "missing python3 exits 1" 1 \
  env PATH="$EMPTY_BIN" /bin/bash "$SCRIPT" youtube-transcript-api
assert_error "missing python3 names the dependency" "youtube-transcript-api"
check_exit "failed pip install exits 1" 1 \
  env PATH="$BIN:$PATH" PYTHON_MODE=failed "$SCRIPT" youtube-transcript-api
assert_error "failed pip install names the dependency" \
  "pip install youtube-transcript-api failed"
rm -f "$BIN/defuddle"
check_exit "successful npm install with unusable defuddle exits 1" 1 \
  env PATH="$BIN:$PATH" NPM_MODE=unusable "$SCRIPT" defuddle
assert_error "unusable defuddle names the dependency" "defuddle isn't on PATH"
check_exit "missing npm exits 1" 1 \
  env PATH="$EMPTY_BIN" /bin/bash "$SCRIPT" defuddle
assert_error "missing npm names the dependency" "defuddle"
rm -f "$BIN/firecrawl"
check_exit "failed npm install exits 1" 1 \
  env PATH="$BIN:$PATH" NPM_MODE=failed "$SCRIPT" firecrawl
assert_error "failed npm install names the dependency" \
  "npm install -g firecrawl-cli failed"

echo "--- usage errors ---"
: > "$LOG"
check_exit "no dependency exits 1" 1 env PATH="$BIN:$PATH" "$SCRIPT"
assert_error "no dependency prints the usage message" "Usage:"
check_exit "unknown dependency exits 1" 1 env PATH="$BIN:$PATH" "$SCRIPT" unknown
assert_error "unknown dependency prints the usage message" "Usage:"
assert_error "unknown dependency is named" "unknown dependency: unknown"
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
