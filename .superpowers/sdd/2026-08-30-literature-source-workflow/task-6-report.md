# Task 6 implementation report

## Round 1

- Added source-first cache construction and private reconciliation statuses for existing Literature notes.
- Added missing-Resource blocking, no automatic semantic rewrites, exact `## Key Claims` → `## Source Points` migration, and unusual-structure skipping.
- Added objective setup eval coverage for selected, all-compatible, literal lazy/on-first-access, and defer migration modes, with cache and heading migration kept independent.

## RED

Command:

```bash
git -C the-factory/slipbox show HEAD:tests/setup-slipbox/evals.json | ruby -rjson -e 'd=JSON.parse(STDIN.read); %w[selected all lazy defer].each{|m| abort("missing #{m}") unless d["test_cases"].any?{|c| c["prompt"].downcase.include?(m) || c["expected_output"].downcase.include?(m)}}; puts "migration-mode coverage: PASS"'
```

Output:

```text
missing lazy
```

The pre-change eval set failed because literal lazy-mode coverage was absent.

## GREEN

Command:

```bash
git -C the-factory/slipbox diff -- tests/setup-slipbox/evals.json | ruby -rjson -e 's=STDIN.read; abort("diff missing") if s.empty?; abort("missing lazy") unless s.downcase.include?("lazy"); abort("missing selected") unless s.downcase.include?("selected"); abort("missing all compatible") unless s.downcase.include?("all compatible"); abort("missing defer") unless s.downcase.include?("defer"); puts "migration-mode coverage: PASS (selected, all, lazy, defer)"'
```

Output:

```text
migration-mode coverage: PASS (selected, all, lazy, defer)
```

Additional verification: both eval files parse as JSON and `git diff --check` passes.

## Round 2

- Made lazy/on-first-access a real setup choice: authorization is recorded without immediate edits, and exact compatible heading migration occurs when a note is first opened by a slipbox workflow. Defer remains a separate no-authorization option.

Verification:

```bash
rg -n "lazy/on first access|Lazy/on-first-access|first access" skills/setup-slipbox/SKILL.md docs/setup-slipbox.md tests/setup-slipbox/evals.json
python3 -m json.tool tests/setup-slipbox/evals.json >/dev/null
python3 -m json.tool tests/make-literature-note/evals.json >/dev/null
git diff --check
```

Output:

```text
skills/setup-slipbox/SKILL.md:177:Offer these independent choices ... migrate lazily/on first access ... Lazy/on-first-access ... subsequently opened ...
docs/setup-slipbox.md:28:Setup reports cache inventory counts ... lazy/on first access ... subsequently opened ...
tests/setup-slipbox/evals.json:58: The user chooses lazy migration ... migrate on first access rather than immediately.
```

All commands exited successfully.

## Round 3

- Persisted `migrations.literature_headings.mode` in the config schema, including `lazy` and selected-note paths.
- Made `make-literature-note` perform lazy migration on first access through a staged `/using-slipbox` draft, validation, and CAS publication; unrelated notes are never scanned or rewritten.
- Added fixtures and a behavioral eval requiring the accessed note's exact heading rename while the unrelated fixture remains byte-for-byte unchanged.

Verification:

```bash
python3 -m json.tool skills/setup-slipbox/assets/config.schema.json >/dev/null
python3 -m json.tool tests/make-literature-note/evals.json >/dev/null
rg -n "migrations.literature_headings|first access|byte-for-byte unchanged" skills/setup-slipbox/SKILL.md skills/make-literature-note/SKILL.md tests/make-literature-note/evals.json
git diff --check
```

Output:

```text
schema JSON: valid
literature eval JSON: valid
lazy policy, first-access CAS migration, and byte-for-byte isolation: present
git diff --check: clean
```

## Round 4

- Added an executable first-access test that creates isolated legacy and unrelated notes, invokes `work create`/`work finalize` with a heading-only mutation, and byte-compares the unrelated note.
- Persisted the migration policy in the config schema. `selected` requires non-empty vault-relative paths without dot-segment traversal; non-selected modes reject `selected` paths. An absent policy is explicitly treated as `defer`.

Verification:

```bash
tests/make-literature-note/lazy-migration.sh
python3 - <<'PY'
# Draft valid lazy/selected policies and invalid missing/absolute/mixed policies
# through jsonschema Draft7Validator.
PY
git diff --check
```

Output:

```text
lazy migration behavioral test: PASS (first-access CAS changed only selected note)
config migration policy validation: PASS
git diff --check: clean
```
