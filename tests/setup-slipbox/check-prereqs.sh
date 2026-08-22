#!/usr/bin/env bash
# Mechanical smoke test for skills/setup-slipbox/scripts/check-prereqs.sh.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/../.." && pwd)"
SCRIPT="$REPO_ROOT/skills/setup-slipbox/scripts/check-prereqs.sh"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

BIN="$SCRATCH/bin"
PYTHON="$SCRATCH/python"
mkdir -p "$BIN" "$PYTHON"
REAL_PYTHON="$(command -v python3)"
cat > "$BIN/python3" <<EOF
#!/usr/bin/env bash
exec "$REAL_PYTHON" -S "\$@"
EOF
chmod +x "$BIN/python3"
cat > "$PYTHON/youtube_transcript_api.py" <<'EOF'
"""Dummy module for the prerequisite import probe."""
EOF
cat > "$BIN/defuddle" <<'EOF'
#!/usr/bin/env bash
if [ "${1:-}" = "--version" ]; then
  echo "defuddle test-version"
fi
EOF
chmod +x "$BIN/defuddle"

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
assert_output() {
  local desc="$1" text="$2"
  if grep -Fqi "$text" "$SCRATCH/out"; then
    echo "ok   - $desc"
  else
    echo "FAIL - $desc (missing: $text)"
    fail=1
  fi
}

echo "--- required dependencies ---"
check_exit "all required dependencies present" 0 env PATH="$BIN:$PATH" PYTHONPATH="$PYTHON" "$SCRIPT"
assert_output "all-present output reports youtube_transcript_api" "youtube_transcript_api: present"
assert_output "all-present output reports defuddle" "defuddle: present"
assert_output "missing optional firecrawl is marked optional" "firecrawl: missing (optional"

rm "$PYTHON/youtube_transcript_api.py"
check_exit "missing youtube_transcript_api exits 1" 1 env PATH="$BIN:$PATH" PYTHONPATH="$PYTHON" "$SCRIPT"
assert_output "missing youtube_transcript_api is reported" "youtube_transcript_api: missing"
cat > "$PYTHON/youtube_transcript_api.py" <<'EOF'
"""Dummy module for the prerequisite import probe."""
EOF
rm "$BIN/defuddle"
check_exit "missing defuddle exits 1" 1 env PATH="$BIN:$PATH" PYTHONPATH="$PYTHON" "$SCRIPT"
assert_output "missing defuddle is reported" "defuddle: missing"
cat > "$BIN/defuddle" <<'EOF'
#!/usr/bin/env bash
echo "defuddle test-version"
EOF
chmod +x "$BIN/defuddle"

echo "--- optional firecrawl ---"
cat > "$BIN/firecrawl" <<'EOF'
#!/usr/bin/env bash
echo "Status: not logged in"
EOF
chmod +x "$BIN/firecrawl"
check_exit "unauthenticated firecrawl remains optional" 0 env PATH="$BIN:$PATH" PYTHONPATH="$PYTHON" "$SCRIPT"
assert_output "unauthenticated firecrawl is reported" "firecrawl: present, not authenticated"
cat > "$BIN/firecrawl" <<'EOF'
#!/usr/bin/env bash
echo "Authenticated"
EOF
chmod +x "$BIN/firecrawl"
check_exit "authenticated firecrawl succeeds" 0 env PATH="$BIN:$PATH" PYTHONPATH="$PYTHON" "$SCRIPT"
assert_output "authenticated firecrawl is reported" "firecrawl: present, authenticated"

if [ "$fail" = "0" ]; then
  echo "ALL PASS"
else
  echo "SOME TESTS FAILED"
  exit 1
fi
