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
CLI_VERSION=$(grep -m1 '^CLI_VERSION=' "$SLIPBOX" | cut -d'"' -f2)

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

assert_contains() {
  local desc="$1" needle="$2" file="$3"
  if grep -Fq "$needle" "$file"; then pass "$desc"; else failed "$desc (missing: $needle)"; fi
}
# check_json <desc> <python body> -- asserts against the JSON on stdin, bound as `data`.
check_json() {
  if python3 -c "import json, sys
data = json.load(sys.stdin)
$2"; then pass "$1"; else failed "$1"; fi
}
# check_json_file <desc> <python body> <path> -- same, against a file's JSON.
check_json_file() {
  if python3 -c "import json, sys
data = json.load(open(sys.argv[1]))
$2" "$3"; then pass "$1"; else failed "$1"; fi
}
# check_table <subject> <header glob> <expected data rows> <output>
check_table() {
  check_match "$1 table output has a tab-separated header" "$2" "$(printf '%s\n' "$4" | head -1)"
  check_eq "$1 table output has one line per row" "$3" "$(printf '%s\n' "$4" | tail -n +2 | grep -c .)"
}
assert_humanize_signal() {
  local desc="$1" file="$2" expected_id="$3"
  if EXPECTED_ID="$expected_id" python3 - "$file" <<'PY'
import json
import os
import sys

with open(sys.argv[1]) as handle:
    result = json.load(handle)
expected = os.environ["EXPECTED_ID"]
assert result["flagged"] is True
assert expected in result["signals_passed"]
PY
  then pass "$desc"; else failed "$desc"; fi
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

echo "--- slug validation confines writes to evergreen/ ---"
check_exit "evergreen add rejects a traversal slug" 2 "$SLIPBOX" evergreen add --slug "../../etc/pwned" --reason "x"
check_exit "evergreen add rejects an absolute-path slug" 2 "$SLIPBOX" evergreen add --slug "/etc/pwned" --reason "x"
check_exit "evergreen add rejects a dot-segment slug" 2 "$SLIPBOX" evergreen add --slug "foo..bar" --reason "x"
check_exit "evergreen update rejects a traversal --slug" 2 "$SLIPBOX" evergreen update "final-test-1" --slug "../pwned"
check_exit "evergreen update rejects a non-numeric --iteration" 2 "$SLIPBOX" evergreen update "final-test-1" --iteration abc
find "$SCRATCH" -mindepth 1 -maxdepth 1 ! -name bin ! -name evergreen ! -name config.json ! -name style-profile.json ! -name humanize-checklist.json | grep -q . \
  && failed "unexpected file written outside evergreen/" \
  || pass "no file written outside evergreen/"

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

echo "--- dispatch and flag usage ---"
check_exit "--help exits 0" 0 "$SLIPBOX" --help
assert_contains "--help prints the usage block" "Usage:" /tmp/slipbox-test-out
check_exit "-h exits 0" 0 "$SLIPBOX" -h
assert_contains "-h prints the usage block" "slipbox — CLI" /tmp/slipbox-test-out
check_exit "--version exits 0" 0 "$SLIPBOX" --version
assert_contains "--version prints the CLI version" "slipbox $CLI_VERSION" /tmp/slipbox-test-out
check_exit "-v exits 0" 0 "$SLIPBOX" -v
assert_contains "-v prints the CLI version" "slipbox $CLI_VERSION" /tmp/slipbox-test-out
check_exit "no arguments prints help and exits 2" 2 "$SLIPBOX"
assert_contains "no arguments prints the usage block" "Usage:" /tmp/slipbox-test-out
for group in evergreen links config humanize; do
  check_exit "$group with no action exits 2" 2 "$SLIPBOX" "$group"
  check_exit "$group with a bogus action exits 2" 2 "$SLIPBOX" "$group" bogus
done
check_exit "a final flag without a value exits 2" 2 "$SLIPBOX" evergreen find --status

echo "--- deterministic filename formatting ---"
cat > "$SCRATCH/config.json" <<'EOF'
{"filenames":{"literature":"Sentence case","reference":"kebab-case","evergreen":"Sentence case"},"prefixes":{"literature":"§","reference":"※","evergreen":false}}
EOF
check_eq "Sentence case preserves proper name and prefixes after casing" "§ Software fundamentals matter more than ever: Matt Pocock" \
  "$("$SLIPBOX" filename format --type literature --title 'Software Fundamentals Matter More Than Ever: Matt Pocock' --preserve 'Matt Pocock')"
check_eq "Sentence case preserves acronyms" "§ API design for NASA teams" \
  "$("$SLIPBOX" filename format --type literature --title 'API Design for NASA Teams')"

echo "--- whole-artifact validation ---"
cat > "$SCRATCH/config.json" <<'EOF'
{
  "filenames": {"literature":"Sentence case","reference":"kebab-case","evergreen":"Sentence case"},
  "prefixes": {"literature":"§","reference":"※","evergreen":false},
  "frontmatter": {"literature": {"type":{"name":"type","type":"text","zone":"top"},"created":{"name":"created","type":"date","zone":"top"},"source":{"name":"source","type":"text","zone":"bottom"}}}
}
EOF
cat > "$SCRATCH/§ Exact source title.md" <<'EOF'
---
type: "literature"
created: 2026-08-24
source: "[[A resource]]"
---
# Exact source title
One compact paragraph.
EOF
check "note validate accepts a complete artifact" "$SLIPBOX" note validate --type literature --path "$SCRATCH/§ Exact source title.md" --basename "§ Exact source title.md" --title "Exact source title"
sed 's/type: "literature"/type: literature/' "$SCRATCH/§ Exact source title.md" > "$SCRATCH/§ Bare text.md"
check "note validate accepts bare mapped text" "$SLIPBOX" note validate --type literature --path "$SCRATCH/§ Bare text.md" --basename "§ Bare text.md" --title "Exact source title"
cat > "$SCRATCH/§ Backtick comment.md" <<'EOF'
---
type: literature
created: 2026-08-24
source: "[[A resource]]"
---
# Exact source title
```sh
# Shell comment
echo "ok"
```
EOF
check "note validate ignores H1-like lines in backtick fences" "$SLIPBOX" note validate --type literature --path "$SCRATCH/§ Backtick comment.md" --basename "§ Backtick comment.md" --title "Exact source title"
cat > "$SCRATCH/§ Tilde comment.md" <<'EOF'
---
type: literature
created: 2026-08-24
source: "[[A resource]]"
---
# Exact source title
~~~sh
# Shell comment
echo "ok"
~~~
EOF
check "note validate ignores H1-like lines in tilde fences" "$SLIPBOX" note validate --type literature --path "$SCRATCH/§ Tilde comment.md" --basename "§ Tilde comment.md" --title "Exact source title"
cat > "$SCRATCH/§ Multiple real H1.md" <<'EOF'
---
type: literature
created: 2026-08-24
source: "[[A resource]]"
---
# Exact source title
## A section
# Another real heading
EOF
check_exit "note validate rejects multiple real H1s" 1 "$SLIPBOX" note validate --type literature --path "$SCRATCH/§ Multiple real H1.md" --basename "§ Multiple real H1.md" --title "Exact source title"
check_exit "note validate rejects a basename mismatch" 1 "$SLIPBOX" note validate --type literature --path "$SCRATCH/§ Exact source title.md" --basename "§ Other title.md" --title "Exact source title"
cat > "$SCRATCH/config.json" <<'EOF'
{
  "filenames": {"literature":"Sentence case","reference":"kebab-case","evergreen":"Sentence case"},
  "prefixes": {"literature":"§","reference":"※","evergreen":false},
  "frontmatter": {"reference": {"type":{"name":"type","type":"text","zone":"top"},"created":{"name":"created","type":"date","zone":"top"},"sources":{"name":"sources","type":"list","zone":"bottom"}}}
}
EOF
cat > "$SCRATCH/※ Reference.md" <<'EOF'
---
type: "reference"
created: 2026-08-24
sources: ["[[A resource]]"]
---
# Reference
Definition.
EOF
check "note validate accepts a parsed list" "$SLIPBOX" note validate --type reference --path "$SCRATCH/※ Reference.md" --basename "※ Reference.md" --title "Reference"
cat > "$SCRATCH/※ block-list.md" <<'EOF'
---
type: reference
created: 2026-08-24
sources:
  - "[[A resource]]"
  - "[[Another resource]]"
---
# Reference
Definition.
EOF
check "note validate accepts a block YAML list" "$SLIPBOX" note validate --type reference --path "$SCRATCH/※ block-list.md" --basename "※ block-list.md" --title "Reference"
sed 's/sources: \[.*/sources: [not valid/' "$SCRATCH/※ Reference.md" > "$SCRATCH/malformed-list.md"
check_exit "note validate rejects malformed list serialization" 1 "$SLIPBOX" note validate --type reference --path "$SCRATCH/malformed-list.md" --basename "malformed-list.md" --title "Reference"
sed 's/created: 2026-08-24/created: "2026-08-24"/' "$SCRATCH/※ Reference.md" > "$SCRATCH/quoted-date.md"
check_exit "note validate rejects quoted date" 1 "$SLIPBOX" note validate --type reference --path "$SCRATCH/quoted-date.md" --basename "quoted-date.md" --title "Reference"
cat > "$SCRATCH/config.json" <<'EOF'
{
  "filenames": {"literature":"Sentence case","reference":"kebab-case","evergreen":"Sentence case"},
  "prefixes": {"literature":"§","reference":"※","evergreen":false},
  "frontmatter": {"evergreen": {"type":{"name":"type","type":"text","zone":"top"},"score":{"name":"score","type":"number","zone":"top"},"enabled":{"name":"enabled","type":"checkbox","zone":"top"},"created":{"name":"created","type":"date","zone":"top"},"updated":{"name":"updated","type":"datetime","zone":"bottom"}}}
}
EOF
cat > "$SCRATCH/kinds.md" <<'EOF'
---
type: evergreen
score: 3.5
enabled: true
created: 2026-08-24
updated: 2026-08-24T12:34:56Z
---
# Kinds
Definition.
EOF
check "note validate accepts number checkbox date and datetime" "$SLIPBOX" note validate --type evergreen --path "$SCRATCH/kinds.md" --basename "kinds.md" --title "Kinds"
sed 's/score: 3.5/score: "not a number"/' "$SCRATCH/kinds.md" > "$SCRATCH/bad-number.md"
check_exit "note validate rejects a non-number" 1 "$SLIPBOX" note validate --type evergreen --path "$SCRATCH/bad-number.md" --basename "bad-number.md" --title "Kinds"
sed 's/enabled: true/enabled: yes/' "$SCRATCH/kinds.md" > "$SCRATCH/bad-checkbox.md"
check_exit "note validate rejects a non-checkbox" 1 "$SLIPBOX" note validate --type evergreen --path "$SCRATCH/bad-checkbox.md" --basename "bad-checkbox.md" --title "Kinds"
sed 's/updated: 2026-08-24T12:34:56Z/updated: "2026-08-24T12:34:56Z"/' "$SCRATCH/kinds.md" > "$SCRATCH/quoted-datetime.md"
check_exit "note validate rejects quoted datetime" 1 "$SLIPBOX" note validate --type evergreen --path "$SCRATCH/quoted-datetime.md" --basename "quoted-datetime.md" --title "Kinds"
check_eq "unsafe filename characters are sanitized" "§ A title-with-unsafe-chars-yes" \
  "$("$SLIPBOX" filename format --type literature --title 'A Title/With: Unsafe*Chars? Yes')"
check_eq "no prefix returns the complete unprefixed basename" "An evergreen idea" \
  "$("$SLIPBOX" filename format --type evergreen --title 'An Evergreen Idea')"
check_eq "multiple protected spans survive casing" "§ Design with Matt Pocock and OpenAI" \
  "$("$SLIPBOX" filename format --type literature --title 'Design With Matt Pocock and OpenAI' --preserve 'Matt Pocock' --preserve 'OpenAI')"
check_eq "protected substring does not alter an unrelated word in Sentence case" "§ AI and PAIR" \
  "$($SLIPBOX filename format --type literature --title 'AI and PAIR' --preserve 'AI')"
check_eq "protected substring does not alter a mixed-case word" "§ AI and pairwise" \
  "$($SLIPBOX filename format --type literature --title 'AI and PAIRwise' --preserve 'AI')"
check_eq "protected span survives kebab-case" "※ guide-by-OpenAI" \
  "$($SLIPBOX filename format --type reference --title 'Guide By OpenAI' --preserve 'OpenAI')"
check_eq "multiword protected span uses kebab separators" "※ guide-by-Matt-Pocock" \
  "$($SLIPBOX filename format --type reference --title 'Guide By Matt Pocock' --preserve 'Matt Pocock')"
cat > "$SCRATCH/config.json" <<'EOF'
{"filenames":{"literature":"Sentence case","reference":"snake_case","evergreen":"Sentence case"},"prefixes":{"literature":"§","reference":"※","evergreen":false}}
EOF
check_eq "protected span survives snake_case" "※ guide_by_OpenAI" \
  "$($SLIPBOX filename format --type reference --title 'Guide By OpenAI' --preserve 'OpenAI')"
check_eq "multiword protected span uses snake separators" "※ guide_by_Matt_Pocock" \
  "$($SLIPBOX filename format --type reference --title 'Guide By Matt Pocock' --preserve 'Matt Pocock')"
cat > "$SCRATCH/config.json" <<'EOF'
{"filenames":{"literature":"Sentence case","reference":"kebab-case","evergreen":"Sentence case"},"prefixes":{"literature":"§","reference":"※","evergreen":false}}
EOF
check_eq "mixed-case hyphenated words are not treated as acronyms" "§ AI-assisted coding" \
  "$($SLIPBOX filename format --type literature --title 'AI-Assisted Coding')"
check_match "unmatched protected names are surfaced" '*not found*preview*' \
  "$(stderr_of "$SLIPBOX" filename format --type literature --title 'A Title' --preserve 'Missing Name')"
check_match "ambiguous protected names are surfaced" '*ambiguous*preview*' \
  "$(stderr_of "$SLIPBOX" filename format --type literature --title 'OpenAI and OpenAI' --preserve 'OpenAI')"
check_eq "only the protected-name subtitle colon is preserved" "§ First: Matt Pocock-second title" \
  "$($SLIPBOX filename format --type literature --title 'First: Matt Pocock: Second Title' --preserve 'Matt Pocock')"
check_eq "auto-detected acronyms do not preserve subtitle colons" "§ API-NASA teams" \
  "$($SLIPBOX filename format --type literature --title 'API: NASA Teams')"
check_match "uncertain protected names are surfaced on stderr" '*uncertain*preview*' \
  "$(stderr_of "$SLIPBOX" filename format --type literature --title 'A Title' --uncertain 'Title')"
check_exit "filename format missing title is a usage error" 2 "$SLIPBOX" filename format --type literature
check_exit "filename format unknown type is a usage error" 2 "$SLIPBOX" filename format --type article --title Title
check_exit "filename format help exits 0" 0 "$SLIPBOX" filename format --help

echo "--- evergreen edge cases ---"
check_exit "evergreen add missing --slug exits 2" 2 "$SLIPBOX" evergreen add --reason reason
mv "$SCRATCH/evergreen" "$SCRATCH/evergreen.saved"
check_exit "evergreen add without its data directory exits 1" 1 "$SLIPBOX" evergreen add --slug no-dir --reason reason
check_exit "evergreen find without its data directory exits 1" 1 "$SLIPBOX" evergreen find
check_exit "evergreen update without its data directory exits 1" 1 "$SLIPBOX" evergreen update no-dir --status discussing
mv "$SCRATCH/evergreen.saved" "$SCRATCH/evergreen"

check_exit "evergreen find with no matching status returns 0" 0 "$SLIPBOX" evergreen find --status no-such-status
check_json_file "unmatched evergreen status returns an empty JSON array" "assert data == []" /tmp/slipbox-test-out
check_table evergreen $'slug\t*' 1 "$("$SLIPBOX" evergreen find --format table)"
check_eq "evergreen table output marks an empty result" "(no rows)" "$("$SLIPBOX" evergreen find --status no-such-status --format table)"
printf 'this file has no frontmatter\n' > "$SCRATCH/evergreen/no-frontmatter.md"
"$SLIPBOX" evergreen find | check_json "evergreen find skips a file with no frontmatter" "assert len(data) >= 1"
cat > "$SCRATCH/evergreen/typed-values.md" <<'EOF'
---
status: plain-status
plain_string: plain
integer_value: 42
empty_value:
created_at: "2099-01-03T00:00:00Z"
---
EOF
"$SLIPBOX" evergreen find | check_json "evergreen frontmatter parses plain strings, integers, and empty values" '
row = next(row for row in data if row["slug"] == "typed-values")
assert row["plain_string"] == "plain" and isinstance(row["plain_string"], str)
assert row["integer_value"] == 42 and isinstance(row["integer_value"], int)
assert row["empty_value"] is None
'
cat > "$SCRATCH/evergreen/older.md" <<'EOF'
---
status: to-discuss
created_at: "2020-01-01T00:00:00Z"
---
EOF
cat > "$SCRATCH/evergreen/newer.md" <<'EOF'
---
status: to-discuss
created_at: "2099-01-02T00:00:00Z"
---
EOF
"$SLIPBOX" evergreen find | check_json "evergreen rows sort by created_at descending" '
positions = {row["slug"]: index for index, row in enumerate(data)}
assert positions["newer"] < positions["older"]
'
check "evergreen update persists --note-path" "$SLIPBOX" evergreen update final-test-1 --note-path notes/final.md
assert_contains "evergreen update persisted note_path" 'note_path: "notes/final.md"' "$SCRATCH/evergreen/final-test-1.md"
check "add collision candidate" "$SLIPBOX" evergreen add --slug collision-target --reason collision
cp "$SCRATCH/evergreen/final-test-1.md" "$SCRATCH/final-before-collision.md"
cp "$SCRATCH/evergreen/collision-target.md" "$SCRATCH/collision-before-collision.md"
check_exit "evergreen update rejects a colliding rename" 1 "$SLIPBOX" evergreen update final-test-1 --slug collision-target
if cmp -s "$SCRATCH/evergreen/final-test-1.md" "$SCRATCH/final-before-collision.md" &&
  cmp -s "$SCRATCH/evergreen/collision-target.md" "$SCRATCH/collision-before-collision.md"; then
  pass "colliding rename leaves both original files untouched"
else
  failed "colliding rename changed an original file"
fi

echo "--- links edge cases ---"
"$SLIPBOX" links find --target some-term | check_json "links find filters by --target" "assert len(data) == 2"
"$SLIPBOX" links find --rel extends | check_json "links find filters by --rel" 'assert len(data) == 1 and data[0]["source_id"] == "other-slug"'
"$SLIPBOX" links find --source final-test-1 --rel cites | check_json "links find combines source and relation filters" "assert len(data) == 1"
cp "$SCRATCH/links.jsonl" "$SCRATCH/links.jsonl.before-blank-line"
printf '\n' >> "$SCRATCH/links.jsonl"
"$SLIPBOX" links find | check_json "links find skips a blank JSONL line" "assert len(data) == 2"
mv "$SCRATCH/links.jsonl.before-blank-line" "$SCRATCH/links.jsonl"
check_table links $'source_id\ttarget_id*' 2 "$("$SLIPBOX" links find --format table)"
check_eq "links table output marks an empty result" "(no rows)" "$("$SLIPBOX" links find --target no-such-target --format table)"
mv "$SCRATCH/links.jsonl" "$SCRATCH/links.saved"
"$SLIPBOX" links find | check_json "links find without links.jsonl returns an empty array" "assert data == []"
mv "$SCRATCH/links.saved" "$SCRATCH/links.jsonl"

echo "--- config edge cases ---"
printf '{"paths":{"literature":"literature"},"settings":{"number":0,"enabled":false}}' > "$SCRATCH/config.json"
"$SLIPBOX" config get | check_json "config get without a path prints the whole document" 'assert data["paths"]["literature"] == "literature"'
check_exit "config get unknown path exits 2" 2 "$SLIPBOX" config get paths.unknown
check_exit "config get through a non-dict exits 2" 2 "$SLIPBOX" config get paths.literature.missing
check_exit "config set unknown intermediate path exits 2" 2 "$SLIPBOX" config set missing.leaf value
check_exit "config set unknown leaf exits 2" 2 "$SLIPBOX" config set paths.unknown value
check "config set stores a JSON number" "$SLIPBOX" config set settings.number 42
check "config set stores a JSON boolean" "$SLIPBOX" config set settings.enabled true
check "config set stores a bare word as a string" "$SLIPBOX" config set paths.literature Literature
check_json_file "config set preserves JSON types and bare words as strings" '
assert data["settings"]["number"] == 42 and isinstance(data["settings"]["number"], int)
assert data["settings"]["enabled"] is True
assert data["paths"]["literature"] == "Literature" and isinstance(data["paths"]["literature"], str)
' "$SCRATCH/config.json"

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

echo "--- humanize edge cases ---"
printf 'plain prose with no mechanical signals.\n' > "$SCRATCH/clean.md"
if "$SLIPBOX" humanize check "$SCRATCH/clean.md" > "$SCRATCH/clean-result.json" &&
  python3 -c 'import json,sys; assert json.load(open(sys.argv[1]))["flagged"] is False' "$SCRATCH/clean-result.json"; then
  echo "ok   - clean prose is not flagged"
else
  echo "FAIL - clean prose was flagged"
  fail=1
fi
check_exit "humanize check on a nonexistent file exits 1" 1 "$SLIPBOX" humanize check "$SCRATCH/missing.md"
mv "$SCRATCH/config.json" "$SCRATCH/config.saved"
check_exit "humanize check without config.json exits 1" 1 "$SLIPBOX" humanize check "$SCRATCH/clean.md"
mv "$SCRATCH/config.saved" "$SCRATCH/config.json"
mv "$SCRATCH/humanize-checklist.json" "$SCRATCH/humanize-checklist.saved"
check_exit "humanize check without humanize-checklist.json exits 1" 1 "$SLIPBOX" humanize check "$SCRATCH/clean.md"
mv "$SCRATCH/humanize-checklist.saved" "$SCRATCH/humanize-checklist.json"
mv "$SCRATCH/style-profile.json" "$SCRATCH/style-profile.saved"
check_exit "humanize check without style-profile.json exits 1" 1 "$SLIPBOX" humanize check "$SCRATCH/clean.md"
mv "$SCRATCH/style-profile.saved" "$SCRATCH/style-profile.json"
check_exit "humanize check rejects an extra argument" 2 "$SLIPBOX" humanize check "$SCRATCH/clean.md" extra
check_exit "humanize check rejects --language without a value" 2 "$SLIPBOX" humanize check "$SCRATCH/clean.md" --language
cat > "$SCRATCH/french.md" <<'EOF'
Let's dive in.
EOF
if "$SLIPBOX" humanize check "$SCRATCH/french.md" --language French > "$SCRATCH/french-result.json" &&
  python3 - "$SCRATCH/french-result.json" <<'PY'
import json
import sys
with open(sys.argv[1]) as handle:
    result = json.load(handle)
assert any(signal.get("skipped") == "language_scope" for signal in result["signals"])
PY
then
  echo "ok   - out-of-profile language skips en-scoped signals"
else
  echo "FAIL - out-of-profile language did not skip en-scoped signals"
  fail=1
fi
printf '# One\n' > "$SCRATCH/one-heading.md"
if "$SLIPBOX" humanize check "$SCRATCH/one-heading.md" > "$SCRATCH/one-heading-result.json" &&
  python3 -c 'import json,sys; assert json.load(open(sys.argv[1]))["flagged"] is False' "$SCRATCH/one-heading-result.json"; then
  echo "ok   - a single-significant-word title-case heading is not flagged"
else
  echo "FAIL - a single-significant-word title-case heading was flagged"
  fail=1
fi

CHECKLIST="$REPO_ROOT/skills/setup-slipbox/assets/humanize-checklist.json"
read_signal_value() {
  local signal_id="$1" expected_type="$2" field="$3"
  python3 - "$CHECKLIST" "$signal_id" "$expected_type" "$field" <<'PY'
import json
import sys

checklist_path, expected_id, expected_type, field = sys.argv[1:]
with open(checklist_path) as handle:
    signals = json.load(handle)["detection"]["mechanical"]["signals"]
matches = [signal for signal in signals if signal.get("id") == expected_id]
if not matches:
    raise SystemExit(
        f"FAIL - checklist is missing expected signal id {expected_id!r}"
    )
signal = matches[0]
if signal.get("type") != expected_type:
    raise SystemExit(
        f"FAIL - checklist signal {expected_id!r} has type "
        f"{signal.get('type')!r}, expected {expected_type!r}"
    )
value = signal.get(field)
if not value:
    raise SystemExit(
        f"FAIL - checklist signal {expected_id!r} has no usable {field}"
    )
if isinstance(value, list):
    print(value[0])
else:
    print(value)
PY
}

WORD_ID="ai_vocabulary"
WORD=$(read_signal_value "$WORD_ID" word_list words)
printf '%s %s\n' "$WORD" "$WORD" > "$SCRATCH/word-list.md"
"$SLIPBOX" humanize check "$SCRATCH/word-list.md" > "$SCRATCH/word-list-result.json"
assert_humanize_signal "word_list signal is detected from the checklist" "$SCRATCH/word-list-result.json" "$WORD_ID"

PHRASE_ID="filler_phrases"
PHRASE=$(read_signal_value "$PHRASE_ID" phrase_list phrases)
printf '%s.\n' "$PHRASE" > "$SCRATCH/phrase-list.md"
"$SLIPBOX" humanize check "$SCRATCH/phrase-list.md" > "$SCRATCH/phrase-list-result.json"
assert_humanize_signal "phrase_list signal is detected from the checklist" "$SCRATCH/phrase-list-result.json" "$PHRASE_ID"

ANNOUNCEMENT_ID="signposting_announcements"
ANNOUNCEMENT=$(read_signal_value "$ANNOUNCEMENT_ID" announcement_opener phrases)
printf '%s.\n' "$ANNOUNCEMENT" > "$SCRATCH/announcement-opener.md"
"$SLIPBOX" humanize check "$SCRATCH/announcement-opener.md" > "$SCRATCH/announcement-opener-result.json"
assert_humanize_signal "announcement_opener signal is detected from the checklist" "$SCRATCH/announcement-opener-result.json" "$ANNOUNCEMENT_ID"

REGEX_ID="em_dash"
REGEX_PATTERN=$(read_signal_value "$REGEX_ID" regex pattern)
if [ "$REGEX_PATTERN" != "—|–|--" ]; then
  echo "FAIL - checklist signal $REGEX_ID pattern changed: $REGEX_PATTERN"
  fail=1
else
  printf '%s\n' '— —' > "$SCRATCH/regex.md"
fi
"$SLIPBOX" humanize check "$SCRATCH/regex.md" > "$SCRATCH/regex-result.json"
assert_humanize_signal "regex signal is detected from the checklist pattern" "$SCRATCH/regex-result.json" "$REGEX_ID"

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
