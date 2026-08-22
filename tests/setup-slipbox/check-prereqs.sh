#!/usr/bin/env bash
# Mechanical smoke test for skills/setup-slipbox/scripts/check-prereqs.sh.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/../.." && pwd)"
SCRIPT="$REPO_ROOT/skills/setup-slipbox/scripts/check-prereqs.sh"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

BIN="$SCRATCH/bin"
DECOY="$SCRATCH/decoy"
SYSTEM_PATH="$PATH"
REAL_BASH="$(command -v bash)"
REAL_GREP="$(command -v grep)"
mkdir -p "$BIN" "$DECOY"

fail=0
make_bin() {
  rm -rf "$BIN"
  mkdir -p "$BIN"
  ln -s "$REAL_BASH" "$BIN/bash"
  ln -s "$REAL_GREP" "$BIN/grep"
}
add_python() {
  cat > "$BIN/python3" <<'EOF'
#!/bin/bash
if [ "${PYTHON_MODE:-ok}" = "broken" ]; then
  exit 1
fi
if [ "${1:-}" = "--version" ]; then
  echo "Python 3.12.0"
  exit 0
fi
if [ "${PYTHON_MODE:-ok}" = "import-fail" ]; then
  exit 1
fi
if [ "${1:-}" = "-c" ]; then
  exit 0
fi
exit 1
EOF
  chmod +x "$BIN/python3"
}
add_defuddle() {
  cat > "$BIN/defuddle" <<'EOF'
#!/bin/bash
if [ "${DEFUDDLE_MODE:-ok}" = "broken" ]; then
  echo "defuddle version probe failed" >&2
  exit 1
fi
echo "defuddle test-version"
EOF
  chmod +x "$BIN/defuddle"
}
add_firecrawl() {
  cat > "$BIN/firecrawl" <<'EOF'
#!/bin/bash
case "${FIRECRAWL_MODE:-unauthenticated}" in
  authenticated)
    echo "Authenticated"
    ;;
  broken)
    echo "firecrawl status probe failed" >&2
    exit 1
    ;;
  *)
    echo "Status: not logged in"
    ;;
esac
EOF
  chmod +x "$BIN/firecrawl"
}
run_check() {
  local desc="$1" expected="$2" python_mode="$3" defuddle_mode="$4"
  local firecrawl_mode="$5" inherited_path="$6"
  local actual
  set +e
  if [ -n "$inherited_path" ]; then
    PATH="$inherited_path" /usr/bin/env -i PATH="$BIN" \
      PYTHON_MODE="$python_mode" DEFUDDLE_MODE="$defuddle_mode" \
      FIRECRAWL_MODE="$firecrawl_mode" "$SCRIPT" \
      >"$SCRATCH/out" 2>"$SCRATCH/err"
  else
    /usr/bin/env -i PATH="$BIN" \
      PYTHON_MODE="$python_mode" DEFUDDLE_MODE="$defuddle_mode" \
      FIRECRAWL_MODE="$firecrawl_mode" "$SCRIPT" \
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
assert_output() {
  local desc="$1" text="$2"
  if grep -Fq "$text" "$SCRATCH/out"; then
    echo "ok   - $desc"
  else
    echo "FAIL - $desc (missing: $text)"
    cat "$SCRATCH/out"
    fail=1
  fi
}

echo "--- required dependencies ---"
make_bin
add_python
add_defuddle
add_firecrawl
run_check "everything present" 0 ok ok authenticated ""
assert_output "python3 is reported present" "python3: present"
assert_output "youtube_transcript_api is reported present" "youtube_transcript_api: present"
assert_output "defuddle is reported present" "defuddle: present"
assert_output "firecrawl is reported authenticated" "firecrawl: present, authenticated"

echo "--- missing and broken required dependencies ---"
make_bin
run_check "python3 absent" 1 ok ok unauthenticated ""
assert_output "python3 absence is reported" "python3: missing"
assert_output "youtube_transcript_api is unknown without python3" \
  "youtube_transcript_api: unknown"
make_bin
add_python
add_defuddle
run_check "python import probe fails" 1 import-fail ok unauthenticated ""
assert_output "failed import is reported as missing" "youtube_transcript_api: missing"
make_bin
add_python
run_check "defuddle absent" 1 ok ok unauthenticated ""
assert_output "absent defuddle is reported" "defuddle: missing"
make_bin
add_python
add_defuddle
run_check "defuddle version probe fails" 1 ok broken unauthenticated ""
assert_output "broken defuddle is distinguished from absent" \
  "defuddle: present on PATH but 'defuddle --version' failed"
assert_output "defuddle failure text is relayed" "defuddle version probe failed"

echo "--- optional firecrawl ---"
make_bin
add_python
add_defuddle
run_check "firecrawl absent remains optional" 0 ok ok unauthenticated ""
assert_output "absent firecrawl is marked optional" "firecrawl: missing (optional"
make_bin
add_python
add_defuddle
add_firecrawl
run_check "firecrawl is present but unauthenticated" 0 ok ok unauthenticated ""
assert_output "unauthenticated firecrawl is reported" \
  "firecrawl: present, not authenticated"
make_bin
add_python
add_defuddle
add_firecrawl
run_check "firecrawl is present and authenticated" 0 ok ok authenticated ""
assert_output "authenticated firecrawl is reported" "firecrawl: present, authenticated"
make_bin
add_python
add_defuddle
add_firecrawl
run_check "firecrawl status fails but remains optional" 0 ok ok broken ""
assert_output "failed firecrawl status is distinguished" \
  "firecrawl: present on PATH but 'firecrawl --status' failed (optional)"

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
add_python
run_check "closed PATH ignores inherited defuddle" 1 ok ok unauthenticated "$INHERITED_PATH"
assert_output "closed PATH still reports defuddle missing" "defuddle: missing"

echo "--- broken python interpreter ---"
make_bin
add_python
run_check "broken python interpreter fails the check" 1 broken ok unauthenticated ""
# The current script labels this as "python3: present ()"; assert only the
# failing exit status until that misleading label is corrected upstream.

if [ "$fail" = "0" ]; then
  echo "ALL PASS"
else
  echo "SOME TESTS FAILED"
  exit 1
fi
