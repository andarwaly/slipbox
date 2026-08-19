# Grounding / Literature-Note Upgrades — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Before drafting any new prose in any task below, invoke `/mattpocock-skills:writing-for-agents` fresh — don't rely on an earlier read of it.

**Goal:** Apply every confirmed decision from four resolved discussion topics to the `grounding` and `make-literature-note` skills — persistent-opinion routing, off-source-question handling, the Open Questions mechanism, a new source-architecture reading pass, claim-writing quality checks (list-as-one-claim, Fidelity Signals), and a full rewrite of the session-close sequence (backlog three-state tracking, Core Idea confirmation, density/overlap review, a fresh source re-read, and an opinion-seed prompt).

**Architecture:** Same as the sibling plan — independent `SKILL.md` + `references/`/`assets/` bundles under `skills/`, each installed standalone via `npx skills add`. Every cross-skill fact resolves through `.slipbox/GLOSSARY.md` (the only thing that ships at runtime across skill boundaries) or gets restated inline — never through an authoring-time pointer at a sibling skill's bundle, and never at all toward `CONTEXT.md` or any `discussion/` file, since neither ships.

**Tech Stack:** Markdown (`SKILL.md`, `references/*.md`), JSON (`GLOSSARY.md` is markdown, not JSON — no schema changes this plan). No app code.

**Spec:** Four resolved discussion topics in the outer `skill-kojo` workspace, all `status: resolved`, all holding the ratified decisions this plan executes without re-deriving them:
- [`personal-drift-and-off-source-questions.md`](../../../../../discussion/slipbox/discussion-topics/personal-drift-and-off-source-questions.md)
- [`claim-density-and-compression.md`](../../../../../discussion/slipbox/discussion-topics/claim-density-and-compression.md)
- [`core-idea-never-gated.md`](../../../../../discussion/slipbox/discussion-topics/core-idea-never-gated.md)
- [`grounding-session-review-fixes.md`](../../../../../discussion/slipbox/discussion-topics/grounding-session-review-fixes.md)

---

## Global Constraints

- **No skill points outside its own bundled files at authoring time**, except through `.slipbox/GLOSSARY.md` (the only cross-skill fact that ships to the vault at runtime). A reference to `CONTEXT.md`, `reference-note-admission-contract.md`, or any other `discussion/` path is out of bounds inside any shipped `SKILL.md` or `references/*.md` — every rule sourced from a discussion topic this plan executes gets **restated directly** in the shipped file, or added to `GLOSSARY.md`, never cited by pointing at the topic file itself.
- **`.slipbox/config.json`, `.slipbox/AGENTS.md`, `.slipbox/GLOSSARY.md` are legitimate runtime paths**, not workspace-internal documents — referencing these is fine everywhere it already happens.
- **No numbered step-headings** in any `SKILL.md` — named, descriptive headings only.
- **"You"/"your" always means the agent**; the user is spelled out as "the user."
- **Leading words stay consistent**: Gate, Fidelity, Core Idea, Claim, Evidence, Warrant, Backlog, Open Question, Key Concepts, Mentioned, Session — reused exactly as already defined, never re-coined.
- **`metadata.version` stays under `1.x`** — minor bump for any mechanism change, patch for wording-only.
- **Prefer a script over manual repetition** for regression checks and cross-file consistency sweeps — see Task 1's grep script, rerun at the end of every later task, never re-derived by eye.
- **Real fixtures, not hypotheticals** — the two sources and one transcript captured in Task 2 are what every later task's eval step tests against.

---

## File Structure

New files this plan creates:

- `skills/make-literature-note/references/source-architecture.md` — the six-group private reading lens (Situation & Starting Point, Problem/Tension, Argument Movement, Support & Boundaries, Fidelity Signals, Resolution).
- `tests/make-literature-note/fixtures/sun-gating-and-morning-light.md` — the Banner Health source article.
- `tests/make-literature-note/fixtures/sun-gating-grounding-transcript.md` — the verbatim session transcript for that article.
- `tests/make-literature-note/fixtures/less-is-more.md` — the Jakub Krehel source article.
- `tests/make-literature-note/fixtures/less-is-more-note-before.md` — the 14-Key-Claim note produced before this plan's fixes, kept as a before/after comparison baseline.

Modified files:

- `skills/grounding/SKILL.md`
- `skills/make-literature-note/SKILL.md`
- `skills/make-literature-note/references/writing-a-claim.md`
- `skills/make-literature-note/references/qew-theory.md` (cross-reference only, Task 5)
- `skills/setup-slipbox/assets/GLOSSARY.md`
- `CONTEXT.md` (repo root — does not ship, edited as workspace documentation)
- `tests/make-literature-note/evals.json`

---

## Task 1: Sweep — build the findings table before any edit

**Files:** none (read-only; produces the working list every later task executes against)

- [ ] **Step 1: Run the sweep script**

```bash
cd the-factory/slipbox
grep -rn "CONTEXT.md" skills/
grep -rn "discussion/" skills/
grep -rn "reference-note-admission-contract\|grounding-session-review-fixes\|claim-density-and-compression\|core-idea-never-gated\|personal-drift-and-off-source-questions" skills/
grep -rn "qec-theory" skills/ docs/superpowers/plans/2026-08-08* docs/superpowers/plans/2026-08-17-writing-for-agents-cleanup.md
grep -n "version:" skills/grounding/SKILL.md skills/make-literature-note/SKILL.md
grep -n "Knowing when the session is done" skills/make-literature-note/SKILL.md
grep -n "Key Concepts\|Mentioned" skills/find-connections/SKILL.md
grep -c "^\*\*" skills/setup-slipbox/assets/GLOSSARY.md
```

- [ ] **Step 2: Record every hit as `file:line — planned action`**, cross-checked against the four resolved topics. A hit not named in one of those four gets flagged back to the user before anything is touched.

- [ ] **Step 3: Confirm the `qec-theory`/`CONTEXT.md`/`discussion/` greps come back clean or fully accounted for** — this sweep exists specifically because earlier this session a stale `GLOSSARY.md` entry and six unbumped versions were both missed until a dedicated regression pass caught them. Do not proceed to Task 3 until every hit above has an owning task.

---

## Task 2: Capture fixtures

**Files:**
- Create: `tests/make-literature-note/fixtures/sun-gating-and-morning-light.md`
- Create: `tests/make-literature-note/fixtures/sun-gating-grounding-transcript.md`
- Create: `tests/make-literature-note/fixtures/less-is-more.md`
- Create: `tests/make-literature-note/fixtures/less-is-more-note-before.md`

- [ ] **Step 1: Write the Banner Health "Sun Gating and Morning Light" article** (full resource frontmatter + body, as already captured in this session's conversation) to its fixture path.
- [ ] **Step 2: Write the verbatim Morning Light grounding transcript** to its fixture path — this is the source of every Fidelity/coverage/Gate finding in `grounding-session-review-fixes.md`.
- [ ] **Step 3: Write the "Less is more, more or less" article** to its fixture path.
- [ ] **Step 4: Write the 14-Key-Claim note produced before this plan's fixes** to its fixture path, as the before/after baseline for Task 6's compression eval.
- [ ] **Step 5: Verify no fixture references anything outside `tests/`** — these are eval inputs, not shipped skill content, so the "no pointer outside the bundle" constraint doesn't apply to them, but they should still be self-contained and not silently depend on repo state that could drift.

---

## Task 3: Grounding engine — persistent opinion + off-source questions

**Files:** Modify `skills/grounding/SKILL.md`

**Spec:** `personal-drift-and-off-source-questions.md`, Resolution (cases 1 and 2)

- [ ] **Step 1: Read `grounding/SKILL.md`'s Fidelity section in full**, confirm the exact insertion point for the new rule (after the existing "if source or notes already say something, read it" line, before the caller-direction-parameter paragraph — matching this session's own earlier edits to the same section).

- [ ] **Step 2: Add the persistent-opinion rule.** Piggyback Fidelity's existing direction parameter — no new parameter. Trigger on the *second* occurrence of the user restating their own opinion after a first push-back. On trigger: stop, offer (never auto-route) capturing it in the evergreen backlog, immediately — not deferred to post-Gate the way a tension is. The offer itself may be binary ("capture this separately, or set it aside?") since it's a routing choice over the user's own words, not a confirmation of agent-authored content — distinguish this explicitly from Gate's own ban on binary confirmation questions, so a future reader doesn't read this as contradicting that rule.

- [ ] **Step 3: Add the off-source-question rule.** Acknowledge-then-redirect (reuse the acknowledgment-line pattern already shipped for Hesitant/Blank/Confused readings), never a bare redirect. Before stating the source doesn't cover something, the agent must actually check rather than assume — a false "the source doesn't say that" is its own Fidelity violation.

- [ ] **Step 4: Regression check** — re-read the whole Fidelity section end to end for internal coherence now that it holds four related-but-distinct rules (source-present hold-to-source, retrieved-notes hold-to-notes, never-pre-quote, persistent-opinion, off-source-question). Confirm no rule restates another under different wording (no-op check).

- [ ] **Step 5: Eval** — construct a short synthetic dialogue exercising both triggers (a user restating an opinion twice; a user asking an off-source tangent), verify the drafted rule text produces the expected behavior when read as instructions.

- [ ] **Step 6: Bump `metadata.version`** on `grounding/SKILL.md` — minor (new mechanism, two new rules).

- [ ] **Step 7: Commit**

```bash
git -C the-factory/slipbox add skills/grounding/SKILL.md
git -C the-factory/slipbox commit -m "feat(grounding): persistent-opinion routing and off-source-question handling"
```

---

## Task 4: Open Questions mechanism

**Files:**
- Modify: `CONTEXT.md` (repo root)
- Modify: `skills/make-literature-note/SKILL.md`
- Modify: `skills/make-literature-note/references/writing-a-claim.md`
- Modify: `skills/setup-slipbox/assets/GLOSSARY.md`

**Spec:** `personal-drift-and-off-source-questions.md`, Resolution (2026-08-18 amendment, case 3)

- [ ] **Step 1: Read `CONTEXT.md`'s Literature note definition and Flagged ambiguities section in full.**

- [ ] **Step 2: Add the narrow purity-rule exception** — a marked `*Assumption*` bullet under an Open Question is the one exception to "no personal stance, no reaction field of any kind." Everything else the rule bans stays exactly as forbidden. State explicitly that this exception is scoped to this one bullet type, under this one section, never elsewhere in the note.

- [ ] **Step 3: Add the Open-Questions-is-append-only exemption** to the "frozen once written" rule — separate from the existing out-of-band-fidelity-correction exception, since an `*Answered*` bullet added later isn't a correction, it's new information arriving after the fact.

- [ ] **Step 4: Read `writing-a-claim.md`'s Structure section**, add `## Open Questions` as a top-level section, sibling to `## Key Claims` and `## Key Concepts`/`## Mentioned`. Document the bullet format:

```markdown
## Open Questions

- [plain declarative question naming a gap in the source]
  - *Assumption*: [user's own guess, marked, never a Claim]
  - *Answered*: [[Other Literature Note#the-claim-that-answers-it]]
```

State: user-flagged only, the agent never invents an open question unprompted; `*Answered*` links are user-initiated, never auto-detected (no cross-note scanning).

- [ ] **Step 5: Read `make-literature-note/SKILL.md`'s Surface pass and "Write each claim, incrementally" sections.** Add capture logic: when the user notices a gap during grounding, offer to record it as an Open Question; when the user wants a guess recorded, append it as `*Assumption*`, clearly marked; when the user names another literature note that resolves it, append `*Answered*` as a wikilink.

- [ ] **Step 6: Add `GLOSSARY.md` entries** for **Open Question** and **Assumption** (the note-body kind — distinguish from any existing JSON-schema-level "deferred"/assumption-adjacent term if one exists; check before naming, don't assume a collision).

- [ ] **Step 7: Regression check** — confirm `find-connections/SKILL.md` does *not* need to scan `## Open Questions` (no cross-note tracking, per the resolution) — state this explicitly in `find-connections/SKILL.md` if it currently reads ambiguous, rather than leaving a reader to guess whether the omission was deliberate.

- [ ] **Step 8: Eval** — run the Morning Light transcript's own SAD scenario (an unanswered question, a user-requested tentative answer) against the new mechanism; confirm the shape matches what actually happened in the fixture, corrected to the *Assumption* format instead of the transcript's original ad hoc "fleeting note" framing.

- [ ] **Step 9: Bump `metadata.version`** on `make-literature-note/SKILL.md` — minor.

- [ ] **Step 10: Commit**

```bash
git -C the-factory/slipbox add skills/make-literature-note/ skills/setup-slipbox/assets/GLOSSARY.md
git -C /Users/dzakyandarwa/Documents/01-Projects/Personal/skill-kojo add CONTEXT.md
git -C the-factory/slipbox commit -m "feat(make-literature-note): Open Questions section, Assumption/Answered bullets"
git -C /Users/dzakyandarwa/Documents/01-Projects/Personal/skill-kojo commit -m "docs(slipbox): Open Questions purity-rule exception and frozen-note exemption"
```

---

## Task 5: Source Architecture reference file

**Files:**
- Create: `skills/make-literature-note/references/source-architecture.md`
- Modify: `skills/make-literature-note/SKILL.md` (Surface pass)
- Modify: `skills/make-literature-note/references/qew-theory.md` (scope cross-reference only)

**Spec:** `core-idea-never-gated.md`, Resolution (both dated subsections)

- [ ] **Step 1: Draft `source-architecture.md`** with the six groups, each an optional lens, not a mandatory template — a source lacking a piece is a valid finding:
  1. **Situation & Starting Point** — motivation/context/purpose, where the source begins intellectually.
  2. **Problem/Tension** — the tension typology (contradiction, trade-off, gap, mismatch, bottleneck-shift, unintended consequence, paradox, tension between principles, ambiguity, model failure) — notice which form applies, don't default to "problem."
  3. **Argument Movement** — conceptual-move chains, premise→consequence→argument dependency, causal structure, reframing, contrasts, repetition-vs-reinforcement (an idea restated five times is usually one claim, not five).
  4. **Support & Boundaries** — definitions/distinctions, what job an example does (illustration vs. counterexample vs. evidence), qualifications/caveats, objections/responses, competing positions.
  5. **Fidelity Signals** — epistemic stance (does the source say "X is," "X suggests," or "X may"?) and what the source doesn't establish. Kept prominent, not folded into Support & Boundaries.
  6. **Resolution** — what the source does with its tension, including "left unresolved" as a valid, complete finding.

  For the two items that restate an existing rule elsewhere (source-vs-reader implication; argument dependency's deletion test), write the rule **inline**, in this file's own words — do not cite `CONTEXT.md` or `reference-note-admission-contract.md` by path.

- [ ] **Step 2: Read `make-literature-note/SKILL.md`'s Surface pass.** Add: before/alongside claim discovery, read the source's architecture per the new reference file, feeding Core Idea formation specifically — a Core Idea synthesized purely from discovered claims risks missing the source's own throughline.

- [ ] **Step 3: Add a one-line scope cross-reference in `qew-theory.md`'s opening**, noting `source-architecture.md` covers whole-source reasoning, distinct from Q/E/W's per-claim scope — prevents a reader from conflating the two files' jobs.

- [ ] **Step 4: Regression check** — grep for any other file that might assume Core Idea is derived purely from claims (the Review checklist's "does every claim serve it" language in `writing-a-claim.md` — confirm this still makes sense once Core Idea also draws on architecture, not just claims).

- [ ] **Step 5: Eval** — run "Less is more" through architecture-aware Core Idea derivation. Compare against the fixture's original Core Idea line (which nearly duplicated Claim 1) — confirm the new derivation produces something distinct, informed by the source's actual motivation → tension → build-up arc.

- [ ] **Step 6: Bump `metadata.version`** on `make-literature-note/SKILL.md` — minor.

- [ ] **Step 7: Commit**

```bash
git -C the-factory/slipbox add skills/make-literature-note/
git -C the-factory/slipbox commit -m "feat(make-literature-note): add source-architecture reference file, wire into Surface pass"
```

---

## Task 6: Claim-writing quality

**Files:** Modify `skills/make-literature-note/references/writing-a-claim.md`

**Spec:** `claim-density-and-compression.md`, Resolution; `grounding-session-review-fixes.md`, 2026-08-19 subsection

- [ ] **Step 1: Add the list-as-one-claim rule** to the Review checklist or Key Concepts section (wherever atomicity is currently checked): when several claims trace back to one source-authored list, default to one claim citing the list as a whole, its items folded into Evidence — not one claim per item.

- [ ] **Step 2: Add the Fidelity Signals check** to the Conclusion review checklist, alongside the existing metaphor-drift check added earlier this session: does the Conclusion upgrade the source's own hedged or comparative language into something stronger than stated? Reference `source-architecture.md`'s Fidelity Signals group by name (in-bundle reference, fine) rather than restating the whole group's definition here.

- [ ] **Step 3: Regression check** — re-read the Conclusion checklist end to end now that it holds two similar-sounding checks (metaphor drift, epistemic-stance drift) in sequence; confirm each has a distinct enough worked example that a reader won't conflate them.

- [ ] **Step 4: Eval, "Less is more"** — apply the list-as-one-claim rule to the seven-bullet-list case (claims 8–11 in the before-fixture); confirm it collapses to one claim per the already-worked 14→~5 compression.

- [ ] **Step 5: Eval, Morning Light** — apply the Fidelity Signals check to the "most sensitive" → "most effective" overclaim and the dropped eyewear nuance; confirm both fail the new check as designed.

- [ ] **Step 6: Bump `metadata.version`** on `make-literature-note/SKILL.md` (references share the parent skill's version) — minor.

- [ ] **Step 7: Commit**

```bash
git -C the-factory/slipbox add skills/make-literature-note/references/writing-a-claim.md
git -C the-factory/slipbox commit -m "feat(make-literature-note): list-as-one-claim rule, Fidelity Signals check in Conclusion review"
```

---

## Task 7: Session-close overhaul

**Files:** Modify `skills/make-literature-note/SKILL.md` ("Knowing when the session is done")

**Spec:** `core-idea-never-gated.md` (Core Idea confirmation), `claim-density-and-compression.md` (density/overlap), `grounding-session-review-fixes.md` (backlog three-state, source re-read, opinion-seed prompt)

This is the largest single edit — five separate resolutions converge on one section. Read the current section fully before drafting; consider whether it needs to split into two named sub-sections (checking what's already written vs. looking beyond it) once actually drafting, rather than assuming one flat section holds all five pieces cleanly.

- [ ] **Step 1: Backlog three-state tracking.** Add a drafted-but-unconfirmed state, distinct from untouched. The closing nudge names a drafted-but-unconfirmed item specifically ("you drafted X earlier — finish it?") rather than the generic "anything else?" Still overridden by the user's own "that's everything."

- [ ] **Step 2: Core Idea confirmation.** One genuine open question first ("what do you think is the main idea this source is arguing?"), satisfying Gate's precondition. Falls back to the full reading-state dispatch table if the answer isn't Confident. Final confirmation is open, never binary, same as a Claim's Gate.

- [ ] **Step 3: Density/overlap check.** Reuse `qew-theory.md`'s existing shared-Warrant merge test. "6–8" stated as a reference point for this one pass's judgment, not a hard gate — no mid-conversation interrupt.

- [ ] **Step 4: Fresh source re-read.** Full re-read (not targeted), judgment call not mandatory — skip when the session already felt thorough. Same batch-presentation pattern as "Spot terms and entities": re-read, compare, show findings in one message, user decides all/some/none.

- [ ] **Step 5: Opinion-seed prompt.** "What do you think of this article?" by default, unless a real opinion already surfaced and got routed during grounding (Task 3's persistent-opinion case). Answer never touches the literature note — only ever becomes an evergreen-backlog candidate. Offer before logging ("capture this as a seed, or set it aside?"), same shape as the persistent-opinion offer, never auto-saved.

- [ ] **Step 6: Regression check** — re-read the entire rewritten section for internal coherence and ordering (which of the five pieces fires first matters: backlog/density before Core Idea, or after? Decide and state the order explicitly rather than leaving it implicit). Confirm this section doesn't visually read as a numbered checklist (root `AGENTS.md`'s no-numbered-headings rule) despite holding five sequenced pieces.

- [ ] **Step 7: Eval** — run both fixtures (Morning Light, Less is more) through the full rewritten section end to end. Confirm: the drafted-but-unconfirmed morning-light-therapy claim gets named specifically; the Core Idea confirmation fires with an open question first; density triggers on the pre-fix 14-claim case; a fresh re-read surfaces at least the previously-missing "outdoor light is brighter" claim on the Morning Light fixture.

- [ ] **Step 8: Bump `metadata.version`** on `make-literature-note/SKILL.md` — minor.

- [ ] **Step 9: Commit**

```bash
git -C the-factory/slipbox add skills/make-literature-note/SKILL.md
git -C the-factory/slipbox commit -m "feat(make-literature-note): rewrite session-close sequence — backlog states, Core Idea confirmation, density check, source re-read, opinion-seed prompt"
```

---

## Task 8: Post-implementation

**Files:**
- Modify: all four discussion topics (append-only, per `discussion/AGENTS.md`'s own convention)
- Modify: `discussion/slipbox/decision.md` if any `Last updated` date needs bumping
- Extend: `tests/make-literature-note/evals.json`

- [ ] **Step 1: Append a short dated note to each of the four resolved topics** stating which commit(s) shipped its resolution — no re-litigation, just a pointer from decision to execution.

- [ ] **Step 2: Add eval cases to `tests/make-literature-note/evals.json`** using the two fixtures — at minimum: an Open-Questions/Assumption case, a claim-density/list-collapse case, a Core-Idea-confirmation case, and a Fidelity-Signals-overclaim case. Start with these four per the family's own "2-3 varied prompts, add assertions after seeing a first run" convention — don't over-build the eval suite in this pass.

- [ ] **Step 3: Run the full Task 1 sweep script one final time** — confirm zero remaining hits outside what was actioned, confirm every touched `SKILL.md`'s version was bumped, confirm `GLOSSARY.md`'s entry count matches its `_Avoid_` count.

- [ ] **Step 4: Final commit**

```bash
git -C /Users/dzakyandarwa/Documents/01-Projects/Personal/skill-kojo add discussion/
git -C /Users/dzakyandarwa/Documents/01-Projects/Personal/skill-kojo commit -m "docs(slipbox): mark four resolved topics as implemented"
git -C the-factory/slipbox add tests/
git -C the-factory/slipbox commit -m "test(make-literature-note): add eval cases for Open Questions, density, Core Idea, Fidelity Signals"
```
