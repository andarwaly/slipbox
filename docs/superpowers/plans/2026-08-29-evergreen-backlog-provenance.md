# Evergreen Backlog Provenance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Preserve the exact context that sparked every new evergreen backlog candidate without conflating queue-entry provenance with an Evergreen note's `derived-from` lineage.

**Architecture:** Extend the existing file-per-candidate CLI contract with one enum field (`origin_kind`) and one YAML list (`origin_paths`). The CLI owns syntax, path safety, cardinality, legacy defaults, persistence, and display; each producer skill owns the semantic choice of kind and supplies actual vault-relative paths from files already in context. Obsidian note and Resource templates remain unchanged.

**Tech Stack:** Bash 3.2, embedded Python 3 standard library, YAML-like frontmatter handled by the existing CLI parser, Markdown skill/runtime documentation, JSON eval fixtures, shell smoke tests.

**Spec:** [`discussion/slipbox/discussion-topics/evergreen-backlog-provenance.md`](../../../../../discussion/slipbox/discussion-topics/evergreen-backlog-provenance.md), Resolution dated 2026-08-29.

**Beads:** `sk-slipbox.5` is the durable implementation issue. Claim it before editing and close it only after Task 4 passes.

## Global Constraints

- Backlog provenance records where a candidate entered the queue; Evergreen note `derived-from` remains unchanged and note-output-only.
- `reason` remains the user's idea, reaction, or tension in the user's own words.
- Allowed `origin_kind` values are exactly `source`, `literature-note`, `note-connection`, `standalone`, and `unknown`.
- `source` and `literature-note` require exactly one path; `note-connection` requires one or more; `standalone` and `unknown` require none.
- Every supplied origin is an existing vault-relative `.md` path observed at capture time. Reject absolute paths, `..` traversal, non-Markdown targets, paths outside the vault after realpath resolution, and missing files.
- Store paths with `/` separators while preserving configured directory names, filename casing, spaces, Unicode, and symbol prefixes.
- `--origin-kind` is optional at the CLI boundary and defaults to `unknown`; every shipped producer skill passes provenance explicitly.
- Existing candidate files read as `origin_kind: unknown` and `origin_paths: []` without being rewritten or backfilled.
- Provenance is immutable: `evergreen update` gains no provenance flags.
- Duplicate slugs continue to fail and never merge capture events.
- A stale origin path never makes `evergreen find` fail after capture.
- No configured Literature, Reference, Evergreen, Article, News, Social, or Video template changes.
- Keep Bash compatible with macOS Bash 3.2 and use only Python's standard library.
- `metadata.version` remains under `1.x`: minor for changed behavior, patch only for prose-only changes.
- The checklist in this plan is an execution guide; Beads remains the durable task source of truth.

---

## File Structure

Files modified by the implementation:

- `skills/setup-slipbox/scripts/slipbox` — parse, validate, persist, and display provenance; bump `CLI_VERSION` from `2.3.0` to `2.4.0`.
- `tests/setup-slipbox/slipbox.sh` — deterministic CLI coverage for kinds, paths, legacy reads, stale paths, duplicate behavior, table output, and failure cases.
- `skills/setup-slipbox/SKILL.md` — install-time CLI contract and version `1.7.0` → `1.8.0`.
- `skills/setup-slipbox/assets/AGENTS.md` — canonical installed backlog contract.
- `skills/setup-slipbox/assets/GLOSSARY.md` — Candidate/Backlog terminology includes provenance without changing note lineage.
- `skills/make-literature-note/SKILL.md` — `source`/`literature-note` producer mapping; version `1.16.0` → `1.17.0`.
- `skills/make-reference-note/SKILL.md` — `note-connection` producer mapping; version `1.7.0` → `1.8.0`.
- `skills/find-connections/SKILL.md` — `note-connection` producer mapping; version `1.4.2` → `1.5.0`.
- `skills/make-evergreen-note/SKILL.md` — `note-connection`/`standalone` producer mapping; version `1.8.0` → `1.9.0`.
- `skills/grounding/references/compass.md` — caller handoff includes the paths participating in a spawned idea.
- `skills/grounding/SKILL.md` — clarify that the write-free engine returns origin context to its caller; version `1.5.1` → `1.6.0`.
- `tests/make-literature-note/evals.json`
- `tests/make-reference-note/evals.json`
- `tests/find-connections/evals.json`
- `tests/make-evergreen-note/evals.json`
- `tests/grounding/evals.json` — objective behavior cases for every producer branch.
- `docs/slipbox-cli.md` — public CLI flags, storage shape, validation, compatibility, and immutability.
- `docs/setup-slipbox.md` — installed runtime contract.
- `docs/make-literature-note.md`
- `docs/make-reference-note.md`
- `docs/find-connections.md`
- `docs/make-evergreen-note.md`
- `docs/grounding.md` — human-facing provenance behavior.

Files explicitly reviewed and left unchanged:

- `skills/setup-slipbox/assets/config.schema.json` — provenance is candidate state, not vault configuration.
- All seven configured Obsidian templates — backlog files are CLI-owned and do not use templates.
- `skills/ground-me/SKILL.md` and `docs/ground-me.md` — `ground-me` reports a flagged thought but does not write backlog candidates.
- `CONTEXT.md` — note-type definitions and `derived-from` semantics do not change.

---

### Task 1: CLI provenance contract

**Files:**
- Modify: `tests/setup-slipbox/slipbox.sh`
- Modify: `skills/setup-slipbox/scripts/slipbox`
- Modify: `skills/setup-slipbox/SKILL.md`

**Interfaces:**
- Consumes: existing `.slipbox/evergreen/*.md` candidate files and vault root inferred as the parent of `.slipbox/`.
- Produces: `evergreen add --slug NAME --reason TEXT [--origin-kind KIND] [--origin-path PATH]...`; JSON rows always contain `origin_kind: str` and `origin_paths: list[str]`.

- [ ] **Step 1: Claim the implementation issue**

```bash
bd show sk-slipbox.5
bd update sk-slipbox.5 --claim
```

Expected: `sk-slipbox.5` becomes `in_progress` and names the current worker.

- [ ] **Step 2: Add failing success-path tests**

Patch the evergreen section of `tests/setup-slipbox/slipbox.sh` with a nested vault whose
`.slipbox/` layout matches a real installation. Keep the existing `$SLIPBOX` fixture for
the rest of the suite and use `$PROV_SLIPBOX` for this block:

```bash
PROV_VAULT="$SCRATCH/provenance-vault"
mkdir -p "$PROV_VAULT/.slipbox/bin" "$PROV_VAULT/.slipbox/evergreen" \
  "$PROV_VAULT/Notes" "$PROV_VAULT/Resources"
cp "$REPO_ROOT/skills/setup-slipbox/scripts/slipbox" "$PROV_VAULT/.slipbox/bin/slipbox"
chmod +x "$PROV_VAULT/.slipbox/bin/slipbox"
PROV_SLIPBOX="$PROV_VAULT/.slipbox/bin/slipbox"
printf '%s\n' '# Article' > "$PROV_VAULT/Resources/Article.md"
printf '%s\n' '# Literature' > "$PROV_VAULT/Notes/§ Article Name.md"
printf '%s\n' '# Related' > "$PROV_VAULT/Notes/Related Idea.md"

SOURCE_ADD=$(
  "$PROV_SLIPBOX" evergreen add --slug source-spark --reason "the reaction" \
    --origin-kind source --origin-path "Resources/Article.md"
)
check_json "source provenance is returned" \
  'assert data["origin_kind"] == "source"; assert data["origin_paths"] == ["Resources/Article.md"]' \
  <<< "$SOURCE_ADD"

CONNECTION_ADD=$(
  "$PROV_SLIPBOX" evergreen add --slug connected-spark --reason "the connection" \
    --origin-kind note-connection \
    --origin-path "Notes/§ Article Name.md" \
    --origin-path "Notes/Related Idea.md"
)
check_json "repeated origin paths preserve order and Unicode" \
  'assert data["origin_kind"] == "note-connection"; assert data["origin_paths"] == ["Notes/§ Article Name.md", "Notes/Related Idea.md"]' \
  <<< "$CONNECTION_ADD"

UNKNOWN_ADD=$("$PROV_SLIPBOX" evergreen add --slug legacy-call --reason "old caller")
check_json "omitted provenance defaults to unknown" \
  'assert data["origin_kind"] == "unknown"; assert data["origin_paths"] == []' \
  <<< "$UNKNOWN_ADD"
```

- [ ] **Step 3: Add failing invariant and safety tests**

```bash
check_exit "source requires one path" 2 \
  "$PROV_SLIPBOX" evergreen add --slug source-none --reason r --origin-kind source
check_exit "source rejects two paths" 2 \
  "$PROV_SLIPBOX" evergreen add --slug source-two --reason r --origin-kind source \
    --origin-path "Resources/Article.md" --origin-path "Notes/Related Idea.md"
check_exit "note-connection requires a path" 2 \
  "$PROV_SLIPBOX" evergreen add --slug connection-none --reason r --origin-kind note-connection
check_exit "standalone rejects paths" 2 \
  "$PROV_SLIPBOX" evergreen add --slug standalone-path --reason r --origin-kind standalone \
    --origin-path "Notes/Related Idea.md"
check_exit "unknown rejects paths" 2 \
  "$PROV_SLIPBOX" evergreen add --slug unknown-path --reason r --origin-path "Notes/Related Idea.md"
check_exit "unknown kind is rejected" 2 \
  "$PROV_SLIPBOX" evergreen add --slug bad-kind --reason r --origin-kind conversation
check_exit "absolute origin path is rejected" 2 \
  "$PROV_SLIPBOX" evergreen add --slug absolute --reason r --origin-kind source \
    --origin-path "$PROV_VAULT/Resources/Article.md"
check_exit "traversal is rejected" 2 \
  "$PROV_SLIPBOX" evergreen add --slug traversal --reason r --origin-kind source \
    --origin-path "../outside.md"
check_exit "non-Markdown path is rejected" 2 \
  "$PROV_SLIPBOX" evergreen add --slug text-file --reason r --origin-kind source \
    --origin-path "Resources/Article.txt"
check_exit "missing origin is rejected" 1 \
  "$PROV_SLIPBOX" evergreen add --slug missing --reason r --origin-kind source \
    --origin-path "Resources/Missing.md"
check_exit "provenance cannot be updated" 2 \
  "$PROV_SLIPBOX" evergreen update source-spark --origin-kind standalone
```

- [ ] **Step 4: Add failing compatibility, stale-path, persistence, and display tests**

Create a legacy file without the new fields, delete a once-valid origin after capture, and assert reads remain total:

```bash
printf '%s\n' \
  '---' \
  'status: "to-discuss"' \
  'reason: "legacy file"' \
  'discussion_path:' \
  'note_path:' \
  'iteration: 1' \
  'created_at: "2026-08-29T00:00:00Z"' \
  'updated_at: "2026-08-29T00:00:00Z"' \
  '---' > "$PROV_VAULT/.slipbox/evergreen/legacy-file.md"

LEGACY_FIND=$("$PROV_SLIPBOX" evergreen find --status to-discuss)
check_json "legacy candidates receive read-time defaults" \
  'row = next(item for item in data if item["slug"] == "legacy-file"); assert row["origin_kind"] == "unknown"; assert row["origin_paths"] == []' \
  <<< "$LEGACY_FIND"
check_no_match "legacy file is not backfilled on disk" '*origin_kind*' \
  "$(cat "$PROV_VAULT/.slipbox/evergreen/legacy-file.md")"

rm "$PROV_VAULT/Resources/Article.md"
STALE_FIND=$("$PROV_SLIPBOX" evergreen find --status to-discuss)
check_json "a stale captured path does not break find" \
  'row = next(item for item in data if item["slug"] == "source-spark"); assert row["origin_paths"] == ["Resources/Article.md"]' \
  <<< "$STALE_FIND"

TABLE_FIND=$("$PROV_SLIPBOX" evergreen find --status to-discuss --format table)
check_match "table exposes origin columns" '*origin_kind*origin_paths*' \
  "$(printf '%s\n' "$TABLE_FIND" | head -1)"
check_match "table joins repeated paths readably" '*Notes/§ Article Name.md; Notes/Related Idea.md*' \
  "$TABLE_FIND"

check_exit "duplicate slug still fails" 1 \
  "$PROV_SLIPBOX" evergreen add --slug connected-spark --reason "second event" \
    --origin-kind standalone
```

- [ ] **Step 5: Run the focused tests and confirm red**

Run:

```bash
bash tests/setup-slipbox/slipbox.sh
```

Expected: new tests fail because `--origin-kind` and `--origin-path` are unknown and read rows lack provenance; pre-existing tests continue running to completion.

- [ ] **Step 6: Extend the frontmatter parser and serializer for string lists**

In the embedded Python prelude, make `parse_frontmatter` recognize both `origin_paths: []` and indented string items, while preserving existing null/scalar behavior. Make `serialize_frontmatter` emit an empty list inline and non-empty lists as YAML sequence entries:

```python
def serialize_frontmatter(fields, order):
    lines = ["---"]
    for key in order:
        value = fields.get(key)
        if isinstance(value, list):
            if not value:
                lines.append(f"{key}: []")
            else:
                lines.append(f"{key}:")
                lines.extend(f"  - {json.dumps(item)}" for item in value)
        elif value is None:
            lines.append(f"{key}:")
        elif isinstance(value, str):
            lines.append(f"{key}: {json.dumps(value)}")
        else:
            lines.append(f"{key}: {value}")
    lines.append("---")
    return "\n".join(lines) + "\n"
```

The parser must reject an indented sequence without a preceding key, reject non-string sequence items for `origin_paths`, and continue parsing old frontmatter unchanged.

- [ ] **Step 7: Add origin validation**

Add a shared embedded-Python helper and call it only from `evergreen add`:

```python
ORIGIN_KINDS = {"source", "literature-note", "note-connection", "standalone", "unknown"}

def validate_origin(kind, paths, vault_root):
    if kind not in ORIGIN_KINDS:
        fail(f"--origin-kind must be one of {', '.join(sorted(ORIGIN_KINDS))}", USAGE_EXIT)
    required = {"source": (1, 1), "literature-note": (1, 1), "note-connection": (1, None)}
    if kind in required:
        minimum, maximum = required[kind]
        if len(paths) < minimum or (maximum is not None and len(paths) > maximum):
            fail(f"origin kind {kind} received {len(paths)} path(s), expected " +
                 (str(minimum) if maximum == minimum else f"at least {minimum}"), USAGE_EXIT)
    elif paths:
        fail(f"origin kind {kind} does not accept --origin-path", USAGE_EXIT)

    vault_real = os.path.realpath(vault_root)
    normalized = []
    for raw in paths:
        if os.path.isabs(raw) or ".." in raw.replace("\\", "/").split("/"):
            fail(f"origin path must be vault-relative without traversal: {raw}", USAGE_EXIT)
        candidate = os.path.normpath(raw).replace(os.sep, "/")
        if not candidate.lower().endswith(".md"):
            fail(f"origin path must name a Markdown file: {raw}", USAGE_EXIT)
        resolved = os.path.realpath(os.path.join(vault_real, candidate))
        if os.path.commonpath([vault_real, resolved]) != vault_real:
            fail(f"origin path escapes the vault: {raw}", USAGE_EXIT)
        if not os.path.isfile(resolved):
            fail(f"origin path not found: {candidate}")
        normalized.append(candidate)
    return normalized
```

- [ ] **Step 8: Parse repeated flags and persist fields**

Replace `cmd_evergreen_add`'s single-value flag reads with a Bash 3.2-compatible positional loop using indexed arrays. Default `origin_kind` to `unknown`, JSON-encode the repeated path array, pass the vault root and values into embedded Python, validate, then write this order:

```python
order = [
    "status", "reason", "origin_kind", "origin_paths", "discussion_path",
    "note_path", "iteration", "created_at", "updated_at"
]
fields = {
    "status": "to-discuss",
    "reason": reason,
    "origin_kind": origin_kind,
    "origin_paths": origin_paths,
    "discussion_path": None,
    "note_path": None,
    "iteration": 1,
    "created_at": now,
    "updated_at": now,
}
```

Do not add provenance flags to `cmd_evergreen_update`.

- [ ] **Step 9: Normalize legacy reads and table display**

Inside `cmd_evergreen_find`, add read-time defaults without mutating files:

```python
fields.setdefault("origin_kind", "unknown")
fields.setdefault("origin_paths", [])
row = {"slug": slug, **fields}
```

For table output only, render `origin_paths` as `"; ".join(paths)`; JSON output remains a list.

- [ ] **Step 10: Update help, install contract, and versions**

Change the help surface to:

```text
slipbox evergreen add --slug SLUG --reason "..." [--origin-kind KIND] [--origin-path PATH]...
```

Bump `CLI_VERSION="2.4.0"`. Add the same invocation and compatibility rule to `skills/setup-slipbox/SKILL.md`, and bump its metadata version to `1.8.0`.

- [ ] **Step 11: Run the complete CLI suite and confirm green**

```bash
bash tests/setup-slipbox/slipbox.sh
```

Expected: exit `0` and final line `ALL PASS`.

- [ ] **Step 12: Commit the CLI slice**

```bash
git add skills/setup-slipbox/scripts/slipbox skills/setup-slipbox/SKILL.md tests/setup-slipbox/slipbox.sh
git commit -m "feat(cli): add evergreen backlog provenance"
```

---

### Task 2: Producer skills and behavior evals

**Files:**
- Modify: `skills/make-literature-note/SKILL.md`
- Modify: `skills/make-reference-note/SKILL.md`
- Modify: `skills/find-connections/SKILL.md`
- Modify: `skills/make-evergreen-note/SKILL.md`
- Modify: `skills/grounding/SKILL.md`
- Modify: `skills/grounding/references/compass.md`
- Modify: `tests/make-literature-note/evals.json`
- Modify: `tests/make-reference-note/evals.json`
- Modify: `tests/find-connections/evals.json`
- Modify: `tests/make-evergreen-note/evals.json`
- Modify: `tests/grounding/evals.json`

**Interfaces:**
- Consumes: Task 1's `evergreen add` flags and actual paths already read or written by each skill.
- Produces: every shipped candidate write includes an explicit kind and the complete participating path set.

- [ ] **Step 1: Add failing eval cases before skill edits**

Add one concrete case to each eval file:

- `make-literature-note`: before first Literature write, command uses `source` plus `resources/design-tokens.md`; after a Literature path exists, reaction/tension uses `literature-note` plus that actual configured path.
- `make-reference-note`: conflicting characterizations from `Notes/§ A.md` and `Notes/§ B.md` use `note-connection` with both repeated paths.
- `find-connections`: a spark between `Notes/Spacing.md` and `Notes/Compounding.md` uses `note-connection` with both paths.
- `make-evergreen-note`: notes-in-play uses `note-connection`; a bare hunch with no retrieved notes uses `standalone` and no path flag.
- `grounding`: the engine returns the origin context to its caller and performs no CLI write itself.

Each case must assert the exact kind token and either exact path strings or explicit absence of `--origin-path` for standalone.

- [ ] **Step 2: Validate eval JSON and confirm instruction coverage is red**

```bash
python3 -m json.tool tests/make-literature-note/evals.json >/dev/null
python3 -m json.tool tests/make-reference-note/evals.json >/dev/null
python3 -m json.tool tests/find-connections/evals.json >/dev/null
python3 -m json.tool tests/make-evergreen-note/evals.json >/dev/null
python3 -m json.tool tests/grounding/evals.json >/dev/null
rg -n -- '--origin-kind|--origin-path' \
  skills/make-literature-note/SKILL.md \
  skills/make-reference-note/SKILL.md \
  skills/find-connections/SKILL.md \
  skills/make-evergreen-note/SKILL.md
```

Expected: JSON commands pass; `rg` finds no producer commands with the new flags yet.

- [ ] **Step 3: Update `make-literature-note` producer branches**

Use the Resource path already accepted by Take the source before the first Literature write:

```bash
.slipbox/bin/slipbox evergreen add --slug source-tension \
  --reason "The source treats coordination as free" \
  --origin-kind source \
  --origin-path "resources/design-tokens.md"
```

Once the Literature file exists, use its exact saved vault-relative path instead:

```bash
.slipbox/bin/slipbox evergreen add --slug literature-reaction \
  --reason "I think coordination cost is the real bottleneck" \
  --origin-kind literature-note \
  --origin-path "Notes/§ Design Tokens.md"
```

Instruction prose must say these are actual paths already in hand, not names reconstructed from `paths.*`, `filenames.*`, or prefixes. Bump version to `1.17.0`.

- [ ] **Step 4: Update `make-reference-note`**

For a deferred conflict, pass every Literature note whose grounded characterization participates:

```bash
.slipbox/bin/slipbox evergreen add --slug framework-conflict \
  --reason "The framework alternates between a diagnostic and a sequence" \
  --origin-kind note-connection \
  --origin-path "Notes/§ A.md" \
  --origin-path "Notes/§ B.md"
```

Do not use the Reference output path as the origin: the conflict arose among the input Literature notes. Bump version to `1.8.0`.

- [ ] **Step 5: Update `find-connections --evergreen`**

Require every note participating in the generated spark as a repeated path:

```bash
.slipbox/bin/slipbox evergreen add --slug compounding-repetition \
  --reason "Spacing and compounding share delayed reinforcement" \
  --origin-kind note-connection \
  --origin-path "Notes/Spacing.md" \
  --origin-path "Notes/Compounding.md"
```

The paths come from the files scanned, regardless of whether every configured note type lives under `Notes/`. Bump version to `1.5.0`.

- [ ] **Step 6: Update `make-evergreen-note`**

When notes are in play, pass all notes contributing to the tension or spawned Compass branch with `note-connection`. When the session began as a bare hunch and retrieval found no related notes, use:

```bash
.slipbox/bin/slipbox evergreen add --slug independent-hunch \
  --reason "Good prompts may benefit from deliberate incompleteness" \
  --origin-kind standalone
```

Reading an existing backlog candidate does not rewrite its provenance. Bump version to `1.9.0`.

- [ ] **Step 7: Update the write-free grounding handoff**

In `grounding/SKILL.md`, state that an opted-in opinion/tension handoff includes the paths actually in play, or an explicit no-path context. In `references/compass.md`, remove the provenance-free example command and state that the caller writes `note-connection` with participating paths or `standalone` with none. Preserve the existing rule that `grounding` executes no database/CLI write. Bump `grounding` to `1.6.0`.

- [ ] **Step 8: Run static behavioral checks**

```bash
rg -n -- '--origin-kind (source|literature-note|note-connection|standalone)' \
  skills/make-literature-note/SKILL.md \
  skills/make-reference-note/SKILL.md \
  skills/find-connections/SKILL.md \
  skills/make-evergreen-note/SKILL.md
rg -n -- '--origin-path' \
  skills/make-literature-note/SKILL.md \
  skills/make-reference-note/SKILL.md \
  skills/find-connections/SKILL.md \
  skills/make-evergreen-note/SKILL.md
rg -n 'performs no.*write|no.*CLI write' skills/grounding/SKILL.md skills/grounding/references/compass.md
```

Expected: all four producer skills show their assigned kinds and path flags; grounding remains explicitly write-free.

- [ ] **Step 9: Commit the producer slice**

```bash
git add \
  skills/make-literature-note/SKILL.md \
  skills/make-reference-note/SKILL.md \
  skills/find-connections/SKILL.md \
  skills/make-evergreen-note/SKILL.md \
  skills/grounding/SKILL.md \
  skills/grounding/references/compass.md \
  tests/make-literature-note/evals.json \
  tests/make-reference-note/evals.json \
  tests/find-connections/evals.json \
  tests/make-evergreen-note/evals.json \
  tests/grounding/evals.json
git commit -m "feat(skills): capture evergreen candidate provenance"
```

---

### Task 3: Runtime contract and human-facing documentation

**Files:**
- Modify: `skills/setup-slipbox/assets/AGENTS.md`
- Modify: `skills/setup-slipbox/assets/GLOSSARY.md`
- Modify: `docs/slipbox-cli.md`
- Modify: `docs/setup-slipbox.md`
- Modify: `docs/make-literature-note.md`
- Modify: `docs/make-reference-note.md`
- Modify: `docs/find-connections.md`
- Modify: `docs/make-evergreen-note.md`
- Modify: `docs/grounding.md`

**Interfaces:**
- Consumes: the green CLI and producer contracts from Tasks 1–2.
- Produces: one canonical installed contract plus concise public explanations that agree with executable behavior.

- [ ] **Step 1: Update the installed canonical backlog contract**

In `skills/setup-slipbox/assets/AGENTS.md`, document the exact command:

```bash
.slipbox/bin/slipbox evergreen add --slug literature-reaction \
  --reason "The source assumes coordination is cheap" \
  --origin-kind literature-note \
  --origin-path "Notes/§ Coordination.md"
```

State all five kinds, cardinality, configured-path semantics, capture-time existence checks, stale-path read behavior, read-time legacy defaults, immutability, and unchanged duplicate failure. Explicitly separate provenance from Evergreen `derived-from`.

- [ ] **Step 2: Tighten glossary definitions**

Update **Candidate** to say it carries immutable queue-entry provenance. Update **Backlog** only enough to point at the canonical contract. Do not define provenance as note lineage and do not change the **Evergreen note** definition.

- [ ] **Step 3: Update CLI documentation**

In `docs/slipbox-cli.md`, update the command surface and add a focused `evergreen provenance` subsection containing:

```yaml
origin_kind: note-connection
origin_paths:
  - Notes/Spacing.md
  - Notes/Compounding.md
```

Document validation, legacy defaults, JSON list/table joining behavior, no update flags, duplicate behavior, and why paths reflect `config.json` indirectly through actual files rather than being recomputed.

- [ ] **Step 4: Update setup and producer docs**

Make each human-facing page state its concrete mapping without reproducing the entire shared contract:

- `docs/setup-slipbox.md`: installed CLI supports immutable candidate provenance; templates remain unchanged.
- `docs/make-literature-note.md`: Resource before first note write, Literature path afterward.
- `docs/make-reference-note.md`: all participating Literature paths.
- `docs/find-connections.md`: every note participating in a spark.
- `docs/make-evergreen-note.md`: notes-in-play or standalone.
- `docs/grounding.md`: write-free handoff carries origin context to the caller.

- [ ] **Step 5: Run contract consistency checks**

```bash
rg -n 'origin_kind|origin_paths|origin-kind|origin-path' \
  skills/setup-slipbox/assets/AGENTS.md \
  docs/slipbox-cli.md \
  docs/setup-slipbox.md \
  docs/make-literature-note.md \
  docs/make-reference-note.md \
  docs/find-connections.md \
  docs/make-evergreen-note.md \
  docs/grounding.md
rg -n 'derived-from' skills/setup-slipbox/assets/AGENTS.md docs/slipbox-cli.md
rg -n 'templates\.(literature|reference|evergreen|article|news|social|video)' \
  skills/setup-slipbox/assets/AGENTS.md docs/slipbox-cli.md
```

Expected: provenance appears in every listed contract/doc; `derived-from` is explicitly separate; no provenance field is added to template configuration.

- [ ] **Step 6: Commit the documentation slice**

```bash
git add \
  skills/setup-slipbox/assets/AGENTS.md \
  skills/setup-slipbox/assets/GLOSSARY.md \
  docs/slipbox-cli.md \
  docs/setup-slipbox.md \
  docs/make-literature-note.md \
  docs/make-reference-note.md \
  docs/find-connections.md \
  docs/make-evergreen-note.md \
  docs/grounding.md
git commit -m "docs: define evergreen backlog provenance contract"
```

---

### Task 4: Full verification and parent-repository handoff

**Files:**
- Verify: all files from Tasks 1–3
- Verify unchanged: `skills/setup-slipbox/assets/config.schema.json`, `CONTEXT.md`, configured template files
- Update in parent repository: `.beads/issues.jsonl`, `.beads/interactions.jsonl`, `discussion/slipbox/decision.md`, `discussion/slipbox/discussion-topics/evergreen-backlog-provenance.md`, and the `the-factory/slipbox` gitlink

**Interfaces:**
- Consumes: three reviewed submodule commits.
- Produces: passing package, closed Beads feature, and a parent commit that pins the implemented submodule revision alongside its decision record.

- [ ] **Step 1: Run the complete deterministic suite**

```bash
bash tests/setup-slipbox/slipbox.sh
```

Expected: exit `0`, final line `ALL PASS`.

- [ ] **Step 2: Validate every changed eval file**

```bash
for file in \
  tests/make-literature-note/evals.json \
  tests/make-reference-note/evals.json \
  tests/find-connections/evals.json \
  tests/make-evergreen-note/evals.json \
  tests/grounding/evals.json; do
  python3 -m json.tool "$file" >/dev/null || exit 1
done
```

Expected: exit `0` with no output.

- [ ] **Step 3: Run the provenance and no-template sweep**

```bash
rg -n 'evergreen add' skills docs | rg -v 'origin-kind|command surface|Usage:'
rg -n 'origin_kind|origin_paths' skills/setup-slipbox/scripts/slipbox skills/setup-slipbox/assets/AGENTS.md docs/slipbox-cli.md
git diff -- skills/setup-slipbox/assets/config.schema.json CONTEXT.md
git diff --check
```

Expected: every executable producer command is either provenance-bearing or is a clearly documented generic syntax line; provenance exists in CLI/runtime/docs; config schema and `CONTEXT.md` have no diff; `git diff --check` is silent.

- [ ] **Step 4: Verify version floors exactly**

```bash
rg -n 'version:' \
  skills/setup-slipbox/SKILL.md \
  skills/grounding/SKILL.md \
  skills/make-literature-note/SKILL.md \
  skills/make-reference-note/SKILL.md \
  skills/find-connections/SKILL.md \
  skills/make-evergreen-note/SKILL.md
rg -n '^CLI_VERSION=' skills/setup-slipbox/scripts/slipbox
```

Expected versions: setup `1.8.0`, grounding `1.6.0`, Literature `1.17.0`, Reference `1.8.0`, connections `1.5.0`, Evergreen `1.9.0`, CLI `2.4.0`.

- [ ] **Step 5: Review the full submodule diff against the resolved spec**

Check each Resolution paragraph against the implementation. Confirm especially that omitted CLI provenance yields `unknown`, every shipped producer passes explicit provenance, stale paths survive reads, no update path mutates provenance, and no template/config field was introduced.

- [ ] **Step 6: Close the implementation issue after all checks pass**

```bash
bd close sk-slipbox.5 --reason="Implemented immutable evergreen backlog provenance; CLI, producer skills, runtime docs, eval JSON, and full deterministic tests pass."
```

- [ ] **Step 7: Commit any final verification-only corrections in the submodule**

If Step 5 required corrections, stage only those reviewed files and commit them with:

```bash
git add skills tests docs
git commit -m "fix: close evergreen provenance verification gaps"
```

Skip this step when the worktree is already clean.

- [ ] **Step 8: Pin the completed submodule and decision in the parent repository**

From the parent workspace:

```bash
git add \
  .beads/issues.jsonl \
  .beads/interactions.jsonl \
  discussion/slipbox/decision.md \
  discussion/slipbox/discussion-topics/evergreen-backlog-provenance.md \
  the-factory/slipbox
git commit -m "feat(slipbox): preserve evergreen backlog provenance"
```

Expected: the parent commit contains the resolved topic, derived index row, Beads closure, and one gitlink bump; it never contains bucket files directly.
