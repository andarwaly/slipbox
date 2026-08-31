# Literature Source Workflow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace claim-exhaustive Literature grounding with source-shaped, inquiry-led learning, adaptive Source Points, guided reading, and reusable per-Resource source maps.

**Architecture:** `make-literature-note` owns reading context, source posture, private source analysis, Adaptive Split Gate routing, Source Point semantics, and closeout. `/grounding` supplies active-learning techniques, including renamed `guided-reading`; `/using-slipbox` owns work/cache/publication/Git. Literature writes remain one-source and source-facing.

**Tech Stack:** Agent Skills Markdown, JSON evals, Markdown fixtures, shared Slipbox CLI/runtime from the runtime-engine plan.

**Spec:** `../../../../discussion/slipbox/discussion-topics/workflow-runtime-and-reference-notes.md`

## Global Constraints

- Execute after `2026-08-30-slipbox-runtime-engine.md`.
- Controller Terra-medium; every implementer/task reviewer Luna-medium. Final whole-branch review is a separate Sol-low task/thread after implementation, allowed to dispatch tracked Luna-low/medium fix subagents; every dispatch is tracked under the Slipbox Beads epic.
- Never close the Slipbox epic.
- Literature note stays one source, clean H1, bare Core Idea, `## Source Points`, no user stance.
- Source verification is agent-owned; user agreement never verifies source truth.
- Source maps contain no transcript, chain-of-thought, or reader-owned Evergreen synthesis.
- TDD and one independently reviewable commit per task.

---

### Task 1: Rewrite the shared Literature domain contract

**Files:**
- Modify: `CONTEXT.md`
- Modify: `skills/setup-slipbox/assets/GLOSSARY.md`
- Modify: `skills/make-literature-note/references/writing-a-claim.md`
- Rename: `skills/make-literature-note/references/writing-a-claim.md` → `skills/make-literature-note/references/writing-a-source-point.md`
- Modify: `AGENTS.md`

**Interfaces:**
- Produces definitions: Core Idea, Source Point, reading context, source posture, source-owned vs reader-owned proposition.
- Removes live `Claim`/`Key Claims` as canonical Literature output terminology while preserving historical discussion text.

- [ ] **Step 1: Add failing terminology regression assertions**

Add/modify Literature eval assertions so live output requires `Source Points`, accepts reporting/explanatory postures, and rejects `Key Claims`/“what did this author argue?” as universal language.

- [ ] **Step 2: Run Literature evals and verify failure**

- [ ] **Step 3: Rewrite glossary definitions**

Use exact boundary:

```markdown
**Source Point**: An independently interpretable, source-owned proposition selected
because it answers the user's inquiry, supports the Core Idea, prevents material
distortion, or preserves a distinct source idea worth retaining. It keeps local
posture, attribution, evidential status, scope, and qualifications.
```

Define Core Idea as what the source chiefly communicates through argument, explanation,
reporting, or mixture. Keep Open Questions and Assumption rules.

- [ ] **Step 4: Rename and rewrite the point-writing reference**

Change note structure to `## Source Points`; preserve conclusion-heading/evidence prose only where compatible; add reporting attribution/certainty checks and “independently interpretable without material distortion.”

- [ ] **Step 5: Update repository structure/cross-references and run terminology sweep**

Run:

```bash
rg -n 'writing-a-claim|## Key Claims|per Key Claim' skills CONTEXT.md AGENTS.md docs tests
```

Historical plans/discussion may retain old terms; live contracts may not.

- [ ] **Step 6: Commit**

```bash
git add -A CONTEXT.md AGENTS.md skills/setup-slipbox/assets/GLOSSARY.md skills/make-literature-note/references tests/make-literature-note
git commit -m "refactor(literature): define source-point note contract"
```

---

### Task 2: Replace discovery walk with adaptive guided reading

**Files:**
- Rename: `skills/grounding/references/discovery-walk.md` → `skills/grounding/references/guided-reading.md`
- Modify: `skills/grounding/SKILL.md`
- Modify: `docs/grounding.md`
- Modify: `tests/grounding/evals.json`

**Interfaces:**
- Produces technique `guided-reading` for not-started/partial source collaboration.
- Consumes reading context/state supplied by `make-literature-note`.

- [ ] **Step 1: Write failing evals for fluid route choice and adaptive moves**

Cases: explicit “finish first” receives natural acknowledgment without fixed card; unclear intent offers independent/collaborative choice; collaborative path may use explanation/clarification/comparison/retrieval/prediction but never requires prediction before every passage.

- [ ] **Step 2: Run grounding evals and verify old discovery-walk behavior fails**

- [ ] **Step 3: Rewrite the technique**

State semantic moves and support calibration, not fixed dialogue. Preserve one substantive question per turn. Remove the universal `what stood out?` opener from `grounding`; callers now supply context/read-state entry.

- [ ] **Step 4: Update dispatch table and docs**

Route source-present not-started/partial collaborative reading to `guided-reading`. Ensure direct `/grounding` without a wrapper still has a sensible plain-context opener.

- [ ] **Step 5: Run evals and cross-reference sweep**

```bash
rg -n 'discovery-walk|what stood out' skills/grounding docs/grounding.md tests/grounding
```

Expected: no live obsolete reference; historical docs excluded.

- [ ] **Step 6: Commit**

```bash
git add -A skills/grounding docs/grounding.md tests/grounding
git commit -m "feat(grounding): replace discovery walk with guided reading"
```

---

### Task 3: Define source-map and inquiry-map contracts

**Files:**
- Create: `skills/make-literature-note/references/source-map.md`
- Create: `skills/make-literature-note/references/adaptive-split-gate.md`
- Modify: `skills/make-literature-note/references/source-architecture.md`
- Modify: `tests/make-literature-note/evals.json`
- Create: `tests/make-literature-note/fixtures/source-map-conceptual-depth.json`
- Create: `tests/make-literature-note/fixtures/inquiry-map-conceptual-depth.json`

**Interfaces:**
- Source-map cache: source metadata/posture, 3–8 move spine, units, relationships, local epistemic metadata, plural Core Idea candidates, audit flags, concept/referent candidates.
- Inquiry map: reading context/state, unit relevance, learning relevance, interpretive risk, comprehension/selection/disposition, draft state.
- Derived grounding frontier; never stored as authoritative list.

- [ ] **Step 1: Add fixture validation/eval failures**

Assert source map excludes user inquiry and transcript; inquiry map references unit IDs; high-learning/low-risk routing requires user semantic relation then agent draft; low-learning/high-risk requires verification without forced paraphrase.

- [ ] **Step 2: Run evals and verify failure**

- [ ] **Step 3: Write source-map contract with progressive density**

Provide exact allowed relationships: `supports|explains|qualifies|contrasts-with|depends-on|example-of|evidence-for|counterargument-to|disputes|defines|causes|precedes|restates`. Define local epistemic fields and source-integrity flags.

- [ ] **Step 4: Write two-axis Gate routing matrix**

```markdown
| | Routine interpretation | Consequential/ambiguous |
|---|---|---|
| Inquiry-central | user reconstructs relation; agent drafts/verifies | user reconstructs; ambiguity discussed; agent verifies |
| Supporting/contextual | agent drafts/verifies | agent verifies; consult only for defensible-choice impact |
```

Define sufficient comprehension as an independently generated contrast/mechanism/condition/reason/implication/qualification/attribution relation; assent and keyword echo fail.

- [ ] **Step 5: Update source architecture to feed the map rather than output template**

- [ ] **Step 6: Run evals and validate fixtures as JSON**

```bash
jq empty tests/make-literature-note/fixtures/*map*.json
```

- [ ] **Step 7: Commit**

```bash
git add skills/make-literature-note/references tests/make-literature-note
git commit -m "feat(literature): define source and inquiry maps"
```

---

### Task 4: Rewrite `make-literature-note` entry and grounding flow

**Files:**
- Modify: `skills/make-literature-note/SKILL.md`
- Modify: `docs/make-literature-note.md`
- Modify: `tests/make-literature-note/evals.json`

**Interfaces:**
- Consumes: `/using-slipbox` work/cache actions, `guided-reading`, source/inquiry map contracts, Adaptive Split Gate.
- Produces: retained Source Points and staged Literature draft; no direct final-file mutation.

- [ ] **Step 1: Add failing workflow evals**

Cover context already explicit, implied reflection, absent-purpose question, exploratory mode, all four reading states, primary/secondary posture independent of Resource type, one sharp point complete, and news allegation preservation.

- [ ] **Step 2: Run evals and verify current universal opener/exhaustive audit fail**

- [ ] **Step 3: Rewrite entry sequence**

Use natural caller instructions:

```markdown
Start or resume Literature work for the Resource `/using-slipbox`.
```

Load/build source cache, create inquiry map, derive grounding frontier, then follow the inquiry one substantive question at a time.

- [ ] **Step 4: Replace per-point full Gate and direct writes**

Inquiry-central points require semantic reconstruction; supporting/contextual points may be agent-drafted. Every final point receives source audit. Checkpoint map and `draft.md` through `/using-slipbox`; never mutate final path mid-session.

- [ ] **Step 5: Update work status/recovery paths**

Returning invocation matches unfinished work, reuses prior comprehension evidence, and resumes next unresolved thinking obligation rather than repeating questions.

- [ ] **Step 6: Run evals**

- [ ] **Step 7: Commit**

```bash
git add skills/make-literature-note/SKILL.md docs/make-literature-note.md tests/make-literature-note/evals.json
git commit -m "feat(literature): make grounding inquiry-led and recoverable"
```

---

### Task 5: Implement closeout, optional discovery, and concepts/referents

**Files:**
- Modify: `skills/make-literature-note/SKILL.md`
- Modify: `skills/make-literature-note/references/writing-a-source-point.md`
- Modify: `tests/make-literature-note/evals.json`

**Interfaces:**
- Produces: completion based on inquiry+source orientation; one optional discovery batch; compact structural closeout; context-aware reader-owned handoff.

- [ ] **Step 1: Add failing closeout evals**

Cases: declining optional idea does not produce `partial`; source audit catches distortion/qualification but not every uncaptured proposition; Core Idea uses user reconstruction plus agent verification; compact closeout lists all retained headings; reaction prompt omitted for factual session; user-added relevant concept accepted.

- [ ] **Step 2: Run evals and verify failure**

- [ ] **Step 3: Rewrite completion audit**

Audit attribution/certainty/scope/chronology/causality/reported-vs-verified/speaker/analysis-vs-observation/dispute. Missing material blocks only when necessary for inquiry, Core Idea, or non-distortion.

- [ ] **Step 4: Add optional discovery and compact closeout behavior**

One closing batch, any/all/none. Then Core Idea active-learning moment. Show Core Idea, retained Source Point headings, Open Questions, unresolved discussed items, and saved path; full note only on request/structural review.

- [ ] **Step 5: Update Key Concepts/Mentioned selection**

Union of retained-point support, source-present inquiry relevance, and explicit user additions. Do not scan unrelated source-map candidates.

- [ ] **Step 6: Update reader-owned handoff**

When warranted and approved:

```markdown
Record an Evergreen candidate with the proposition, reason, and origin paths
`/using-slipbox`.
```

No mandatory reaction prompt.

- [ ] **Step 7: Run evals and commit**

```bash
git add skills/make-literature-note tests/make-literature-note
git commit -m "feat(literature): add bounded source-shaped closeout"
```

---

### Task 6: Add Literature cache and legacy migrations

**Files:**
- Modify: `skills/setup-slipbox/SKILL.md`
- Modify: `skills/make-literature-note/SKILL.md`
- Modify: `docs/setup-slipbox.md`
- Modify: `tests/setup-slipbox/evals.json`
- Modify: `tests/make-literature-note/evals.json`

**Interfaces:**
- Produces: cache inventory/build workflow and selectable exact-heading migration.

- [ ] **Step 1: Add failing existing-vault evals**

Cover no-cache existing Resource+Literature note, source-first map build, reconciliation statuses, missing Resource blocking, exact `Key Claims`→`Source Points` rename, unusual structure skip, compatible/older/incompatible cache handling, and selected/all/lazy/defer options.

- [ ] **Step 2: Run evals and verify failure**

- [ ] **Step 3: Implement source-first reconciliation**

Never build cache from selective Literature content. Map existing Core Idea/points/concepts/referents/Open Questions to source units with private statuses `matched|matched-with-qualification-risk|matched-to-multiple-units|unmatched|source-support-unclear`. Do not rewrite semantics automatically.

- [ ] **Step 4: Implement setup migration choices**

Build missing/incompatible (recommended), scoped, refresh all, or defer. Separate cache build from heading migration and from any later Reference migration.

- [ ] **Step 5: Run evals and commit**

```bash
git add skills/setup-slipbox/SKILL.md skills/make-literature-note/SKILL.md docs/setup-slipbox.md tests/setup-slipbox/evals.json tests/make-literature-note/evals.json
git commit -m "feat(literature): migrate source maps and source-point headings"
```

---

### Task 7: Literature end-to-end regression

**Files:**
- Modify: `tests/make-literature-note/evals.json`
- Modify: `tests/grounding/evals.json`
- Modify: `README.md`
- Modify: `docs/README.md`

**Interfaces:**
- Consumes: Tasks 1–6.
- Produces: verified Literature workflow ready for Reference plan.

- [ ] **Step 1: Add end-to-end cases**

Use fixtures for short essay, Wikipedia-like explanation, breaking news allegation, explanatory lecture, mixed investigation, partial reading resume, existing legacy note, and immediate Reference handoff data.

- [ ] **Step 2: Run all Literature/grounding evals**

- [ ] **Step 3: Run runtime mechanical tests**

```bash
bash tests/setup-slipbox/slipbox.sh
bash tests/write-checks/routing.sh
git diff --check
```

- [ ] **Step 4: Update public docs and version metadata**

Apply minor version bumps for mechanism changes under the workspace version convention.

- [ ] **Step 5: Commit**

```bash
git add README.md docs tests/make-literature-note tests/grounding skills/grounding/SKILL.md skills/make-literature-note/SKILL.md
git commit -m "test(literature): verify source-shaped workflow end to end"
```

## Plan self-review

- Spec coverage: terminology, opener, reading states, guided reading, posture, source/inquiry maps, Adaptive Split Gate, non-exhaustive completion, optional discoveries, Core Idea, concepts/referents, handoff, cache/migration, and transactions all map to Tasks 1–7.
- Placeholder scan: no placeholders or undefined cross-task interfaces.
- Type consistency: all work uses `work_id`; maps reference stable source-unit IDs; final note uses `Source Points`; caller actions use trailing `/using-slipbox`.

## Execution handoff

Run from a fresh Terra-medium controller after the runtime plan. Each Task implementation and review is a Luna-medium subagent with Beads tracking. Do not close the Slipbox epic. The Terra controller stops after all plans; final review starts later in a separate Sol-low task/thread, which may delegate tracked fixes to Luna-low/medium.
