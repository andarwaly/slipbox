#!/usr/bin/env bash
# Mechanical smoke test for skills/setup-slipbox/scripts/install-prereqs.sh.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/../.." && pwd)"
SCRIPT="$REPO_ROOT/skills/setup-slipbox/scripts/install-prereqs.sh"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

BIN="$SCRATCH/bin"
DECOY="$SCRATCH/decoy"
LOG="$SCRATCH/argv.log"
PY_USABLE="$SCRATCH/python-usable"
SYSTEM_PATH="$PATH"
REAL_BASH="$(command -v bash)"
REAL_CHMOD="$(command -v chmod)"
mkdir -p "$BIN" "$DECOY"

fail=0
make_bin() {
  rm -rf "$BIN"
  mkdir -p "$BIN"
  ln -s "$REAL_BASH" "$BIN/bash"
  ln -s "$REAL_CHMOD" "$BIN/chmod"
  : > "$LOG"
  rm -f "$PY_USABLE"
}
add_python() {
  cat > "$BIN/python3" <<'EOF'
#!/bin/bash
printf 'python3' >> "$LOG"
printf ' <%s>' "$@" >> "$LOG"
printf '\n' >> "$LOG"
if [ "${1:-}" = "-m" ] && [ "${2:-}" = "pip" ]; then
  case "${3:-}" in
    --version)
      [ "${PYTHON_MODE:-ok}" != "pip-missing" ]
      exit
      ;;
    install)
      [ "${PYTHON_MODE:-ok}" != "failed" ] || exit 1
      if [ "${PYTHON_MODE:-ok}" = "ok" ]; then
        : > "$PY_USABLE"
      fi
      exit 0
      ;;
  esac
fi
if [ "${1:-}" = "-c" ]; then
  [ "${PYTHON_MODE:-ok}" = "ok" ] && [ -f "$PY_USABLE" ]
  exit
fi
exit 1
EOF
  chmod +x "$BIN/python3"
}
add_npm() {
  cat > "$BIN/npm" <<'EOF'
#!/bin/bash
printf 'npm' >> "$LOG"
printf ' <%s>' "$@" >> "$LOG"
printf '\n' >> "$LOG"
if [ "${1:-}" != "install" ]; then
  exit 1
fi
[ "${NPM_MODE:-ok}" != "failed" ] || exit 1
if [ "${NPM_MODE:-ok}" = "ok" ]; then
  case "${3:-}" in
    defuddle)
      printf '#!/bin/bash\nexit 0\n' > "$BIN/defuddle"
      chmod +x "$BIN/defuddle"
      ;;
    firecrawl-cli)
      printf '#!/bin/bash\nexit 0\n' > "$BIN/firecrawl"
      chmod +x "$BIN/firecrawl"
      ;;
  esac
fi
exit 0
EOF
  chmod +x "$BIN/npm"
}
run_install() {
  local desc="$1" expected="$2" dep="$3" python_mode="$4"
  local npm_mode="$5" inherited_path="$6" actual
  set +e
  if [ -n "$inherited_path" ]; then
    PATH="$inherited_path" /usr/bin/env -i PATH="$BIN" LOG="$LOG" BIN="$BIN" \
      PY_USABLE="$PY_USABLE" PYTHON_MODE="$python_mode" NPM_MODE="$npm_mode" \
      "$SCRIPT" "$dep" >"$SCRATCH/out" 2>"$SCRATCH/err"
  else
    /usr/bin/env -i PATH="$BIN" LOG="$LOG" BIN="$BIN" PY_USABLE="$PY_USABLE" \
      PYTHON_MODE="$python_mode" NPM_MODE="$npm_mode" "$SCRIPT" "$dep" \
      >"$SCRATCH/out" 2>"$SCRATCH/err"
  fi
  actual=$?
  set -e
  if [ "$actual" = "$expected" ]; then
    echo "ok   - $desc (exit $actual)"
  else
    echo "FAIL - $desc (expected exit $expected, got $actual)"
    cat "$SCRATCH/out" "$SCRATCH/err"
    fail=1
  fi
}
assert_log_exact() {
  local desc="$1" expected="$2" actual
  actual="$(cat "$LOG")"
  if [ "$actual" = "$expected" ]; then
    echo "ok   - $desc"
  else
    echo "FAIL - $desc"
    printf 'expected:\\n%s\\nactual:\\n%s\\n' "$expected" "$actual"
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

echo "--- documented install dispatch ---"
make_bin
add_python
run_install "youtube-transcript-api dispatches through python3 pip" 0 \
  youtube-transcript-api ok ok ""
assert_log_exact "youtube install argv is exact" \
  $'python3 <-m> <pip> <--version>\npython3 <-m> <pip> <install> <youtube-transcript-api>\npython3 <-c> <import youtube_transcript_api>'

make_bin
add_npm
run_install "defuddle dispatches through npm" 0 defuddle ok ok ""
assert_log_exact "defuddle install argv is exact" "npm <install> <-g> <defuddle>"

make_bin
add_npm
run_install "firecrawl dispatches through npm" 0 firecrawl ok ok ""
assert_log_exact "firecrawl install argv is exact" \
  "npm <install> <-g> <firecrawl-cli>"

echo "--- installer failures ---"
make_bin
run_install "missing python3 exits 1" 1 youtube-transcript-api ok ok ""
assert_error "missing python3 names the dependency" "youtube-transcript-api"

make_bin
add_python
run_install "python3 without usable pip exits 1" 1 youtube-transcript-api pip-missing ok ""
assert_error "missing pip capability is identified" "has no usable pip module"

make_bin
add_python
run_install "failed pip install exits 1" 1 youtube-transcript-api failed ok ""
assert_error "failed pip install names the dependency" \
  "pip install youtube-transcript-api failed"

make_bin
add_python
run_install "unusable youtube install exits 1" 1 youtube-transcript-api unusable ok ""
assert_error "unusable youtube install is reported" \
  "import youtube_transcript_api"

make_bin
add_npm
run_install "successful but unusable defuddle install exits 1" 1 defuddle ok unusable ""
assert_error "unusable defuddle install is reported" "defuddle isn't on PATH"

make_bin
run_install "missing npm exits 1" 1 defuddle ok ok ""
assert_error "missing npm names the dependency" "defuddle"

make_bin
add_npm
run_install "failed npm install exits 1" 1 firecrawl ok failed ""
assert_error "failed npm install names the dependency" \
  "npm install -g firecrawl-cli failed"

echo "--- usage errors ---"
make_bin
add_python
add_npm
run_install "empty dependency exits 1" 1 "" ok ok ""
assert_error "empty dependency prints usage" "Usage:"
run_install "unknown dependency exits 1" 1 unknown ok ok ""
assert_error "unknown dependency prints usage" "Usage:"
assert_error "unknown dependency is identified" "unknown dependency: unknown"
if [ ! -s "$LOG" ]; then
  echo "ok   - usage errors do not invoke a package manager"
else
  echo "FAIL - usage errors invoked a package manager"
  cat "$LOG"
  fail=1
fi

echo "--- closed PATH isolation ---"
cat > "$DECOY/defuddle" <<'EOF'
#!/bin/bash
echo "decoy defuddle"
EOF
cat > "$DECOY/npm" <<'EOF'
#!/bin/bash
echo "decoy npm"
EOF
chmod +x "$DECOY/defuddle" "$DECOY/npm"
INHERITED_PATH="$DECOY:$SYSTEM_PATH"
if PATH="$INHERITED_PATH" command -v defuddle >/dev/null 2>&1 &&
  PATH="$INHERITED_PATH" command -v npm >/dev/null 2>&1; then
  echo "ok   - decoy defuddle and npm are available on the inherited PATH"
else
  echo "FAIL - decoy executables were not available on the inherited PATH"
  fail=1
fi
make_bin
run_install "closed PATH ignores inherited npm" 1 defuddle ok ok "$INHERITED_PATH"
assert_error "closed PATH reports npm missing" "npm is required"

if [ "$fail" = "0" ]; then
  echo "ALL PASS"
else
  echo "SOME TESTS FAILED"
  exit 1
fi
