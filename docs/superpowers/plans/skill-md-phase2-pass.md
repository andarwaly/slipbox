# Plan: Phase 2 content pass (vertical slices)

## Spec

Two binding sources in the sibling `skill-kojo` repo:
- `discussion/slipbox/discussion-topics/grounding-family-writing-for-agents-review.md` —
  resolved-but-unapplied dispositions from a prior `writing-for-agents` sweep.
- `discussion/slipbox/discussion-topics/skill-review-correctness-bugs.md` — four tracked
  defects, status `open` until each is fixed here.

Each task below is a vertical slice: one skill (or a tightly coupled pair) gets every
applicable item from both sources in one pass, not revisited later. Order follows the
dependency check recorded across three decision topics — `ground-me-necessity.md`
(resolved: keep, no slice needed), `grounding-verification-elenchus-redundancy.md`
(resolved: keep as-is, narrows grounding's slice to dispositions only), and
`evergreen-backlog-shared-explanation.md` (open, deferred — narrows the
make-reference-note/make-evergreen-note slice to exclude the backlog-explanation dup).

## Global Constraints

1. No behavior change beyond what a specific disposition/bug item explicitly calls for
   — this is still a documentation-content pass, not a redesign.
2. Every fix stays consistent with the canonical body shape already applied in Phase 1
   (heading skeleton, bulleted Prerequisite, `.slipbox/bin/slipbox` config access,
   duplication-collapse-to-one-source). Don't reintroduce a pattern Phase 1 removed.
3. Version bump: patch for wording/content fixes; minor only if an item adds a genuine
   new mechanism (state which applies per item touched).
4. Commit per skill touched, message `content(<skill>): apply phase 2 dispositions and fixes`.
5. Quote the disposition/bug text you're implementing back in your report — don't
   paraphrase from memory of the brief; verify against the skill's current file state,
   since Phase 1 already changed line numbers and some wording.
6. No tests exist for this repo's markdown files. Self-review means re-reading the diff
   against the brief.

## Task 1: setup-slipbox

Model: standard tier (several distinct small fixes, some requiring careful wording, no
deep judgment call).

Apply, all against the CURRENT file (re-read before editing; line numbers below are
approximate, from a fresh audit, and may drift further as you edit):

**Old dispositions:**
- Cut the duplicated "`paths.term`→`paths.reference` rename" note — it's currently
  stated twice (once in Section A, once in the Write config.json step). Keep one
  occurrence; the historical rename fact doesn't change what the agent does at either
  site, both only need the current name. The Section A occurrence also cites a
  `discussion/slipbox/discussion-topics/reference-note-admission-contract.md` path
  directly — repoint that to `GLOSSARY.md` instead (a shipped skill can never read a
  `discussion/` path at runtime — it doesn't ship).
- The field_map schema shape (`name`/`type`/`wikilink`/`zone`/`deferred`/bare-string
  forms) is currently restated in prose in the "Write config.json" step, duplicating
  `assets/config.schema.json`'s own canonical `description` field. Trim that restatement
  to "see the field_map shape in `assets/config.schema.json`" — do NOT touch the
  resolution-*process* guidance (the type-occupancy check, the interactive three-way
  branch) elsewhere in the file; that's genuinely distinct content (how to resolve a
  mapping, not what the final shape is).
- The re-run trigger condition is inconsistent across the file: the "Re-run semantics"
  section's own header currently implies the trigger is `.slipbox/` existing, but the
  actual branch logic (in the Explore/first-run-detection step) distinguishes bare
  `.slipbox/` with no `config.json` (→ interrupted prior run, clean restart) from
  `.slipbox/config.json` actually existing (→ the real re-run/drift-check flow). Fix the
  "Re-run semantics" header to say: triggered only when the user explicitly asks to
  re-run, or when the setup step finds `.slipbox/config.json` already present — not
  bare `.slipbox/` existing.
- The Explore/Section A step currently describes referencing existing note folders as
  "a style corpus for Section B" — this phrase is the actual source of a temptation the
  file separately warns against (analyzing a corpus / inferring a voice fingerprint).
  Reword it to something like "a general sense of the vault's existing formatting and
  structure, referenced for context, never analyzed as a sample set" — drop "corpus"
  entirely from this line. Leave the downstream prohibition (do not analyze a corpus,
  infer a voice fingerprint, or create `stated_style.json`) as a guardrail — it stays,
  just no longer contradicted by this earlier line's own wording.
- Cut every mention of `stated_style.json` in this file (there are two: the prohibition
  line and its echo elsewhere) — confirmed to be a dev-only artifact from an earlier
  build of this skill, never a real shipped output any vault could have. Don't touch
  anything else in the sentences it's cut from.
- Add a TinyFish prerequisite check: detect-and-report only, no install attempt (TinyFish
  is an MCP-based tool, not a CLI binary/Python library like the other three
  prerequisites this file already checks for — there's no local install step to run for
  it). State plainly that Social-type clipping still fully works Firecrawl-only if
  TinyFish isn't available. Add this as one more bullet/check alongside the file's
  existing Prerequisites content, same shape as the other checks there.

**Bugs (from skill-review-correctness-bugs.md):**
- Phase-count mismatch: the "Write .slipbox/humanize-checklist.json" step currently
  claims the snapshot records "detection, meaning-preserving rewrite, preference-context,
  and final-audit phases" — four items. The actual asset's `workflow.phases` array has
  three entries (`detection`, `meaning_preserving_rewrite`, `final_audit`);
  `preference_context` is a sibling config object under `workflow`, not a phase. Correct
  the sentence to accurately describe three phases plus `preference_context` as a
  separate config concern (e.g. "the snapshot records humanizer v2.8.0's detection,
  meaning-preserving rewrite, and final-audit phases, plus a preference-context config
  block read from `style-profile.json`").
- CLI-doc coverage gap: this file's own procedure text never mentions the `evergreen`,
  `links`, or `humanize check` CLI subcommands anywhere — only `config get`/`config set`.
  They're real, working subcommands in `scripts/slipbox`, and they're already documented
  in `assets/AGENTS.md` (the file this skill copies into the vault for other skills to
  read). Add one sentence — near wherever the CLI install step or the Done section
  currently lists what got installed — acknowledging that the CLI's full command surface
  (`evergreen`, `links`, `config`, `humanize`) is documented in the copied
  `.slipbox/AGENTS.md`, which other skills read from directly. Don't turn this file into
  a duplicate CLI reference — one pointing sentence closes the gap.

## Report file convention

Name each task's report `docs/superpowers/plans/.sdd-phase2-task-N-report.md` (the
sdd-workspace/task-brief scripts handle exact paths — this is just the naming pattern to
expect).

## Task 3: clip-resource

Model: standard tier (two distinct, well-scoped fixes; the second requires a real design
decision on how the invocation gets wired in).

A fresh audit found every old-disposition item for this skill already applied except
two. Do NOT re-touch anything else in this file — the multi-URL subagent design, the
url-patterns.md/extract-*.md splits, the TinyFish-first social fetcher, the Ladder
terminology, the "do not install X yourself" consolidation, and the Step 4 positive
rewording are all already correct on disk. Only these two:

**1. A guard the old disposition explicitly said to KEEP is missing.** The disposition
covering the Prerequisite section's negations said to cut "do not proceed to any other
step" (pure restatement, redundant) but explicitly KEEP "do not improvise conventions in
its place" (guards a distinct failure: fabricating a convention while stalled, rather
than simply failing to advance). The cut happened; the keep didn't — grep confirms
"improvise" appears nowhere in the current file. Add this guard back to the Prerequisite
section, in the file's now-bulleted MUST/NEVER form (Phase 1 already converted this
section to bullets) — e.g. a `NEVER: improvise a naming/folder convention in place of
running setup-slipbox` bullet alongside the existing "NEVER: proceed without either"
bullet.

**2. `references/variable-glossary.md:32` asserts a workflow that never actually fires.**
It states as fact: "Output from a quoted instruction enters the
`.slipbox/humanize-checklist.json` workflow because the agent synthesized or rewrote it;
bare-variable output never does, since there is nothing synthesized to check." But
nothing in `SKILL.md`'s actual procedure invokes `/write-checks` or mentions the
humanize-checklist workflow anywhere — the claim is a dangling assertion, not a wired
step. Fix by actually wiring it: in `SKILL.md`'s "### 06 - Write" step (or wherever
Transform hands off to Write), after a quoted-instruction variable was resolved for this
particular clip, run a `/write-checks` session in its checks-only mode (no field list —
this is a Resource, not a note, so the full frontmatter-resolution pass doesn't apply)
on the synthesized content before writing the file. If NO quoted instruction was used for
a given clip (bare variables only), skip this — matching variable-glossary.md's own
"bare-variable output never does" framing. State this conditionally in the Write step,
and update variable-glossary.md's line 32 if its wording needs to shift to match the
actual wired mechanism (e.g. naming the exact invocation point).

If wiring this in changes what "Write" actually does in a way that reads as more than a
structural/wording change, flag it in your report — this item is closer to closing a real
functional gap (the claim was previously unenforced) than a pure rewording, so it may
warrant a minor version bump rather than patch; use judgment and state which you chose.

## Task 4: make-literature-note

Model: standard tier — operationalizing a named-but-unimplemented exemption requires
matching an existing established shape (the density merge, the Open Questions append),
not inventing a new one from scratch.

A fresh audit found all 6 old-disposition items for this skill already satisfied
(several as confirmed no-ops, several as Phase 1 side effects) — do NOT touch anything
else in this file or its reference files. Only this one item:

**Operationalize the "out-of-band fidelity correction" exemption.** `CONTEXT.md` names
three co-equal exemptions to the literature note's frozen-once-written rule. Two —
the session-close density merge, and the `## Open Questions` append — get full
step-by-step procedures in `SKILL.md`. The third, the out-of-band fidelity correction,
is currently only ever named in a list ("distinct from the out-of-band fidelity
correction," `SKILL.md:250`) with no trigger, no confirmation step, and no write
procedure anywhere in `SKILL.md` or its three reference files.

Per `CONTEXT.md`'s own definition (read it for the exact scope — "fixing a misreading,
a transcription error, or wording that misrepresents the source — the correction must
move the note closer to the source"), give this exemption an actual procedure, matching
the shape the other two exemptions already use:

- **Trigger**: the user (not the agent unprompted — this is a correction the user
  notices, matching the family's user-flagged-only pattern used elsewhere in this skill)
  points out that an already-written Key Claim entry misreads, mistranscribes, or
  misrepresents the source.
- **Scope guard**: this is narrowly a fidelity fix, not a rewrite — the correction must
  move the note closer to the source, never introduce new synthesis, new wording style,
  or anything beyond fixing the specific inaccuracy. State this boundary explicitly so
  it can't be used as a backdoor for a general edit.
- **Confirmation**: run the correction through `/grounding`'s Gate before writing it —
  same discipline every other claim gets, not a shortcut just because it's a correction.
- **Write**: edit the existing Key Claim entry in place (this is the one case where an
  already-written entry is legitimately reopened) once Gate confirms the correction.

Place this as its own short subsection near the other two exemptions (the density merge
and the Open Questions append), in the file's existing prose/structure style — this is
new procedural content, not a reformat, so match the surrounding voice rather than
introducing bullets where the file doesn't already use them for this kind of content.
Cross-reference the other two exemptions the same way they currently cross-reference
each other and this one (the existing "distinct from the out-of-band fidelity
correction" line at `SKILL.md:250` should now point at real content instead of a bare
name).

This is a genuine new mechanism (a previously-unusable exemption becomes usable) —
version bump: minor.

## Task 5: make-reference-note

Model: cheapest tier (a single, fully-specified wording fix — the decision is already
made, this is transcription).

`make-evergreen-note` needs no changes in this pass — it carries no old-disposition
backlog item and no tracked bug; its only flagged item (the evergreen-backlog
explanation duplicated with `make-reference-note`) is explicitly deferred per
`evergreen-backlog-shared-explanation.md`. Do not touch `skills/make-evergreen-note/`.

Only `skills/make-reference-note/SKILL.md`'s `## Open` section needs work. It currently
reads (approximately, re-read the live file before editing):

> "**Still unresolved as of this writing**: whether extending an existing Reference note
> with a source that hasn't gone through `make-literature-note` yet routes there
> automatically (this skill triggering that flow itself) versus this skill simply
> stopping and telling the user to run it separately. This SKILL.md takes the
> stop-and-tell reading above as the safer default given the "no exception" rule, but
> the discussion record ... flags the routing mechanics themselves as open, not just the
> principle. Revisit ..."

This is resolved now, not open. Decision: keep stop-and-tell, no auto-routing — and there
is no missing "routing mechanics" to design, because the "Gather the grounded
characterizations" step (earlier in this same file) already runs this exact check
generically, for both a fresh write and an extension: it looks for a literature note
whose `## Key Concepts` wikilinks to the candidate; if none exists, it stops that source,
tells the user to run `make-literature-note` on it first (bare, backtick-only — never
slash-prefixed, per this family's own convention), and continues with whatever other
sources are already grounded. Since that step already fires before either Write branch,
there is nothing extension-specific left to wire.

Fix: replace the `## Open` section's content. Either delete the section entirely (if the
file has no other open items) or, if you find any other content under `## Open` this
brief doesn't name, leave that untouched and only replace this one item — with a short
note that this was resolved: point at "Gather the grounded characterizations" as the
mechanism that already answers it, and state plainly that no auto-routing was added and
none is needed. Match the file's existing prose voice; don't introduce bullets if this
section doesn't already use them for this kind of note.

Version bump: patch — this closes an open question with a pointer to existing behavior,
it doesn't add a new mechanism.

## Task 7: write-checks

Model: cheapest tier (one-line pointer correction, fully specified).

A fresh audit found every old-disposition item and the tracked bug for this skill
already satisfied, except one: the field_map schema-shape pointer (in the "Frontmatter
fields" section) currently reads "The stored shape for a resolved entry is defined
canonically in `.slipbox/config.json`'s own `description` field — not restated here" —
but `.slipbox/config.json` is the runtime instance file and has no such `description`
field. The actual canonical schema description lives in
`skills/setup-slipbox/assets/config.schema.json`'s own `description` field (confirmed on
disk). Fix: repoint this one sentence to name `assets/config.schema.json` instead of
`.slipbox/config.json`. Do not touch anything else in the file — everything else
(scoped config-access calls, the disable-model-invocation frontmatter, the negation
wording, the stateful-write documentation for the deferred field-mapping cache) is
already correct.

Version bump: patch.

## Task 8: setup-slipbox.md, ground-me.md, find-connections.md (docs sync, batch 1)

Model: standard tier (several distinct facts each, no deep judgment).

Scope widened beyond this session's own drift to the full backlog found in a fresh
docs-vs-SKILL.md audit. Fix everything found for these three doc pages — both drift
this session caused and pre-existing drift found in the same sweep.

**`docs/setup-slipbox.md`** (vs current `skills/setup-slipbox/SKILL.md`):
- Step 2 still says "existing note folders (Literature, Term, Evergreen)" — rename
  "Term" to "Reference" (the type was renamed `paths.term`→`paths.reference` long before
  this session; the doc never caught up).
- The doc's flat 1–7 list omits step `07 - Copy GLOSSARY.md and write .slipbox/AGENTS.md`
  entirely (it only lists through what's now step 06, "Write config.json") — add it.
- Step 1 (Prerequisite check) only mentions `youtube-transcript-api` and `defuddle`;
  the current file also checks `firecrawl`'s auth status and, new this session, a
  TinyFish detect-and-report-only check (no install attempt — TinyFish is MCP-based,
  not a local dependency). Add both.
- Confirm the doc's re-run/drift-check description still matches (per the audit, it
  already does — no change needed there).

**`docs/ground-me.md`** (vs current `skills/ground-me/SKILL.md`):
- Add a mention of the Prerequisite gate this session added (`.slipbox/AGENTS.md` must
  exist, confirming `setup-slipbox` ran — currently entirely unmentioned in the doc).
- Add a description of the "Crystalized Thought" closing-card format (`## Done` in
  SKILL.md): Core Thesis line, an optional "Flagged for later" line omitted entirely
  when there's no tension to flag, one closing question. This existed before this
  session but was never documented in the doc.

**`docs/find-connections.md`** (vs current `skills/find-connections/SKILL.md`):
- Add a mention of the Prerequisite section (`.slipbox/AGENTS.md` check, and that every
  `slipbox` CLI call in this skill uses the full `.slipbox/bin/slipbox` path).
- The doc's flat "How `--references` works" (5 items) / "How `--evergreen` works" (3
  items) lists should reflect that `--references` mode scans `## Mentioned` sections too
  (not just `## Key Concepts`), explicitly does NOT scan `## Open Questions`, and that
  variant labels get carried forward as `alt_names` candidates on write.
- Add that `--evergreen` mode checks `.slipbox/bin/slipbox links find --source <slug>`
  first to avoid re-suggesting an already-linked pair, and that both link-writing and
  backlog-logging happen via specific CLI invocations (`.slipbox/bin/slipbox links add`,
  `.slipbox/bin/slipbox evergreen add`) — currently the doc describes these steps with
  no CLI detail at all.
- Add a one-line mention of the `## Done` completion criteria section.

Version: no `metadata.version` field exists in `docs/*.md` files — these are plain
human-facing pages, not skills. No version bump for this task or any doc-sync task.
Commit message: `docs(setup-slipbox,ground-me,find-connections): sync doc pages to current SKILL.md`.

## Task 9: clip-resource.md (docs sync)

Model: standard tier (the extraction-ladder clarification needs care to state precisely,
not deep judgment).

**`docs/clip-resource.md`** (vs current `skills/clip-resource/SKILL.md`):
- Frontmatter description and step 1 both frame this as fetching "a URL" (singular).
  Update to "one or more URLs," matching the current skill's multi-URL support (one
  subagent per URL, in parallel, with a sequential fallback if no subagent capability
  exists in this harness).
- Step 6 ("Report") only describes the single-outcome case. Add the batch-table report
  format used when multiple URLs were clipped in one run.
- Step 3 ("Extract facts") currently states one universal "extraction ladder: schema.org
  JSON-LD first, then `<meta>` tags, then LLM-read fallback" as if it applies to every
  content type. It doesn't — this specific three-rung Ladder is Social/Forum-specific.
  Article/News uses a different, two-rung Ladder (Defuddle first, Firecrawl fallback),
  and its `published` field resolves from Defuddle's own output, not this ladder at all.
  Correct step 3 to state both mechanisms distinctly rather than one generalized claim.
- Add a mention of the `## Prerequisite` section (requires `.slipbox/AGENTS.md` to
  exist, i.e. `setup-slipbox` has run, plus every dependency it checks for) — currently
  unmentioned anywhere in the doc.
- Step 5 ("Write") should mention the conditional `/write-checks` invocation: when a
  quoted `{{"instruction"}}` variable was resolved for a given clip (synthesized
  content), a `/write-checks` session runs in checks-only mode before writing; bare-
  variable-only clips skip this.
- Add a one-line mention that a `## References` table now exists at the end of the
  skill listing its six reference files.

Commit message: `docs(clip-resource): sync doc page to current SKILL.md`.

## Task 10: grounding.md (docs sync)

Model: standard tier — the heaviest single doc page in this backlog, many distinct
omissions to add without turning the doc into a restatement of SKILL.md.

**`docs/grounding.md`** (vs current `skills/grounding/SKILL.md`):
- The doc's numbered step list jumps from "Never your own opinion" straight to "Reading
  the answer," skipping an entire named section that exists between them in SKILL.md:
  "Never finish it for them" — the completion, candidate, connection, or counter-argument
  is always the user's to supply, never the agent's. Add it as its own item, in the
  doc's existing list style.
- Step "Fidelity" should mention: a source and retrieved notes can apply together, not
  just one at a time; the self-contradicting-source case; notes-vs-source conflict
  handling; the never-pre-quote-the-source rule; the second-restated-opinion routing
  offer. Summarize each in one clause — don't reproduce SKILL.md's full explanations.
- Step "Reading the answer" should mention the one-short-acknowledgment rule for
  Hesitant/Blank/Confused readings before the next question.
- Step "Gate" should mention the compound-claim incremental-build rule, and the
  discovery-walk exception (Gate fires once over the whole accumulated result at the
  end of a walk, not per turn).
- Step "Noticing a tension" should mention that at most one tension surfaces even if
  several came up — the rest are dropped silently, not queued.
- Add a one-line mention of the `## Done` hand-back contract (the confirmed statement
  verbatim, plus an optional flagged-tension description if opted into; no filename, no
  format, no database write — that's the calling skill's job).
- Add a one-line mention that a `## References` table now exists, listing all ten
  technique files.

Keep every addition proportionate to the doc's existing step-summary format — one clause
per fact, not a paragraph. This page is meant to orient a human reader, not replace
SKILL.md as the operational instructions.

Commit message: `docs(grounding): sync doc page to current SKILL.md`.
