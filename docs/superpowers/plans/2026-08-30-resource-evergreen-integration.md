# Resource and Evergreen Runtime Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the shared recoverable runtime, clean-title prefix contract, and staged side-effect publication to Resource clipping and Evergreen notes without redesigning their domain semantics.

**Architecture:** `clip-resource` and `make-evergreen-note` keep their existing extraction/Take behavior but delegate work lifecycle, draft publication, state mutations, and Git to `/using-slipbox`. Resource operations use extraction state and never replace frozen targets; Evergreen operations use temporary synthesis state and publish note/backlog/link changes as one compensated work item.

**Tech Stack:** Agent Skills Markdown, Bash/Python CLI interfaces from runtime plan, JSON evals, Markdown fixtures.

**Spec:** `../../../../discussion/slipbox/discussion-topics/workflow-runtime-and-reference-notes.md`

## Global Constraints

- Execute after the runtime plan; coordinate final title/prefix rules with Literature and Reference plans.
- Controller Terra-medium; implementers/reviewers Luna-medium; final whole-branch reviewer Sol-low; all dispatches tracked in Beads under the never-closed Slipbox epic.
- Do not reopen Evergreen Compass/Take/sign-off semantics.
- One URL = one Resource work ID; one Evergreen operation = one Evergreen work ID.
- Work directories never enter Git; exact side effects stay within the owning work transaction.
- TDD and independently reviewable commits.

---

### Task 1: Integrate recoverable Resource clipping

**Files:**
- Modify: `skills/clip-resource/SKILL.md`
- Modify: `docs/clip-resource.md`
- Modify: `tests/clip-resource/evals.json`
- Modify: `tests/setup-slipbox/slipbox.sh`
- Modify: `skills/using-slipbox/references/work-lifecycle.md`

**Interfaces:**
- Resource work: `manifest.json` + `extraction.json` + `draft.md`.
- Activity: `clip`; target is create-only/frozen.

- [ ] **Step 1: Add failing Resource work evals/tests**

Cover single URL recovery, transcript/fetch failure persistence, bare-variable draft transaction, synthesized Resource-mode `/write-checks`, target collision, frozen target non-replacement, resume/discard, and multi-URL work isolation.

- [ ] **Step 2: Run evals/mechanical tests and verify direct-write behavior fails**

- [ ] **Step 3: Rewrite Resource work lifecycle**

For each URL:

```markdown
Start Resource work for this URL `/using-slipbox`.
Checkpoint extraction state and the template-resolved draft `/using-slipbox`.
Publish the frozen Resource `/using-slipbox`.
```

Record detected type, method, metadata, status, and failure details. Do not create a permanent extraction cache.

- [ ] **Step 4: Preserve extraction semantics and batch independence**

Keep URL safety, content-type conflict handling, extraction references, template semantics, and one-result-per-URL reporting. Each URL receives independent work and commit boundary.

- [ ] **Step 5: Run tests and commit**

```bash
git add skills/clip-resource docs/clip-resource.md tests/clip-resource tests/setup-slipbox/slipbox.sh skills/using-slipbox/references/work-lifecycle.md
git commit -m "feat(resource): make clipping recoverable and atomic"
```

---

### Task 2: Integrate Evergreen recoverable work and staged side effects

**Files:**
- Modify: `skills/make-evergreen-note/SKILL.md`
- Modify: `docs/make-evergreen-note.md`
- Modify: `tests/make-evergreen-note/evals.json`
- Modify: `skills/using-slipbox/references/work-lifecycle.md`
- Modify: `skills/using-slipbox/references/evergreen-candidates.md`

**Interfaces:**
- Evergreen work: `manifest.json` + `synthesis-map.json` + `draft.md`.
- Activities: `create|revise`.
- Staged mutations: note, citations/link events, backlog status/slug/note-path update.

- [ ] **Step 1: Add failing Evergreen integration evals**

Cover backlog-origin create, bare hunch create, existing-note revise, interruption/resume, concurrent target change, clean H1/prefixed basename, staged citations/backlog updates, and failure compensation.

- [ ] **Step 2: Run evals and verify current direct writes/side effects fail**

- [ ] **Step 3: Replace direct writes with work actions**

Keep existing grounding/Compass/purity/sign-off content. Store contributing notes, user-owned Take, tensions, citations, and pending side effects in synthesis map. Publish note/backlog/link changes through one compensated work item.

- [ ] **Step 4: Normalize Evergreen candidate action calls**

Peer skills use natural action + marker. Remove duplicated `evergreen add` lifecycle prose where `/using-slipbox` owns it, while leaving domain triggers in the peer.

- [ ] **Step 5: Run evals and commit**

```bash
git add skills/make-evergreen-note docs/make-evergreen-note.md tests/make-evergreen-note skills/using-slipbox/references
git commit -m "feat(evergreen): publish takes through shared runtime"
```

---

### Task 3: Enforce universal prefix/link/H1 behavior

**Files:**
- Modify: `skills/write-checks/SKILL.md`
- Modify: `skills/setup-slipbox/SKILL.md`
- Modify: `skills/setup-slipbox/assets/config.schema.json`
- Modify: `skills/setup-slipbox/assets/AGENTS.md`
- Modify: `skills/make-reference-note/SKILL.md`
- Modify: `skills/make-evergreen-note/SKILL.md`
- Modify: `skills/make-literature-note/SKILL.md`
- Modify: `docs/write-checks.md`
- Modify: `tests/write-checks/evals.json`
- Modify: `tests/setup-slipbox/slipbox.sh`

**Interfaces:**
- Filename/link target: exact configured prefix.
- Display alias/link label: clean/unprefixed preferred.
- H1: clean/unprefixed for Literature, Reference, Evergreen.
- Resource: no prefix.

- [ ] **Step 1: Add failing cross-type prefix tests**

Assert:

```text
File: § Literature.md   Link: [[§ Literature|Literature]]   H1: # Literature
File: ※ Reference.md    Link: [[※ Reference|Reference]]     H1: # Reference
File: ✱ Evergreen.md    Link: [[✱ Evergreen|Evergreen]]     H1: # Evergreen
```

Reject unprefixed targets for prefixed files and reject prefix in any H1.

- [ ] **Step 2: Run tests and verify Reference/Evergreen H1 failures**

- [ ] **Step 3: Rewrite prefix contract and validator expectations**

Remove Literature-only H1 exception by making clean H1 universal. Rename setup wording to filename/link-target prefix. Keep Reference frontmatter alias distinct from per-link display alias.

- [ ] **Step 4: Add selectable mechanical migration evals**

Setup detects legacy prefixed H1s across Reference/Evergreen and exact `Key Claims` headings in Literature; offers all-valid/selected/lazy/defer and skips unusual structures.

- [ ] **Step 5: Run tests and commit**

```bash
git add skills/write-checks skills/setup-slipbox skills/make-reference-note skills/make-evergreen-note skills/make-literature-note docs/write-checks.md tests/write-checks tests/setup-slipbox/slipbox.sh
git commit -m "fix(naming): keep prefixes out of note headings"
```

---

### Task 4: Normalize shared action calls across peer skills

**Files:**
- Modify: `skills/find-connections/SKILL.md`
- Modify: `skills/make-literature-note/SKILL.md`
- Modify: `skills/make-reference-note/SKILL.md`
- Modify: `skills/make-evergreen-note/SKILL.md`
- Modify: `skills/clip-resource/SKILL.md`
- Modify: corresponding docs and eval files

**Interfaces:**
- Canonical trailing marker `/using-slipbox` and initial action vocabulary.

- [ ] **Step 1: Add failing action-vocabulary assertions**

Require canonical actions and reject direct shared commands/phrases such as “log tension,” “route seed,” “run `/using-slipbox`,” or duplicated Git/work lifecycle.

- [ ] **Step 2: Run evals and terminology sweep**

- [ ] **Step 3: Rewrite peer caller prose naturally**

Examples:

```markdown
Record an Evergreen candidate with the proposition, reason, and origin paths
`/using-slipbox`.

Record the approved link `/using-slipbox`.

Publish the artifact `/using-slipbox`.
```

Keep domain recognition in peers and operational guarantees in the engine.

- [ ] **Step 4: Run evals and commit**

```bash
git add skills docs tests
git commit -m "refactor(skills): centralize shared slipbox actions"
```

---

### Task 5: Whole-family integration regression

**Files:**
- Modify: `README.md`
- Modify: `docs/README.md`
- Modify: all affected eval files
- Modify: version metadata in changed `SKILL.md` files

**Interfaces:**
- Consumes all four plans; produces branch ready for final Sol-low review.

- [ ] **Step 1: Add cross-family scenarios**

Cover multi-URL clips; Resource→Literature→Reference immediate handoff with distinct work IDs; reader-owned Literature implication→Evergreen candidate; later Evergreen creation; tracked/local cache; Git ask/auto/off; pre-dirty downgrade; commit failure recovery; migration batch.

- [ ] **Step 2: Run every mechanical test**

```bash
bash tests/setup-slipbox/check-prereqs.sh
bash tests/setup-slipbox/install-prereqs.sh
bash tests/setup-slipbox/slipbox.sh
bash tests/write-checks/routing.sh
git diff --check
```

- [ ] **Step 3: Run all skill evals through the repository eval procedure**

Expected: all pass; document any harness-only limitation in the task report, not as an unchecked plan placeholder.

- [ ] **Step 4: Run live-contract sweeps**

```bash
rg -n '## Key Claims|discovery-walk|Run `/using-slipbox`|through `/using-slipbox`|git: true|evergreen-shaped|append-only body' skills docs CONTEXT.md AGENTS.md
```

Expected: no obsolete live-contract occurrence; historical plan text excluded.

- [ ] **Step 5: Update public docs and versions**

Apply minor/patch rules from workspace `AGENTS.md`. Ensure README installation makes `setup-slipbox` self-contained and names `/using-slipbox` as mandatory shared runtime skill for peer operations.

- [ ] **Step 6: Commit**

```bash
git add README.md CONTEXT.md AGENTS.md skills docs tests
git commit -m "test(slipbox): verify runtime redesign across the family"
```

## Plan self-review

- Coverage: Resource and Evergreen work, staged side effects, prefix/H1 consistency, action vocabulary, migrations, and whole-family verification map to Tasks 1–5.
- Placeholder scan: none.
- Interface consistency: work IDs remain per artifact; Resource final is frozen; Evergreen semantics unchanged; all shared actions use trailing `/using-slipbox`.

## Execution handoff

Execute after runtime and coordinate with Literature/Reference plans in a fresh Terra-medium controller. Each Task implementer and reviewer is Luna-medium with Beads tracking. Do not close the Slipbox epic. After this final integration task, dispatch the separately tracked Sol-low whole-branch reviewer.
