# Slipbox Runtime Engine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `/using-slipbox` and the CLI-backed recoverable work, source-map cache, transactional publication, Git, and migration-policy foundation shared by every Slipbox artifact.

**Architecture:** `setup-slipbox` keeps owning the bundled executable and bootstrap installation; the new `using-slipbox` skill owns the agent-facing core loop and named shared actions. The single Bash/Python CLI owns schemas, path safety, atomic mutations, compare-and-swap, compensation, cache mechanics, link tombstones, and isolated-index Git commits. Specialist skills consume these interfaces in later plans.

**Tech Stack:** Agent Skills Markdown, Bash, Python 3 standard library, JSON/JSONL, Git CLI, shell regression tests.

**Spec:** `../../../../discussion/slipbox/discussion-topics/workflow-runtime-and-reference-notes.md`

## Global Constraints

- Execution controller: fresh `gpt-5.6-terra` session at medium reasoning.
- Every implementation and task-review dispatch: `gpt-5.6-luna` at medium reasoning, tracked by a Beads task/subtask under the long-running Slipbox epic.
- After all plans, stop the Terra controller. Final whole-branch review runs in a separate new `gpt-5.6-sol` task/thread at low reasoning, tracked in Beads; that review task may dispatch tracked Luna-low or Luna-medium fix subagents and re-review their changes.
- Never close the Slipbox epic when this plan or all current children complete.
- Keep `skills/setup-slipbox/scripts/slipbox` as the bundled executable source and `.slipbox/bin/slipbox` as the installed path.
- JSON remains CLI default; tables require `--format table`; errors remain JSON on stderr with exit 2 for usage and exit 1 for runtime failure.
- `.slipbox/work/` is always local/untracked. Source-map caches use independent `local|tracked` policy.
- Prefixes identify filenames and exact link targets only; H1s remain clean.
- TDD each behavior; each task ends in an independently reviewable commit.

---

### Task 1: Scaffold the `/using-slipbox` engine

**Files:**
- Create: `skills/using-slipbox/SKILL.md`
- Create: `skills/using-slipbox/references/work-lifecycle.md`
- Create: `skills/using-slipbox/references/evergreen-candidates.md`
- Create: `skills/using-slipbox/references/link-ledger.md`
- Create: `skills/using-slipbox/references/source-map-cache.md`
- Create: `skills/using-slipbox/references/git-finalization.md`
- Create: `docs/using-slipbox.md`
- Create: `tests/using-slipbox/evals.json`
- Modify: `AGENTS.md`

**Interfaces:**
- Consumes: `.slipbox/AGENTS.md`, `.slipbox/bin/slipbox`, `/write-checks`.
- Produces: canonical actions `Start or resume work`, `Checkpoint work`, `Publish an artifact`, `Record an Evergreen candidate`, `Record a link`, `Remove a link`, `Store source analysis`, `Inspect source analysis`, `Refresh source analysis`, `Finish work with Git`, `Recover failed work`, `Discard work`.

- [ ] **Step 1: Write failing eval cases for action routing and caller syntax**

Add cases asserting that callers use natural imperative prose followed by `/using-slipbox`, that the engine delegates validation to `/write-checks`, and that exact CLI flags live in references/help rather than being duplicated in every action.

```json
{
  "prompt": "A Literature workflow has an approved reader-owned proposition with origin paths. Record it.",
  "expected_output": "Routes to the Record an Evergreen candidate action, requires proposition, reason, origin kind and origin paths, and does not reinterpret the proposition.",
  "assertions": [
    {"type": "contains", "text": "Record an Evergreen candidate"},
    {"type": "not_contains", "text": "Run /using-slipbox"}
  ]
}
```

- [ ] **Step 2: Run the eval harness and verify the new skill is absent/failing**

Run: the repository's existing skill-eval procedure against `tests/using-slipbox/evals.json`.

Expected: FAIL because `skills/using-slipbox/SKILL.md` does not exist.

- [ ] **Step 3: Write the compact core skill and progressive references**

Use named, non-numbered action headings. Each action specifies trigger, required inputs, guarantee, and reference file. Add this exact caller rule:

```markdown
Caller skills state the natural imperative action and append `/using-slipbox`.
Write “Record the link `/using-slipbox`,” never “Run `/using-slipbox`” or
“record the link through `/using-slipbox`.”
```

Keep CLI mechanics out of `SKILL.md`; references may show exact commands.

- [ ] **Step 4: Add human documentation and repository structure entries**

Document the responsibility split: specialist → `/using-slipbox` → CLI. Update `AGENTS.md` so `/using-slipbox`, `/grounding`, and `/write-checks` are the slash-prefixed engine skills.

- [ ] **Step 5: Run evals and Markdown/reference checks**

Run: all `using-slipbox` evals plus `rg -n 'Run `/using-slipbox`|through `/using-slipbox`' skills docs`.

Expected: evals PASS; forbidden caller forms absent from live docs.

- [ ] **Step 6: Commit**

```bash
git add skills/using-slipbox docs/using-slipbox.md tests/using-slipbox AGENTS.md
git commit -m "feat(runtime): add using-slipbox action engine"
```

---

### Task 2: Extend setup config and bootstrap artifacts

**Files:**
- Modify: `skills/setup-slipbox/assets/config.schema.json`
- Modify: `skills/setup-slipbox/SKILL.md`
- Modify: `skills/setup-slipbox/assets/AGENTS.md`
- Modify: `docs/setup-slipbox.md`
- Modify: `tests/setup-slipbox/evals.json`
- Modify: `tests/setup-slipbox/slipbox.sh`

**Interfaces:**
- Consumes: existing setup drift-check and config validation.
- Produces: required config objects `git` and `cache`; `.slipbox/work/`; `.slipbox/cache/source-maps/`; migration detection contract.

- [ ] **Step 1: Add failing schema and setup tests**

Test exact valid configuration:

```json
{
  "git": {
    "mode": "ask",
    "commit_style": {"mode": "detected"},
    "activity_trailers": true
  },
  "cache": {
    "source_maps": {"persistence": "local"}
  }
}
```

Add failures for unknown Git modes, missing cache persistence, and any attempt to configure `.slipbox/work/` as tracked.

- [ ] **Step 2: Run setup tests and verify failure**

Run: `bash tests/setup-slipbox/slipbox.sh`.

Expected: FAIL because schema rejects/does not require the new groups.

- [ ] **Step 3: Extend the schema without a stored Git-detection boolean**

Add definitions equivalent to:

```json
"git": {
  "type": "object",
  "required": ["mode", "commit_style", "activity_trailers"],
  "additionalProperties": false,
  "properties": {
    "mode": {"enum": ["off", "ask", "auto"]},
    "commit_style": {
      "type": "object",
      "required": ["mode"],
      "properties": {"mode": {"enum": ["detected", "fallback"]}},
      "additionalProperties": false
    },
    "activity_trailers": {"type": "boolean"}
  }
}
```

Do not add `git: true` or repository-root state.

- [ ] **Step 4: Update first-run and re-run interviews**

If no repository is detected, store `off` and explain later enablement. If detected, ask `off|ask|auto` with `ask` recommended. Ask cache persistence separately, default `local`. Rename setup copy from “note-title prefixes” to filename/link-target prefixes and state H1s are clean.

- [ ] **Step 5: Create runtime directories and ignore rules safely**

First run creates `.slipbox/work/` and `.slipbox/cache/source-maps/`. Ensure local cache/work patterns are proposed or written to the vault's relevant ignore mechanism only with the same ask-first policy used for vault instructions; tracked cache omits the source-map ignore.

- [ ] **Step 6: Add cache/migration inventory behavior to setup docs/evals**

Cover compatible, missing, incompatible, older-compatible, unresolved-source, and orphaned cache counts; offer build missing+incompatible, scoped, refresh-all, or defer. Keep cache and note-format migration authorizations separate.

- [ ] **Step 7: Run setup regression suite**

Run: `bash tests/setup-slipbox/slipbox.sh` and setup evals.

Expected: PASS, including interrupted-run sentinel ordering.

- [ ] **Step 8: Commit**

```bash
git add skills/setup-slipbox docs/setup-slipbox.md tests/setup-slipbox
git commit -m "feat(setup): configure work cache and git policies"
```

---

### Task 3: Implement CLI work lifecycle and inspectable schemas

**Files:**
- Modify: `skills/setup-slipbox/scripts/slipbox`
- Modify: `docs/slipbox-cli.md`
- Modify: `tests/setup-slipbox/slipbox.sh`

**Interfaces:**
- Produces commands: `work create|list|inspect|update|resume|discard`.
- Produces work manifest fields: `work_id`, `kind`, `activity`, `status`, UTC `created_at`/`updated_at`, source/target identity, source/target starting fingerprints, affected paths.
- Consumers: all later runtime actions and plans.

- [ ] **Step 1: Add failing lifecycle tests**

Add shell tests for ULID-shaped IDs, one directory per work ID, UTC timestamps, JSON-default list/inspect, explicit table format, unknown status/flag exit 2, destructive discard requiring `--yes`, and no age-based deletion.

```bash
result="$($CLI work create --kind literature --activity create \
  --source resources/a.md --target literature/a.md)"
work_id="$(printf '%s' "$result" | jq -r '.work_id')"
test -d ".slipbox/work/$work_id"
```

- [ ] **Step 2: Run the focused test and verify failure**

Run: `bash tests/setup-slipbox/slipbox.sh`.

Expected: FAIL with unknown command `work`.

- [ ] **Step 3: Add manifest/schema helpers and work ID generation**

Implement Python helpers with exact signatures inside the CLI prelude:

```python
def new_work_id(now_ms=None, random_bytes=None) -> str: ...
def load_work(work_root: Path, work_id: str) -> tuple[Path, dict]: ...
def save_work_manifest(work_dir: Path, manifest: dict) -> None: ...
def file_fingerprint(path: Path) -> str | None: ...
```

Validate `kind` as `resource|literature|reference|evergreen|migration` and statuses as `active|blocked|failed|ready-to-finalize|commit-failed|repair-required`.

- [ ] **Step 4: Implement create/list/inspect/update/resume/discard**

Use JSON default and `--format table` only on list/inspect. `resume` validates source/target fingerprints and returns state; it does not claim to resume conversation. `discard` previews interactively and requires `--yes` in non-interactive use; support `--no-input`.

- [ ] **Step 5: Add subcommand help**

Support `slipbox work --help` and `slipbox work <action> --help`. Do not regress top-level help.

- [ ] **Step 6: Run tests and error-contract checks**

Expected: every invalid invocation prints one JSON error object to stderr and no traceback.

- [ ] **Step 7: Commit**

```bash
git add skills/setup-slipbox/scripts/slipbox docs/slipbox-cli.md tests/setup-slipbox/slipbox.sh
git commit -m "feat(cli): add recoverable work lifecycle"
```

---

### Task 4: Implement source-map cache commands and validation

**Files:**
- Modify: `skills/setup-slipbox/scripts/slipbox`
- Modify: `docs/slipbox-cli.md`
- Modify: `tests/setup-slipbox/slipbox.sh`
- Modify: `skills/using-slipbox/references/source-map-cache.md`

**Interfaces:**
- Produces: `cache status|inspect|store|remove` and cache identity keyed by Resource SHA-256.
- Cache required metadata: schema/map contract/producer versions, source fingerprint/known paths, timestamps.

- [ ] **Step 1: Add failing cache tests**

Cover one cache per identical Resource bytes, path rename reuse, incompatible contract reporting, JSON/table status, explicit remove confirmation, atomic store, and no semantic `cache build` command.

- [ ] **Step 2: Run tests and verify unknown `cache` failure**

- [ ] **Step 3: Implement strict cache schema validation**

Require top-level sections `source`, `contract`, `posture`, `source_spine`, `source_units`, `relations`, `core_idea_candidates`, `integrity_flags`, `concept_candidates`, `referent_candidates`, timestamps. Allow progressive empty arrays/optional per-unit epistemic fields; reject transcript/unknown top-level payload keys.

- [ ] **Step 4: Implement cache commands**

`store` accepts validated JSON from a file or stdin, verifies the Resource fingerprint, and atomically writes `<sha256>.json`. `status` reports compatible/missing/incompatible/older/orphaned states mechanically; it never derives semantic maps.

- [ ] **Step 5: Update `/using-slipbox` cache actions and docs**

State that agents build/refresh semantic content; the CLI only validates, stores, inspects, and removes.

- [ ] **Step 6: Run tests**

Expected: PASS including malformed UTF-8/JSON, stale known paths, and cache persistence policy behavior.

- [ ] **Step 7: Commit**

```bash
git add skills/setup-slipbox/scripts/slipbox skills/using-slipbox/references/source-map-cache.md docs/slipbox-cli.md tests/setup-slipbox/slipbox.sh
git commit -m "feat(cli): manage versioned source-map caches"
```

---

### Task 5: Add append-only link removal events

**Files:**
- Modify: `skills/setup-slipbox/scripts/slipbox`
- Modify: `skills/setup-slipbox/assets/AGENTS.md`
- Modify: `skills/using-slipbox/references/link-ledger.md`
- Modify: `docs/slipbox-cli.md`
- Modify: `tests/setup-slipbox/slipbox.sh`

**Interfaces:**
- Produces: `links remove --source S --target T --rel cites|extends`.
- `links find` returns active edges after folding legacy add rows, explicit add events, and removal tombstones in file order.

- [ ] **Step 1: Add failing fold/tombstone tests**

Test legacy rows as adds, add→remove absence, add→remove→add presence, removing missing edge as idempotent warning/success, corrupt event failure with line number, and exact relationship identity.

- [ ] **Step 2: Run tests and verify `links remove` failure**

- [ ] **Step 3: Implement event normalization and fold**

```python
def normalize_link_event(row: dict) -> dict:
    return {"op": row.get("op", "add"), "source_slug": row["source_slug"],
            "target_slug": row["target_slug"], "rel_type": row["rel_type"]}

def fold_link_events(rows: list[dict]) -> list[dict]: ...
```

Append tombstones; never rewrite JSONL history.

- [ ] **Step 4: Update runtime action and docs**

Document “Remove a link `/using-slipbox`” and migration compensation semantics.

- [ ] **Step 5: Run full CLI tests**

- [ ] **Step 6: Commit**

```bash
git add skills/setup-slipbox/scripts/slipbox skills/setup-slipbox/assets/AGENTS.md skills/using-slipbox/references/link-ledger.md docs/slipbox-cli.md tests/setup-slipbox/slipbox.sh
git commit -m "feat(cli): add append-only link tombstones"
```

---

### Task 6: Implement compare-and-swap and compensating publication

**Files:**
- Modify: `skills/setup-slipbox/scripts/slipbox`
- Modify: `skills/using-slipbox/references/work-lifecycle.md`
- Modify: `docs/slipbox-cli.md`
- Modify: `tests/setup-slipbox/slipbox.sh`

**Interfaces:**
- Produces: `work finalize <work-id>`.
- Consumes: validated draft, manifest baselines, staged mutation list.
- Guarantees: no silent target overwrite; rollback or `repair-required` diagnostics.

- [ ] **Step 1: Add failing transaction tests**

Cover new-file collision, changed target fingerprint, successful atomic replace, simulated second-file failure restoring first, ledger compensation via tombstone, simulated compensation failure → `repair-required`, and path-lock ordering.

- [ ] **Step 2: Run tests and verify failure**

- [ ] **Step 3: Implement staged mutation model**

```python
Mutation = dict  # keys: path, expected_fingerprint, replacement_path, kind
Backup = dict    # keys: path, existed, bytes, fingerprint

def preflight_mutations(mutations: list[Mutation]) -> list[Backup]: ...
def apply_mutations(mutations: list[Mutation], backups: list[Backup]) -> None: ...
def compensate(mutations: list[Mutation], backups: list[Backup]) -> list[str]: ...
```

- [ ] **Step 4: Add finalize command and status transitions**

Require `ready-to-finalize`; validate all draft/side-effect inputs before locks; update to `failed`, `repair-required`, or published state deterministically. Do not run Git in this task.

- [ ] **Step 5: Update runtime docs and run tests**

- [ ] **Step 6: Commit**

```bash
git add skills/setup-slipbox/scripts/slipbox skills/using-slipbox/references/work-lifecycle.md docs/slipbox-cli.md tests/setup-slipbox/slipbox.sh
git commit -m "feat(runtime): publish work with compensating transactions"
```

---

### Task 7: Implement exact-path Git finalization

**Files:**
- Modify: `skills/setup-slipbox/scripts/slipbox`
- Modify: `skills/using-slipbox/references/git-finalization.md`
- Modify: `skills/setup-slipbox/assets/AGENTS.md`
- Modify: `docs/slipbox-cli.md`
- Modify: `tests/setup-slipbox/slipbox.sh`

**Interfaces:**
- Produces: `work commit <work-id> [--yes|--leave-uncommitted]`.
- Consumes: work allowlist, baseline Git path states, activity, subject, configured mode/style.
- Guarantees: unrelated index unchanged; one commit/work ID; hooks honored; trailers present.

- [ ] **Step 1: Add failing Git integration tests in temporary repositories**

Create isolated fixture repos covering no repo→off, unrelated dirty/staged files, clean allowlist commit, pre-dirty affected path safety downgrade, hook failure, concurrent HEAD movement, ask/auto/off, cache local/tracked, and trailers.

- [ ] **Step 2: Run tests and verify failure**

- [ ] **Step 3: Implement runtime repo detection and baseline capture**

Never persist a detected Boolean. Store per-path baseline status and blob/worktree fingerprint in manifest. Build commit allowlist only from successful staged mutations.

- [ ] **Step 4: Implement isolated-index commit**

Use a temporary `GIT_INDEX_FILE`, seed from current `HEAD`, add exact allowlisted paths, run normal hooks, and update the current branch. Preserve the user's real index byte-for-byte. Reject/bound concurrent ref movement through Git's normal reference lock/update.

- [ ] **Step 5: Generate message and trailers**

Render detected/fallback subject and append:

```text
Slipbox-Activity: <kind>.<activity>
Slipbox-Work-ID: <work-id>
```

- [ ] **Step 6: Implement failure lifecycle**

Commit/hook failure keeps valid files and sets `commit-failed`; retry or explicit uncommitted finish cleans work. Never bypass hooks or roll back validated knowledge.

- [ ] **Step 7: Run full CLI tests**

- [ ] **Step 8: Commit**

```bash
git add skills/setup-slipbox/scripts/slipbox skills/setup-slipbox/assets/AGENTS.md skills/using-slipbox/references/git-finalization.md docs/slipbox-cli.md tests/setup-slipbox/slipbox.sh
git commit -m "feat(runtime): add isolated exact-path git finalization"
```

---

### Task 8: Runtime integration documentation and regression gate

**Files:**
- Modify: `README.md`
- Modify: `docs/README.md`
- Modify: `skills/setup-slipbox/assets/GLOSSARY.md`
- Modify: `CONTEXT.md`
- Modify: `tests/using-slipbox/evals.json`
- Modify: `tests/setup-slipbox/evals.json`
- Modify: `tests/write-checks/evals.json`

**Interfaces:**
- Consumes: Tasks 1–7.
- Produces: published runtime contract ready for specialist-plan consumption.

- [ ] **Step 1: Add cross-skill regression evals**

Cover natural caller syntax, no duplicated work/Git procedure in specialist skills, CLI-help authority, work recovery, cache policy, and Resource/Literature/Reference/Evergreen work kinds.

- [ ] **Step 2: Update top-level documentation and glossary**

Document the new engine and runtime files without yet claiming specialist workflow changes from later plans are shipped.

- [ ] **Step 3: Run mechanical suites**

Run:

```bash
bash tests/setup-slipbox/slipbox.sh
bash tests/write-checks/routing.sh
git diff --check
```

Run all affected eval files through the repository eval procedure.

Expected: PASS.

- [ ] **Step 4: Audit executable command references**

Run `rg -n '\.slipbox/bin/slipbox' skills docs` and verify shared work/cache/Git commands live only in `/using-slipbox` references, setup/runtime docs, or CLI docs; peer-domain exceptions must be justified.

- [ ] **Step 5: Commit**

```bash
git add README.md CONTEXT.md skills/setup-slipbox/assets/GLOSSARY.md docs tests/using-slipbox tests/setup-slipbox tests/write-checks
git commit -m "docs(runtime): publish shared slipbox transaction contract"
```

## Plan self-review

- Spec coverage: runtime engine, CLI ownership, work/cache lifecycle, tombstones, transaction safety, Git, config, setup migration detection, caller syntax, and tests are mapped to Tasks 1–8.
- Placeholder scan: no TBD/TODO/“similar to” steps remain.
- Interface consistency: all consumers use `work_id`; source caches key by Resource SHA-256; Git trailers use kind/activity plus work ID; later plans consume the committed runtime interfaces.

## Execution handoff

Execute in a fresh Terra-medium controller session with `superpowers:subagent-driven-development`. Dispatch each Task implementation and task review on Luna-medium, with corresponding Beads task/subtask records. Do not close the Slipbox epic. After all four plans complete, stop and report the branch ready. Create the final Sol-low whole-branch review as a separate task/thread; it may dispatch tracked Luna-low or Luna-medium fix subagents and perform scoped re-review.
