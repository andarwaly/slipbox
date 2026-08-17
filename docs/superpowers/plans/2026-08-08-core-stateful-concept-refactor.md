# Core Stateful Concept Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Retire `idea.db` (SQLite) for a plain-file state layer, rebuild the literature-note pipeline around direct capture and multi-claim Q/E/C notes, harden `grounding`'s own mechanics, and trim `setup-slipbox`'s onboarding surface — all four grilling-session resolutions recorded in `skill-kojo/discussion/slipbox/decision.md` (2026-08-08 entries), implemented in one pass on this repo's `refactor/core-stateful-concept` branch.

**Architecture:** The `slipbox` CLI (renamed from `idea-db`) drops SQLite entirely — `evergreen` becomes one YAML-frontmatter file per candidate under `.slipbox/evergreen/`, `links` becomes an append-only `.slipbox/links.jsonl` log, `seeds` disappears (literature/term tracking is now derived on demand from existing notes' own frontmatter/wikilinks). `ground-claim` moves from backlog-pull to direct capture → self-surfaced candidate list → per-claim `/grounding` loop → incremental multi-claim writes. `surface-ideas` is retired, replaced by two independently-invoked skills (`find-terms`, `find-connections`). `grounding` gains a named probing taxonomy and a hardened Gate. `setup-slipbox` sheds its SQLite prerequisite and gains a lazy/defer option for `field_map`.

**Tech Stack:** Bash (CLI dispatch, unchanged runtime decision), Python 3 stdlib only (structured file read/write inside the CLI — already a dependency via `config get/set`/`humanize check`, no new dependency), Markdown/YAML frontmatter (skill bodies, note templates, `config.schema.json`).

## Global Constraints

- Bash 3.2 compatibility: no `declare -A` (associative arrays) anywhere in `scripts/slipbox` — macOS ships bash 3.2 by default (GPL licensing freeze). Verified pattern already in the file being replaced; preserve it.
- No new external dependencies. Python 3 stdlib only — no `PyYAML` or any pip package. `sqlite3` is fully removed as a dependency; do not reintroduce it anywhere in this plan.
- Every `.slipbox/bin/slipbox` invocation shown in any skill body uses the full path `.slipbox/bin/slipbox`, never a bare `slipbox` — matches the existing project-wide convention (nothing in this family puts the binary on `PATH`).
- Atomic writes only for anything touching `.slipbox/evergreen/*.md`: write to a temp file in the same directory via `tempfile.mkstemp`, then `os.replace` — never write the real path directly.
- No numbered step-headings in any `SKILL.md` prose added or rewritten (`## 1. Foo` is banned workspace-wide) — named/descriptive headings only, matching this repo's established style (`## Take the idea`, not `## 1. Take the idea`). The existing numbered-step convention in `setup-slipbox/SKILL.md` predates this rule and is being edited in place here, not retrofitted wholesale — only touch the specific numbered sections this plan's tasks modify.
- "You"/"your" in narrative prose always means the agent; the user is spelled out as "the user" — except quoted dialogue the agent speaks aloud (workspace-wide convention, `skill-kojo/AGENTS.md`).
- Every skill touching `.slipbox/evergreen/` or `.slipbox/links.jsonl` goes through `.slipbox/bin/slipbox` exclusively — no skill ever hand-parses frontmatter or hand-appends to `links.jsonl` itself.

---

## Before Task 1: confirm the branch

This entire plan executes on `refactor/core-stateful-concept`, branched off `main` — created empty ahead of this plan, not part of it. Before Task 1's first step:

```bash
git branch --show-current
```

Expected: `refactor/core-stateful-concept`. If it's `main` or anything else:

```bash
git checkout refactor/core-stateful-concept
```

Do not create the branch fresh from this plan if it doesn't exist under this exact name — check with the person who asked for this plan first; a missing branch of this exact name is a sign something upstream changed, not something to silently work around.

## Task 1: Write the failing test suite for the new `slipbox` CLI

**Files:**
- Create: `tests/setup-slipbox/slipbox.sh`
- Delete (in this task, before writing the new file): `tests/setup-slipbox/idea-db.sh`

**Interfaces:**
- Produces: a bash smoke-test script invoked as `bash tests/setup-slipbox/slipbox.sh`, exit 0 on all-pass, exit 1 on any failure — the exact shape Task 2's implementation must satisfy.

- [ ] **Step 1: Delete the old test file**

```bash
git rm tests/setup-slipbox/idea-db.sh
```

- [ ] **Step 2: Write the new test file**

```bash
cat > tests/setup-slipbox/slipbox.sh <<'TESTEOF'
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
TESTEOF
chmod +x tests/setup-slipbox/slipbox.sh
```

- [ ] **Step 3: Run it to verify it fails (the CLI doesn't exist yet)**

Run: `bash tests/setup-slipbox/slipbox.sh`
Expected: FAIL immediately at `cp "$REPO_ROOT/skills/setup-slipbox/scripts/slipbox"` — no such file (the old file is still named `idea-db` at this point).

- [ ] **Step 4: Commit**

```bash
git add tests/setup-slipbox/slipbox.sh
git commit -m "test: add failing smoke test suite for the file-tier slipbox CLI"
```

---

## Task 2: Implement the `slipbox` CLI (drops SQLite, evergreen/links go file-tier)

**Files:**
- Create: `skills/setup-slipbox/scripts/slipbox`
- Delete: `skills/setup-slipbox/scripts/idea-db`, `skills/setup-slipbox/assets/schema.sql`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: `.slipbox/bin/slipbox` command surface — `evergreen add|find|update`, `links add|find`, `config get|set`, `humanize check`, `--help`/`--version`. No `init`/`migrate`/`seeds` commands. Every later task that shells out to this CLI (Tasks 5, 8, 9, 10, 11, 12) depends on this exact surface.

- [ ] **Step 1: Delete the old script and schema**

```bash
git rm skills/setup-slipbox/scripts/idea-db skills/setup-slipbox/assets/schema.sql
```

- [ ] **Step 2: Write the new script**

```bash
cat > skills/setup-slipbox/scripts/slipbox <<'SCRIPTEOF'
#!/usr/bin/env bash
# slipbox — CLI wrapping .slipbox/evergreen/*.md, .slipbox/links.jsonl, and .slipbox/config.json.
# Canonical source; setup-slipbox copies this file verbatim to .slipbox/bin/slipbox
# on every run (always overwritten — versioned code, not user data).
# See docs/adr/0002-slipbox-file-tier-cli.md for the design decisions behind this file's shape.
#
# No SQLite dependency. Evergreen candidates are plain files (one YAML-
# frontmatter file per candidate, atomic write via tempfile+os.replace) and
# links are an append-only JSONL log — sync-native, git-mergeable, no binary
# database. See ADR 0002 for why idea.db was retired. `seeds` no longer
# exists at all: literature/term tracking is now derived on demand from
# existing notes' own frontmatter and wikilinks, not surfaced into a queue.
#
# Portability note: macOS ships bash 3.2 by default (GPL licensing) — this file
# deliberately avoids associative arrays (`declare -A`, bash 4+) for that reason.
set -euo pipefail

CLI_VERSION="2.0.0"

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EVERGREEN_DIR="$SELF_DIR/evergreen"
LINKS_FILE="$SELF_DIR/links.jsonl"
CONFIG="$SELF_DIR/config.json"

# ---- helpers ----
usage_err() { echo "{\"error\":\"$1\"}" >&2; exit 2; }
runtime_err() { echo "{\"error\":\"$1\"}" >&2; exit 1; }
require_config() { [ -f "$CONFIG" ] || runtime_err "config.json not found at $CONFIG — run setup-slipbox first"; }
require_evergreen_dir() { [ -d "$EVERGREEN_DIR" ] || runtime_err "evergreen directory not found at $EVERGREEN_DIR — run setup-slipbox first"; }

# get_flag <name> "$@" — scans args for "--<name> <value>", echoes value, exits 1 if absent.
# Plain positional scan, not an associative array — keeps this file bash-3.2-safe.
get_flag() {
  local name="--$1"; shift
  while [ $# -gt 0 ]; do
    if [ "$1" = "$name" ]; then
      [ $# -ge 2 ] || usage_err "flag $name needs a value"
      printf '%s' "$2"
      return 0
    fi
    shift
  done
  return 1
}

print_help() {
  cat <<'EOF'
slipbox — CLI for .slipbox/evergreen/*.md, .slipbox/links.jsonl, and .slipbox/config.json

Usage:
  slipbox evergreen add    --slug SLUG --reason "..."
  slipbox evergreen find   [--status S]
  slipbox evergreen update <slug> [--status S] [--note-path P] [--slug NEW] [--iteration N]
  slipbox links add        --source S --target T --rel cites|extends
  slipbox links find       [--source S] [--target T] [--rel cites|extends]
  slipbox config get       [<dotted.path>]
  slipbox config set       <dotted.path> <value>
  slipbox humanize check   <file> [--language LANG]
  slipbox --help | --version

Output is JSON by default (--format table optional on find/get commands).
Exit 2 on usage errors, exit 1 on runtime failures.
EOF
}

# ---- evergreen (file-per-candidate, YAML frontmatter, no body) ----
cmd_evergreen_add() {
  require_evergreen_dir
  local slug reason
  slug=$(get_flag slug "$@") || slug=""
  reason=$(get_flag reason "$@") || reason=""
  [ -n "$slug" ] || usage_err "evergreen add requires --slug"
  [ -n "$reason" ] || usage_err "evergreen add requires --reason"
  EVERGREEN_DIR="$EVERGREEN_DIR" SLUG="$slug" REASON="$reason" python3 - <<'PYEOF'
import json, os, sys, tempfile
from datetime import datetime, timezone

evergreen_dir = os.environ["EVERGREEN_DIR"]
slug = os.environ["SLUG"]
reason = os.environ["REASON"]
path = os.path.join(evergreen_dir, f"{slug}.md")

if os.path.exists(path):
    print(json.dumps({"error": f"evergreen slug already exists: {slug}"}), file=sys.stderr)
    sys.exit(1)

now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
order = ["status", "reason", "discussion_path", "note_path", "iteration", "created_at", "updated_at"]
fields = {
    "status": "to-discuss",
    "reason": reason,
    "discussion_path": None,
    "note_path": None,
    "iteration": 1,
    "created_at": now,
    "updated_at": now,
}

def serialize(fields, order):
    lines = ["---"]
    for key in order:
        value = fields[key]
        if value is None:
            lines.append(f"{key}:")
        elif isinstance(value, str):
            lines.append(f"{key}: {json.dumps(value)}")
        else:
            lines.append(f"{key}: {value}")
    lines.append("---")
    return "\n".join(lines) + "\n"

fd, tmp_path = tempfile.mkstemp(dir=evergreen_dir, prefix=f".{slug}-", suffix=".md.tmp")
with os.fdopen(fd, "w") as f:
    f.write(serialize(fields, order))
os.replace(tmp_path, path)

print(json.dumps({"slug": slug, **fields}, indent=2))
PYEOF
}

cmd_evergreen_find() {
  require_evergreen_dir
  local status format
  status=$(get_flag status "$@") || status=""
  format=$(get_flag format "$@") || format="json"
  EVERGREEN_DIR="$EVERGREEN_DIR" STATUS_FILTER="$status" FORMAT="$format" python3 - <<'PYEOF'
import glob, json, os, re

evergreen_dir = os.environ["EVERGREEN_DIR"]
status_filter = os.environ.get("STATUS_FILTER", "")
fmt = os.environ.get("FORMAT", "json")

def parse_frontmatter(text):
    match = re.match(r"^---\n(.*?)\n---\n?", text, re.DOTALL)
    if not match:
        return None, []
    fields, order = {}, []
    for line in match.group(1).splitlines():
        if ":" not in line:
            continue
        key, _, raw = line.partition(":")
        key = key.strip()
        raw = raw.strip()
        order.append(key)
        if raw == "":
            fields[key] = None
        elif raw.startswith('"'):
            fields[key] = json.loads(raw)
        elif raw.lstrip("-").isdigit():
            fields[key] = int(raw)
        else:
            fields[key] = raw
    return fields, order

rows = []
for path in sorted(glob.glob(os.path.join(evergreen_dir, "*.md"))):
    fields, _ = parse_frontmatter(open(path).read())
    if fields is None:
        continue
    slug = os.path.splitext(os.path.basename(path))[0]
    row = {"slug": slug, **fields}
    if status_filter and row.get("status") != status_filter:
        continue
    rows.append(row)

rows.sort(key=lambda r: r.get("created_at") or "", reverse=True)

if fmt == "table":
    if not rows:
        print("(no rows)")
    else:
        cols = list(rows[0].keys())
        print("\t".join(cols))
        for row in rows:
            print("\t".join(str(row.get(c, "")) for c in cols))
else:
    print(json.dumps(rows, indent=2))
PYEOF
}

cmd_evergreen_update() {
  require_evergreen_dir
  [ $# -ge 1 ] || usage_err "evergreen update requires <slug>"
  local slug="$1"; shift
  local status note_path iteration new_slug
  status=$(get_flag status "$@") || status=""
  note_path=$(get_flag note-path "$@") || note_path=""
  iteration=$(get_flag iteration "$@") || iteration=""
  new_slug=$(get_flag slug "$@") || new_slug=""
  if [ -z "$status" ] && [ -z "$note_path" ] && [ -z "$iteration" ] && [ -z "$new_slug" ]; then
    usage_err "evergreen update requires at least one of --status, --note-path, --slug, --iteration"
  fi
  local path="$EVERGREEN_DIR/$slug.md"
  [ -f "$path" ] || runtime_err "evergreen slug not found: $slug"
  EVERGREEN_DIR="$EVERGREEN_DIR" SLUG="$slug" NEW_SLUG="$new_slug" STATUS="$status" NOTE_PATH="$note_path" ITERATION="$iteration" python3 - <<'PYEOF'
import json, os, re, sys, tempfile
from datetime import datetime, timezone

evergreen_dir = os.environ["EVERGREEN_DIR"]
slug = os.environ["SLUG"]
new_slug = os.environ.get("NEW_SLUG", "")
status = os.environ.get("STATUS", "")
note_path = os.environ.get("NOTE_PATH", "")
iteration = os.environ.get("ITERATION", "")

path = os.path.join(evergreen_dir, f"{slug}.md")
text = open(path).read()
match = re.match(r"^---\n(.*?)\n---\n?", text, re.DOTALL)
fields, order = {}, []
for line in match.group(1).splitlines():
    key, _, raw = line.partition(":")
    key = key.strip()
    raw = raw.strip()
    order.append(key)
    if raw == "":
        fields[key] = None
    elif raw.startswith('"'):
        fields[key] = json.loads(raw)
    elif raw.lstrip("-").isdigit():
        fields[key] = int(raw)
    else:
        fields[key] = raw

if status:
    fields["status"] = status
if note_path:
    fields["note_path"] = note_path
if iteration:
    fields["iteration"] = int(iteration)
fields["updated_at"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

def serialize(fields, order):
    lines = ["---"]
    for key in order:
        value = fields[key]
        if value is None:
            lines.append(f"{key}:")
        elif isinstance(value, str):
            lines.append(f"{key}: {json.dumps(value)}")
        else:
            lines.append(f"{key}: {value}")
    lines.append("---")
    return "\n".join(lines) + "\n"

final_slug = new_slug or slug
final_path = os.path.join(evergreen_dir, f"{final_slug}.md")
if new_slug and os.path.exists(final_path):
    print(json.dumps({"error": f"evergreen slug already exists: {new_slug}"}), file=sys.stderr)
    sys.exit(1)

fd, tmp_path = tempfile.mkstemp(dir=evergreen_dir, prefix=f".{final_slug}-", suffix=".md.tmp")
with os.fdopen(fd, "w") as f:
    f.write(serialize(fields, order))
os.replace(tmp_path, final_path)
if new_slug and new_slug != slug:
    os.remove(path)

print(json.dumps({"slug": final_slug, **fields}, indent=2))
PYEOF
}

# ---- links (append-only JSONL log; edges have no natural filename) ----
cmd_links_add() {
  local source target rel
  source=$(get_flag source "$@") || source=""
  target=$(get_flag target "$@") || target=""
  rel=$(get_flag rel "$@") || rel=""
  [ -n "$source" ] || usage_err "links add requires --source"
  [ -n "$target" ] || usage_err "links add requires --target"
  [ -n "$rel" ] || usage_err "links add requires --rel"
  case "$rel" in cites|extends) ;; *) usage_err "--rel must be one of cites, extends" ;; esac
  LINKS_FILE="$LINKS_FILE" SOURCE="$source" TARGET="$target" REL="$rel" python3 - <<'PYEOF'
import json, os
from datetime import datetime, timezone

links_file = os.environ["LINKS_FILE"]
row = {
    "source_id": os.environ["SOURCE"],
    "target_id": os.environ["TARGET"],
    "rel_type": os.environ["REL"],
    "created_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
}
with open(links_file, "a") as f:
    f.write(json.dumps(row) + "\n")
print(json.dumps({"status": "ok", **row}))
PYEOF
}

cmd_links_find() {
  local source target rel format
  source=$(get_flag source "$@") || source=""
  target=$(get_flag target "$@") || target=""
  rel=$(get_flag rel "$@") || rel=""
  format=$(get_flag format "$@") || format="json"
  LINKS_FILE="$LINKS_FILE" SOURCE_FILTER="$source" TARGET_FILTER="$target" REL_FILTER="$rel" FORMAT="$format" python3 - <<'PYEOF'
import json, os

links_file = os.environ["LINKS_FILE"]
source_filter = os.environ.get("SOURCE_FILTER", "")
target_filter = os.environ.get("TARGET_FILTER", "")
rel_filter = os.environ.get("REL_FILTER", "")
fmt = os.environ.get("FORMAT", "json")

rows = []
if os.path.exists(links_file):
    with open(links_file) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            row = json.loads(line)
            if source_filter and row.get("source_id") != source_filter:
                continue
            if target_filter and row.get("target_id") != target_filter:
                continue
            if rel_filter and row.get("rel_type") != rel_filter:
                continue
            rows.append(row)

if fmt == "table":
    if not rows:
        print("(no rows)")
    else:
        cols = list(rows[0].keys())
        print("\t".join(cols))
        for row in rows:
            print("\t".join(str(row.get(c, "")) for c in cols))
else:
    print(json.dumps(rows, indent=2))
PYEOF
}

# ---- config (dotted-path get/set over config.json — unchanged from idea-db) ----
cmd_config_get() {
  require_config
  local path="${1:-}"
  CONFIG_PATH="$CONFIG" DOTTED="$path" python3 - <<'PYEOF'
import json, os, sys
with open(os.environ["CONFIG_PATH"]) as f:
    data = json.load(f)
dotted = os.environ.get("DOTTED", "")
node = data
if dotted:
    for part in dotted.split("."):
        if not isinstance(node, dict) or part not in node:
            print(json.dumps({"error": f"unknown path: {dotted}"}), file=sys.stderr)
            sys.exit(2)
        node = node[part]
print(json.dumps(node, indent=2))
PYEOF
}

cmd_config_set() {
  require_config
  [ $# -ge 2 ] || usage_err "config set requires <dotted.path> <value>"
  local dotted="$1" value="$2"
  CONFIG_PATH="$CONFIG" DOTTED="$dotted" VALUE="$value" python3 - <<'PYEOF'
import json, os, sys

config_path = os.environ["CONFIG_PATH"]
dotted = os.environ["DOTTED"]
raw = os.environ["VALUE"]

with open(config_path) as f:
    data = json.load(f)

try:
    value = json.loads(raw)
except json.JSONDecodeError:
    value = raw

parts = dotted.split(".")
node = data
for part in parts[:-1]:
    if not isinstance(node, dict) or part not in node:
        print(json.dumps({"error": f"unknown path: {dotted}"}), file=sys.stderr)
        sys.exit(2)
    node = node[part]
leaf = parts[-1]
if not isinstance(node, dict) or leaf not in node:
    print(json.dumps({"error": f"unknown path: {dotted}"}), file=sys.stderr)
    sys.exit(2)
node[leaf] = value

with open(config_path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")

print(json.dumps({"status": "ok", "path": dotted, "value": value}))
PYEOF
}

# ---- humanize check (unchanged from idea-db — mechanical detection only) ----
cmd_humanize_check() {
  [ $# -ge 1 ] || usage_err "humanize check requires <file> [--language LANG]"
  local file="$1"
  shift
  local passage_language=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --language)
        [ $# -ge 2 ] || usage_err "--language requires LANG"
        passage_language="$2"
        shift 2
        ;;
      *) usage_err "unknown humanize check argument: $1" ;;
    esac
  done
  [ -f "$file" ] || runtime_err "file not found: $file"
  require_config
  local checklist="$SELF_DIR/humanize-checklist.json"
  [ -f "$checklist" ] || runtime_err "humanize-checklist.json not found at $checklist — run setup-slipbox first"
  local style="$SELF_DIR/style-profile.json"
  [ -f "$style" ] || runtime_err "style-profile.json not found — run setup-slipbox first"

  FILE_PATH="$file" CHECKLIST_PATH="$checklist" STYLE_PATH="$style" PASSAGE_LANGUAGE="$passage_language" python3 - <<'PYEOF'
import json, os, re

with open(os.environ["FILE_PATH"]) as f:
    text = f.read()
with open(os.environ["CHECKLIST_PATH"]) as f:
    checklist = json.load(f)
with open(os.environ["STYLE_PATH"]) as f:
    style = json.load(f)

language = style.get("language", {})
allowed_langs = {
    str(language.get("primary", "")),
    str(language.get("secondary", "")),
}
allowed_langs.update(str(value) for value in language.get("additional", []))
allowed_langs = {value.lower() for value in allowed_langs if value}
passage_language = os.environ.get("PASSAGE_LANGUAGE", "").lower()
english_ok = bool({"en", "english"} & ({passage_language} if passage_language else allowed_langs))

def language_allowed(signal):
    scope = signal.get("language", "universal")
    return scope == "universal" or (scope == "en" and english_ok)

def title_case_headings(value):
    matches = []
    for line in value.splitlines():
        match = re.match(r"^\s{0,3}#{1,6}\s+(.+?)\s*$", line)
        if not match:
            continue
        words = re.findall(r"[A-Za-z]+", match.group(1))
        significant = [word for word in words if word.lower() not in {"a", "an", "and", "as", "at", "by", "for", "in", "of", "on", "or", "the", "to"}]
        if len(significant) >= 2 and all(word[0].isupper() for word in significant):
            matches.append(line.strip())
    return matches

def signal_matches(signal):
    stype = signal.get("type")
    if stype == "title_case_heading":
        return title_case_headings(text)
    if stype == "word_list":
        matches = []
        for word in signal.get("words", []):
            matches.extend(re.findall(r"\b" + re.escape(word) + r"\b", text, re.IGNORECASE))
        return matches
    if stype == "phrase_list":
        matches = []
        for phrase in signal.get("phrases", []):
            matches.extend(re.findall(re.escape(phrase), text, re.IGNORECASE))
        return matches
    if stype == "announcement_opener":
        matches = []
        for phrase in signal.get("phrases", []):
            pattern = r"(?im)(?:^|[.!?]\s+)\s*" + re.escape(phrase)
            matches.extend(re.findall(pattern, text))
        return matches
    if stype == "regex":
        return [match if isinstance(match, str) else " ".join(match) for match in re.findall(signal.get("pattern", ""), text, re.IGNORECASE)]
    return []

signals_present = []
signals_passed = []
signal_results = []

for signal in checklist.get("detection", {}).get("mechanical", {}).get("signals", []):
    if not language_allowed(signal):
        signal_results.append({"id": signal["id"], "skipped": "language_scope"})
        continue
    matches = signal_matches(signal)
    present = bool(matches)
    threshold = 1 if signal.get("flag") == "single" else int(signal.get("min_hits", 1))
    passed = present and (signal.get("flag") == "single" or len(matches) >= threshold)
    result = {
        "id": signal["id"],
        "flag": signal.get("flag"),
        "hits": len(matches),
        "min_hits": threshold,
        "present": present,
        "passed": passed,
    }
    if matches:
        result["matches"] = matches[:20]
        signals_present.append(signal["id"])
    if passed:
        signals_passed.append(signal["id"])
    signal_results.append(result)

cross_signal_passed = len(signals_present) >= 2
flagged = bool(signals_passed or cross_signal_passed)
result = {
    "flagged": flagged,
    "signals": signal_results,
    "signals_passed": signals_passed,
    "cross_signal": {
        "mechanical_only": True,
        "distinct_present": len(signals_present),
        "min_distinct": 2,
        "passed": cross_signal_passed,
    },
    "judgment": "Apply detection.judgment with reading comprehension; judgment signals are not counted by this CLI.",
}
print(json.dumps(result, indent=2))
PYEOF
}

# ---- dispatch ----
[ $# -ge 1 ] || { print_help; exit 2; }

case "$1" in
  --help|-h) print_help; exit 0 ;;
  --version|-v) echo "slipbox $CLI_VERSION"; exit 0 ;;
  evergreen)
    shift
    [ $# -ge 1 ] || usage_err "evergreen requires an action: find, add, update"
    action="$1"; shift
    case "$action" in
      find) cmd_evergreen_find "$@" ;;
      add) cmd_evergreen_add "$@" ;;
      update) cmd_evergreen_update "$@" ;;
      *) usage_err "unknown evergreen action: $action" ;;
    esac
    ;;
  links)
    shift
    [ $# -ge 1 ] || usage_err "links requires an action: add, find"
    action="$1"; shift
    case "$action" in
      add) cmd_links_add "$@" ;;
      find) cmd_links_find "$@" ;;
      *) usage_err "unknown links action: $action" ;;
    esac
    ;;
  config)
    shift
    [ $# -ge 1 ] || usage_err "config requires an action: get, set"
    action="$1"; shift
    case "$action" in
      get) cmd_config_get "$@" ;;
      set) cmd_config_set "$@" ;;
      *) usage_err "unknown config action: $action" ;;
    esac
    ;;
  humanize)
    shift
    [ $# -ge 1 ] || usage_err "humanize requires an action: check"
    action="$1"; shift
    case "$action" in
      check) cmd_humanize_check "$@" ;;
      *) usage_err "unknown humanize action: $action" ;;
    esac
    ;;
  *)
    usage_err "unknown command: $1"
    ;;
esac
SCRIPTEOF
chmod +x skills/setup-slipbox/scripts/slipbox
```

- [ ] **Step 3: Run the test suite to verify it passes**

Run: `bash tests/setup-slipbox/slipbox.sh`
Expected: `ALL PASS`

- [ ] **Step 4: Commit**

```bash
git add skills/setup-slipbox/scripts/slipbox
git rm skills/setup-slipbox/scripts/idea-db skills/setup-slipbox/assets/schema.sql
git commit -m "feat: replace idea-db (SQLite) with slipbox (file-tier CLI)"
```

---

## Task 3: Update `.gitignore` (drop the dead `idea.db*` exclusion)

**Files:**
- Modify: `.gitignore`

**Interfaces:**
- Consumes: nothing.
- Produces: nothing consumed by later tasks — pure cleanup.

- [ ] **Step 1: Remove the stray-idea.db comment and exclusions**

Current content:
```
.DS_Store

# Stray idea.db from running idea-db inside the repo. The real database belongs at
# .slipbox/idea.db in a user's vault, created by setup-slipbox — never in the package.
idea.db
idea.db-shm
idea.db-wal
```

Replace with:
```
.DS_Store
```

- [ ] **Step 2: Verify no other reference to the excluded pattern exists**

Run: `grep -rn "idea.db" --include="*.gitignore" .`
Expected: no output.

- [ ] **Step 3: Commit**

```bash
git add .gitignore
git commit -m "chore: drop dead idea.db gitignore entry (SQLite removed)"
```

---

## Task 4: Update `config.schema.json` (drop `field_map`'s bare-string ambiguity risk, add `"deferred"` marker and `prefixes`)

**Files:**
- Modify: `skills/setup-slipbox/assets/config.schema.json`

**Interfaces:**
- Produces: two new schema shapes later tasks depend on — `field_map`'s deferred-entry object form (Tasks 5, 8), and the top-level `prefixes` object (Tasks 5, 9).

- [ ] **Step 1: Add the `"deferred"` form to `field_map`'s `oneOf`**

Find the `field_map` definition (currently a 3-way `oneOf`: bare string, `false`, or the full `{name, type, wikilink, zone}` object). Add a 4th branch — a distinct object shape (`{"deferred": true}`) that cannot be confused with a real property name (a bare string) or a fully-resolved mapping (which requires `name`/`type`/`zone`):

```json
    "field_map": {
      "type": "object",
      "additionalProperties": {
        "oneOf": [
          { "type": "string" },
          { "type": "boolean", "const": false },
          {
            "type": "object",
            "required": ["deferred"],
            "additionalProperties": false,
            "properties": {
              "deferred": { "type": "boolean", "const": true }
            }
          },
          {
            "type": "object",
            "required": ["name", "type", "zone"],
            "additionalProperties": false,
            "properties": {
              "name": { "type": "string" },
              "type": { "type": "string", "enum": ["text", "list", "number", "checkbox", "date", "datetime"] },
              "wikilink": { "type": "boolean", "default": false },
              "zone": { "type": "string", "enum": ["top", "bottom"] }
            }
          }
        ]
      },
      "description": "Per required field, one of four forms: (a) a bare string — shorthand for {name: <string>, type: \"text\", wikilink: false, zone: \"top\"}, the existing user property it maps onto or the standard field name if newly created (zone defaults to \"top\" for this shorthand form); (b) false for explicit opt-out; (c) {deferred: true} — resolution deliberately deferred to write-checks' first-write fallback, distinct from bare absence (which setup-slipbox's own drift-check would otherwise mistake for an interrupted setup); (d) an object {name, type, wikilink, zone} giving full control — name is the existing or standard property name, type is Obsidian's own native Properties type (text/list/number/checkbox/date/datetime, i.e. Text/List/Number/Checkbox/Date/Date & Time), wikilink (default false) marks whether the value(s) get wrapped per the sibling top-level links.style field, and zone (required, \"top\" or \"bottom\") places a newly-created field at the top or bottom of the frontmatter block — only meaningful for fields being newly created, since a field mapped onto an existing user property stays wherever that property already sits in the user's template. Never a key equal to the reserved properties tags, aliases, or cssclasses."
    }
```

- [ ] **Step 2: Add the top-level `prefixes` object**

Add a new required top-level property, sibling to `paths`/`filenames`/`frontmatter`/`links`/`templates`/`transcript_languages`:

```json
    "prefixes": {
      "type": "object",
      "required": ["literature", "term", "evergreen"],
      "additionalProperties": false,
      "properties": {
        "literature": { "oneOf": [{ "type": "string" }, { "type": "boolean", "const": false }] },
        "term": { "oneOf": [{ "type": "string" }, { "type": "boolean", "const": false }] },
        "evergreen": { "oneOf": [{ "type": "string" }, { "type": "boolean", "const": false }] }
      }
    },
```

Add `"prefixes"` to the root `required` array (currently `["paths", "filenames", "frontmatter", "links", "templates", "transcript_languages"]`).

- [ ] **Step 3: Validate the schema itself is well-formed JSON Schema**

Run:
```bash
python3 -c "import json; json.load(open('skills/setup-slipbox/assets/config.schema.json'))"
```
Expected: no output, exit 0 (valid JSON — this only checks syntax, not JSON-Schema semantics, which is sufficient here since no schema-validator dependency exists in this project).

- [ ] **Step 4: Commit**

```bash
git add skills/setup-slipbox/assets/config.schema.json
git commit -m "feat: add field_map deferred marker and prefixes to config.schema.json"
```

---

## Task 5: Update `grounding/SKILL.md` — probing taxonomy + hardened Gate

**Files:**
- Modify: `skills/grounding/SKILL.md`
- Modify: `tests/grounding/evals.json`

**Interfaces:**
- Produces: the "Probing" and hardened "Gate" sections every `ground-*` wrapper (Tasks 7, 9, 11, 12) inherits automatically by calling `/grounding` — no wrapper file itself changes for this.

- [ ] **Step 1: Add a new eval case for the hardened Gate precondition**

Add to `tests/grounding/evals.json`'s `test_cases` array (append, don't replace the existing three):

```json
    {
      "prompt": "ground this: [source text about design tokens] — I think design tokens are basically just CSS variables with extra branding, right?",
      "expected_output": "Does not immediately present a finished draft statement for yes/no confirmation. Runs at least one open probe first (e.g. asking what distinguishes a token from a CSS variable) and only presents a draft once the user's own words have contributed to it, with the confirmation phrased as an open question ('what's missing or wrong?') rather than a bare yes/no.",
      "assertions": [
        {"type": "not_contains", "text": "yes or no"},
        {"type": "contains", "text": "?"}
      ]
    }
```

- [ ] **Step 2: Rewrite `skills/grounding/SKILL.md`**

Full replacement content:

```markdown
---
name: grounding
description: A relentless one-question-at-a-time interview that holds a statement to whatever material is present — a source, retrieved notes, or nothing at all — until it's explicitly confirmed.
---

# Grounding

Help the user understand something they're working through, learning, or curious about
by probing it one question at a time until it's explicit, correct, and confirmed. Never
state it for them — draw only from what they actually said. Ask exactly one substantive
question per turn — never batch, never present a checklist.

## Fidelity

Material arrives already handed to you — a source's text, notes someone else retrieved,
or nothing. Whichever is present decides who gets held to it. These can apply together,
not just one at a time:

- **A source is present** → hold the user to it. If their statement drifts into their
  own opinion, push back:
  > "is that what the source says, or is that your own read?"
- **Retrieved notes are present** → hold yourself to them. Never fill a gap from general
  knowledge — if sharpening the statement needs something no retrieved note contains,
  say so rather than inventing it.
- **Neither is present** → say so plainly and continue anyway. An ungrounded hunch is a
  valid, complete outcome — not a failure state.
- **The source contradicts itself** → surface both sides directly rather than silently
  picking a reading:
  > "the source says X in one place and Y in another — which is it holding to?"
- **Retrieved notes disagree with the source** → the source wins outright; notes are a
  gap-filling reference, not a co-equal authority. Don't argue the disagreement out
  mid-interview — it's a candidate for **Noticing a tension** below, surfaced only after
  the gate passes like any other tension.

If the source or retrieved notes already say something, read it — don't ask the user to
repeat what's already there.

## Never your own opinion

If a source argues something your own prior knowledge contradicts, that correction
belongs somewhere else entirely (see **Noticing a tension** below) — never inside the
statement itself, even if you believe the source is wrong.

## Probing

When the working statement has more than one gap, pick the question by naming the gap
first — don't reach for whichever question feels natural. Three named patterns, each
tied to a specific missing thing:

- **Mechanism probe** — the statement asserts a claim without the underlying cause or
  process. "You noted [claim], but what's the mechanism that causes it?"
- **Boundary probe** — the statement generalizes or asserts something absolute. "Under
  what conditions would [claim] fail to hold?"
- **Distinction probe** — the statement uses squishy or overlapping terminology.
  "How are you distinguishing [A] from [B] here?"

If none of the three fit the actual gap, ask the specific question the gap calls for —
these three are the common cases, not an exhaustive menu to force a fit into.

## Gate

The statement is fixed only when the caller explicitly confirms it — and getting there
requires two things, not one:

- **A precondition on ever showing a draft**: never present a finished statement for
  confirmation until at least one open probe-and-answer round has already produced real
  content from the user. If the first thing shown in a session is a polished draft, that
  is a Gate failure by construction — go back and probe first.
- **The confirmation question itself stays open**, never binary. Present the draft as
  "here's what I have so far, based on what you said — what's missing or wrong?" not
  "does this capture it, yes or no?" A genuine "yes, exactly" still closes the gate; the
  question just never invites a reflexive rubber-stamp.

**Fixes it**: "yes, that's it," "fixed," or equivalent — an explicit, unambiguous signal,
after the precondition above has been met.

**Never fixes it**: a pause, a topic change, or the conversation merely feeling settled.
Before treating the gate as passed, confirm the user has either produced the statement's
content themselves or meaningfully revised wording you introduced — agreement alone,
without either, isn't enough. Probe once more if it isn't.

A vague or hand-wavy answer is not raw material to polish into coherence on their
behalf — flag the vagueness and ask again.

## Noticing a tension

While grounding, you may notice something in real tension with the material — your own
prior knowledge pulling against what the source argues, or anything else that doesn't
belong in the statement itself. Don't act on it, and don't let it leak into the
statement. Once the gate has passed, ask once — surfacing at most one, the tension most
likely to matter later, and dropping the rest silently if several came up:

> "while grounding this, I noticed [X] — want this flagged for later, or skip it?"

Never manufacture a tension to fill this slot; only surface one you actually noticed.

## Done

Hand back at most two things, nothing else:

- the confirmed statement, verbatim
- only if the user opted in above, a short description of the flagged tension

No filename, no format, no note-type label, no database write of any kind — all of that
belongs to whichever skill invoked this one.
```

- [ ] **Step 3: Verify the eval JSON is still valid**

Run: `python3 -c "import json; json.load(open('tests/grounding/evals.json'))"`
Expected: no output, exit 0.

- [ ] **Step 4: Commit**

```bash
git add skills/grounding/SKILL.md tests/grounding/evals.json
git commit -m "feat: add probing taxonomy and harden grounding's confirmation gate"
```

---

## Task 6: Add an exit card to `ground-me/SKILL.md`

**Files:**
- Modify: `skills/ground-me/SKILL.md`
- Modify: `tests/ground-me/evals.json`

**Interfaces:**
- Consumes: `grounding`'s `Done` contract (Task 5) — exactly one confirmed statement, at most one flagged tension.
- Produces: nothing consumed by later tasks — `ground-me` is a leaf, no sibling depends on its output shape.

- [ ] **Step 1: Add a new eval case for the exit card**

Append to `tests/ground-me/evals.json`'s `test_cases` array:

```json
    {
      "prompt": "ground me on: does spaced repetition actually generalize past rote memorization? — and I flagged a tension about it partway through",
      "expected_output": "After the /grounding session confirms, presents a plain closing card: a 'Crystalized Thought' heading, a bold 'Core Thesis' label with the confirmed statement in a blockquote, a 'Flagged for later' line with the tension description, and a closing line asking whether to explore the tension further, move to something else, or call it done. No emoji anywhere in the output.",
      "assertions": [
        {"type": "contains", "text": "Core Thesis"},
        {"type": "contains", "text": "Flagged for later"},
        {"type": "not_contains", "text": "🎯"}
      ]
    }
```

- [ ] **Step 2: Rewrite `skills/ground-me/SKILL.md`**

Full replacement content:

```markdown
---
name: ground-me
description: A bare, freeform grounding session — no note-type commitment, no sibling
  routing.
disable-model-invocation: true
---

# Ground-me

Run a /grounding session on whatever the user gave — an idea, notes, a source, an
article, anything. If nothing was given, ask what they want to work through.

## Done

Once /grounding confirms, present a plain closing card — no emoji, no invented fields
beyond what /grounding actually hands back (one confirmed statement, at most one flagged
tension):

```
Crystalized Thought

**Core Thesis:**
> [the confirmed statement, verbatim]

**Flagged for later:** [the tension description, only if one was flagged]

---
Want to explore that further, move to something else, or call it done here?
```

Omit the "Flagged for later" line entirely if no tension was flagged — never an empty
placeholder.
```

- [ ] **Step 3: Verify the eval JSON is still valid**

Run: `python3 -c "import json; json.load(open('tests/ground-me/evals.json'))"`
Expected: no output, exit 0.

- [ ] **Step 4: Commit**

```bash
git add skills/ground-me/SKILL.md tests/ground-me/evals.json
git commit -m "feat: give ground-me a defined, plain-text exit card"
```

---

## Task 7: Update `write-checks/SKILL.md` — rename `idea-db`→`slipbox`, add lazy field_map fallback

**Files:**
- Modify: `skills/write-checks/SKILL.md`
- Create: `tests/write-checks/evals.json` (didn't exist before this task)

**Interfaces:**
- Consumes: `config.schema.json`'s `{"deferred": true}` field_map form and `prefixes` object (Task 4).
- Produces: the "Frontmatter fields" resolution (including the new deferred fallback) that Tasks 9, 11, 12 all invoke via "Run a /write-checks session."

- [ ] **Step 1: Write the new eval file**

```json
{
  "test_cases": [
    {
      "prompt": "write-checks on a term-note draft, field list [type, created, sources], where config.json's frontmatter.term.sources is {\"deferred\": true}",
      "expected_output": "Detects the deferred marker for sources, runs the same interactive resolution logic setup-slipbox's field_map step would have run (checks whether an existing property already holds this data, asks the user to map onto it or create a new List property), writes the resolved mapping back into config.json's frontmatter.term.sources, then proceeds with formatting and zone placement using the newly-resolved mapping.",
      "assertions": [
        {"type": "contains", "text": "?"}
      ]
    },
    {
      "prompt": "write-checks on a literature-note draft, field list [type, created, source], where config.json's frontmatter.literature.source is already a fully-resolved mapping object",
      "expected_output": "Skips the interactive resolution entirely since the field is already resolved, and proceeds directly to formatting and zone placement.",
      "assertions": [
        {"type": "not_contains", "text": "map onto"}
      ]
    },
    {
      "prompt": "write-checks in checks-only mode (no field list) on an extending term note",
      "expected_output": "Runs Style and Humanize only, skipping Frontmatter fields and Zone placement entirely — hands back a pass/revise signal alone, no resolved-field data.",
      "assertions": [
        {"type": "not_contains", "text": "zone"}
      ]
    }
  ]
}
```

- [ ] **Step 2: Rewrite `skills/write-checks/SKILL.md`**

Full replacement content:

```markdown
---
name: write-checks
description: Check a note draft against the vault's own style and humanize checklist, and resolve its frontmatter fields against config.json's field_map — use when another skill in the slipbox family is about to write a note to disk.
license: MIT
metadata:
  version: "1.0.0"
---

# Write-checks

## Prerequisite

Requires `.slipbox/config.json`, `.slipbox/style-profile.json`, and
`.slipbox/humanize-checklist.json` — all produced by `setup-slipbox`. If any is missing, stop and say so.

## Style

Read `.slipbox/style-profile.json` as the user's stated note-shape and editing preference contract. Follow its sentence shape, configured note-type tone, formatting, vocabulary, and editing preferences. Do not infer or mimic a corpus voice, and do not use the profile as a humanizer detection baseline.

## Humanize

Run the checklist's `detection.mechanical` section through
`.slipbox/bin/slipbox humanize check <draft-path>`. When the draft or passage language is known,
pass `--language LANG` so language-scoped signals skip non-English passages; without
the override, the CLI uses the profile's configured languages. It never reads profile
baselines and never dual-reads `stated_style.json`. Apply `detection.judgment` with
reading comprehension. Respect each signal's `single` or `cluster` policy, and keep
judgment signals out of CLI cross-signal counting.

If detection or judgment surfaces a flag, execute the checklist's declared
`rewrite` phase before writing: rewrite rather than delete, preserve meaning, and follow
the stated profile through `workflow.preference_context`. Then execute the required
`audit` phase and revise again if the audit finds a remaining pattern. The checklist
guides the workflow; it never rewrites a file automatically.

## Invocation modes

Called with a field list, `write-checks` runs Style, Humanize, Frontmatter fields, and
Zone placement — the full pass below. Called with no field list (already-resolved
fields, e.g. a term extension re-using its first write's mapping), it runs Style and
Humanize only, skipping Frontmatter fields and Zone placement entirely.

## Frontmatter fields

Given a note type and its field list (e.g. literature: `type`, `created`, `source`),
resolve each field through `.slipbox/config.json`'s `frontmatter.<type>` map:

- **Already resolved** (a bare string, `false`, or a full `{name, type, wikilink, zone}`
  object) — write under the mapped property, the standard name if new, or skip if
  `false`. No interactive step; this is the common case for every field `setup-slipbox`
  already resolved upfront.
- **Deferred** (`{"deferred": true}`) — this is the first time this note type is being
  written. Run the same interactive resolution `setup-slipbox`'s own field_map step
  would run: check whether an existing user property already holds this field's data
  (reading its actual discovered type — Text/List/Number/Checkbox/Date/Date & Time —
  never assuming one), and resolve one of map-onto-existing, create-standard-field, or
  explicit opt-out, following the same reserved-property guardrail (never `tags`,
  `aliases`, `cssclasses`, except Term's `alt_names`→`aliases` carve-out) and the same
  type-mismatch check for multi-valued fields (`sources`, `derived-from`) that
  `setup-slipbox` uses. Write the resolved mapping back into `.slipbox/config.json`'s
  `frontmatter.<type>.<field>` before continuing — every subsequent write for this note
  type finds it already resolved and skips this branch entirely.

The field's own name is never the mapping. Format the value per the entry's recorded
`type` (a `list` type is a YAML array, a `date`/`datetime` type is `YYYY-MM-DD` or a full
timestamp), and wrap in wikilink or markdown-link syntax per the top-level
`links.style` when `wikilink: true`.

## Note-type prefix

Check `.slipbox/config.json`'s `prefixes.<type>` for this note type. If it's a string,
prepend it to the note's title (e.g. `§ Design Tokens`, not `Design Tokens`). If it's
`false`, the title stays unprefixed. Never touch `resources/` — no prefix key exists for
that type.

## Zone placement

Zone only places newly-created fields — a mapped-onto-existing field stays put. New
`top` fields sit right after the opening `---`; new `bottom` fields sit right before
the closing `---`.

## Done

Hand back: a pass/revise signal for style and humanize (revise before writing if
either flags a cluster), plus — on the full pass only — each resolved field's final
property name, formatted value, and placement (already-positioned, or the zone it
belongs in), and the resolved title prefix (or none), so the calling skill never
re-derives field_map, zone, or prefix logic itself. The checks-only mode hands back the
pass/revise signal alone.
```

- [ ] **Step 3: Verify both JSON files are valid**

Run: `python3 -c "import json; json.load(open('tests/write-checks/evals.json'))"`
Expected: no output, exit 0.

- [ ] **Step 4: Commit**

```bash
git add skills/write-checks/SKILL.md tests/write-checks/evals.json
git commit -m "feat: write-checks gains lazy field_map fallback, note-type prefix; renames idea-db to slipbox"
```

---

## Task 8: Rewrite `ground-claim/SKILL.md` — direct capture, surface pass, multi-claim Q/E/C loop

**Files:**
- Modify: `skills/ground-claim/SKILL.md`
- Modify: `tests/ground-claim/evals.json`
- Modify: `docs/ground-claim.md`

**Interfaces:**
- Consumes: `grounding`'s hardened Gate/probing (Task 5), `write-checks`' Frontmatter-fields/prefix resolution (Task 7).
- Produces: the multi-claim literature-note shape (`## Key Claims` with Q/E/C bullets, `## Key Concepts`) that `find-terms` (Task 10) scans for term-recurrence detection — that task depends on this file's write shape existing.

- [ ] **Step 1: Rewrite `tests/ground-claim/evals.json`**

The old `sql_query` assertions no longer apply — nothing in this pipeline touches SQL anymore. Full replacement content:

```json
{
  "test_cases": [
    {
      "prompt": "ground-claim on resources/2026-08-08-design-tokens.md, a freshly clipped source with no literature note yet",
      "expected_output": "Reads the whole source, surfaces a list of candidate claims worth grounding (e.g. 'this source seems to argue: A, B, C — which do you want grounded, or is there something I missed?'), lets the user pick a subset or add their own, then runs one independent /grounding call per selected claim, writing each confirmed Q/E/C claim to the literature note incrementally as it's confirmed — not batched at the end.",
      "assertions": [
        {"type": "contains", "text": "?"},
        {"type": "not_contains", "text": "surface-ideas"}
      ]
    },
    {
      "prompt": "ground-claim on resources/2026-08-08-design-tokens.md, where the literature note already has one confirmed claim from a prior session",
      "expected_output": "Reads the existing literature note's ### claim headings first, and only offers candidates not already covered — does not re-surface the already-grounded claim.",
      "assertions": [
        {"type": "contains", "text": "?"}
      ]
    },
    {
      "prompt": "ground-claim on a candidate whose derived filename already exists on disk with unrelated content",
      "expected_output": "Stops and asks the user to reword the claim or confirm a genuine duplicate, rather than auto-disambiguating the filename.",
      "assertions": [
        {"type": "contains", "text": "?"}
      ]
    }
  ]
}
```

- [ ] **Step 2: Rewrite `skills/ground-claim/SKILL.md`**

Full replacement content:

```markdown
---
name: ground-claim
description: Ground a clipped source into one or more Claims — the source's own
  position, restated in the user's own words and checked against the source — writing
  each as a Key Claim in a shared literature note for that source.
disable-model-invocation: true
license: MIT
metadata:
  version: "1.0.0"
---

# Ground-claim

## What these words mean

- **Claim** — the source's own position on one specific question the source answers,
  restated in the user's words and checked for fidelity. Never the user's opinion — an
  object of understanding, not agreement. A source usually holds several.
- **Literature note** — the file a source's confirmed Claims get written into. One per
  source clip, holding as many Key Claims as the source actually supports — written
  incrementally as each is confirmed, never revisited afterward once written except
  out-of-band manual fidelity corrections: fixing a misreading, a transcription error,
  or wording that misrepresents the source. Reaction, stance, or synthesis never enters;
  a correction must move the note closer to the source. Slugs stay final once written.

## Prerequisite

Requires `.slipbox/config.json` — same as every skill in this family. If it's missing,
stop and say so. Same check for `.slipbox/bin/slipbox` — if it doesn't exist or isn't
executable, stop and say so too. Every `slipbox` call below uses this same path,
`.slipbox/bin/slipbox` — never bare `slipbox`, which isn't guaranteed to be on `PATH`.

## Take the source

Direct capture only — no candidate backlog to pull from. Take the resource the user
names, or the one just clipped by `/clip-resource`.

Check whether a literature note for this source already exists: scan `/literature/*.md`
frontmatter for a note whose `source` field points at this resource.

- **No note exists yet** — this source hasn't been grounded at all. Proceed to the
  surface pass below with a fresh candidate list.
- **A note already exists** — read it in full. Its existing `## Key Claims` `###`
  headings are claims already confirmed; the surface pass below must not re-offer them.

## Surface pass

Read the whole source yourself — this is your own judgment, not a `/grounding` call;
`/grounding` was never built for open-ended "what does this cover" scanning, only for
probing something already anchored. Identify every distinct claim the source actually
supports, skipping anything an existing literature note (per Take the source above)
already covers.

Present the list to the user before grounding anything:

> "This source is talking about these: [list]. Which do you want grounded — or is there
> something I missed?"

The user can pick any subset, all of them, or name a claim you didn't surface. This
candidate list is session-scoped only — nothing gets written to disk from this step, and
it's discarded once the session ends regardless of how many claims got picked.

## Ground each selected claim

For every claim the user picked (in the order they picked, one at a time), run a fully
independent `/grounding` session — no shared state between calls, no memory of a
previous claim in this same sitting. Hold the user to the source. If a term comes up
mid-session that already has (or could start) its own Term note, propose linking it with
a one-line reason — the user accepts or rejects each one individually, never linked
silently.

`/grounding` hands back the confirmed Claim as a Question/Evidence/Conclusion triplet,
and — only if the user opted in — a flagged tension. If a tension came back, insert it
into the evergreen backlog before moving on to writing this claim:

```bash
.slipbox/bin/slipbox evergreen add --slug <draft-slug> --reason "<tension description>"
```

## Write each claim, incrementally

As soon as one claim is confirmed — before starting the next one, if there is a next
one:

- Run a `/write-checks` session on the draft, passing the literature field list
  (`type`, `created`, `source`) — it resolves each field's mapping, formatting, zone
  placement, and title prefix, and checks the draft's style and humanize signals.
- Filename per `.slipbox/config.json`'s casing convention for the literature type. The
  title is source/topic-oriented (what the source is about), never claim-shaped — it
  doesn't change as more claims get added.
- Re-read the target path from disk right before writing (the note may already hold
  earlier claims from this same session, or from a prior one).
- Assemble the claim as its own `###`-headed entry under `## Key Claims`:

```markdown
### [short name for this claim]
- **Question:** [the question this claim answers]
- **Evidence:** [paraphrased evidence, or a quote — see below]
- **Conclusion:** [the confirmed Claim, in the user's own words]
```

  If any evidence is a direct quote (earns its place only when the exact wording
  carries something paraphrase would lose — a definition, a phrase later discussion
  refers back to), place it after the bullet list, still under this same `###` heading,
  never nested inside the Evidence bullet:

  ```markdown
  > [the quoted text]
  [[Author Name]] #quote
  ```

  `[[Author Name]]` is a bare, intentionally-unresolved wikilink — no author-note entity
  exists in this family.

- Add or extend `## Key Concepts` with a wikilinked, 1-line gloss for any term this
  claim introduces or leans on: `- [[term/<slug>|Term Name]]: [what this source says
  about it, in one line]`. This section is load-bearing — `find-terms` scans it for
  term-recurrence detection, so every term the claim actually uses must appear here.
- Filename collision on the note's first claim → stop and ask, never auto-disambiguate.
  On a second or later claim for an existing note, the existing file is expected, not a
  collision.

Repeat for the next selected claim, if any — a fresh `/grounding` call, then this same
write step, until every selected claim is written.

## Done

The literature note exists on disk with every selected claim as its own `## Key Claims`
entry (partial if the session stopped early — that's a complete, valid outcome, not a
failure), any flagged tensions are logged in the evergreen backlog, and the user is told
the file path.
```

- [ ] **Step 3: Rewrite `docs/ground-claim.md`**

Full replacement content:

```markdown
# ground-claim

Ground a clipped source into one or more Claims — the source's own position, restated in
your own words and checked against the source — writing each as a Key Claim in a shared
literature note for that source.

## When to use

Run this directly on a clipped source — no `surface-ideas` step required. It reads the
whole source, surfaces the claims it actually supports, lets you pick which to ground,
then runs a grounding interview per claim and writes each one to the literature note as
soon as it's confirmed.

If the note already has claims from a prior session, it only offers what's left.

## How it works

1. **Take the source** — direct capture, checked against existing literature notes'
   `source` field to see if this source has already been (partially) grounded.
2. **Surface pass** — reads the source, proposes a candidate list of claims, lets you
   pick a subset, all of them, or add your own.
3. **Ground each selected claim** — a fully independent `/grounding` session per claim,
   holding you to the source.
4. **Write each claim, incrementally** — each confirmed claim lands on disk as its own
   Question/Evidence/Conclusion entry the moment it's confirmed, not batched at the end.
   A filename collision on the note's first claim stops and asks rather than
   auto-disambiguating.

## Usage

> Ground claims from [source], or just: ground-claim

## Installation

```bash
npx skills add andarwaly/slipbox
```

See the [skill source](../../skills/slipbox/ground-claim/) for the full agent-facing
instructions.
```

- [ ] **Step 4: Verify the eval JSON is valid**

Run: `python3 -c "import json; json.load(open('tests/ground-claim/evals.json'))"`
Expected: no output, exit 0.

- [ ] **Step 5: Commit**

```bash
git add skills/ground-claim/SKILL.md tests/ground-claim/evals.json docs/ground-claim.md
git commit -m "feat: rewrite ground-claim for direct capture and multi-claim Q/E/C notes"
```

---

## Task 9: Retire `surface-ideas`; create `find-terms` and `find-connections`

**Files:**
- Delete: `skills/surface-ideas/` (entire directory), `docs/surface-ideas.md`, `tests/surface-ideas/evals.json`
- Create: `skills/find-terms/SKILL.md`, `docs/find-terms.md`, `tests/find-terms/evals.json`
- Create: `skills/find-connections/SKILL.md`, `docs/find-connections.md`, `tests/find-connections/evals.json`

**Interfaces:**
- Consumes: `ground-claim`'s literature-note write shape (Task 8) — both new skills scan `## Key Claims`/`## Key Concepts` sections that task produces.
- Produces: nothing consumed by later tasks in this plan — both are leaves. `find-connections` calls `.slipbox/bin/slipbox links find/add` (Task 2) and writes into the evergreen backlog (same mechanism Task 8 uses).

- [ ] **Step 1: Delete `surface-ideas` entirely**

```bash
git rm -r skills/surface-ideas docs/surface-ideas.md tests/surface-ideas/evals.json
```

- [ ] **Step 2: Write `tests/find-terms/evals.json`**

```json
{
  "test_cases": [
    {
      "prompt": "find-terms across the vault",
      "expected_output": "Scans every literature note's ## Key Concepts wikilinks, counts how many distinct literature notes link each [[term/<slug>]], and reports which terms cross the recurrence threshold but have no term/<slug>.md file yet. Writes nothing to disk — pure read/report.",
      "assertions": [
        {"type": "not_contains", "text": "wrote"}
      ]
    },
    {
      "prompt": "find-terms in a vault where every wikilinked term already has its own term note",
      "expected_output": "Reports that nothing crosses the recurrence-without-a-note threshold — a null result is a complete, valid outcome, not a failure.",
      "assertions": [
        {"type": "not_contains", "text": "error"}
      ]
    }
  ]
}
```

- [ ] **Step 3: Write `skills/find-terms/SKILL.md`**

```markdown
---
name: find-terms
description: Report which terms recur across literature notes' Key Concepts sections but don't have their own Term note yet. Pure read/report — writes nothing to disk.
disable-model-invocation: true
license: MIT
metadata:
  version: "1.0.0"
---

# Find-terms

Read-only. This skill never writes anything — not a note, not a backlog entry, not a
database row. If the user wants to act on what it reports, they invoke `ground-term`
themselves, right after seeing the report.

## Scan

Read every literature note's `## Key Concepts` section. Each entry wikilinks a term
(`[[term/<slug>|Term Name]]`) with a 1-line gloss of what that specific source said
about it. For every distinct `[[term/<slug>]]` target, count how many different
literature notes link to it.

## Report

For each term where the link count crosses a recurrence threshold (two or more distinct
literature notes) and `term/<slug>.md` does not already exist on disk, list it — the
term name, the count, and which literature notes mention it. Terms already backed by an
existing term note are not reported, regardless of recurrence count; nothing here checks
whether an existing term note needs extending, only whether one needs creating.

Zero terms crossing the threshold is a complete, valid result — report it as such, not as
an error or an empty failure.

## Done

The user has seen the report. Nothing was written. If they want to act on any of it,
they run `/ground-term` themselves, naming the term directly.
```

- [ ] **Step 4: Write `docs/find-terms.md`**

```markdown
# find-terms

Report which terms recur across literature notes' Key Concepts sections but don't have
their own Term note yet.

## When to use

Run this whenever you want to check whether any recurring vocabulary across your
literature notes is worth its own Term note. It's read-only — nothing gets written,
recurrence is recomputed fresh every time from the notes themselves, so there's no
backlog to keep in sync.

## How it works

1. **Scan** — reads every literature note's `## Key Concepts` section, counting how many
   distinct notes wikilink each term.
2. **Report** — lists any term crossing the recurrence threshold (2+ literature notes)
   that has no `term/<slug>.md` file yet. A term already backed by a note is never
   reported, no matter how often it recurs.

## Usage

> Find terms worth grounding.

Then, for anything worth acting on:

> ground-term "the term name"

## Installation

```bash
npx skills add andarwaly/slipbox
```

See the [skill source](../../skills/slipbox/find-terms/) for the full agent-facing
instructions.
```

- [ ] **Step 5: Write `tests/find-connections/evals.json`**

```json
{
  "test_cases": [
    {
      "prompt": "find-connections across the vault",
      "expected_output": "Scans existing notes for two distinct outputs, presented separately: (a) mechanical link suggestions — two related but unlinked notes, presented as a batch for the user to approve/reject together, then written as both a links row and a [[wikilink]]; (b) sparked ideas — a genuinely new synthesis noticed between existing notes, not stated in either alone, routed into the evergreen candidate store for later ground-my-take grounding, never auto-written as a note itself.",
      "assertions": [
        {"type": "contains", "text": "?"}
      ]
    },
    {
      "prompt": "find-connections where two notes are related but already linked",
      "expected_output": "Does not re-suggest the existing link — checks .slipbox/bin/slipbox links find before proposing a candidate.",
      "assertions": [
        {"type": "not_contains", "text": "already linked"}
      ]
    }
  ]
}
```

- [ ] **Step 6: Write `skills/find-connections/SKILL.md`**

```markdown
---
name: find-connections
description: Scan existing notes for missing links and sparked ideas — splits mechanical link suggestions (batch-confirmed) from generative ideas (routed to the evergreen backlog).
disable-model-invocation: true
license: MIT
metadata:
  version: "1.0.0"
---

# Find-connections

## Prerequisite

Requires `.slipbox/config.json` and `.slipbox/bin/slipbox` — same as every skill in this
family. Every `slipbox` call below uses this same path, `.slipbox/bin/slipbox` — never
bare `slipbox`.

## Scan

Read across existing literature, term, and evergreen notes for two genuinely different
things — don't conflate them:

- **A link worth adding** — two notes are related but not yet wikilinked. Check
  `.slipbox/bin/slipbox links find --source <slug>` first; never re-suggest a pair that
  already has a `links` row.
- **A sparked idea** — noticing two or more existing notes together produces something
  neither one states alone. This is generative, not mechanical — it needs full
  `ground-my-take` grounding before it's a real Take, not a citation edit.

## Present link suggestions as a batch

Show every candidate link together, not one at a time — there's no dependency chain
between suggestions the way `/grounding`'s Socratic questions have, so reviewing them
together is strictly less friction than one full turn per candidate. The user approves,
rejects, or edits each one in one pass.

For each approved suggestion:

```bash
.slipbox/bin/slipbox links add --source <slug> --target <slug> --rel cites
```

Then add the matching `[[wikilink]]` in whichever note's prose the connection belongs
to, per the existing two-part criterion: it needs the `links` row above as a mechanical
baseline, and the specific sentence must actually assert something about the linked
note's subject, not just incidentally name it.

## Route sparked ideas to the evergreen backlog

For each sparked idea, insert it as its own candidate — never write a note directly, and
never fold it into a link suggestion:

```bash
.slipbox/bin/slipbox evergreen add --slug <draft-slug> --reason "<the spark, described>"
```

`ground-my-take` picks these up from its own backlog read, same as any other flagged
tension.

## Done

Every approved link is written (both the `links` row and, where the criterion is met,
the inline wikilink); every sparked idea is logged in the evergreen backlog, not written
as a note. The user is told what was added and what was routed to the backlog.
```

- [ ] **Step 7: Write `docs/find-connections.md`**

```markdown
# find-connections

Scan existing notes for missing links and sparked ideas — splits mechanical link
suggestions (batch-confirmed) from generative ideas (routed to the evergreen backlog).

## When to use

Run this whenever you want to sit down and see what your vault has been quietly building
toward — connections between existing notes that were never made explicit, or ideas that
only emerge when two notes are read together. This is a heavier, whole-corpus pass, not
something tied to any single capture.

## How it works

1. **Scan** — reads across literature/term/evergreen notes for two distinct things: link
   candidates (mechanical) and sparked ideas (generative).
2. **Link suggestions, presented as a batch** — every candidate shown together, approved
   or rejected in one pass, never one-at-a-time.
3. **Sparked ideas, routed to the evergreen backlog** — never written as a note
   directly; `ground-my-take` picks them up later.

## Usage

> Find connections in my vault.

## Installation

```bash
npx skills add andarwaly/slipbox
```

See the [skill source](../../skills/slipbox/find-connections/) for the full agent-facing
instructions.
```

- [ ] **Step 8: Verify both new eval files are valid JSON**

Run:
```bash
python3 -c "import json; json.load(open('tests/find-terms/evals.json'))"
python3 -c "import json; json.load(open('tests/find-connections/evals.json'))"
```
Expected: no output, exit 0 for both.

- [ ] **Step 9: Commit**

```bash
git add skills/find-terms skills/find-connections docs/find-terms.md docs/find-connections.md tests/find-terms/evals.json tests/find-connections/evals.json
git commit -m "feat: retire surface-ideas, add find-terms and find-connections"
```

---

## Task 10: Fix `ground-term/SKILL.md` — drop the dead backlog-pull path, rename `idea-db`→`slipbox`

**Files:**
- Modify: `skills/ground-term/SKILL.md`
- Modify: `tests/ground-term/evals.json`
- Modify: `docs/ground-term.md`

**Interfaces:**
- Consumes: `find-terms`' existence (Task 9) — this file's own prose now points there instead of a `seeds` query.
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Rewrite `tests/ground-term/evals.json`**

The old `sql_query` assertions targeted `seeds`, which no longer exists. Full replacement content:

```json
{
  "test_cases": [
    {
      "prompt": "ground-term \"confirmation bias\" — this term has never been recorded before",
      "expected_output": "Writes a fresh Term note through /write-checks, resolving the field_map for the term type (interactively, if it was deferred during setup) and the term-type prefix.",
      "assertions": [
        {"type": "contains", "text": "term"}
      ]
    },
    {
      "prompt": "ground-term \"confirmation bias\" again, from a second resource that also mentions it",
      "expected_output": "Folds the new resource's contribution into the existing file via /write-checks' checks-only mode (sources' mapping already resolved from the first write), appending to the sources frontmatter array rather than overwriting the file wholesale, and inserts a links row with rel_type='extends' pointing at the canonical term note.",
      "assertions": [
        {"type": "not_contains", "text": "seeds"}
      ]
    },
    {
      "prompt": "ground-term with no term named",
      "expected_output": "Asks the user which term they want grounded rather than guessing or pulling from any backlog — there is no backlog to pull from for literature-style term surfacing anymore; the user names it directly, whether on their own or because find-terms suggested it.",
      "assertions": [
        {"type": "contains", "text": "?"}
      ]
    }
  ]
}
```

- [ ] **Step 2: Rewrite `skills/ground-term/SKILL.md`**

Full replacement content:

```markdown
---
name: ground-term
description: Ground a term into a cumulative Term note — a running, per-term
  definition that may draw on multiple sources over separate sessions.
disable-model-invocation: true
license: MIT
metadata:
  version: "1.0.0"
---

# Ground-term

## What these words mean

- **Term** — a named concept, method, tool, or bias with a stable label, independent of
  any one source (e.g. "confirmation bias," "CRDT") — not a source's own argued
  organizing scheme.
- **Term note** — the cumulative file a term's definition lives in. Unlike a Claim,
  never one-shot: extended across however many sources touch this term, over however
  many separate sessions. Only ever appends or extends — never overwrites what's
  already there.

## Prerequisite

Requires `.slipbox/config.json` — same as every skill in this family. If it's missing,
stop and say so. Same check for `.slipbox/bin/slipbox` — if it doesn't exist or isn't
executable, stop and say so too. Every `slipbox` call below uses this same path,
`.slipbox/bin/slipbox` — never bare `slipbox`, which isn't guaranteed to be on `PATH`.

## Take the term

Named directly, only — the user says which term they want grounded, whether they
thought of it themselves or because `/find-terms` suggested it. There is no backlog to
pull from; term recurrence is derived on demand, not surfaced into a queue.

Per `.slipbox/config.json`'s filename/casing convention, check whether a Term note for
this term already exists before grounding:

- **New term** — no note exists. Proceed planning to create one.
- **Extending** — a note already exists. Read it in full now. You'll ground the
  discussion against it and fold the new resource into it later; the file's own
  accumulated text is the working summary of everything before it, not its historical
  resource list.

## Ground it

Run a /grounding session, holding the user to whichever source (or sources) this
particular mention of the term traces back to. If the term note already exists, treat
its current content as material too — the user's new answer must stay consistent with
what's already recorded, not contradict it silently.

/grounding hands back the confirmed definition, and — only if the user opted in — a
flagged tension. If a tension came back, insert it into the evergreen backlog before
moving on to writing:

```bash
.slipbox/bin/slipbox evergreen add --slug <draft-slug> --reason "<tension description>"
```

## Write — new term

Write fresh:

- Run a /write-checks session on the draft, passing the Term field list (`type`,
  `created`, `sources`, plus `alt_names` if any were given) — it resolves each field's
  mapping, formatting, zone placement, and title prefix, and checks the draft's style
  and humanize signals.
- Filename per `.slipbox/config.json`'s casing convention for the Term type.
- Re-read the target path from disk right before writing.
- Assemble the frontmatter from write-checks' returned fields and write the file.
- Filename collision → stop and ask, never auto-disambiguate.

## Write — extending an existing term

**This is the collision-safe path. Follow it exactly.**

`sources` already has its resolved mapping and formatting from the term's first write —
no field resolution needed here.

1. Run a /write-checks session on the draft in its checks-only mode (no field list).
2. Re-read the file from disk immediately before writing (state can have changed since
   the read in "Take the term").
3. Append the new resource to the `sources` frontmatter array, formatted per its
   existing recorded `type` (list) and `wikilink` flag, and write the file. Never
   overwrite the file wholesale.
4. Insert a `links` row recording the relationship — this term's own note is the target,
   the resource being folded in is the source:

   ```bash
   .slipbox/bin/slipbox links add --source <this-resource-slug> --target <term-note-slug> --rel extends
   ```

## Done

- New term: the file on disk reflects the confirmed definition.
- Extension: the file on disk reflects every resource that has ever fed it, old and
  new; a `links` row (`rel_type: 'extends'`) connects the new resource to the term note.
- Any flagged tension is logged in the evergreen backlog.
- The user is told the file path.
```

- [ ] **Step 3: Rewrite `docs/ground-term.md`**

Full replacement content:

```markdown
# ground-term

Ground a term into a cumulative Term note — a running, per-term definition that may
draw on multiple sources over separate sessions.

## When to use

Run this whenever you (or `find-terms`) name a term worth its own note. There's no
backlog to check first — you name the term directly, every time.

## How it works

1. **Take the term** — named directly, checked against existing term notes to see if
   this is a new term or an extension.
2. **Ground it** — a `/grounding` session, holding you to whichever source backs this
   particular mention.
3. **Write** — a fresh term note on first occurrence, or an in-place extension
   (append-only, never overwritten wholesale) on repeat mentions, with a typed `links`
   edge connecting the two.

## Usage

> ground-term "confirmation bias"

## Installation

```bash
npx skills add andarwaly/slipbox
```

See the [skill source](../../skills/slipbox/ground-term/) for the full agent-facing
instructions.
```

- [ ] **Step 4: Verify the eval JSON is valid**

Run: `python3 -c "import json; json.load(open('tests/ground-term/evals.json'))"`
Expected: no output, exit 0.

- [ ] **Step 5: Commit**

```bash
git add skills/ground-term/SKILL.md tests/ground-term/evals.json docs/ground-term.md
git commit -m "fix: drop ground-term's dead backlog-pull path, rename idea-db to slipbox"
```

---

## Task 11: Rename `idea-db`→`slipbox` in `ground-my-take/SKILL.md`

**Files:**
- Modify: `skills/ground-my-take/SKILL.md`
- Modify: `docs/ground-my-take.md`

**Interfaces:**
- Consumes: nothing new — this is a pure rename, no behavior change (confirmed during the grilling session: `ground-my-take` needs no functional change from this refactor).

- [ ] **Step 1: Replace every `.slipbox/bin/idea-db` with `.slipbox/bin/slipbox` in `skills/ground-my-take/SKILL.md`**

Five occurrences, each a bare path substitution — no other text changes:

```bash
sed -i '' 's|\.slipbox/bin/idea-db|.slipbox/bin/slipbox|g' skills/ground-my-take/SKILL.md
```

Verify the substitution caught every instance:

```bash
grep -n "idea-db" skills/ground-my-take/SKILL.md
```

Expected: no output.

- [ ] **Step 2: Replace every `idea-db` reference in `docs/ground-my-take.md`**

Read the file first — it doesn't currently name `idea-db` explicitly in the prose shown earlier in this plan's file reads, but re-check directly:

```bash
grep -n "idea-db" docs/ground-my-take.md
```

If any hits appear, replace them with `slipbox` the same way. If none, this step is a no-op — confirm and move on.

- [ ] **Step 3: Commit**

```bash
git add skills/ground-my-take/SKILL.md docs/ground-my-take.md
git commit -m "chore: rename idea-db to slipbox in ground-my-take"
```

---

## Task 12: Update `setup-slipbox/SKILL.md` — drop SQLite prereq, hybrid field_map defer, drift check, rename

**Files:**
- Modify: `skills/setup-slipbox/SKILL.md`
- Modify: `docs/setup-slipbox.md`
- Modify: `tests/setup-slipbox/evals.json`

**Interfaces:**
- Consumes: `slipbox` CLI (Task 2), `config.schema.json`'s `prefixes`/deferred field_map (Task 4), `write-checks`' lazy fallback (Task 7).
- Produces: `.slipbox/bin/slipbox`, `.slipbox/evergreen/`, `.slipbox/links.jsonl`, `.slipbox/config.json` (with `prefixes` and possibly-deferred `frontmatter` entries) — every other skill in this family checks for these at its own prerequisite step.

- [ ] **Step 1: Update `tests/setup-slipbox/evals.json`**

Replace the `idea.db` file-existence assertion and the `sqlite3`-stops-everything case; the CLI no longer needs SQLite and there's no `idea.db` file to check for. Full replacement content:

```json
{
  "test_cases": [
    {
      "prompt": "Set up slipbox in my vault for the first time.",
      "expected_output": "Runs the explore step, walks through Section A conventions one item at a time proposing defaults (including a combined question on which note types to resolve field_map for now versus defer), interviews the user for the stated note-preferences profile, copies the humanizer workflow snapshot, installs the slipbox CLI and initializes its evergreen directory and links log, and shows a draft config.json for approval before writing.",
      "assertions": [
        {"type": "file_exists", "path": ".slipbox/bin/slipbox"},
        {"type": "file_exists", "path": ".slipbox/config.json"},
        {"type": "file_exists", "path": ".slipbox/style-profile.json"},
        {"type": "file_exists", "path": ".slipbox/humanize-checklist.json"}
      ]
    },
    {
      "prompt": "youtube-transcript-api is not installed, set up slipbox anyway.",
      "expected_output": "Stops before writing anything, tells the user youtube-transcript-api is required for clipping video transcripts, and offers to pip install it or asks the user to install it themselves — never proceeds or auto-installs without asking.",
      "assertions": [
        {"type": "contains", "text": "youtube-transcript-api"},
        {"type": "not_contains", "text": "installed automatically without confirmation"}
      ]
    },
    {
      "prompt": "I already ran setup-slipbox once, my vault's filename convention changed from kebab-case to Title Case since then. Re-run setup.",
      "expected_output": "Re-discovers conventions, diffs against the existing config.json, reports the specific mismatch (kebab-case vs Title Case), and asks the user which side wins — does not silently overwrite, does not re-ask every question from scratch, does not touch existing evergreen candidates or notes.",
      "assertions": [
        {"type": "contains", "text": "mismatch"},
        {"type": "not_contains", "text": "idea.db"}
      ]
    },
    {
      "prompt": "Re-run setup-slipbox — one of my term note's sources property changed type from List to Text since last setup.",
      "expected_output": "The field_map drift check catches the type mismatch, reports it by field name and both values, and asks the user which side wins — re-resolve to a new List property, or override and accept the mismatch.",
      "assertions": [
        {"type": "contains", "text": "sources"}
      ]
    }
  ]
}
```

- [ ] **Step 2: Rewrite `skills/setup-slipbox/SKILL.md`**

Full replacement content:

```markdown
---
name: setup-slipbox
description: One-time onboarding for the slipbox skill family — discovers vault conventions, writing style, and clip preferences; installs the slipbox CLI. Run once per vault; re-run only to change conventions.
disable-model-invocation: true
license: MIT
metadata:
  version: "1.0.0"
---

# Setup Slipbox

Every other skill in this family reads `.slipbox/config.json` before it writes anything, and fails fast with "run setup-slipbox first" if it's absent. This skill produces `config.json` plus the `.slipbox/bin/slipbox` CLI, `style-profile.json`, and `humanize-checklist.json` through the steps below: prerequisite check, explore, Section A (conventions + clip config), Section B (stated note preferences), humanizer workflow snapshot, CLI install, config write. Three of those outputs are built from fixed assets rather than composed fresh each run: `assets/config.schema.json`, `assets/humanize-checklist.json`, and `assets/style-profile.schema.json`. Re-running this skill on different vaults produces structurally consistent files, not just similarly-worded ones. `config.json` can also be edited after this first setup without re-running the whole interview, via the `slipbox config get`/`slipbox config set` CLI (see Done).

## Prerequisites

This is the only place in the slipbox family that installs anything — every other skill that hits a missing dependency stops and points back here rather than installing it inline.

Run `scripts/check-prereqs.sh` and read its report. It checks `youtube_transcript_api` importability and `defuddle` resolvability via `npx` — no database dependency exists anymore, so `sqlite3` is not checked. The video-transcript check can be skipped entirely if the user has already said they have no interest in clipping video; otherwise check both by default.

For each dependency the report marks missing: stop, tell the user what it's needed for (`youtube-transcript-api` for `clip-resource`'s Video path; `defuddle` for `clip-resource`'s Article and News path), and ask explicitly before doing anything about it — never install without that per-dependency ask. If the user agrees, run `scripts/install-prereqs.sh <dependency>` for just that one dependency. If they'd rather install it themselves, tell them to re-run this skill once it's in place.

**Done when:** every dependency the report flagged has been either installed, explicitly deferred by the user, or the user has said they'll handle it themselves.

## Explore (no questions yet)

Check the vault for existing signal before asking the user anything:

- `.obsidian/` for a `templates/` folder and Templater plugin config (`.obsidian/plugins/templater-obsidian`), which show the vault's real template location and syntax.
- Root `AGENTS.md` or `CLAUDE.md` for conventions the user already wrote down.
- Existing `Literature`/`Term`/`Evergreen` (or similarly named) folders — these are both a convention signal and a style corpus for Section B.
- Whatever `tags` actually seems to be used for in this vault — note it in plain language for Section A's presentation (e.g. subtype-marker, topic/subject labels, a catch-all, a minimal signal, some mixture, or not used at all). This is descriptive narration only, never a mapping decision, and never forced into a fixed category list — real vaults don't fit a clean taxonomy, so describe what's actually observed. `tags` itself is never mapped onto or written to by any field_map resolution, regardless of what this narration finds.
- An existing `.slipbox/` directory. Its presence branches three ways, not two:
  - `.slipbox/config.json` exists → this is a re-run; switch to the drift-check flow in Re-run semantics.
  - `.slipbox/` exists but `config.json` does not → an interrupted prior run. Check individually for `.slipbox/evergreen/`, `style-profile.json`, and `humanize-checklist.json` — don't assume any one's presence alone tells you how far the prior run got. Tell the user setup was interrupted before completion, then **resume with a clean restart of Sections A/B below** (this and the first-run path are identical from here — there is no partial-answer persistence to resume from, and no existing `config.json` to diff against, so the drift-check mechanics don't apply). Never delete or overwrite whatever partial artifacts already exist until their step is reached normally.
  - No `.slipbox/` at all → first run, proceed below.

**Done when:** you know, for each check above, whether it found something or came up empty, and which of the three branches above applies.

## Section A: conventions

Present what you found, one item at a time. Recommend a default and lead with it — e.g. "No filename convention found. I recommend kebab-case (`my-note-title.md`): sound right, or do you use something else?" Silence is not confirmation; wait for an explicit answer per item before moving to the next.

- **Paths**: `resources/`, `literature/`, `evergreen/`, and the term notes' folder.
- **Filename casing** per note type (kebab-case, Title Case, snake_case, or whatever the vault already does).
- **Note-type prefixes**: ask once, for all three note types together — "Want a symbol prefix on note titles, so they're distinguishable at a glance even if they all end up in the same folder? Default: `§` for literature, `※` for term, `✱` for evergreen. Keep these, pick your own, or skip prefixes entirely?" Record per-type: a string, or `false` for no prefix. Resources never get a prefix — no question asked for that type.
- **Templates**: three note templates (literature, term, evergreen) plus four resource templates (article, news, social, video) — seven total, each with its own explicit path. These are real Obsidian template files: the core Templates plugin's default location, or Templater's if the user already has it configured. Do not invent a separate agent-native template spec.
  - **The three note templates almost always already exist** — resolve their path and move on, same as any other convention item.
  - **The four resource templates usually don't** — the templates *folder* typically exists (from note-taking), but article/news/social/video `.md` files inside it typically don't, since clipping is a newer concept for most vaults than note-taking. For each one that's missing at its resolved path, offer to draft it together right there rather than asking the user to go write Obsidian template syntax cold:
    1. Tell them which variables apply to this content type and what each does, in plain language — pull this from `../clip-resource/references/variable-glossary.md` and `../clip-resource/references/filter-glossary.md`, but never point the user at those files directly; you are the interface to that reference, not a librarian handing over a card catalog.
    2. Ask what they want captured in the note and in what order (title, source link, a raw excerpt, a synthesized summary, etc.).
    3. As you propose each variable, explain bare vs. quoted inline, concretely: "`{{content}}` pulls the article body verbatim; if you'd rather have a compressed summary instead, that's a quoted instruction like `{{"a 3-sentence summary of the article"}}` — I'll write whichever one you want here." Do not make the user learn the bare/quoted rule in the abstract before they can make this choice.
    4. Write the draft to the resolved path, show it, and let them edit or approve before moving to the next missing template.
  - This drafting help is conversational, not a fixed asset — template *content* reflects the user's own note structure and is never the same across two vaults, unlike `config.json`/`humanize-checklist.json`/`style-profile.json` elsewhere in this skill.

### field_map

**First, one combined question**: "Want to resolve frontmatter field mappings for all three note types now, or defer any of them until you actually write one?" Any type the user defers gets `{"deferred": true}` recorded for each of its required fields in `config.json`, skipping the branch below entirely for that type — `write-checks` runs this same resolution logic the first time that type is actually written (see `write-checks/SKILL.md`'s "Frontmatter fields" section), and writes the resolved mapping back at that point.

For each required field below, on a type the user chose to resolve now, resolve one of (a) map onto an existing user property, (b) create the standard field, or (c) explicit opt-out. When mapping onto an EXISTING property, read its actual type from the note (Text/List/Number/Checkbox/Date/Date & Time) and record that discovered type in the field_map entry — don't assume a type. When creating a NEW field, assign the type that fits its semantic nature, per this table (still verify+record the discovered type instead when mapping onto an existing property), with a `zone` (top/bottom) alongside each type — zone only governs placement of fields being newly created, never fields mapped onto an existing property:
  - Literature: `type` → text, zone top; `created` → date, zone top; `source` → list + wikilink: true, zone bottom.
  - Term: `type` → text, zone top; `created` → date, zone top; `sources` → list + wikilink: true, zone bottom; `alt_names` (optional) — default: map onto Obsidian's reserved `aliases` property (type `list`, no wikilink; record `list` directly, skip the live-read-type step since `aliases` is Obsidian-fixed, not vault-specific) — or create fresh as `alt_names` (list, no wikilink, zone bottom) if the user prefers to keep it separate from `aliases`.
  - Evergreen: `type` → text, zone top; `created` → date, zone top; `derived-from` → list + wikilink: true, zone bottom; `updated-at` → datetime (not bare date — multiple revisions can land the same day), no wikilink, zone bottom.

  **`type`-occupancy check**, resolving the `type` field specifically (present in all three note types' field tables): this is a 3-way branch, not a simple create-or-map choice.
  - `type` is absent/unused in existing notes → create fresh with the standard name `type` (today's default, unchanged).
  - `type` already holds exactly the identity value needed (existing notes literally already have `type: literature`/`type: term`/`type: evergreen`) → map onto the existing `type` property directly, no new field needed.
  - `type` already holds something unrelated (e.g. a base/umbrella value like `note`) → stop and ask: recommend mapping slipbox's own type-identity onto a new, differently-named field (e.g. `note-type`) instead of colliding with the existing `type`, leaving the existing `type` property untouched. Offer the user the choice of field name — don't hardcode `note-type` as the only option, it's just the recommended default.

  **Type-mismatch check**, only for multi-valued fields (`source`s that grow: `sources`,
  `derived-from` — never `source`, which is genuinely single-valued and fits into an
  existing Text property fine): if the existing property's discovered type isn't List,
  it structurally can't hold what the field needs to grow into. Stop and ask, recommending
  mapping onto a new, standard-named List property instead and leaving the existing
  property untouched — the same recommend-a-default pattern as every other item in this
  section. Offer the other two answers too: point at a different existing property, or
  override and accept the mismatch anyway (least recommended, never the silent default).

  Never map any of these onto the reserved `tags`, `aliases`, or `cssclasses` properties — with exactly one named exception: Term's optional `alt_names` may map onto `aliases`, since the two are semantically identical (both mean "other names for this thing"), and this is in fact the default recommendation for that field (see the Term row above). No other field, on any note type, gets this carve-out. The required fields themselves, for reference:
  - Literature: `type: literature`, `created`, `source: [[resource]]`.
  - Term: `type: term`, `created`, `sources: [...]` (array/multitext — grows with each extension), `alt_names: [...]` (optional).
  - Evergreen: `type: evergreen`, `created`, `derived-from: [[...]]` (bare wikilink list, no reasons attached — reasons stay in the note body), `updated-at` (written on first write, refreshed every time an existing evergreen note is revisited/rewritten).
- **Clip config** (folded into this same flow, not a separate gate):
  - All four resource content-types (article, news, social, video) are on by default. Ask only about exceptions the user wants to turn off.
  - Transcript language: ask which languages are wanted (multi-select). Only ask for a priority order if more than one language is selected.
  - This runs unconditionally, regardless of whether the user already has some other clipper tool in their workflow.

**Done when:** the user has explicitly confirmed or corrected every item above, including the field_map verification reads for any type resolved now (deferred types are explicitly not re-asked about here).

## Section B: stated note preferences

Build one user-stated preference profile at `.slipbox/style-profile.json`. Do not analyze a corpus, infer a voice fingerprint, or create `stated_style.json`. The profile tells note-writing skills how to shape and edit notes; it is not a sample-mimicry model.

Start from `assets/style-profile.schema.json` and interview the user against its fixed sections:

- `voice`: stated descriptors such as overall quality, verbosity, confidence, hedging, and energy. Record what the user says; never infer these from a corpus.
- `sentence_style`: average length, structure, list preference, paragraph shape, and conclusion placement.
- `tone_by_note`: inspect the actual note types under `config.json`'s `frontmatter` map and ask for the tone of each configured type. Never hardcode unsupported note types. Always asked upfront for every type, regardless of whether that type's `field_map` was deferred above — tone is vault-wide, not tied to any per-type resolution step, and asking it is a single short question, not worth deferring.
- `language`: primary language, secondary language, technical-term preference, and the user's own code-switching description. `code_switching` remains a free string until its vocabulary is settled.
- `vocabulary`: phrases the user says they often use and words or phrases they want avoided.
- `formatting`: bullet use, wikilinks, aliases, headings, quotes, and citation placement.
- `editing_style`: iterative editing, renaming, compression, and redundancy removal preferences.

Show the complete draft to the user. Let them edit or approve it. Verify preference-sensitive shape choices against an actual note where useful, but never treat that note as a corpus to analyze. Validate the approved profile against `assets/style-profile.schema.json` before writing `.slipbox/style-profile.json`.

**Done when:** the user has approved one stated profile, it validates against the fixed schema, and `.slipbox/style-profile.json` is written. No corpus branch and no `stated_style.json` output exist.

## Write `.slipbox/humanize-checklist.json`

Canonical: copy `assets/humanize-checklist.json` verbatim to `.slipbox/humanize-checklist.json`. The snapshot records humanizer v2.8.0's detection, meaning-preserving rewrite, preference-context, and final-audit phases. Detection remains generic and fixed; it does not read profile baselines. The rewrite phase may read the stated profile through its `preference_context`. Explain that the file flags and guides but never rewrites automatically. Preserve its per-signal thresholds, language gating, false-positive guidance, and judgment-only signals. Re-copy it on every re-run so vaults receive package-level updates.

**Done when:** `.slipbox/humanize-checklist.json` matches `assets/humanize-checklist.json` exactly.

## Install the `slipbox` CLI

Runs identically on every invocation, first run or re-run — no conditional branch:

```bash
mkdir -p .slipbox/bin .slipbox/evergreen
touch .slipbox/links.jsonl
cp skills/setup-slipbox/scripts/slipbox .slipbox/bin/slipbox
chmod +x .slipbox/bin/slipbox
```

The script copy is always overwritten (versioned code, not user data — distinct from `.slipbox/evergreen/*.md`/`config.json`, which are never overwritten by this step). `mkdir -p`/`touch` are no-ops on a re-run — nothing here needs a conditional "does this already exist" branch the way SQLite's schema-version check once did, since there's no schema left to be at a version of.

**Done when:** `.slipbox/bin/slipbox` is installed and executable, and `.slipbox/evergreen/` and `.slipbox/links.jsonl` exist.

## Write `.slipbox/config.json`

Draft the config from everything confirmed in Sections A and B, against the fields defined in `assets/config.schema.json`:

- `paths` — the resources/literature/evergreen/term folder paths from Section A.
- `filenames` — casing per note type.
- `prefixes` — the per-type title prefix (or `false`) from Section A.
- `frontmatter` — the field_map from Section A, per type (literature/term/evergreen); each entry carries `name`/`type`/`wikilink`/`zone`, `{"deferred": true}`, the bare string/`false` shorthand, validated against `assets/config.schema.json`.
- `links.style` — the link style discovered/confirmed for `derived-from`, `sources`, `source`.
- `templates` — seven explicit paths: `literature_path`, `term_path`, `evergreen_path`, `article_path`, `news_path`, `social_path`, `video_path`.
- `transcript_languages` — ordered list from Section A's clip config.

Show the draft to the user, let them edit it, then validate the approved draft against `assets/config.schema.json` before writing. If validation fails, fix the draft and re-validate — never write a config that doesn't conform.

**Done when:** `.slipbox/config.json` is written, matches the approved draft, and validates against `assets/config.schema.json`.

## Done

Tell the user what was created: `.slipbox/config.json`, `.slipbox/bin/slipbox`, `.slipbox/evergreen/`, `.slipbox/links.jsonl`, `.slipbox/style-profile.json`, and `.slipbox/humanize-checklist.json`. Tell them which skills depend on this having run first: `clip-resource`, `find-terms`, `find-connections`, the ground-family skills that write notes from it — `grounding` (the bare engine, invoked directly for ad-hoc grounding), `ground-me` (literature-style passthrough), `ground-claim` (literature notes), `ground-term` (term notes), and `ground-my-take` (evergreen notes) — and `write-checks`, which every note-writing skill above runs before writing — checking the stated note preferences and humanizer workflow, and resolving each frontmatter field's mapping, formatting, zone placement, and title prefix. Also tell them that individual `config.json` values can be changed later without re-running this whole setup, via `slipbox config set <dotted.path> <value>` (and `slipbox config get` to inspect current values).

Propose (never write silently) a one-line pointer into the vault's own `AGENTS.md`/`CLAUDE.md` — e.g. "This vault uses the slipbox skill family; its CLI lives at `.slipbox/bin/slipbox`." — the same way the vault may already document where to find the `obsidian` CLI. Show the exact line, ask before appending it, and skip this entirely if the user declines.

## Re-run semantics (drift check, manual trigger only)

Triggered only when the user explicitly asks to re-run, or when Explore finds an existing `.slipbox/`. Never runs automatically otherwise.

1. Validate the existing `.slipbox/config.json` against `assets/config.schema.json` first, before doing anything else. A file that predates the schema or was hand-edited may not conform — surface any validation errors to the user before proceeding to the diff, rather than feeding a malformed file straight into it.
2. Re-discover conventions and style the same way as Explore/Section A/Section B, using the current state of the vault.
3. Diff the re-discovered conventions against the existing `.slipbox/config.json`.
4. Report specific mismatches, e.g. "config says kebab-case, the last 12 notes are Title Case" — name the field and both values, don't just say something changed.
5. For each mismatch, ask the user which side wins. Do not re-ask questions that didn't drift.
6. **Field_map drift check** — for each *resolved* (non-deferred) `field_map` entry, re-read the mapped-onto property's current type from the vault and compare against what's recorded:
   - **Type changed** (e.g. was List, now reads Text) — report the specific mismatch by field name and both values, ask which side wins: re-resolve to match reality, or override and keep the recorded mapping.
   - **Property gone entirely** (deleted from every note in the vault) — re-trigger the *original* resolution branch for that field (map onto a different property, create fresh, or opt-out); the old mapping now points at nothing.
   - **Deferred entries are skipped by this check entirely** — nothing's resolved yet to drift from; they stay `{"deferred": true}` until `write-checks` resolves them lazily at first write.
7. Update `config.json` with the resolved answers, then re-validate against `assets/config.schema.json` before writing.
8. Refresh `.slipbox/style-profile.json` through the stated preference interview, using the current configured note types and current notes only for verification. Show the old/new profile diff and ask before overwriting it.
9. Re-copy `assets/humanize-checklist.json` to `.slipbox/humanize-checklist.json`, overwriting the existing copy — this picks up any skill-package-level update to the canonical workflow snapshot since the vault was last set up.
10. Check whether the vault's `AGENTS.md`/`CLAUDE.md` already carries the `.slipbox/bin/slipbox` pointer from Done. If it's missing (a vault set up before that step existed, or the user declined it previously), propose adding it now the same way, ask before writing, skip if declined.

**Never** overwrite `.slipbox/evergreen/*.md`, `.slipbox/discussions/`, or any existing note during a re-run.

**Done when:** `config.json` reflects only the mismatches the user resolved (including field_map drift) and re-validates against `assets/config.schema.json`, the user has seen the stated-profile diff, and `.slipbox/humanize-checklist.json` matches the current `assets/humanize-checklist.json`.
```

- [ ] **Step 3: Rewrite `docs/setup-slipbox.md`**

Full replacement content:

```markdown
# setup-slipbox

One-time onboarding for the slipbox skill family. Discovers your vault's conventions, interviews you for stated note-shape and editing preferences, and installs the `slipbox` CLI that all other skills depend on. Run once per vault; run again only if you want to update conventions or preferences.

## When to use

Run this before using any other slipbox skill. It discovers conventions from your vault structure and existing notes (filename casing, folder paths, Obsidian templates), interviews you about clip preferences (content types and transcript languages), and interviews you for a stated profile of note shape, tone by note type, language, vocabulary, formatting, and editing behavior. It does not infer a voice model from a corpus. If you already have a `.slipbox/config.json`, it can re-run to detect and reconcile drift.

## How it works

1. **Prerequisite check** — verifies `youtube-transcript-api` and `defuddle` are available (the video-transcript check skippable if you've said you have no interest in clipping video). Asks before installing anything missing; never installs without that ask. No database dependency exists to check for.
2. **Explore** — checks for existing signal: `.obsidian/` templates, any `AGENTS.md` or `CLAUDE.md` files, existing note folders (Literature, Term, Evergreen), and whether `.slipbox/` already exists. This branches three ways: no `.slipbox/` at all (first run), `.slipbox/` with `config.json` present (triggers a drift-check re-run instead), or `.slipbox/` with `config.json` missing (an interrupted prior run — resumes with a clean restart of the conventions/style steps, since there's no config yet to diff against).
3. **Conventions** — interviews you about filename casing, folder paths, note-title prefixes (optional per-type symbols, e.g. `§`/`※`/`✱`, for scanning notes at a glance even in a flat folder), note templates, frontmatter field names (with an explicit option to defer any note type's field mapping until you actually write one), and clip config (content types, transcript languages). Recommends defaults and verifies each one against an actual note before moving on.
4. **Stated note preferences** — interviews you for `.slipbox/style-profile.json`, a user-stated contract for note shape, tone by configured note type, language, vocabulary, formatting, and editing behavior. It does not analyze a corpus or create a separate `stated_style.json` file.
5. **Humanizer workflow snapshot** — copies a fixed, skill-package-versioned `.slipbox/humanize-checklist.json`.
6. **CLI install** — copies `slipbox` (the CLI every other skill uses to talk to `.slipbox/evergreen/`, `.slipbox/links.jsonl`, and `.slipbox/config.json` — no SQLite, plain files) into your vault at `.slipbox/bin/slipbox`, and creates its evergreen directory and links log.
7. **Config write** — drafts `.slipbox/config.json` from everything confirmed above, shows it to you, and writes it only after your approval and after it validates against the skill's own config schema.

## Usage

Invoke it by name when you're ready to initialize a slipbox:

> Set up my slipbox vault.

Once it completes, every other slipbox skill is ready to use.

## Installation

This skill ships as part of the `andarwaly/slipbox` repo:

```bash
npx skills add andarwaly/slipbox
```

See the [skill source](../skills/setup-slipbox/) for the full agent-facing instructions.
```

- [ ] **Step 4: Verify the eval JSON is valid**

Run: `python3 -c "import json; json.load(open('tests/setup-slipbox/evals.json'))"`
Expected: no output, exit 0.

- [ ] **Step 5: Run the mechanical smoke test suite (regression check)**

Run: `bash tests/setup-slipbox/slipbox.sh`
Expected: `ALL PASS` — confirms this task's docs/prose edits haven't broken the CLI Task 2 already implemented.

- [ ] **Step 6: Commit**

```bash
git add skills/setup-slipbox/SKILL.md docs/setup-slipbox.md tests/setup-slipbox/evals.json
git commit -m "feat: drop sqlite3 prereq, add field_map defer + drift check, prefixes to setup-slipbox"
```

---

## Task 13: Update `docs/grounding.md`

**Files:**
- Modify: `docs/grounding.md`

**Interfaces:**
- Consumes: nothing — pure documentation sync with Task 5's `SKILL.md` rewrite.

- [ ] **Step 1: Read the current file and align it with the rewritten `skills/grounding/SKILL.md`**

Add a short "Probing" and "Gate" mention matching Task 5's additions — specifically, note the three named probe patterns and the two-part hardened Gate (precondition on showing a draft, open confirmation question) as part of the "How it works" section. Keep the rest of the file's existing structure and tone; this is a sync edit, not a rewrite.

- [ ] **Step 2: Commit**

```bash
git add docs/grounding.md
git commit -m "docs: sync grounding.md with the probing taxonomy and hardened gate"
```

---

## Task 14: Update `CONTEXT.md` — multi-claim literature notes, direct-capture pipeline, retire `surface-ideas`

**Files:**
- Modify: `CONTEXT.md`

**Interfaces:**
- Consumes: every decision recorded in this plan — this is the domain glossary every other skill's own prose defers to, so it must reflect the final settled shape, not the pre-refactor one.

- [ ] **Step 1: Rewrite the Literature note definition**

Find:
```
**Literature note** (bibliographic note, `ground-claim`'s output — internally discussed via `grounding`, source-bound fidelity):
Source-oriented. Answers "what did this author argue?" Contains only the Claim — the author's position restated in the user's own words. Anchored to exactly one source, one clip, one discussion, written once, never revisited afterward — except out-of-band manual fidelity corrections (fixing a misreading, a transcription error, or wording that misrepresents the source); the correction must move the note closer to the source, and the slug stays final. Contains no personal stance and no reaction/reflection field of any kind — even a lightweight spontaneous reaction edges into personal synthesis, which this note type never holds. A stance requires weighing multiple sources, which a single-source note structurally cannot do.
```

Replace with:
```
**Literature note** (bibliographic note, `ground-claim`'s output — internally discussed via `grounding`, source-bound fidelity):
Source-oriented. Answers "what did this author argue?" Anchored to exactly one source, one clip — but holds as many Key Claims as that source actually supports, each independently citable, structured as Question/Evidence/Conclusion. Atomicity applies per claim, not once to the whole note: historically, a literature note holds several points from one source, while atomicity ("one idea, one note") is the *permanent*-note rule (see Atomicity below). Written incrementally, one claim at a time, as each is confirmed — never revisited afterward except out-of-band manual fidelity corrections (fixing a misreading, a transcription error, or wording that misrepresents the source); the correction must move the note closer to the source, and slugs stay final once written. Contains no personal stance and no reaction/reflection field of any kind — even a lightweight spontaneous reaction edges into personal synthesis, which this note type never holds. A stance requires weighing multiple sources, which a single-source note structurally cannot do.
```

- [ ] **Step 2: Update the Atomicity definition to scope it explicitly**

Find:
```
**Atomicity** (for evergreen notes):
An evergreen note is atomic if it expresses exactly one independently referenceable claim — not one topic, not one paragraph. Test: if another note wanted to cite this one, is there exactly one clear thing it would be citing?
```

Replace with:
```
**Atomicity**:
For evergreen notes, atomicity applies to the whole note — an evergreen note is atomic if it expresses exactly one independently referenceable claim, not one topic, not one paragraph. For literature notes, atomicity applies per Key Claim, not once to the whole note — a single-source note may hold several claims, each independently citable. Test either way: if another note wanted to cite this one, is there exactly one clear thing it would be citing (the whole evergreen note, or the one specific Key Claim)?
```

- [ ] **Step 3: Update the Relationships section**

Find:
```
- A literature note is anchored to exactly one source and holds only a Claim.
```

Replace with:
```
- A literature note is anchored to exactly one source and holds one or more Claims, each its own Key Claim entry.
```

Find:
```
- `ground-term` produces/extends term notes, triggered by the user naming a term directly, or by a recurring-term row `surface-ideas` surfaces into `idea.db` (`type: raw, target_type: term`). Routes its interview through `grounding` (source-bound fidelity, same as literature notes — the term note traces to whichever source(s) back it) too, same as the other two — not left inline.
```

Replace with:
```
- `ground-term` produces/extends term notes, triggered by the user naming a term directly, or by `find-terms` reporting a term that recurs across literature notes' `## Key Concepts` wikilinks but has no term note yet — a derived, on-demand report, not a stored queue. Routes its interview through `grounding` (source-bound fidelity, same as literature notes — the term note traces to whichever source(s) back it) too, same as the other two — not left inline.
```

- [ ] **Step 4: Add a new "Flagged ambiguities" entry documenting this refactor**

Append to the end of the "Flagged ambiguities" section:

```
- Resolved 2026-08-08: literature notes hold several Key Claims per source, not one atomic Claim — the earlier one-Claim-only design conflated the permanent-note atomicity rule with the literature-note stage, where it doesn't historically apply (see `discussion/slipbox/decision.md`'s "Literature note holds several claims, not one" entry for the full grounding). `surface-ideas` and the `seeds` concept it fed are retired entirely — literature/term tracking is now derived on demand from existing notes' own frontmatter and wikilinks, replaced for the whole-corpus connection/recurrence work by two independent skills, `find-terms` and `find-connections`.
```

- [ ] **Step 5: Commit**

```bash
git add CONTEXT.md
git commit -m "docs: update CONTEXT.md for multi-claim literature notes and surface-ideas retirement"
```

---

## Task 15: Write ADR 0002 superseding ADR 0001

**Files:**
- Create: `docs/adr/0002-slipbox-file-tier-cli.md`
- Modify: `docs/adr/0001-idea-db-cli.md` (status header only — ADRs are historical records, not rewritten)

**Interfaces:**
- Consumes: every CLI-shape decision from Task 2.

- [ ] **Step 1: Mark ADR 0001 as superseded, without rewriting its body**

Change only the frontmatter status line:

Find:
```
---
status: accepted
---
```

Replace with:
```
---
status: superseded-by-0002
---
```

Everything else in the file stays exactly as-is — it's the historical record of why `idea-db` was built the way it was, still true of that point in time.

- [ ] **Step 2: Write the new ADR**

```markdown
---
status: accepted
---

# slipbox CLI: SQLite retired, file-tier evergreen/links, renamed from idea-db

Supersedes [0001-idea-db-cli.md](0001-idea-db-cli.md). `idea-db`'s `seeds` table (and the `surface-ideas` skill that fed it) is retired entirely — literature/term tracking is now derived on demand from existing notes' own frontmatter and wikilinks. `evergreen` and `links` no longer need SQLite as their storage engine once `seeds` is gone, since every remaining SQL touchpoint only existed because it shared a database with `seeds`.

## Decisions

1. **SQLite dropped entirely.** `evergreen` becomes one YAML-frontmatter file per candidate under `.slipbox/evergreen/`, written atomically (`tempfile.mkstemp` + `os.replace`). `links` becomes an append-only `.slipbox/links.jsonl` log — edges have no natural filename, so a directory-per-edge doesn't fit; a flat log costs nothing given `links` was already confirmed write-only (nothing reads it back until `find-connections` needed to, which is why `links find` was added in this same pass). `config`/`humanize check` were never SQL-backed and are untouched.
2. **Runtime stays bash wrapping Python 3 stdlib — the same split the SQLite-era script already had.** `config get/set` and `humanize check` already shelled out to `python3` for JSON handling before this rewrite; the same split now extends to `evergreen`'s YAML-frontmatter read/write. Considered switching the whole CLI to Python given SQL (bash's original reason for existing) is gone — rejected: the frontmatter here is flat `key: value`, and Python has no YAML parser in its stdlib either (`PyYAML` would be a new dependency, the same category of cost SQLite's removal was trying to avoid). Bash-wrapping-Python was already the shape for two of the CLI's commands; extending it to a third is zero new surface, not a new pattern.
3. **`init`/`migrate` dropped as subcommands entirely.** Their whole remaining job — ensuring `.slipbox/evergreen/`/`links.jsonl` exist, checking a schema version — either shrinks to two trivial filesystem operations (`mkdir -p`, `touch`, done inline by `setup-slipbox`) or disappears outright (no schema left to have a version).
4. **Renamed `idea-db` → `slipbox`.** The old name described a database that no longer exists. Checked the obvious naming collision (a CLI named the same as the whole skill family) against real precedent (`git`, `docker`) and found it's not a problem — the binary is always invoked by full path (`.slipbox/bin/slipbox`), never bare on `PATH`.

## Considered options

- **Keep SQLite, drop only `seeds`** — rejected; once `seeds`' tables/triggers/FTS5 index are gone, nothing else in the schema needs a relational engine at all, and keeping one around for two remaining tables that fit trivially into flat files would be exactly the kind of leftover machinery the broader `setup-slipbox` overengineering audit exists to catch.
- **Rewrite the whole CLI in Python** — rejected; no SQL left to justify the switch, and Python doesn't avoid a dependency here either (no stdlib YAML parser).
- **Keep the name `idea-db`** — rejected; actively misleading once there's no database.

## Consequences

- Every skill touching evergreen candidates or links talks to them exclusively through `slipbox`; none hand-parses frontmatter or hand-appends to `links.jsonl`.
- `setup-slipbox`'s prerequisite check drops `sqlite3` entirely — one fewer dependency a new user needs already installed.
- `.slipbox/evergreen/*.md` and `.slipbox/links.jsonl` are plain text, git-mergeable, sync-native — no binary-diff risk under any sync mechanism (git, Obsidian Sync, iCloud), unlike a WAL-mode SQLite file.
```

- [ ] **Step 3: Commit**

```bash
git add docs/adr/0001-idea-db-cli.md docs/adr/0002-slipbox-file-tier-cli.md
git commit -m "docs: write ADR 0002 (slipbox file-tier CLI), mark ADR 0001 superseded"
```

---

## Task 16: Rename `docs/idea-db.md` → `docs/slipbox-cli.md`; fix `docs/README.md`

**Files:**
- Create: `docs/slipbox-cli.md`
- Delete: `docs/idea-db.md`
- Modify: `docs/README.md`

**Interfaces:**
- Consumes: the final `slipbox` command surface (Task 2), `find-terms`/`find-connections` (Task 9).

- [ ] **Step 1: Delete the old CLI doc**

```bash
git rm docs/idea-db.md
```

- [ ] **Step 2: Write `docs/slipbox-cli.md`**

```markdown
# slipbox

The CLI every slipbox skill uses to read and write `.slipbox/evergreen/*.md`, `.slipbox/links.jsonl`, and `.slipbox/config.json`. No skill ever hand-parses frontmatter or hand-appends to the links log — everything goes through this one script, installed at `.slipbox/bin/slipbox` by `setup-slipbox`.

This page documents the CLI itself, for anyone reading or auditing the skill family rather than running one skill in particular. It doesn't replace the invocations shown inline in each skill's own `SKILL.md` — those are the ones an agent actually follows.

## Command surface

```
slipbox evergreen add    --slug SLUG --reason "..."
slipbox evergreen find   [--status S]
slipbox evergreen update <slug> [--status S] [--note-path P] [--slug NEW] [--iteration N]
slipbox links add        --source S --target T --rel cites|extends
slipbox links find       [--source S] [--target T] [--rel cites|extends]
slipbox config get       [<dotted.path>]
slipbox config set       <dotted.path> <value>
slipbox humanize check   <file> [--language LANG]
slipbox --help | --version
```

There is no `seeds` table and no `init`/`migrate` command — this CLI has never used a
database. `evergreen` is a flagged tension or sparked idea, one YAML-frontmatter file
per candidate under `.slipbox/evergreen/`, written by `ground-claim`, `ground-term`, or
`find-connections` and read back by `ground-my-take`. `links` is an append-only JSONL
log of typed edges (`cites`, `extends`) — separate from, and in addition to, the
`[[wikilink]]`s a note's own prose uses for Obsidian's backlink pane.

## `humanize check`

`slipbox humanize check <file> [--language LANG]` runs only the checklist's `detection.mechanical` signals. It reads `.slipbox/style-profile.json` only to decide whether English-scoped signals are available; an explicit `--language` overrides the profile for the checked passage. It never reads profile baselines and never falls back to `stated_style.json`. Each signal declares its own `single` or `cluster` threshold. Cross-signal counting uses raw presence from mechanical signals only. Judgment signals are handled by the calling skill. The checklist's declarative rewrite, preference-context, and final-audit phases remain in the JSON; the calling skill executes them.

The JSON result includes per-signal hits, signals that passed their own thresholds, the mechanical cross-signal result, and a reminder that the caller must apply `detection.judgment` separately.

`created_at`/`updated_at` on evergreen candidates are handled automatically — `created_at` on `add`, `updated_at` on any subsequent `update` call. No flag exists to set either directly; nothing needs one.

## Output and error conventions

Every command prints JSON by default. `find`/`get`-family commands accept `--format table` for a human-readable alternative. Exit code `2` means a usage error (bad flags, missing required argument); exit code `1` means a runtime failure (file not found, duplicate slug, etc.).

## Atomicity

`evergreen add` and `evergreen update` write via a temp file in the same directory, then an atomic rename (`os.replace`) — a write either fully lands or doesn't happen at all, never leaves a half-written file behind. `links add` appends a single line, which is atomic at the filesystem level for a line this short.

## Installation

`slipbox` is a bash script wrapping Python 3's standard library — no SQLite, no `PyYAML`, no dependency beyond what's already required for `config get/set` and `humanize check`. It's copied into a vault by `setup-slipbox`, never installed standalone — see [setup-slipbox.md](setup-slipbox.md).
```

- [ ] **Step 3: Rewrite `docs/README.md`**

Full replacement content:

```markdown
# Slipbox Docs

Human-facing documentation for the slipbox skill family.

- [setup-slipbox](./setup-slipbox.md) — One-time onboarding: discovers vault conventions, analyzes writing style, installs the `slipbox` CLI
- [clip-resource](./clip-resource.md) — Fetch a URL and write it as a frozen Resource, for users without a clipper tool
- [find-terms](./find-terms.md) — Report which terms recur across literature notes but have no Term note yet — read-only
- [find-connections](./find-connections.md) — Scan existing notes for missing links and sparked ideas
- [grounding](./grounding.md) — Bare Socratic-discussion engine underlying the ground-* skills
- [ground-me](./ground-me.md) — Literature-style passthrough grounding session
- [ground-claim](./ground-claim.md) — Ground a clipped source into one or more Claims, written as Key Claims in a shared literature note
- [ground-term](./ground-term.md) — Manually-triggered definitional note for a recurring term, extendable across sessions
- [ground-my-take](./ground-my-take.md) — Connect two or more existing notes into a new, purely original idea via Socratic discussion
- [slipbox (CLI reference)](./slipbox-cli.md) — The command surface every skill above talks to `.slipbox/` state through
```

- [ ] **Step 4: Commit**

```bash
git add docs/slipbox-cli.md docs/README.md
git rm docs/idea-db.md
git commit -m "docs: rename idea-db.md to slipbox-cli.md, fix README skill index"
```

---

## Task 17: Full regression pass

**Files:**
- None modified — verification only.

**Interfaces:**
- Consumes: every prior task's output.

- [ ] **Step 1: Run the CLI smoke test suite**

Run: `bash tests/setup-slipbox/slipbox.sh`
Expected: `ALL PASS`

- [ ] **Step 2: Validate every JSON file in the repo parses**

```bash
find . -name "*.json" -not -path "./tests/*/  *-workspace/*" | while read -r f; do
  python3 -c "import json; json.load(open('$f'))" || echo "INVALID: $f"
done
```
Expected: no `INVALID:` lines.

- [ ] **Step 3: Confirm no stray `idea-db`/`idea.db`/`seeds` references remain in any skill or doc**

```bash
grep -rln "idea-db\|idea\.db\|\.slipbox/bin/idea-db" skills/ docs/ CONTEXT.md AGENTS.md 2>/dev/null
```
Expected: no output — `docs/adr/0001-idea-db-cli.md` is the one intentional exception (a historical record) and is excluded by name if this check flags it; confirm by hand that it's the only hit if any appear.

```bash
grep -rln "\bseeds\b" skills/ docs/ CONTEXT.md 2>/dev/null | grep -v "docs/adr/0001"
```
Expected: no output.

- [ ] **Step 4: Confirm `surface-ideas` and `idea-db.md` are fully gone**

```bash
[ ! -d skills/surface-ideas ] && [ ! -f docs/surface-ideas.md ] && [ ! -d tests/surface-ideas ] && [ ! -f docs/idea-db.md ] && echo "confirmed removed" || echo "STILL PRESENT"
```
Expected: `confirmed removed`

- [ ] **Step 5: Confirm every doc file referenced from `docs/README.md` actually exists**

```bash
grep -oE '\(\./[a-z-]+\.md\)' docs/README.md | tr -d '()' | sed 's|^\./||' | while read -r f; do
  [ -f "docs/$f" ] || echo "MISSING: docs/$f"
done
```
Expected: no `MISSING:` lines.

- [ ] **Step 6: Confirm the branch and log**

```bash
git branch --show-current
git log --oneline refactor/core-stateful-concept -15
```
Expected: `refactor/core-stateful-concept`, and every commit from Tasks 1–15 listed.

No commit for this task — it's verification only. If any check fails, fix it in the task that introduced the gap and re-run this task before moving on.
