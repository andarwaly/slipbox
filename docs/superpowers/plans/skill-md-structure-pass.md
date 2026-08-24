# Plan: SKILL.md structure pass (Phase 1)

## Spec

`discussion/slipbox/discussion-topics/skill-md-body-structure.md` in the sibling
`skill-kojo` repo (`../../../discussion/slipbox/discussion-topics/skill-md-body-structure.md`
relative to this file) is the binding spec — its `## Resolution` section is the ruling
this plan argues from. This plan file breaks that ruling into four independent,
per-skill-group tasks. Do not re-derive the shape from first principles; read the spec.

## Global Constraints

Apply to every task below, no exceptions found in a task's own text override these:

1. **Heading skeleton, in order**: Title (H1) → scope line as inline prose under the H1
   (no heading) → `## Prerequisite` (bulleted MUST/NEVER) → mode-selection H2 (only if
   the skill branches on an explicit flag) → take-the-input H2 → core procedure (either
   `## Workflow` with `### 01 - Step Name` children if the procedure is a genuinely
   fixed, unconditional sequence, or plain descriptive non-numbered headings if it
   branches/dispatches) → `## Write` positioned exactly where persistence happens
   chronologically → `## Done` → trailing edge-case H2s (Open questions, re-run
   semantics) → `## References` table (file | one-line purpose | triggering condition),
   last section overall, only when `references/` exists.
2. **Config access**: never describe a raw/mental read of `.slipbox/config.json`.
   Always `.slipbox/bin/slipbox config get/set <dotted.path>` — no bare `slipbox`,
   no exceptions, including inside a `references/` file describing an algorithm.
3. **Duplicated substance** (the same rule/fact stated in full more than once, in one
   file or across a skill's own files) collapses to one canonical location, with every
   other occurrence reduced to a one-line pointer into it.
4. **Scope-disclaimer headings** (a boundary statement given its own H2, e.g. "This
   skill never runs /grounding") demote to one sentence of inline prose under the H1.
5. **No behavior change.** This is a structural/wording pass only. If a fix seems to
   require changing what the skill actually does (not just how it's organized/worded),
   stop and report it as a concern rather than deciding it — do not resolve it silently.
6. **Version bump**: patch (`1.x.Z+1`) for wording/structure-only changes; minor
   (`1.X+1.0`) when a task adds a real mechanism (a new required gate, a new
   `references/` file that didn't exist before). Each task states which applies; where
   it says "use judgment," report the choice and why in your report file.
7. **Commit per skill touched**, message `refactor(<skill>): apply canonical SKILL.md body structure`.
   Multiple skills in one task get multiple commits, not one combined commit.
8. Do not edit anything outside the skill directories your task names. Root-level
   `GLOSSARY.md`/`CONTEXT.md`/`AGENTS.md` are read-only context for this pass.
9. No tests to run — this is markdown documentation editing, not code. Self-review means
   re-reading your own diff against these constraints and the task's specific items,
   not running a test suite.

## Pre-flight scan

Four tasks, each touching only its own named skill directories
(`skills/<name>/SKILL.md` and `skills/<name>/references/*`). No two tasks share a file.
No task touches a root-level file. Scan: clean, no cross-task conflicts to rule on.

## Task 1: mechanical structure fixes — ground-me, find-connections, write-checks, clip-resource

Model: cheapest tier (complete, mechanical spec; transcription + verification, not design).

Apply, per skill (read each skill's current `SKILL.md` before editing — line numbers
below are from the audit that produced the spec and may have drifted):

**`skills/ground-me/SKILL.md`**
- Add a `## Prerequisite` section (currently missing — the only skill without one):
  bullet that `.slipbox/AGENTS.md` MUST exist, else stop and tell the user to run
  `setup-slipbox`. Place directly after the H1 (and after a scope line, if one exists).
- Version bump: minor (adds a new gate).

**`skills/find-connections/SKILL.md`**
- Two occurrences of `/make-reference-note` are currently slash-prefixed; fix both to
  bare `` `make-reference-note` `` (backtick only, no slash) — every skill except
  `/grounding` and `/write-checks` is referenced bare per the family's own convention.
- The reusability test (deletion test + declarative-title test) and the entity-check-
  before-reusability rationale are each restated here in full, duplicating CONTEXT.md's
  own definition. Collapse both to a short pointer at the name/test, not a restatement.
- Version bump: patch.

**`skills/write-checks/SKILL.md`**
- Move "## Invocation modes" to directly after "## Prerequisite" (currently it sits
  after Style and Humanize) — it determines whether later sections even apply, so it
  needs to be read before them.
- Rewrite "## Prerequisite" as bulleted MUST/NEVER.
- Normalize the bare `slipbox config get`/`slipbox config set` calls (three of them) to
  `.slipbox/bin/slipbox config get`/`.slipbox/bin/slipbox config set`.
- The rule "style-profile.json is read for language-gating only, never as a humanize-
  detection baseline" is stated once in Style and again, near-identically, in Humanize.
  Keep one statement, reduce the other to a pointer.
- Version bump: patch.

**`skills/clip-resource/SKILL.md`**
- Rewrite "## Prerequisite" as bulleted MUST/NEVER.
- Normalize the four bare `slipbox config get` calls to `.slipbox/bin/slipbox config get`.
- The Resource `type`-field rule (frontmatter holds the content type directly, never a
  generic `"resource"` value) restates CONTEXT.md's own definition verbatim — collapse
  to a short pointer to `GLOSSARY.md` instead of restating it.
- The bare-vs-quoted `{{variable}}` explanation is currently given in full three times:
  inline in "Transform," inline again in "Variable syntax (summary)," and in
  `references/variable-glossary.md`. Keep the fullest version in
  `references/variable-glossary.md` only; reduce both inline occurrences to short
  pointers.
- Add a `## References` table (file | purpose | triggering condition) covering:
  `extract-article-news.md`, `extract-social.md`, `extract-video.md`,
  `filter-glossary.md`, `url-patterns.md`, `variable-glossary.md`.
- Its procedure (Take the URL(s) → Detect the content type → Fetch and extract →
  Transform → Write → Report the outcome) is a fixed, unconditional sequence for every
  run — wrap it under a literal `## Workflow` heading with `### 01 - Take the URL(s)`,
  `### 02 - Detect the content type`, etc., keeping each step's existing descriptive
  name after its number.
- Version bump: patch.

Report file: `docs/superpowers/plans/.sdd-task1-report.md` (actual path comes from the
report-file convention below).

## Task 2: grounding, setup-slipbox

Model: standard tier — cross-file coherence (grounding/SKILL.md + compass.md must stay
consistent) and a structural judgment call (setup-slipbox's Workflow numbering, field_map
subheadings).

**`skills/grounding/SKILL.md` + `skills/grounding/references/compass.md`**
- In "## Never finish it for them," the worked example presupposes Compass's four
  directions before "## Choosing a technique" (later in the file) ever introduces
  Compass — a forward reference. Prefer generalizing that example to a technique-agnostic
  one over reordering sections; "never finish it for them" is a general rule and
  shouldn't need Compass specifically to illustrate it.
- In `references/compass.md`, the text describing a spawned sub-idea being logged to the
  evergreen backlog (`slipbox evergreen add ...`) currently reads as if Compass itself
  performs the write. Reword to attribute the write to "whichever skill invoked this
  one" — matching `SKILL.md`'s own Done section ("no database write of any kind... all
  of that belongs to whichever skill invoked this one").
- Add a `## References` table at the end of `SKILL.md` covering all ten technique files:
  `verification.md`, `elenchus.md`, `feynman.md`, `discovery-walk.md`, `maieutic.md`,
  `self-explanation.md`, `compass.md`, `connect.md`, `challenge.md`, `distil.md`.
- `grounding`'s core procedure is dispatch-driven (a reading-state table), not a fixed
  sequence — do NOT add a `## Workflow` wrapper or numbering; keep the existing
  descriptive headings (Fidelity, Never your own opinion, Never finish it for them,
  Reading the answer, Choosing a technique, Gate, Noticing a tension, Done).
- `grounding` has no Prerequisite and keeps none — it's an engine invoked mid-procedure
  by an already-gated caller.
- Version bump: patch (one `metadata.version` field covers both files in this skill).

**`skills/setup-slipbox/SKILL.md`**
- The required-fields table (Literature/Reference/Evergreen field lists) is currently
  stated twice in the `field_map` section. Keep one occurrence; reduce the other to a
  short "see above" reference, or delete it if the first fully covers it.
- The file currently gives three different orderings of the same "what this skill
  produces" artifact list (the intro sentence, and the Done section manifest) — make all
  three consistent with one order (recommend: the order the file actually performs the
  writes in).
- The `field_map` subsection crams three branching algorithms (the main mapping table,
  the type-occupancy check, the type-mismatch check) under one H3 using bolded
  pseudo-headers as the only structure. Give each its own real H4 subheading.
- Confirm "## Re-run semantics" reads unambiguously as trailing/optional content after
  "## Done," not part of the main first-run path — reword if it doesn't, no reordering
  needed if it already sits after Done positionally.
- The core procedure (Explore → Section A: conventions → Section B: stated note
  preferences → write humanize-checklist.json → install the CLI → write config.json →
  copy GLOSSARY.md/write AGENTS.md) is a fixed, unconditional sequence for a first run
  — wrap it under a literal `## Workflow` heading with `### 01 - ...` numbered children,
  keeping each step's existing descriptive name after its number. "Re-run semantics"
  stays outside the Workflow block, as trailing content after Done.
- Version bump: patch.

## Task 3: make-literature-note

Model: standard-to-high tier — the largest, highest-risk file in the family; several
interacting changes across `SKILL.md` and its three reference files.

**`skills/make-literature-note/SKILL.md`**
- Move "## Write each claim, incrementally" to directly after "## Ground the source — one
  continuous conversation, not one session per claim" (before "## Knowing when the
  session is done" and its three subsections) — claims are written mid-conversation, not
  after session-end checks; the heading order should match that.
- The "three exemptions to the frozen-once-written rule" are stated in full twice (once
  near the density-merge discussion, once near Open Questions/claim-writing). Keep the
  fuller statement once; reduce the other to a one-line cross-reference.
- The "coverage check" (re-reading the source/backlog, batch-presenting what's missing)
  and "## Spot terms and entities" restate the same batch-diff-and-present mechanic
  nearly in full — `SKILL.md` itself already notes the overlap ("the same
  batch-presentation pattern as Spot terms and entities below"). Describe the mechanic
  once, in whichever section comes first, and have the other point back to it.
- Five occurrences reference `grounding` attributively without the slash prefix (e.g.
  "`grounding`'s own default Fidelity direction," "`grounding`'s persistent-opinion
  case," plus unformatted mentions). Normalize every reference — attributive or
  invocational — to `` `/grounding` ``, per the family's convention that it's always
  slash-prefixed wherever mentioned.
- Add a `## References` table at the end covering `qew-theory.md`,
  `source-architecture.md`, `writing-a-claim.md`.
- Normalize any bare `slipbox config` calls found to the full `.slipbox/bin/slipbox` path.
- Do NOT add a `## Workflow` wrapper — this is a continuous conversation with a
  backlog/Gate loop, not a fixed linear sequence. Keep existing descriptive headings.

**`skills/make-literature-note/references/writing-a-claim.md`**
- The prefix-resolution algorithm (resolving `prefixes.literature` or `prefixes.reference`
  from config to build a wikilink) is written out in full three separate times: once for
  the note's own title prefix, once for an Answered-bullet link (which explicitly points
  forward to "the Reference-note rule below" — a forward reference), and once in full
  with Correct/Incorrect examples for Key Concepts links. Collapse into one canonical
  subsection, e.g. "## Resolving a note-type prefix," generic over `<type>` (covering
  `paths.<type>`, `filenames.<type>`, `prefixes.<type>`, keeping the existing
  Correct/Incorrect examples), with all three call sites reduced to a one-line pointer
  into it.
- Its own "## Open Questions" subsection restates rules already stated in `SKILL.md`'s
  "Ground the source" section (user-flagged-only, the `*Assumption*`/`*Answered*` bullet
  mechanics) nearly verbatim. Reduce to a short pointer back to `SKILL.md`, keeping only
  what's genuinely specific to this file (the markdown formatting/mechanics), not the
  policy rules.

**Explicitly out of scope for this task** — do not touch: operationalizing the
"out-of-band fidelity correction" exemption (tracked separately as a correctness bug,
not a structure item), trimming inline decision-log rationale prose, any change to the
actual claim-writing policy or behavior.

Version bump: patch, for `SKILL.md` and `writing-a-claim.md`.

## Task 4: make-reference-note, make-evergreen-note

Model: standard tier — moderate judgment, one genuine content-to-reference-file split.

**`skills/make-reference-note/SKILL.md`**
- Move "## This skill never runs /grounding" from its own H2 (currently before
  Prerequisite) to one sentence of inline prose directly under the H1 title.
- Three occurrences reference `/write-checks` with incorrect formatting (two missing
  backticks around the slash-prefixed name, one missing both the slash and the
  backticks around plain "write-checks"). Normalize all three to `` `/write-checks` ``.
- Shrink "## What these words mean" to a naming-only line (bold the term, e.g.
  "**Reference note**" — no multi-sentence re-derivation of its definition). The actual
  definition lives solely in `GLOSSARY.md`.
- No `references/` folder exists for this skill — do not add a References table.
- Version bump: patch.

**`skills/make-evergreen-note/SKILL.md`**
- Merge "## Ground it" and the following "## Purity check, before writing" (a separate
  4-line H2) into one section — fold the purity-check content in as the closing part of
  "Ground it" rather than its own heading.
- Shrink "## What these words mean" to a naming-only line, same treatment as
  `make-reference-note` above.
- "## Sign-off, shown to the user before finishing" currently holds 35+ lines of inline
  Matuschak/Ahrens theory/citation (the "### Concept" subsection) before its actual 5
  operational "### Criteria" bullets. Extract the theory/citation content into a new file
  at `skills/make-evergreen-note/references/sign-off-theory.md` (an empty, untracked
  `references/` directory already exists — use it). Leave "## Sign-off" in `SKILL.md`
  with only the "### Criteria" bullets plus a one-line pointer to the new file for
  readers who want the rationale.
- Add a `## References` table at the end of `SKILL.md` now that
  `references/sign-off-theory.md` exists.
- Its procedure (Take the material → Ground it → Write → Sign-off → Done) is mostly a
  fixed sequence. Use judgment on whether "Sign-off" belongs inside a numbered
  `## Workflow` block as a step, or stays outside it as a pre-write gate immediately
  before Write/Done (closer in kind to a check than a workflow step). Report which you
  chose and why.
- Version bump: minor (the `references/` file is a real structural addition, not just
  wording).

Report file: `docs/superpowers/plans/.sdd-task4-report.md`.
