# Reference Lookup Workflow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert Reference notes from source-shaped append-only syntheses into concise, source-independent, evidence-admitted lookup entries with safe recomposition and legacy migration.

**Architecture:** `make-reference-note` discovers candidates only from retained Literature content/user requests, applies lookup-specific admission, synthesizes through grounded Literature notes while verifying original Resources/source maps, and publishes through `/using-slipbox`. The final Reference note is the durable concept artifact; synthesis work is temporary.

**Tech Stack:** Agent Skills Markdown, JSON evals, Markdown fixtures, shared Slipbox runtime/CLI.

**Spec:** `../../../../discussion/slipbox/discussion-topics/workflow-runtime-and-reference-notes.md`

## Global Constraints

- Execute after runtime and Literature plans.
- Controller Terra-medium; implementers/reviewers Luna-medium. Final review is a separate Sol-low task/thread after implementation and may dispatch tracked Luna-low/medium fix subagents; every dispatch is tracked in Beads under the never-closed Slipbox epic.
- Reference H1 is clean; filename/link target uses configured prefix; displayed link label is clean.
- Original Resources—not Literature notes—populate configured `sources` frontmatter.
- Reference body is bounded lookup, not a generative model, source dossier, or Evergreen Take.
- TDD and one reviewable commit per task.

---

### Task 1: Rewrite Reference domain and admission rules

**Files:**
- Modify: `CONTEXT.md`
- Modify: `skills/setup-slipbox/assets/GLOSSARY.md`
- Modify: `tests/make-reference-note/evals.json`
- Modify: `tests/find-connections/evals.json`

**Interfaces:**
- Produces lookup-specific admission sequence and bounded Reference definition.

- [ ] **Step 1: Add failing admission evals**

Cases: authoritative one-source standard passes; source-specific coined term without independent support stays unresolved; contested definition needs independent support; Person/Location/Organization excluded; framework substeps remain inside natural unit; declarative-title test not invoked.

- [ ] **Step 2: Run evals and verify current rules fail**

- [ ] **Step 3: Rewrite Reference glossary**

Replace “atomic, evergreen-shaped” with concise concept-centered lookup. Define admission in this exact order: entity exclusion; stable lookup identity; source independence; boundedness; adaptive evidence sufficiency; natural-unit scope.

- [ ] **Step 4: Update discovery contract**

`find-connections --references` reads final Literature `Key Concepts`, `Mentioned`, and relevant retained prose. It may use caches only to verify a selected candidate, never to surface unretained candidates.

- [ ] **Step 5: Run evals and terminology sweep**

```bash
rg -n 'declarative-title|evergreen-shaped|source map.*candidate' CONTEXT.md skills tests docs
```

- [ ] **Step 6: Commit**

```bash
git add CONTEXT.md skills/setup-slipbox/assets/GLOSSARY.md tests/make-reference-note/evals.json tests/find-connections/evals.json skills/find-connections/SKILL.md
git commit -m "refactor(reference): define bounded lookup admission"
```

---

### Task 2: Define bounded adaptive body and provenance

**Files:**
- Create: `skills/make-reference-note/references/bounded-lookup.md`
- Modify: `skills/make-reference-note/SKILL.md`
- Modify: `docs/make-reference-note.md`
- Modify: `tests/make-reference-note/evals.json`
- Create: `tests/make-reference-note/fixtures/conceptual-depth-bounded.md`

**Interfaces:**
- Body: clean H1, one concise definition, essential characteristics/components, optional disambiguation.
- Adaptive subject kinds: concept/framework/tool/event/creative work; no subtype configs.
- Frontmatter: configured type/created/aliases/sources; `sources` resolves original Resources.

- [ ] **Step 1: Add failing body-shape evals/fixture assertions**

Reject mandatory body Sources/mechanism/application/implications/Open Questions. Test concept, tool, event, and creative-work inputs without fixed subtype headings. Assert clean H1 and prefixed basename/link target.

- [ ] **Step 2: Run evals and verify failure**

- [ ] **Step 3: Write bounded lookup reference**

Define “enough to identify X” and prohibit source-by-source organization. Add optional distinctions only when a common confusion materially impairs lookup.

- [ ] **Step 4: Rewrite source gathering/provenance resolution**

Read Literature characterizations, resolve each configured Literature `source` to the original Resource, verify against Resource/source map, deduplicate Resource links, and populate only configured frontmatter. Remove body-level provenance prose.

- [ ] **Step 5: Update clean prefix/H1 and alias behavior**

Use exact prefixed basename/link target and clean H1. Keep clean concept name in configured Reference `aliases`/`alt_names` when useful, distinct from per-link display alias.

- [ ] **Step 6: Run evals and validate fixture**

- [ ] **Step 7: Commit**

```bash
git add skills/make-reference-note docs/make-reference-note.md tests/make-reference-note
git commit -m "feat(reference): write bounded lookup entries"
```

---

### Task 3: Implement adaptive evidence and unresolved outcomes

**Files:**
- Modify: `skills/make-reference-note/SKILL.md`
- Modify: `skills/find-connections/SKILL.md`
- Modify: `tests/make-reference-note/evals.json`
- Modify: `tests/find-connections/evals.json`

**Interfaces:**
- Produces admission result: `admitted` with grounded inputs or `unresolved` with missing support.
- No provisional Reference artifact.

- [ ] **Step 1: Add failing evidence-routing evals**

Cover authoritative primary source, two independent grounded sources, duplicated/non-independent sources, contested variants, direct user invocation with insufficient evidence, and find-connections recurrence that still fails admission.

- [ ] **Step 2: Run evals and verify failure**

- [ ] **Step 3: Implement deterministic admission narrative**

State why one source is authoritative or why independence is missing; never equate recurrence count with warrant. If unresolved, report support needed and leave wikilink untouched. Do not create work ID unless an artifact operation actually begins.

- [ ] **Step 4: Run evals and commit**

```bash
git add skills/make-reference-note/SKILL.md skills/find-connections/SKILL.md tests/make-reference-note/evals.json tests/find-connections/evals.json
git commit -m "feat(reference): gate lookup notes on evidence"
```

---

### Task 4: Add transactional synthesis and bounded recomposition

**Files:**
- Modify: `skills/make-reference-note/SKILL.md`
- Create: `skills/make-reference-note/references/synthesis-map.md`
- Modify: `skills/using-slipbox/references/work-lifecycle.md`
- Modify: `tests/make-reference-note/evals.json`

**Interfaces:**
- Reference work: manifest + `synthesis-map.json` + `draft.md`.
- Activity: `create|recompose|extend-provenance`.
- Agent owns verification; user handles naming/scope/genuine ambiguity/conflict.

- [ ] **Step 1: Add failing work/recomposition evals**

Cases: new admitted reference; new source adds warrant only; new source changes boundary; conflicting definitions preserved; no ceremonial confirmation; interruption resumes; concurrent target change blocks.

- [ ] **Step 2: Run evals and verify current append-only behavior fails**

- [ ] **Step 3: Rewrite synthesis flow**

```markdown
Start or resume Reference work for the candidate `/using-slipbox`.
Checkpoint the reconciled synthesis and bounded draft `/using-slipbox`.
Publish the Reference artifact `/using-slipbox`.
```

The synthesis map records contributing Literature paths, Resources, source-map fingerprints, admission evidence, agreements, conflicts, and proposed changes.

- [ ] **Step 4: Replace append-only body updates**

If new source only strengthens warrant, keep body bytes stable and update sources/Resource→Reference edge. If definition changes materially, recompose only required body. No permanent synthesis cache.

- [ ] **Step 5: Run evals and commit**

```bash
git add skills/make-reference-note skills/using-slipbox/references/work-lifecycle.md tests/make-reference-note/evals.json
git commit -m "feat(reference): recompose lookup notes transactionally"
```

---

### Task 5: Implement Reference provenance and legacy migration

**Files:**
- Modify: `skills/setup-slipbox/SKILL.md`
- Modify: `docs/setup-slipbox.md`
- Modify: `tests/setup-slipbox/evals.json`
- Modify: `tests/make-reference-note/evals.json`
- Modify: `skills/make-reference-note/SKILL.md`

**Interfaces:**
- Mechanical audit: clean H1, legacy term/reference fields, aliases, Resource provenance, duplicates, configured zones/types, ledger tombstones.
- Semantic classification: already bounded, detailed lookup, source dossier, admission failure.

- [ ] **Step 1: Add failing migration evals**

Cover Literature link in `sources`, both Literature+Resource duplicate, unresolved source, wrong Literature→Reference edge, prefixed H1, detailed generative body, source dossier, Person note misclassification, interrupted semantic migration.

- [ ] **Step 2: Run evals and verify failure**

- [ ] **Step 3: Implement safe mechanical audit/options**

Offer all/selected/lazy/defer. Normalize resolvable Literature provenance to Resources, deduplicate, clean H1, and use link tombstones + correct Resource edge. Skip unresolved structures.

- [ ] **Step 4: Implement scoped semantic migration**

For selected notes, create Reference work, re-verify original inputs, classify unique removed material as already preserved source detail, reader-owned Evergreen candidate, unsupported, or unresolved. Never silently delete/reclassify.

- [ ] **Step 5: Run evals and commit**

```bash
git add skills/setup-slipbox/SKILL.md skills/make-reference-note/SKILL.md docs/setup-slipbox.md tests/setup-slipbox/evals.json tests/make-reference-note/evals.json
git commit -m "feat(reference): migrate legacy lookup notes safely"
```

---

### Task 6: Reference end-to-end regression

**Files:**
- Modify: `README.md`
- Modify: `docs/README.md`
- Modify: `tests/make-reference-note/evals.json`
- Modify: `tests/find-connections/evals.json`
- Modify: `skills/make-reference-note/SKILL.md`
- Modify: `skills/find-connections/SKILL.md`

**Interfaces:**
- Consumes Tasks 1–5; produces completed Reference milestone.

- [ ] **Step 1: Add end-to-end fixtures/cases**

Test concise concept, named framework, tool, event, creative work, insufficient coined term, disputed definition, warrant-only extension, recomposition, legacy migration, and immediate Literature handoff.

- [ ] **Step 2: Run Reference and find-connections evals**

- [ ] **Step 3: Run full runtime mechanical tests**

```bash
bash tests/setup-slipbox/slipbox.sh
bash tests/write-checks/routing.sh
git diff --check
```

- [ ] **Step 4: Update docs/version metadata and run live-term sweep**

Apply minor version bumps for mechanism changes. Ensure live docs no longer claim Reference is evergreen-shaped, append-only, or declarative-title-tested.

- [ ] **Step 5: Commit**

```bash
git add README.md docs skills/make-reference-note skills/find-connections tests/make-reference-note tests/find-connections
git commit -m "test(reference): verify bounded lookup workflow end to end"
```

## Plan self-review

- Coverage: lookup purpose, subject kinds, admission, evidence, unresolved state, source provenance, clean title/prefix, agent-owned verification, recomposition, transactions, discovery boundary, and migrations all map to Tasks 1–6.
- Placeholder scan: none.
- Interface consistency: `sources` always Resources; work uses `work_id`; no permanent Reference synthesis cache; caches never surface candidates.

## Execution handoff

Execute from a fresh Terra-medium controller after runtime and Literature. Each Task implementer and reviewer is Luna-medium with Beads tracking. Keep Slipbox epic in progress. After all plans finish, stop the Terra controller and create a separate Sol-low review task/thread; it may delegate tracked fixes to Luna-low/medium.
