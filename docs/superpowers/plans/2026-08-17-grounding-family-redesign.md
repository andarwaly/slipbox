# Grounding Family Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rewrite `grounding` around an answer-quality technique-dispatch mechanism (replacing the three-probe design), give it ten named `references/` files (six new + four moved in from `ground-my-take`), and rename/redesign the two note-writing wrappers (`ground-the-claim` → `make-literature-note`, `ground-my-take` → `make-evergreen-note`) per the full discussion recorded in `discussion/slipbox/research/grounding-technique-scratchpad.md` (workspace root, sibling repo to this one).

**Architecture:** `grounding` stays the shared interview engine — Fidelity, Gate, "Never your own opinion," "Noticing a tension" carry forward unchanged. The old single "Probing" section splits into "Reading the answer" (detects confident/hesitant/blank/confused, including a 3-way reactive offer that only fires after a genuinely failed first attempt) and "Choosing a technique" (a bare dispatch table pointing into `references/`). Both wrappers keep calling `/grounding` exactly as before, framing it with a Fidelity-direction parameter — nothing about the engine's public contract (statement + optional tension, nothing else) changes.

**Tech Stack:** Markdown skill files (agentskills.io spec: `SKILL.md` + `references/*.md`), no code. This repo has no test runner — "tests" are `tests/{{skill}}/evals.json` (prompt/expected_output/assertions consumed by a human or LLM grader, not pytest). Structural verification in this plan uses `grep`/`test -f` against required headings and forbidden terms as the closest available red/green signal.

## Global Constraints

- Two repos are touched. **Task 0** operates in the `skill-kojo` workspace repo (root: the directory containing `the-factory/`, `discussion/`, `AGENTS.md`). **Every other task** operates in `the-factory/slipbox` — its own independent git repo, nested inside `skill-kojo`. Every git command in a given task runs with that task's own repo as the working directory; never run a `skill-kojo`-scoped git command from inside `the-factory/slipbox`, or vice versa.
- `grounding` and `write-checks` are always referenced **slash-prefixed** (`` `/grounding` ``) everywhere in prose; every other skill (`make-literature-note`, `make-evergreen-note`, `ground-me`, `clip-resource`, `write-reference`, `find-connections`, `setup-slipbox`) is referenced **bare, backtick-only** (`` `make-literature-note` ``), never slash-prefixed — per `AGENTS.md`'s "Cross-skill references" rule.
- Recognizable-vocabulary directive applies to **reader-facing prose only** (`SKILL.md` body text, `references/*.md` explanations, worked examples). Frontmatter field names (`type:`, `derived-from`), CLI command shapes (`slipbox evergreen add --slug ...`), and schema identifiers are config — untouched by this directive, verbatim as shipped today.
- No numbered step-headings anywhere (`## 1. Take the idea` is forbidden) — named, descriptive headings only, per the workspace root `AGENTS.md`'s "Skill-writing conventions."
- `"You"/"your"` in narrative prose always means the agent; the user is spelled out as "the user," never an implicit "you" — same root convention, except literal quoted dialogue the agent speaks aloud.
- `grounding`'s public contract never changes: Done hands back at most two things — the confirmed statement, and (if opted into) a flagged-tension description. No third field, no format, no note-type label, regardless of caller or which technique fired internally.
- Every reference file follows the same seven-part shape: `# {{Name}}` → `## What it is` → `## Why this technique, for this job` → opener (`**Use this when**` / `**Use X instead when**` / `**Don't use this when**`) → `## Concept` → `## Conversational adoption` → `## Worked example` → `## Guardrail`.
- `metadata.version` stays under `1.x` for every touched file (per root `AGENTS.md`) — bump minor (`1.x.0`) for any mechanism change, patch (`1.0.x`) for wording-only changes. Check each file's current version before bumping; do not invent a version number without reading the file first.

---

### Task 0: Promote the scratchpad into a discussion-topic, per `skill-kojo`'s own framework

**Files (in the `skill-kojo` repo, not `the-factory/slipbox`):**
- Create: `discussion/slipbox/discussion-topics/grounding-answer-quality-redesign.md`
- Modify: `discussion/slipbox/decision.md`
- Untouched: `discussion/slipbox/research/grounding-technique-scratchpad.md` stays exactly where it is — a topic file records the *ruling*, it doesn't replace the scratchpad's own raw working notes, same relationship every other resolved topic in this bucket already has to its own research files.

**Interfaces:**
- Consumes: the full scratchpad content (all sessions, 2026-08-15 through 2026-08-17)
- Produces: a `decision.md` index row every other topic-file convention in this bucket already follows — no downstream task in this plan depends on this one; it can run before or after the `the-factory/slipbox` tasks, but must land before this plan is considered complete, per `discussion/AGENTS.md`'s own framework (a decision this size doesn't stay scratchpad-only).

- [ ] **Step 1: Confirm the target files don't already exist / read the index before editing**

Run (from `skill-kojo` root): `test -f discussion/slipbox/discussion-topics/grounding-answer-quality-redesign.md && echo EXISTS || echo MISSING`
Expected: `MISSING`

Run: `tail -5 discussion/slipbox/decision.md`
Expected: the current last row of the index table — confirm the exact table syntax before appending a new row in Step 3.

- [ ] **Step 2: Create the topic file**

```markdown
---
status: resolved
resolved: 2026-08-17
updated: 2026-08-17
---

# `grounding` engine redesign — answer-quality dispatch, wrapper renames, Compass relocation

Surfaced from a precautionary worry, not an observed failure: whether Socratic
interviewing risks exhaustion at scale, before `grounding` had seen heavy real use.
Ran across three sessions (2026-08-15, 2026-08-17 ×2); full raw working notes in
`research/grounding-technique-scratchpad.md`.

## Resolution

### 2026-08-17 — final shape, ready for implementation

**The exhaustion question resolved by reframing, not by picking a lever.** Volume
(sessions-per-source, rounds-per-session) was the real driver, not probe-type choice.
Root cause traced further back to two distinct, previously-bundled problems: exhaustion
(volume) and articulation difficulty (not knowing how to phrase a restatement at all) —
the shipped three-probe design had no answer to the second at all.

**Superseded the four-state reading axis (closely-read/skimmed/forgotten/not-yet-read)
outright.** It only generalized to callers with a fixed source; `ground-my-take`'s
sourceless-hunch case had no answer in it. Replaced with an answer-quality axis
(confident/hesitant/blank-with-source/blank-without-source/confused) that works for
every caller, keyed on the user's actual response rather than a declared-or-inferred
state. Cross-checked against a dedicated technique-comparison research pass (14
techniques scored on articulation-from-nothing vs. source-stress-test fit) and a
follow-on prior-art sweep (no shipped tool enforces "agent interrogates, never drafts"
as a hard rule — closest matches (Socra, Tana) violate the rule at the output step;
closest stated rule (Dixit's Socratic AI) has no confirmed working product).

Final mapping: confident → source-anchored verification, escalating to full elenchus
only on a genuine mismatch; hesitant → Feynman (decay-vs-never-formed distinction
dropped for one solidly-grounded path); blank+source → a new composite technique,
discovery-walk (Maieutic + Feynman + ZPD scaffolding), reached only via a reactive
3-way offer *after* a first plain attempt genuinely fails, never asked upfront (both a
friction and an ethical call — asking "how well do you know this" upfront reads as
judging the user); blank+no-source → maieutic alone; confused-not-blank →
self-explanation/mental-model-repair (Chi et al.).

**Wrapper family survives intact, contrary to the session's own opening premise** ("the
child-skill split may be overkill"). Resolving principle: disk-write output vs. none,
not skill-count minimalism. `ground-me` stays (bare interview + closing card, no disk
write — and specifically because `grounding` itself must stay permanently raw with no
card, so wrappers invoking it as a sub-step never get a stray card leaking into their
own flow). `ground-the-claim` and `ground-my-take` both write files, both stay separate,
both renamed for jargon reasons below.

**Both note-writing wrappers renamed**, on a different axis than the 2026-08-13 naming
review tested (grammar, not comprehension): `ground-the-claim` → `make-literature-note`,
`ground-my-take` → `make-evergreen-note`. "Take" and "Claim" are this family's own
private jargon, opaque without reading `CONTEXT.md`; "literature note" and "evergreen
note" are established, mainstream Zettelkasten vocabulary (Ahrens, Matuschak). The
possessive "my" in the old name flagged a real mechanical fact (the one wrapper
flipping Fidelity's direction toward itself) but turned out non-load-bearing for the
name specifically — the agent's behavior comes from an explicit instruction in the file
body, never inferred from a filename, and "evergreen" already carries the
user's-own-idea connotation for the audience that matters.

**`make-literature-note` gets a mechanical redesign**, not just a rename: the shipped
menu-then-loop-per-claim shape is replaced by a private backlog (never shown to the
user, same role Q/E/C already plays) plus one continuous natural conversation — fixes a
real collision the new discovery-walk technique exposed (re-walking the same source once
per claim across N independent sessions would have reintroduced the exact exhaustion
problem this whole topic started from). `/grounding`'s own per-claim Gate contract is
untouched; only how a claim gets reached changed. Completion: nudge once for anything
genuinely untouched in the backlog, user's "that's everything" always overrides. Q/E/C
stays exactly where the 2026-08-13 `ground-claim-literature-note-exemplar` ruling put it
— it fails the same engine-vs-wrapper test Compass passes, run in the opposite
direction (pre/post-session reasoning, never mid-interrogation).

**Compass/Connect/Challenge/Distil relocate from `ground-my-take` into `grounding`'s own
`references/`**, extending it from six files to ten. They pass the same engine-vs-wrapper
test the other six already did (genuine conversation-time technique, not output-specific
logic) — they only ever lived in a wrapper by accident of when in the family's history
each was written. Verified directly against primary sources (Tseng's own Substack post,
Sascha Fast's zettelkasten.de post, a Stultus mirror) rather than continuing on secondary
summary — corrected the attribution (Tseng coins "Compass of Zettelkasten Thinking";
"Idea Compass" traces to a joint Zhao/Tseng presentation at a LYT conference, which Fast
adopted and credited only once he learned it predated his own post) and found a real
mechanical gap: Compass directions recurse (any answer can become a fresh center idea
with its own sub-branches), which the shipped file treats as four terminal answers.
Resolved without new machinery — the existing evergreen backlog (already written to and
read from by the shipped `ground-my-take` design) absorbs unpursued recursive branches,
same as any other flagged tension.

**A standing implementation-pass principle**: prefer recognizable, generally-weighted
vocabulary over private family jargon in every reader-facing prose file touched by this
redesign — scoped explicitly to prose only, config (frontmatter fields, CLI shapes,
schema identifiers) stays exactly as-is.

**Not yet implemented** — lands on `docs/superpowers/plans/2026-08-17-grounding-family-
redesign.md` inside `the-factory/slipbox`, tracked as separate execution work from this
ruling, same pattern as every other resolved-but-unimplemented topic in this bucket.
```

- [ ] **Step 3: Append the new row to `decision.md`'s index table**

Read the file first (Step 1 already showed the last row's exact syntax), then append immediately after the last existing row:

```markdown
| [grounding-answer-quality-redesign](discussion-topics/grounding-answer-quality-redesign.md) | resolved | 2026-08-17 |
```

- [ ] **Step 4: Verify**

Run: `grep -c "^status: resolved$" discussion/slipbox/discussion-topics/grounding-answer-quality-redesign.md`
Expected: `1`

Run: `grep -c "grounding-answer-quality-redesign" discussion/slipbox/decision.md`
Expected: `1`

Run: `python3 -c "import re,sys; content=open('discussion/slipbox/discussion-topics/grounding-answer-quality-redesign.md').read(); assert content.startswith('---'), 'frontmatter missing'; print('OK')"`
Expected: `OK`

- [ ] **Step 5: Commit (in the `skill-kojo` repo)**

```bash
git add discussion/slipbox/discussion-topics/grounding-answer-quality-redesign.md discussion/slipbox/decision.md
git commit -m "docs(slipbox): promote grounding-technique scratchpad to a resolved discussion topic

Full ruling for the grounding engine redesign, wrapper renames, and
Compass relocation - condensed from three sessions' worth of scratchpad
work (research/grounding-technique-scratchpad.md, kept as-is alongside
this). Not yet implemented - tracked separately at
the-factory/slipbox/docs/superpowers/plans/2026-08-17-grounding-family-
redesign.md.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## File Structure

```
skills/grounding/
├── SKILL.md                     [rewrite]
└── references/
    ├── verification.md          [new]
    ├── elenchus.md               [new]
    ├── feynman.md                 [new]
    ├── maieutic.md                 [new]
    ├── discovery-walk.md           [new]
    ├── self-explanation.md          [new]
    ├── compass.md                    [moved from ground-my-take, rewritten]
    ├── connect.md                     [moved from ground-my-take, rewritten]
    ├── challenge.md                    [moved from ground-my-take, rewritten]
    └── distil.md                        [moved from ground-my-take, rewritten]

skills/make-literature-note/       [renamed from skills/ground-the-claim/]
├── SKILL.md                     [rewrite: backlog model, invocation form]
└── references/
    ├── qec-theory.md             [untouched — git mv only]
    └── writing-a-claim.md        [untouched — git mv only]

skills/make-evergreen-note/        [renamed from skills/ground-my-take/]
└── SKILL.md                     [rewrite: Sign-off Concept section, references now point at grounding's shared files]
    (references/{compass,connect,challenge,distil}.md deleted here — moved to grounding/references/ above)

skills/ground-me/                  [untouched — no changes]

CONTEXT.md                        [cross-reference update: ground-the-claim → make-literature-note, ground-my-take → make-evergreen-note]
AGENTS.md                         [structure-diagram update, same renames]
docs/grounding.md                 [rewrite to match new mechanism]
docs/make-literature-note.md       [renamed from docs/ground-the-claim.md, rewrite]
docs/make-evergreen-note.md        [renamed from docs/ground-my-take.md, rewrite]
docs/ground-me.md                 [untouched]

tests/grounding/evals.json         [rewrite test cases for new mechanism]
tests/make-literature-note/         [renamed from tests/ground-the-claim/, evals.json rewritten]
tests/make-evergreen-note/          [renamed from tests/ground-my-take/, evals.json rewritten]
tests/ground-me/evals.json          [untouched]
```

---

### Task 1: `grounding/SKILL.md` — full rewrite

**Files:**
- Modify: `skills/grounding/SKILL.md`
- Test: manual grep verification (below)

**Interfaces:**
- Consumes: nothing (this is the engine, no upstream dependency within this plan)
- Produces: the `## Choosing a technique` dispatch table other tasks' reference files must match exactly — five rows: Confident → `references/verification.md`, Hesitant → `references/feynman.md`, "Blank, source present, walk together chosen" → `references/discovery-walk.md`, "Blank, no source at all" → `references/maieutic.md`, Confused → `references/self-explanation.md`. `references/elenchus.md` is never a table row — it is reached only from inside `verification.md`.

- [ ] **Step 1: Write the grep check that must fail first**

Run: `grep -c "Probing" skills/grounding/SKILL.md`
Expected: `1` (the old section still exists, unmodified)

- [ ] **Step 2: Replace the file's full content**

```markdown
---
name: grounding
description: A relentless one-question-at-a-time interview that holds a statement to whatever material is present — a source, retrieved notes, or nothing at all — until it's explicitly confirmed.
metadata:
  version: "1.1.0"
---

# Grounding

Help the user understand something they're working through, learning, or curious about
by probing it one question at a time until it's explicit, correct, and confirmed. Never
state it for them — draw only from what they actually said. Ask exactly one substantive
question per turn — never batch, never present a checklist.

**A session-opening line only, then silence**: the first message of a session states
plainly that a grounding session is starting (naming the source or topic in play).
Nothing repeats after that — no per-turn marker, no label on individual questions. A
repeating marker would undercut the very techniques below built to feel like genuine
conversation rather than a labeled interrogation.

## Fidelity

Material arrives already handed to you — a source's text, notes someone else retrieved,
or nothing. Whichever is present decides who gets held to it. These can apply together,
not just one at a time:

- **A source is present** → hold the user to it. If their statement drifts into their
  own opinion, push back:
  > "is that what the source says, or is that your own read?"
- **Retrieved notes are present** → hold yourself to them. Never fill a gap from general
  knowledge — if sharpening the statement needs something no retrieved note contains,
  say so rather than inventing it.
- **Neither is present** → say so plainly and continue anyway. An ungrounded hunch is a
  valid, complete outcome — not a failure state.
- **The source contradicts itself** → surface both sides directly rather than silently
  picking a reading:
  > "the source says X in one place and Y in another — which is it holding to?"
- **Retrieved notes disagree with the source** → the source wins outright; notes are a
  gap-filling reference, not a co-equal authority. Don't argue the disagreement out
  mid-interview — it's a candidate for **Noticing a tension** below, surfaced only after
  the gate passes like any other tension.

If the source or retrieved notes already say something, read it — don't ask the user to
repeat what's already there.

A caller may frame which direction Fidelity points before a session starts — most often
whether to hold the user to the material (the default) or to hold yourself, the agent,
to it instead. This is a parameter the caller supplies going in, never something the
caller reads back out; it doesn't change how Fidelity itself works, only which side of
the conversation it's aimed at.

## Never your own opinion

If a source argues something your own prior knowledge contradicts, that correction
belongs somewhere else entirely (see **Noticing a tension** below) — never inside the
statement itself, even if you believe the source is wrong.

## Reading the answer

Every session starts the same way: ask for a plain restatement — "what stood out to
you?" or equivalent. What comes back is read, not assumed:

- **Confident** — clear, complete, no hedging.
- **Hesitant** — explicit hedging ("I think maybe...", "not sure but..."), trailing off
  mid-thought, or an outright "I don't really get it."
- **Blank** — nothing substantive comes back.
- **Confused** — touched something, but garbled or circular — distinct from Blank:
  something was said, it just doesn't hold together yet.

A blank answer never gets diagnosed silently. Instead, offer a choice:
> "would it help to walk through this together, or do you want to try explaining what
> stood out first?"

This offer only ever fires after a first plain attempt has genuinely failed — never
upfront, never in place of asking for a stated reading state, which is never asked for
at all. A reading state may be volunteered unprompted; if it is, treat it as a soft
prior, not a hard router — if what's actually said contradicts it (a declared "I read
this closely" followed by a blank answer), follow what's observed, not what was
declared.

## Choosing a technique

| Reading | Technique |
|---|---|
| Confident | `references/verification.md` |
| Hesitant | `references/feynman.md` |
| Blank, source present, "walk together" chosen | `references/discovery-walk.md` |
| Blank, no source at all | `references/maieutic.md` |
| Confused | `references/self-explanation.md` |

Each reference file states its own boundary — when to reach for it, what to reach for
instead, and when not to use it at all. Read the relevant one before running it.
`references/elenchus.md` is never dispatched directly from this table — it's reached
only from inside `verification.md`, on a genuine mismatch between a confident statement
and the source.

Reaching for `references/compass.md` and its supporting files (`connect.md`,
`challenge.md`, `distil.md`) is a separate, upstream layer, not a sixth entry in this
table — Compass decides *what to ask about next*; this table decides *how to respond to
whatever comes back*, regardless of which direction a question came from. A caller may
orient a session with Compass and still have every individual answer route through this
same table.

## Gate

The statement is fixed only when the caller explicitly confirms it — and getting there
requires two things, not one:

- **A precondition on ever showing a draft**: never present a finished statement for
  confirmation until at least one open probe-and-answer round has already produced real
  content from the user. If the first thing shown in a session is a polished draft, that
  is a Gate failure by construction — go back and probe first.
- **The confirmation question itself stays open**, never binary. Present the draft as
  "here's what I have so far, based on what you said — what's missing or wrong?" not
  "does this capture it, yes or no?" A genuine "yes, exactly" still closes the gate; the
  question just never invites a reflexive rubber-stamp.

**Fixes it**: "yes, that's it," "fixed," or equivalent — an explicit, unambiguous signal,
after the precondition above has been met.

**Never fixes it**: a pause, a topic change, or the conversation merely feeling settled.
Before treating the gate as passed, confirm the user has either produced the statement's
content themselves or meaningfully revised wording you introduced — agreement alone,
without either, isn't enough. Probe once more if it isn't.

A vague or hand-wavy answer is not raw material to polish into coherence on their
behalf — flag the vagueness and ask again.

A `references/discovery-walk.md` session passes through this same Gate once, over the
whole accumulated result at the end of the walk — not per turn. Each turn already checks
itself against the source locally as the walk proceeds; the Gate's job is confirming the
walk's *whole* result as one statement, the same discipline every other technique
applies to a single restatement.

## Noticing a tension

While grounding, you may notice something in real tension with the material — your own
prior knowledge pulling against what the source argues, or anything else that doesn't
belong in the statement itself. Don't act on it, and don't let it leak into the
statement. Once the gate has passed, ask once — surfacing at most one, the tension most
likely to matter later, and dropping the rest silently if several came up:

> "while grounding this, I noticed [X] — want this flagged for later, or skip it?"

Never manufacture a tension to fill this slot; only surface one you actually noticed.

## Done

Hand back at most two things, nothing else:

- the confirmed statement, verbatim
- only if the user opted in above, a short description of the flagged tension

No filename, no format, no note-type label, no database write of any kind — all of that
belongs to whichever skill invoked this one. This holds regardless of which technique
ran or which caller invoked the session — `grounding`'s output never depends on who's
calling it.
```

- [ ] **Step 3: Run the grep check again to verify it now passes**

Run: `grep -c "Probing" skills/grounding/SKILL.md`
Expected: `0`

Run: `grep -c "^## Reading the answer$" skills/grounding/SKILL.md`
Expected: `1`

Run: `grep -c "^## Choosing a technique$" skills/grounding/SKILL.md`
Expected: `1`

Run: `grep -c "references/discovery-walk.md" skills/grounding/SKILL.md`
Expected: `2` (once in the table, once in the Gate section)

- [ ] **Step 4: Commit**

```bash
cd skills/grounding
git add SKILL.md
git commit -m "feat(grounding): replace Probing with Reading-the-answer/Choosing-a-technique split

Replaces the three named probes (Mechanism/Boundary/Distinction) with a
five-category answer-quality dispatch (confident/hesitant/blank-with-source/
blank-without-source/confused), each routing into a references/ file. Adds a
Fidelity-direction caller-parameter note, a Gate note for discovery-walk's
once-over-the-result pass, and a one-time session-opening line replacing any
per-turn marker.

Public contract unchanged: Done still hands back exactly the confirmed
statement plus an optional flagged tension, regardless of which technique
fired or who's calling."
```

---

### Task 2: `grounding/references/verification.md` — new file

**Files:**
- Create: `skills/grounding/references/verification.md`

**Interfaces:**
- Consumes: dispatched from `grounding/SKILL.md`'s table on a Confident reading
- Produces: escalates to `references/elenchus.md` on a genuine mismatch — Task 3 must accept being reached this way, not just standalone

- [ ] **Step 1: Verify the file doesn't exist yet**

Run: `test -f skills/grounding/references/verification.md && echo EXISTS || echo MISSING`
Expected: `MISSING`

- [ ] **Step 2: Create the file**

```markdown
# Verification

## What it is

The scientific method, applied to a single restatement instead of a lab
experiment: treat what the user just said as a hypothesis about what the
source means, then check it against the actual source text as evidence. If
the hypothesis and the evidence agree, it's confirmed. If they disagree,
that's data too — a real mismatch worth surfacing, not something to smooth
over.

## Why this technique, for this job

Every other technique here checks internal logic — does the statement hold
together, does it survive scrutiny. Verification checks something different
and, for this job, more important: does the statement match what the source
*actually says*, which a perfectly coherent, confidently stated restatement
can still get wrong. A confident answer doesn't mean a correct one; this is
the one technique that anchors the check to the source text itself rather
than to how convincing the answer sounds.

**Use this when** the answer is confident — clear, complete, no hedging. It's
the cheap default for the common case, not a heavyweight check.

**Escalate to `elenchus.md` instead when** this check surfaces a genuine
mismatch between the statement and the source — not for a thin-but-accurate
answer, and never as the default opening move for a confident answer.

**Don't use this when** the answer is hesitant, blank, or confused — there's
no settled statement yet to check against anything. See `feynman.md`,
`discovery-walk.md`, `maieutic.md`, or `self-explanation.md` depending on
which of those applies.

## Concept

The failure mode this targets is overconfidence in an unverified claim —
distinct from elenchus's target (a claim that's internally inconsistent). A
restatement can be perfectly well-reasoned, logically defensible, and still
simply wrong about what the source says. Checking internal logic alone would
miss this entirely; the only real check is against the external evidence,
the source itself.

This borrows the *shape* of hypothesis-testing, not its full apparatus —
there's no control condition, no formal falsifiability criterion, just the
core move: state a claim, check it against evidence, revise if they
disagree. Kept deliberately lightweight because it's meant to run by
default, every time, not as a special heavyweight procedure reserved for
important claims.

## Conversational adoption

- **State the check, don't hide it.** "Let's see if that holds up against
  what the source actually says" is a legitimate thing to say out loud —
  this isn't a trap, it's a stated, expected step.
- **Point to the specific passage.** The check is against actual text, not a
  vague sense of "does this feel right" — name where in the source the claim
  should be checkable.
- **A match closes the loop quickly.** If the restatement holds up, say so
  plainly and move to the Gate — don't manufacture doubt where the check
  passed clean, that would just be friction for its own sake.
- **A mismatch gets surfaced directly, not softened.** "The source actually
  says X, not Y — what do you make of that?" rather than easing into it
  obliquely.

## Worked example

> **Agent:** You said the author argues linking notes helps you "find things
> later." Let's check that against the text — look at the paragraph starting
> "a note gains meaning..." Does that match what it's actually claiming?
> **User:** Oh — no, it's saying something different, that the note's
> meaning itself changes over time as it gets linked to more things.
> **Agent:** Right — that's a stronger and different claim than "easier to
> find." Does the restatement need updating, or does this change anything
> else about what you said?

## Guardrail

The check can slide into rubber-stamping — accepting a restatement as
verified because it sounds plausible, without actually locating and
re-reading the specific passage it should match. If the exact sentence or
paragraph that would confirm or contradict the claim hasn't been pointed to
and read, the check hasn't actually happened yet, regardless of how
confident the exchange feels.
```

- [ ] **Step 3: Verify the file's structure**

Run: `grep -c "^## " skills/grounding/references/verification.md`
Expected: `6` (What it is, Why this technique for this job, Concept, Conversational adoption, Worked example, Guardrail — the opener has no `##` heading of its own)

Run: `grep -c "elenchus.md" skills/grounding/references/verification.md`
Expected: `2`

- [ ] **Step 4: Commit**

```bash
git add skills/grounding/references/verification.md
git commit -m "feat(grounding): add verification.md reference file

Scientific-method-as-hypothesis-check technique for a confident reading.
Escalates to elenchus.md on a genuine source mismatch."
```

---

### Task 3: `grounding/references/elenchus.md` — new file

**Files:**
- Create: `skills/grounding/references/elenchus.md`

**Interfaces:**
- Consumes: reached only from inside `verification.md` (Task 2), never dispatched directly from `SKILL.md`'s table
- Produces: nothing further downstream

- [ ] **Step 1: Verify the file doesn't exist yet**

Run: `test -f skills/grounding/references/elenchus.md && echo EXISTS || echo MISSING`
Expected: `MISSING`

- [ ] **Step 2: Create the file**

```markdown
# Elenchus

## What it is

The refutative form of Socratic questioning: cross-examine a *stated*
position using six distinct question moves — clarification ("what do you
mean by that?"), probing assumptions, probing reasons and evidence,
exploring alternative viewpoints, probing implications and consequences, and
questioning the question itself. Historically adversarial by design — its
purpose is exposing where a claim's own logic doesn't hold, not building
consensus.

## Why this technique, for this job

Elenchus never opens a session — it's reached only from inside
`verification.md`, when the cheap source-check has already surfaced a real
mismatch. At that point, a lighter check has failed and something more
thorough is warranted: not just "does this match the source" but "does this
claim actually hold together once pressed from several angles." It's the
heaviest tool in the set, deliberately gated behind a real trigger rather
than run by default.

**Use this** only when reached from `verification.md`'s own escalation —
never dispatched directly from a fresh answer, and never as an opening move
regardless of how the answer first sounded.

**Don't use this** for a thin-but-accurate answer, or as a way to make an
already-correct restatement feel more rigorously tested — that's friction
without a real trigger behind it.

## Concept

Classical elenchus targets false confidence — a stated belief that feels
solid but hasn't been tested against its own logical consequences or against
a counter-view. This is a genuinely different failure mode from what
`verification.md` alone catches: verification checks the claim against the
source; elenchus checks whether the claim, once granted, actually survives
its own implications and alternatives.

The six question types aren't a checklist to run through mechanically —
they're named options, reached for based on which kind of weakness the
mismatch actually exposed. A mismatch about a vague term calls for a
clarification question; a mismatch about an unsupported leap calls for a
reasons-and-evidence question.

## Conversational adoption

- **Name what triggered this.** "That doesn't quite match what the source
  says — let's press on it a bit" sets the frame honestly, rather than
  launching into interrogation with no stated reason.
- **One question type at a time**, picked to match the specific weakness
  just found — not a rapid-fire sequence through all six.
- **Firm, not hostile.** The historical risk with elenchus is it reading as
  an attempt to embarrass rather than sharpen — the tone should stay
  collaborative even while the questioning gets pointed.
- **Stop once it resolves.** The moment the claim either survives the
  pressure or gets revised to something that does, the escalation is over —
  return to the Gate, don't keep pressing for its own sake.

## Worked example

> **Agent:** The source actually argues linking changes a note's meaning
> over time, not just that it aids retrieval later — that's a stronger
> claim than what you said. What would have to be true for "just helps you
> find things" to be the whole story?
> **User:** I guess... if the note's content itself never changed after
> writing it, connecting it to other things wouldn't really do anything to
> its meaning.
> **Agent:** And does the source say notes stay fixed after they're
> written?
> **User:** No — it specifically argues they don't, that's the whole point
> of the paragraph I skipped.
> **Agent:** So does "helps you find things later" still hold as the full
> claim, or does it need the meaning-shifts-over-time part too?

## Guardrail

Elenchus can tip into a "guess what's in my head" dynamic if the agent
already has a specific correct answer in mind and is steering toward it
rather than genuinely testing the claim's logic. If a question only has one
acceptable answer the agent is fishing for, that's not elenchus anymore —
it's a quiz wearing elenchus's shape. The test should be genuinely open to
the claim surviving, not rigged to fail.
```

- [ ] **Step 3: Verify the file's structure and the escalation-only framing**

Run: `grep -c "^## " skills/grounding/references/elenchus.md`
Expected: `6`

Run: `grep -c "verification.md" skills/grounding/references/elenchus.md`
Expected: `2`

Run: `grep -c "^\*\*Use this\*\* only when reached from" skills/grounding/references/elenchus.md`
Expected: `1` (confirms the variant opener, not the standard "Use this when the reading is X" phrasing)

- [ ] **Step 4: Commit**

```bash
git add skills/grounding/references/elenchus.md
git commit -m "feat(grounding): add elenchus.md reference file

Six-question-type escalation technique, reached only from verification.md
on a genuine source mismatch — never dispatched directly."
```

---

### Task 4: `grounding/references/feynman.md` — new file

**Files:**
- Create: `skills/grounding/references/feynman.md`

**Interfaces:**
- Consumes: dispatched from `grounding/SKILL.md`'s table on a Hesitant reading
- Produces: nothing further downstream

- [ ] **Step 1: Verify the file doesn't exist yet**

Run: `test -f skills/grounding/references/feynman.md && echo EXISTS || echo MISSING`
Expected: `MISSING`

- [ ] **Step 2: Create the file**

```markdown
# Feynman

## What it is

Named for physicist Richard Feynman, who framed real understanding as the
ability to explain something in plain language to someone with no
background in it — if the explanation needs jargon, or falls apart when
simplified, the understanding was never complete to begin with. The classic
four-step shape: pick the concept, explain it as if to someone who's never
heard of it, notice exactly where the explanation breaks down or leans on
words that haven't actually been unpacked, then return to the source to
fill that specific gap before trying again.

## Why this technique, for this job

`grounding`'s whole premise is that the agent never states the user's
understanding for them — the user has to produce it. Feynman is the one
technique built to do exactly that from a standing start: it doesn't test
whether a stated claim survives scrutiny (that's elenchus's job, downstream
of a claim existing), it's the mechanism for getting a first plain-language
claim to exist at all. That's why it's the answer to a hesitant/hedging
response specifically — something was attempted, it's just shaky, and
Feynman's loop is built to turn "shaky" into "solid" without the agent ever
supplying the missing words itself.

**Use this when** the answer is hesitant or hedging — something was
attempted, but it's shaky, hedged, or trails off. Feynman needs *some*
stated content to loop against, even a weak one.

**Use `self-explanation.md` instead when** the answer is confused rather
than hesitant — garbled or circular, not just uncertain. Feynman's loop
assumes a simplifiable idea exists; confusion means there's no settled idea
yet to simplify.

**Don't use this when** nothing at all comes back. That's Blank, not
Hesitant — see `discovery-walk.md` or `maieutic.md` depending on whether a
source is present.

## Concept

Feynman targets the illusion of understanding — the gap between recognizing
a concept and being able to generate a plain-language explanation of it.
Someone can nod along to a source, or even recall its vocabulary, without
having actually built the explanation themselves. Asking them to explain it
simply, as if to someone who hasn't read the source, forces that
construction — and any place the explanation stalls, reaches for jargon it
can't unpack, or trails into vagueness *is* the gap, made visible.

This differs from its traditional standalone-study use (write it out alone,
on paper, then check yourself against a textbook) in one important way
here: it's dialogic, not solitary. The agent isn't a passive checklist the
user consults afterward — it plays the role of "the person who hasn't read
this" *live*, in the conversation itself, which is what makes the gap
visible in real time rather than only on a later re-read.

The loop only works if the gap gets used, not just noticed: find where it
broke, go back to the specific passage that would fill it, and only then
ask for the explanation again. Skipping straight to "try again" without
naming what broke turns this into a guessing game instead of a targeted
repair.

## Conversational adoption

This is a chat, not a worksheet — the technique has to be carried entirely
in how the agent talks, one turn at a time, matching `grounding`'s own
global one-question-per-turn rule.

- **Play the role for real, not performatively.** The agent's confusion at
  a jargon word or an unexplained leap should read as genuine
  not-understanding, not a quiz-show "and what does *that* mean?" The
  question is: what would someone actually need explained here, sincerely
  asked.
- **Sit in the gap.** The moment a gap is spotted, the strongest pull is to
  just say what's missing — resist it. Naming the gap ("what does 'connect'
  mean here, exactly?") is the agent's job; filling it is the user's.
- **Don't finish their sentences.** If the user trails off mid-explanation,
  let the silence or the trailing-off stand as the answer to work with —
  don't complete the thought for them, even when the completion seems
  obvious.
- **Point at the source, don't summarize it.** When sending the user back
  to fill a gap, name *where* to look ("look at the paragraph starting 'a
  note gains meaning...'"), not what it says — reading it and
  re-articulating it is the user's step, not the agent's.
- **Keep the ask small.** One gap, one question, one turn. A hesitant
  answer with three separate weak spots still gets one question about the
  most load-bearing gap first, not three at once.

## Worked example

> **Agent:** What stood out to you from this?
> **User:** Something about... how notes need to connect to each other? I
> think?
> **Agent:** Try explaining that to someone who's never heard of a
> Zettelkasten — what does "connect" actually mean here, in plain terms?
> **User:** Like... you link related notes so you can find them later?
> **Agent:** That's one thing linking does. But the source specifically
> argues linking *changes* what a note means over time, not just that it
> helps you find things again — look at the paragraph starting "a note
> gains meaning..." What's it actually claiming there?
> **User:** Oh — it's saying the note's meaning isn't fixed when you write
> it, it shifts as you connect it to more things later.
> **Agent:** Now say that back to me the way you'd explain it to a friend
> who's never touched a note-taking app.

## Guardrail

The re-explanation step can degenerate into rote restatement — the user
parrots back the same words just used to point out the gap, rather than
actually reconstructing the idea in their own language. If the second
explanation is suspiciously close to the correction just given, that's not
a fixed gap — ask a follow-up that requires genuine translation ("put that
in your own words, not the source's") rather than accepting the echo as
progress.

A second failure mode, distinct from the first: over-explaining the gap
itself when naming it. "What does 'connect' mean here — I mean, does it
mean linking for retrieval, or something about meaning changing over time?"
already hands over the answer inside the question. Name the gap, not the
candidate answers.
```

- [ ] **Step 3: Verify the file's structure**

Run: `grep -c "^## " skills/grounding/references/feynman.md`
Expected: `6`

Run: `grep -c "self-explanation.md" skills/grounding/references/feynman.md`
Expected: `1`

- [ ] **Step 4: Commit**

```bash
git add skills/grounding/references/feynman.md
git commit -m "feat(grounding): add feynman.md reference file

Explain-simply/find-the-gap/return-to-source technique for a hesitant
reading."
```

---

### Task 5: `grounding/references/maieutic.md` — new file

**Files:**
- Create: `skills/grounding/references/maieutic.md`

**Interfaces:**
- Consumes: dispatched from `grounding/SKILL.md`'s table on a "Blank, no source at all" reading
- Produces: `discovery-walk.md` (Task 6) composes this technique as one of its three ingredients — this file must exist before Task 6's cross-reference is meaningful

- [ ] **Step 1: Verify the file doesn't exist yet**

Run: `test -f skills/grounding/references/maieutic.md && echo EXISTS || echo MISSING`
Expected: `MISSING`

- [ ] **Step 2: Create the file**

```markdown
# Maieutic

## What it is

Socrates' own metaphor, from Plato's *Theaetetus*: the philosopher as
midwife, not implanting an idea but helping someone deliver one already
forming inside them — then checking whether the "offspring" (the belief) is
legitimate or "stillborn." Two phases in one continuous act: drawing out,
then testing what came out.

## Why this technique, for this job

This is the one technique built for going from nothing articulated yet to a
first spoken form, without a source text to lean on at all — which is
exactly the sourceless case (a bare hunch, memory, personal experience,
nothing written down anywhere). Feynman needs some existing content to loop
against; maieutic works even when there's genuinely nothing external to
check the emerging idea against, because the "evidence" here is the user's
own experience, not a document.

**Use this when** the answer is blank and there's no source at all — the
same midwife mechanism `discovery-walk.md` uses, aimed directly at memory or
experience since there's no text to walk through instead.

**Don't use this when** a source is present and blank — `discovery-walk.md`
is the composite built for that case, using maieutic as one of its three
ingredients rather than running it alone.

## Concept

The specific problem this solves is an inchoate, pre-verbal sense of
understanding — someone senses they have a position but can't yet say what
it is. The midwife doesn't supply the missing content (there may be nothing
external to check it against anyway); she has only the technique to help
deliver what's already forming, then a separate diagnostic step to test
whether what came out is actually sound once it exists.

This resists reduction to a fixed checklist more than the other techniques
here — it's described in its own tradition as something that "cannot be
taught directly," only exercised indirectly. That's a real limitation to
hold onto: this is closer to a stance than a script.

## Conversational adoption

- **Ask toward the hunch, not around it.** "What's the piece of this you
  keep coming back to?" invites the forming idea forward, rather than
  asking a diagnostic question that presumes something specific already
  exists to interrogate.
- **Don't supply candidate answers.** Because there's no source to point
  at, the temptation to just suggest a plausible-sounding position is
  stronger here than anywhere else in the family — resist it entirely; a
  suggested idea isn't the user's own, however close it might be.
- **Test only after something's delivered.** The diagnostic half (is this
  "offspring" legitimate) only starts once a real position has actually
  been spoken — don't test a hunch that hasn't been said yet.
- **Personal experience is the material here**, not a stand-in for a
  missing source — memory and lived experience are legitimate, complete
  grounding material in their own right for this case.

## Worked example

> **Agent:** What's the piece of this idea you keep circling back to, even
> if you can't say it cleanly yet?
> **User:** Something about how... I only really understand something once
> I've had to explain it to someone else? Like reading it alone never quite
> lands the same way.
> **Agent:** Say more about a specific time that happened — what were you
> trying to explain, and what changed once you had to say it out loud?
> **User:** I was trying to explain a work process to a new hire, and
> halfway through I realized I didn't actually understand a step I thought
> I already knew.
> **Agent:** So is the position something like: understanding isn't
> complete until it survives being explained to someone else — is that
> close to what you mean, or does it need adjusting?

## Guardrail

Because there's no external evidence to check the idea against, there's a
real risk of confirming a position too easily just because it sounds
coherent and nothing contradicts it. The diagnostic half of maieutic —
testing whether the "offspring" is legitimate — still has to happen even
without a source: press the stated position with a boundary or consequence
question before treating it as settled, the same rigor `verification.md`
would apply against a text, applied here against the user's own stated
reasoning instead.
```

- [ ] **Step 3: Verify the file's structure**

Run: `grep -c "^## " skills/grounding/references/maieutic.md`
Expected: `6`

- [ ] **Step 4: Commit**

```bash
git add skills/grounding/references/maieutic.md
git commit -m "feat(grounding): add maieutic.md reference file

Drawing-out/testing-the-offspring technique for a blank reading with no
source present."
```

---

### Task 6: `grounding/references/discovery-walk.md` — new file

**Files:**
- Create: `skills/grounding/references/discovery-walk.md`

**Interfaces:**
- Consumes: dispatched from `grounding/SKILL.md`'s table on a "Blank, source present, walk together chosen" reading; composes `feynman.md` (Task 4) and `maieutic.md` (Task 5) — both must already exist
- Produces: a session that still passes through `grounding/SKILL.md`'s Gate once, over the accumulated result (already stated in Task 1's Gate section — no new contract here)

- [ ] **Step 1: Verify the file doesn't exist yet, and that its two composed dependencies exist**

Run: `test -f skills/grounding/references/discovery-walk.md && echo EXISTS || echo MISSING`
Expected: `MISSING`

Run: `test -f skills/grounding/references/feynman.md && test -f skills/grounding/references/maieutic.md && echo BOTH_EXIST`
Expected: `BOTH_EXIST` (confirms Tasks 4 and 5 landed first)

- [ ] **Step 2: Create the file**

```markdown
# Discovery walk

## What it is

Not a single named academic technique — a composite, built for this family
specifically, of three: Maieutic's drawing-out stance, Feynman's
explain-then-patch loop, and ZPD/scaffolding's paced-support principle. The
source gets walked passage by passage, with a question asked before each
next passage is revealed rather than the passage being delivered and then
discussed afterward. Comprehension is built turn by turn, not handed over
and checked.

## Why this technique, for this job

Every other technique here assumes a restatement already exists, or at
least an attempt at one. Discovery walk is for the one case where nothing
does — the user hasn't engaged with the source at all yet, but a source
exists to walk through. Delivering the source and then asking about it
would be the exact didactic anti-pattern `grounding` exists to avoid;
walking it via questions, one passage at a time, keeps construction in the
user's hands even when there's nothing yet built to check.

**Use this when** the answer is blank, a source is present, and the user
chose "walk through this together" over "let me try explaining first."

**Don't use this when** a source isn't present — there's nothing to walk
through. See `maieutic.md` instead, aimed directly at memory or experience.

**Don't offer this before** a first plain attempt has genuinely failed —
it's a recovery path chosen by the user, never a default opener.

## Concept

The walk works because each turn's question is scoped to what's already
been shown, not what's coming — "what do you think this is building toward,
before I show you the next line?" forces a prediction against only the
material already available, the same way any single-passage question
would, just chained across the whole source rather than asked once at the
end.

ZPD's contribution is pacing, not question content: the amount of
scaffolding (how much of a hint accompanies each question) should track how
the user is actually doing turn to turn — more support after a missed
prediction, less once several land correctly in a row — support withdrawn
as competence shows itself, not held constant regardless of how the walk is
going.

## Conversational adoption

- **Reveal one passage at a time.** Never show more of the source than the
  current question needs — the next passage is the reward for engaging
  with the current one, not something to preview.
- **Ask before revealing, not after.** "What do you think happens next,
  based on what you've read so far?" comes before the next passage is
  shown, not as a recap question once it's already been read.
- **Calibrate support to how it's going.** A missed prediction earns a bit
  more scaffolding on the next question; several correct predictions in a
  row earns less — don't hold the difficulty flat regardless of signal.
- **Consolidate at the end, don't re-verify every turn.** Each turn already
  checks itself against the source locally; save the full Gate pass for the
  accumulated result once the walk concludes.

## Worked example

> **Agent:** Here's the opening: "A note gains meaning not when it's
> written, but..." — before I show you the rest of that sentence, what do
> you think comes next?
> **User:** Maybe... when someone reads it again?
> **Agent:** Close in spirit — here's the actual rest: "...but as it
> accumulates connections to other notes over time." Given that, what do
> you think the author is setting up to argue next?
> **User:** That the value of a note isn't really about what it says on its
> own, but what it ends up linked to?
> **Agent:** That's exactly the direction — let's keep going.

## Guardrail

The walk can quietly turn into delivery if the "before I show you the next
line" question gets skipped on a few turns because the pace feels slow —
once that happens even a couple of times, the session has become exactly
the didactic delivery this technique exists to avoid. Every passage
transition needs its question, no exceptions for pacing.
```

- [ ] **Step 3: Verify the file's structure and its composed cross-references**

Run: `grep -c "^## " skills/grounding/references/discovery-walk.md`
Expected: `6`

Run: `grep -c "feynman.md\|maieutic.md" skills/grounding/references/discovery-walk.md`
Expected: `2` or more (both composed techniques named)

- [ ] **Step 4: Commit**

```bash
git add skills/grounding/references/discovery-walk.md
git commit -m "feat(grounding): add discovery-walk.md reference file

Composite of Maieutic + Feynman + ZPD scaffolding for a blank reading
with a source present. Not a single sourced academic technique - built
for this family specifically."
```

---

### Task 7: `grounding/references/self-explanation.md` — new file

**Files:**
- Create: `skills/grounding/references/self-explanation.md`

**Interfaces:**
- Consumes: dispatched from `grounding/SKILL.md`'s table on a Confused reading
- Produces: nothing further downstream

- [ ] **Step 1: Verify the file doesn't exist yet**

Run: `test -f skills/grounding/references/self-explanation.md && echo EXISTS || echo MISSING`
Expected: `MISSING`

- [ ] **Step 2: Create the file**

```markdown
# Self-explanation

## What it is

From Chi et al.'s research on generative learning: learners explaining
material to themselves while engaging with it, generating inferences and
repairing their own mental model when they notice a discrepancy between new
material and what they already believed. Distinct from asking a targeted
"why" question (that's elaborative interrogation) — this is open-ended,
unprompted sense-making, and the repair happens because the discrepancy was
*noticed*, not because it was corrected for the person.

## Why this technique, for this job

A confused-but-not-blank answer is exactly a mental-model-repair situation —
something was said, it just doesn't hold together, meaning a discrepancy
exists somewhere between what was said and what the source (or the user's
own prior reasoning) actually supports. This technique's whole mechanism is
surfacing that discrepancy and letting the person notice and fix it
themselves, rather than the agent diagnosing and correcting it directly —
which matters here because correcting it outright would be exactly the
kind of "handing over the answer" the whole family exists to avoid.

**Use this when** the answer is confused — touched something, but garbled
or circular, distinct from Hesitant (uncertain but coherent) and Blank
(nothing substantive at all).

**Use `feynman.md` instead when** the answer is hesitant rather than
confused — shaky but not self-contradictory. Feynman's loop assumes a
simplifiable idea exists; this technique assumes a *specific internal
inconsistency* to surface, which a merely-hesitant answer may not have.

## Concept

Chi's own data shows the technique's benefit is highly contingent on how
well someone already self-explains — a "high self-explainer" and a "low
self-explainer" get very different results from the same open-ended
prompt, and the bare technique offers no built-in scaffolding for improving
a poor self-explainer's ability. That's exactly why this family's version
narrows the open-ended version down to something more targeted: rather than
"make sense of this however you can," surface the *specific* discrepancy
noticed in what was just said, pointed at directly, so even someone who
wouldn't self-explain well unprompted has something concrete to work from.

## Conversational adoption

- **Name the specific contradiction, not the general confusion.** "You said
  X, but a moment ago you said Y — how do those fit together?" is far more
  useful than "that doesn't quite make sense, try again."
- **Point at the discrepancy, don't resolve it.** The repair is the user's
  own — the agent's job stops at making the inconsistency visible.
- **Let genuine confusion sit for a moment.** Don't rush to rephrase the
  question if the first attempt to surface the discrepancy doesn't land
  immediately — repair takes a beat, especially for material that was
  genuinely garbled.
- **Distinguish "still confused" from "newly confused."** If naming the
  discrepancy produces a different confusion than the original one, that's
  actually progress (a smaller, sharper gap) — don't treat it as a failed
  attempt.

## Worked example

> **User:** So notes get better the more you write, because linking them
> makes them clearer, but also each note is supposed to stand alone without
> needing the others?
> **Agent:** Those two things you just said seem to be in tension — notes
> get clearer *through* their links, but also need to make sense *without*
> them. How do you square those?
> **User:** Hm. Maybe... the note itself has to be complete on its own, but
> the links are what make it *more* valuable, not what make it
> understandable in the first place?
> **Agent:** That's a real distinction — completeness versus value added.
> Does that resolve the tension, or is there still a piece that doesn't
> fit?

## Guardrail

There's a temptation to soften the discrepancy into something gentler than
it actually is — hedging the contradiction so it doesn't feel like a
callout. That defeats the mechanism: the discrepancy has to be named
clearly enough to actually notice, not smoothed into something so vague
it's easy to wave past without genuinely reconciling it.
```

- [ ] **Step 3: Verify the file's structure**

Run: `grep -c "^## " skills/grounding/references/self-explanation.md`
Expected: `6`

- [ ] **Step 4: Commit**

```bash
git add skills/grounding/references/self-explanation.md
git commit -m "feat(grounding): add self-explanation.md reference file

Mental-model-repair (Chi et al.) technique for a confused, not-blank
reading."
```

---

### Task 8: Move and rewrite `compass.md` into `grounding/references/`

**Files:**
- Create: `skills/grounding/references/compass.md`
- Delete: `skills/ground-my-take/references/compass.md`

**Interfaces:**
- Consumes: nothing (Compass is upstream of the answer-quality table — see Task 1's note on this)
- Produces: `connect.md`/`challenge.md` (Tasks 9-10) execute its West/East directions; `distil.md` (Task 11) runs after both

- [ ] **Step 1: Read the current shipped file before replacing it**

Run: `cat skills/ground-my-take/references/compass.md`

Expected: the current three-part file (Concept, Layout, Directions, Guardrail — no What-it-is/Why-here/opener/Conversational-adoption sections) with the current attribution line: `"also called the Compass of Zettelkasten Thinking"` and no mention of recursion.

- [ ] **Step 2: `git mv` the file into its new location**

```bash
git mv skills/ground-my-take/references/compass.md skills/grounding/references/compass.md
```

- [ ] **Step 3: Rewrite the moved file's full content**

```markdown
# Compass

## What it is

The Idea Compass, a thinking tool that places one idea (X) at the centre
and asks four different questions about it, one per compass direction.
Fei-Ling Tseng's own 2022 post coins it "the Compass of Zettelkasten
Thinking"; the shorter "Idea Compass" name comes from a later joint
presentation by Tseng and Vicky Zhao at a LYT (Nick Milo's "Linking Your
Thinking") conference — Sascha Fast (zettelkasten.de) adopted and
popularized that shorter name once he learned it predated his own writing
on the technique, and classifies it as a "closed creative technique": a
fixed set of questions that provides a direction of exploration from a
known starting point, as opposed to an open-ended technique like
mind-mapping.

## Why this technique, for this job

Compass operates at a different point in a session than the rest of
`grounding`'s techniques — it decides *what to ask about next*, not *how to
respond to whatever comes back*. A question Compass generates still gets a
confident, hesitant, blank, or confused answer, and that answer still
routes through `SKILL.md`'s own dispatch table exactly as any other
question's would. Compass is the layer that orients a synthesis session
toward something worth asking about; the rest of the family handles what
happens once it's asked.

**Use this when** a session is building toward a synthesized position (an
idea drawing on more than one source, or a hunch with nothing yet written
down) and needs a direction to explore next, rather than a response to
something already said.

**Don't use this** as a substitute for the answer-quality dispatch table —
Compass never decides how to handle a confused or hesitant answer; it only
decides what the next question is about.

## Layout

```
                    NORTH
                (where X comes from)
                        │
   WEST ─────────────── X ─────────────── EAST
(what's similar to X)          (what competes with X)
                        │
                    SOUTH
                (where X leads)
```

## Directions

- **NORTH — where does X come from?** Its origin, its parent category, what
  caused it. Not a question to ask fresh — the answer is already in hand:
  for a Take still being drafted, it's whichever notes were named,
  retrieved, or surfaced from the backlog to start this session; for an
  existing evergreen note being revisited, it's that note's own
  `derived-from` frontmatter field, read directly from the file. Never a
  database query either way.

- **WEST — what is similar to X?** What other disciplines already hold this
  idea, what other ways exist to say or do it. Executed via the **Connect**
  technique — see `references/connect.md`.

- **SOUTH — where can X lead? what does X contribute to?** Drilling into
  X's own downstream contribution — what it nurtures, what it could be the
  headline of — asked independently of whatever West or East turn up. A
  plain direct question, same treatment as North: no technique needed, just
  ask it and let the take develop.

- **EAST — what competes with X?** What is the opposite of X, what is it
  missing, its disadvantage. Executed via the **Challenge** technique — see
  `references/challenge.md`.

## Conversational adoption

- **Reach for whichever direction the conversation calls for**, never all
  four as a mandatory checklist — a direction turning up nothing is a
  complete result for that direction, not a gap to force-fill.
- **The four directions are independent of each other.** West's finding and
  East's finding don't get reconciled inside Compass itself — that
  reconciliation, when both have produced something, is Distil's job (see
  `references/distil.md`), never Compass's own.
- **Directions recurse — treat this as optional, not mandatory.** Any
  answer that comes out of a direction can become its own new center idea,
  with its own SOUTH/EAST/WEST branches. This is real and worth noticing,
  but never mandatory to chase within the current sitting: a spawned
  sub-idea that isn't pursued now gets logged to the evergreen backlog
  (`slipbox evergreen add --slug <draft-slug> --reason "<what came up>"`)
  for a later, separate session — the same way any other flagged tension
  gets carried forward, not lost.

## Worked example

A user exploring "housing is a human right because it provides the
stability needed to function in society" reaches EAST and surfaces
"affordability crises make stable housing markets hard to guarantee." That
EAST answer is itself a candidate for a fresh Compass session later — its
own SOUTH might be "land-value taxation as one response," its own EAST
might be "does regulation actually worsen scarcity?" None of that gets
chased down in the current sitting unless the user wants to; if not, it's
logged to the backlog as its own future starting point.

## Guardrail

Forcing every direction on every take produces a rote interview, not a
sharpened one — the compass is a portable thinking tool, not a required
pass. The same discipline applies to recursion: a sub-idea spawned by a
direction is optional to chase, never force-completed within the current
session, and never silently dropped either — it goes to the backlog if it
isn't pursued now.
```

- [ ] **Step 4: Verify the rewrite — attribution, recursion, and structure**

Run: `grep -c "also called the Compass of Zettelkasten Thinking" skills/grounding/references/compass.md`
Expected: `0` (the old conflated attribution line is gone)

Run: `grep -c "LYT" skills/grounding/references/compass.md`
Expected: `1`

Run: `grep -c "recurse\|recursion" skills/grounding/references/compass.md`
Expected: `2` or more

Run: `grep -c "evergreen backlog\|evergreen add" skills/grounding/references/compass.md`
Expected: `1` or more

- [ ] **Step 5: Verify the old location no longer has the file**

Run: `test -f skills/ground-my-take/references/compass.md && echo STILL_THERE || echo MOVED`
Expected: `MOVED`

- [ ] **Step 6: Commit**

```bash
git add -A skills/grounding/references/compass.md skills/ground-my-take/references/compass.md
git commit -m "feat(grounding): move compass.md in from ground-my-take, rewrite

Corrects attribution: Tseng coins 'Compass of Zettelkasten Thinking',
'Idea Compass' traces to a Zhao/Tseng LYT presentation Fast later adopted
and credited, not a single coined-and-presented moment.

Adds the composition-model note (Compass orients what to ask, the
answer-quality table handles how to respond) and names Compass's own
recursion explicitly - a spawned sub-idea is optional to chase, unpursued
branches route to the existing evergreen backlog rather than being force-
completed or dropped.

Upgraded from the shipped 3-part shape (Concept/Guardrail/Worked example)
to the family's full 7-part shape."
```

---

### Task 9: Move and rewrite `connect.md` into `grounding/references/`

**Files:**
- Create: `skills/grounding/references/connect.md`
- Delete: `skills/ground-my-take/references/connect.md`

**Interfaces:**
- Consumes: executed by Compass's WEST direction (Task 8)
- Produces: nothing further downstream

- [ ] **Step 1: Read the current shipped file**

Run: `cat skills/ground-my-take/references/connect.md`

- [ ] **Step 2: `git mv` the file**

```bash
git mv skills/ground-my-take/references/connect.md skills/grounding/references/connect.md
```

- [ ] **Step 3: Rewrite the moved file's full content**

```markdown
# Connect

## What it is

Executes Compass's WEST direction ("what is similar to X?") — see
`compass.md`. Grounded in Niklas Luhmann's own account of why a note
collection becomes a genuine thinking partner: only if it can *surprise*
its author.

## Why this technique, for this job

A synthesis session's material is often several existing notes — Connect is
the move that treats linking two of them not as filing, but as the
operation that actually produces new information the user didn't already
hold. It's what makes a Compass session's WEST direction more than a bare
"does this remind you of anything" question.

**Use this when** Compass has oriented toward WEST — the session is looking
for what else already holds a similar shape to the idea in play.

**Don't use this** as a general-purpose "find something related" step
outside of Compass's own WEST direction — Connect's guardrail (structural,
not thematic) only makes sense in that context.

## Concept

"One of the most basic presuppositions of communication is that the
partners can mutually surprise each other" (Luhmann). Linking a new idea
into an existing note produces "combinatorial possibilities that can never
have been planned, anticipated, or conceived that way" — connection isn't
filing, it's the operation that generates information the author didn't
already hold.

Cognitive-science research independently supports the same mechanism: Craik
& Lockhart's levels-of-processing work found retention and comprehension
scale with how well new material integrates into pre-existing knowledge
structures, not with how much is processed in isolation. Bartlett's schema
theory: relating new material to an existing schema produces understanding
a schema-less encounter with the same material doesn't.

## Conversational adoption

- **Ask for the shared shape, not the shared topic.** "What's the
  underlying pattern these two share?" surfaces structure; "are these
  related?" invites a shallow yes.
- **Trace to material actually in play.** Per `grounding`'s own Fidelity
  rule, a suggested connection must trace to a note actually retrieved or
  already in the session — never supplied from the agent's own outside
  knowledge of "similar things."
- **Let a thin connection stay thin.** If nothing structural turns up,
  that's a complete result for this direction, not a gap to force.

## Worked example

The user has a note on spaced repetition and a note on how compound
interest rewards early, small, repeated contributions. Ask: "both of these
are cases where a small repeated action compounds into an outsized result
over a long enough window — is that the shape you're actually pointing at
here, or is it more specific to learning?"

## Guardrail

A connection only counts if it's structural, not thematic — two notes
sharing a keyword isn't a connection, two notes sharing an underlying shape
is (neither "spaced repetition" nor "compound interest" appears in the
other in the worked example above; the shared shape does).
```

- [ ] **Step 4: Verify the rewrite and the old location**

Run: `grep -c "^## " skills/grounding/references/connect.md`
Expected: `6`

Run: `test -f skills/ground-my-take/references/connect.md && echo STILL_THERE || echo MOVED`
Expected: `MOVED`

- [ ] **Step 5: Commit**

```bash
git add -A skills/grounding/references/connect.md skills/ground-my-take/references/connect.md
git commit -m "feat(grounding): move connect.md in from ground-my-take, upgrade to 7-part shape"
```

---

### Task 10: Move and rewrite `challenge.md` into `grounding/references/`

**Files:**
- Create: `skills/grounding/references/challenge.md`
- Delete: `skills/ground-my-take/references/challenge.md`

**Interfaces:**
- Consumes: executed by Compass's EAST direction (Task 8)
- Produces: nothing further downstream

- [ ] **Step 1: Read the current shipped file**

Run: `cat skills/ground-my-take/references/challenge.md`

- [ ] **Step 2: `git mv` the file**

```bash
git mv skills/ground-my-take/references/challenge.md skills/grounding/references/challenge.md
```

- [ ] **Step 3: Rewrite the moved file's full content**

```markdown
# Challenge

## What it is

Executes Compass's EAST direction ("what competes with X?") — see
`compass.md`. Grounded in Karl Popper's falsificationism: a test only
counts if it carries real risk of negating the claim.

## Why this technique, for this job

A synthesis session's idea is worth sharpening against its strongest
opposition, not just its supporting evidence — Challenge is the move that
actively seeks the condition under which the claim would be false, rather
than gathering more confirmation for it. It's what makes Compass's EAST
direction a genuine test, not a rhetorical gesture.

**Use this when** Compass has oriented toward EAST — the session is looking
for what competes with, or breaks, the idea in play.

**Don't use this** as a way to simply list disadvantages — a real Challenge
has to risk actually breaking the claim, not just note a minor downside.

## Concept

Applied to a take, the move is to actively seek the condition under which
the claim would be false, not gather more support for it. Toulmin's
argument model supplies the structural slot: every argument carries a
rebuttal position, found by examining objections to its grounds, warrant,
and backing. The practitioner form is steelmanning — state the strongest
version of the opposing case, then genuinely try to break the claim, not
perform token objections.

## Conversational adoption

- **Find the real test, not a rhetorical one.** Per Popper's own criterion,
  if the user's answer could only ever confirm the take, it wasn't a real
  test — look for the version of the question that could actually break
  it.
- **Steelman before challenging.** State the strongest form of the
  competing case, not a weak caricature of it, before asking the user to
  respond.
- **Stay a question, not a verdict.** Surfacing the competing case is the
  whole job; delivering the counter-argument's conclusion on the user's
  behalf is not — the same "never your own opinion" rule `grounding` holds
  everywhere, aimed here at a synthesis instead of a source.

## Worked example

The user proposes that open-plan offices always hurt deep work. Ask: "would
that hold for a team doing mostly quick synchronous coordination rather
than long solo focus blocks — where would this connection actually break
down?"

## Guardrail

Two failure modes, both real:

- **A rhetorical question isn't a Challenge.** If the user's answer could
  only ever confirm the take, it wasn't a real test.
- **A Challenge stays a question.** Delivering the counter-argument's
  conclusion for the user is not the job — surfacing the competing case is.
```

- [ ] **Step 4: Verify the rewrite and the old location**

Run: `grep -c "^## " skills/grounding/references/challenge.md`
Expected: `6`

Run: `test -f skills/ground-my-take/references/challenge.md && echo STILL_THERE || echo MOVED`
Expected: `MOVED`

- [ ] **Step 5: Commit**

```bash
git add -A skills/grounding/references/challenge.md skills/ground-my-take/references/challenge.md
git commit -m "feat(grounding): move challenge.md in from ground-my-take, upgrade to 7-part shape"
```

---

### Task 11: Move and rewrite `distil.md` into `grounding/references/`

**Files:**
- Create: `skills/grounding/references/distil.md`
- Delete: `skills/ground-my-take/references/distil.md`

**Interfaces:**
- Consumes: runs after both Connect (Task 9) and Challenge (Task 10) have produced something, per Compass's own Guardrail (Task 8)
- Produces: nothing further downstream — this is the last file in the ten-file `grounding/references/` set

- [ ] **Step 1: Read the current shipped file**

Run: `cat skills/ground-my-take/references/distil.md`

- [ ] **Step 2: `git mv` the file**

```bash
git mv skills/ground-my-take/references/distil.md skills/grounding/references/distil.md
```

- [ ] **Step 3: Rewrite the moved file's full content**

```markdown
# Distil

## What it is

Runs after Compass's West (Connect) and East (Challenge) have both produced
something — see `compass.md`. Not a fourth compass direction. Combines two
opposing inputs into a new claim, closer to Koestler's bisociation and
Fauconnier & Turner's conceptual blending than to classical Hegelian
synthesis, which mandates a single resolving outcome rather than an
open-ended result.

## Why this technique, for this job

Connect and Challenge each produce a separate finding on their own — Distil
is the only technique in the set whose entire job is combining two prior
results into something neither alone said. It's what turns "here's a
similarity" and "here's a tension" into an actual sharpened position,
rather than leaving the two findings sitting side by side unreconciled.

**Use this when** both Connect and Challenge have already produced
something in the same session — never before both have.

**Don't use this** if only one direction has turned something up. A single
finding reflected back isn't Distil; it's just restating that finding.

## Concept

The general move — combining two opposing inputs into a new claim — has an
ancestor in Hegelian dialectical synthesis, though the classical formula
(thesis + antithesis → one resolving synthesis) mandates a single outcome,
not several. A closer structural match for an open-ended result is
Koestler's bisociation and Fauconnier & Turner's conceptual blending: joining
two frames of reference lets a new element emerge, without predetermining
what kind of result that is.

The three-way check below — supports one side, conflicts with both, or
produces a new point of view — is not itself lifted from any one named
theory. It's this skill's own extension, built on top of blending theory's
open-endedness.

## Conversational adoption

- **Reflect the combination back, don't assert it.** State the merged
  result as a question the user confirms or corrects, not a conclusion
  handed down.
- **Reconstruct toward the strongest coherent version** of what's emerging
  (principle of charity), not the weakest or most convenient one to work
  with.
- **The reflect-back only counts once the user has explicitly confirmed
  it** — `grounding`'s own Gate applies at full force here: a pause, a
  topic change, or the conversation merely feeling settled does not fix
  it, and a vague or hand-wavy answer is not raw material to polish into
  coherence on the user's behalf.

## Worked example

West (Connect) surfaced that spaced repetition and compound interest share
a shape: small repeated actions compounding into an outsized result. East
(Challenge) surfaced that friction-removing tools might undermine this —
removing the friction of capturing a thought also removes the friction that
would have forced the user to clarify it first. Reflect the combination
back: "so tools that make capture easier could be working against the same
compounding effect you just connected spaced repetition to — is that the
tension you're pointing at, or have I drifted from what you meant?"

## Guardrail

If the result only supports one side unchanged, that's not synthesis yet —
the same failure the purity check (see the wrapper skill's own `SKILL.md`)
is built to catch, just caught earlier here.
```

- [ ] **Step 4: Verify the rewrite and the old location**

Run: `grep -c "^## " skills/grounding/references/distil.md`
Expected: `6`

Run: `test -f skills/ground-my-take/references/distil.md && echo STILL_THERE || echo MOVED`
Expected: `MOVED`

Run: `find skills/ground-my-take/references -type f 2>/dev/null | wc -l`
Expected: `0` (all four reference files have now moved out)

- [ ] **Step 5: Commit**

```bash
git add -A skills/grounding/references/distil.md skills/ground-my-take/references/distil.md
git commit -m "feat(grounding): move distil.md in from ground-my-take, upgrade to 7-part shape

Completes the move - grounding/references/ now holds all ten technique
files (six original + four moved from ground-my-take)."
```

---

### Task 12: Rewrite `tests/grounding/evals.json`

**Files:**
- Modify: `tests/grounding/evals.json`

**Interfaces:**
- Consumes: the mechanism defined in Task 1

- [ ] **Step 1: Read the current file and confirm it references the old mechanism**

Run: `grep -c "probe\|Mechanism\|Boundary\|Distinction" tests/grounding/evals.json`
Expected: `0` (the current file's prompts/expected_output don't actually name the old probes directly — verify this assumption before editing; if any hits appear, note them for removal in Step 2 below)

- [ ] **Step 2: Replace the file's full content**

```json
{
  "test_cases": [
    {
      "prompt": "ground this statement against a source: [source text] says X — is that right?",
      "expected_output": "Reads as a confident answer, so it runs verification.md: treats the statement as a hypothesis, checks it against the specific passage in the source, and only escalates to elenchus.md if that check surfaces a genuine mismatch.",
      "assertions": [
        {"type": "contains", "text": "source"}
      ]
    },
    {
      "prompt": "ground this with no source and no retrieved notes, just a raw hunch, and the user says 'I don't really know, I just have this feeling'",
      "expected_output": "Reads as a blank answer with no source present, so it runs maieutic.md directly against the user's own experience or memory rather than offering to walk through a source that doesn't exist.",
      "assertions": [
        {"type": "not_contains", "text": "cannot proceed"}
      ]
    },
    {
      "prompt": "the user says 'yeah sounds about right' without engaging with the proposed statement",
      "expected_output": "Does not treat this as a confirmation gate pass — probes once more before accepting, since a rubber-stamp without engagement doesn't count as an explicit fix.",
      "assertions": [
        {"type": "contains", "text": "?"}
      ]
    },
    {
      "prompt": "ground this: [source text about design tokens] — I think, um, design tokens are like... CSS variables? I'm not totally sure though",
      "expected_output": "Reads as a hesitant answer, so it runs feynman.md: asks the user to explain the concept simply, finds where the explanation breaks down or leans on unexplained jargon, points at the specific source passage that fills the gap, and asks for the explanation again — never supplying the missing words itself.",
      "assertions": [
        {"type": "not_contains", "text": "yes or no"},
        {"type": "contains", "text": "?"}
      ]
    },
    {
      "prompt": "ground this against the source, and the user's answer touches the material but contradicts something they said two turns earlier in the same session",
      "expected_output": "Reads as confused, not blank, so it runs self-explanation.md: names the specific discrepancy between what was just said and what was said earlier, and lets the user reconcile it rather than resolving it for them.",
      "assertions": [
        {"type": "contains", "text": "?"}
      ]
    },
    {
      "prompt": "ground this source, and the user gives no substantive answer at all when asked what stood out",
      "expected_output": "Reads as blank with a source present. Does not diagnose silently — offers a choice between walking through the source together (discovery-walk.md) or trying to explain what stood out first, and only after that first plain attempt already failed, never upfront.",
      "assertions": [
        {"type": "contains", "text": "?"}
      ]
    }
  ]
}
```

- [ ] **Step 3: Verify the JSON is valid**

Run: `python3 -m json.tool tests/grounding/evals.json > /dev/null && echo VALID`
Expected: `VALID`

Run: `grep -c "verification.md\|feynman.md\|maieutic.md\|discovery-walk.md\|self-explanation.md" tests/grounding/evals.json`
Expected: `5` or more (each new technique file named at least once across the test cases)

- [ ] **Step 4: Commit**

```bash
git add tests/grounding/evals.json
git commit -m "test(grounding): rewrite evals for the answer-quality dispatch mechanism

Old test cases exercised the three named probes (Mechanism/Boundary/
Distinction), which no longer exist. New cases exercise all five
answer-quality categories against their dispatched technique files."
```

---

### Task 13: Rename `ground-the-claim` → `make-literature-note`, rewrite `SKILL.md`

**Files:**
- Modify (via `git mv`): `skills/ground-the-claim/` → `skills/make-literature-note/`
- Modify: `skills/make-literature-note/SKILL.md`
- Untouched (moved only, no content change): `skills/make-literature-note/references/qec-theory.md`, `skills/make-literature-note/references/writing-a-claim.md`

**Interfaces:**
- Consumes: `/grounding` (unchanged public contract, per Task 1)
- Produces: nothing further downstream within this plan

- [ ] **Step 1: Read the current shipped `SKILL.md` in full before rewriting**

Run: `cat skills/ground-the-claim/SKILL.md`

- [ ] **Step 2: `git mv` the whole directory**

```bash
git mv skills/ground-the-claim skills/make-literature-note
```

- [ ] **Step 3: Rewrite `SKILL.md`'s full content**

```markdown
---
name: make-literature-note
description: Ground a clipped source into one or more Claims — the source's
  own position, restated in the user's own words and checked against the
  source — writing each as a Key Claim in a shared literature note for that
  source.
license: MIT
metadata:
  version: "1.2.0"
---

# Make-literature-note

## What these words mean

- **Claim** — the source's own position on one specific question the source
  answers, restated in the user's words and checked for fidelity, written
  as a declarative sentence. Never the user's opinion — an object of
  understanding, not agreement. A source usually holds several.
- **Core Idea** — the source's central argument, one declarative sentence,
  every Claim in the note in service of it. Distinct from a Claim: a Claim
  is one thing the source argues, the Core Idea is what the source is
  *for*. Written once per note, on its first Claim.
- **Literature note** — the file a source's confirmed Claims get written
  into. One per source clip, holding as many Key Claims as the source
  actually supports — written incrementally as each is confirmed, never
  revisited afterward except out-of-band manual fidelity corrections:
  fixing a misreading, a transcription error, or wording that
  misrepresents the source. Reaction, stance, or synthesis never enters; a
  correction must move the note closer to the source. Slugs stay final
  once written.

## Prerequisite

Requires `.slipbox/config.json` — same as every skill in this family. If
it's missing, stop and say so. Same check for `.slipbox/bin/slipbox` — if
it doesn't exist or isn't executable, stop and say so too. Every `slipbox`
call below uses this same path, `.slipbox/bin/slipbox` — never bare
`slipbox`, which isn't guaranteed to be on `PATH`.

## Invocation

Named directly — `/make-literature-note from this article` (or a URL, or
a path) — grounds that specific source. A bare `/make-literature-note`
with no argument falls back to inferring the source from context: a
just-clipped Resource, a URL pasted earlier in the conversation, or an
already-open file. Ask only if nothing's inferrable — never guess silently
and never require the argument when the source is obvious from context.

## Take the source

Check whether a literature note for this source already exists: read
`paths.literature` from `.slipbox/config.json` and scan `*.md` under that
folder — never assume a folder literally named `literature/` — for a note
whose resolved `source` field (per `frontmatter.literature.source.name` in
the same config) points at this resource.

- **No note exists yet** — this source hasn't been grounded at all. Proceed
  to the surface pass below with a fresh candidate backlog.
- **A note already exists** — read it in full. Its existing `## Key
  Claims` `###` headings are claims already confirmed; the backlog below
  must not re-offer them.

## Surface pass — builds a private backlog, never a shown menu

Read the whole source yourself — this is your own judgment, not a
`/grounding` call; `/grounding` was never built for open-ended "what does
this cover" scanning, only for probing something already anchored. Using
Question/Evidence/Warrant as your own internal reasoning tool (see
`references/qec-theory.md`) — never shown to the user in this form —
identify every distinct claim the source actually supports and the
source's Core Idea, skipping anything an existing literature note (per
Take the source above) already covers. Apply the shared-Warrant merge test
now, before proceeding: two candidates resting on the same inferential move
are one claim, not two.

This candidate list is **your own private backlog, not a menu presented to
the user** — never surfaced as a checklist, never asked "which of these do
you want grounded." It exists only to steer where the conversation still
needs to go and to check coverage once the sitting winds down. It is
session-scoped only — discarded once the session ends, regardless of how
much of it got covered.

## Ground the source — one continuous conversation, not one session per claim

Run a single, continuous `/grounding` session on the source, holding the
user to it (`grounding`'s own default Fidelity direction for a
source-present session — no parameter to supply here). Do not present the
backlog. Do not ask the user to pick claims from a list. Let the
conversation proceed naturally.

Whenever the conversation organically produces something matching a
backlog candidate — in whatever reshaped form the conversation actually
produces, since a candidate can split, merge, or sharpen into something
different from what the Surface pass first found — treat that as a real
Claim: run it through `/grounding`'s own Gate exactly as always (one
confirmed statement, no shortcut), then write it (see Write below) before
continuing the conversation. The Gate itself never changes shape or
relaxes; only how a claim gets *reached* is different from a fixed
menu-then-loop.

If a tension comes back from a Gate pass, insert it into the evergreen
backlog before continuing:

```bash
.slipbox/bin/slipbox evergreen add --slug <draft-slug> --reason "<tension description>"
```

## Knowing when the sitting is done

Once the conversation's natural energy winds down, check the private
backlog against what actually got covered (in whatever reshaped form).
Anything genuinely untouched gets one nudge, never more: "you haven't
mentioned [X] — is that not something the source argues, or should we
leave it for now?" The user's own "I think that's everything" always ends
the sitting regardless of what the backlog still shows uncovered — the
nudge is a single offer, never an insistence.

## Write each claim, incrementally

As soon as one claim is confirmed — before continuing the conversation
toward the next one, if there is a next one:

- Run a `/write-checks` session on the draft, passing the literature field
  list (`type`, `created`, `source`) — it resolves each field's mapping,
  formatting, zone placement, and title prefix, and checks the draft's
  style and humanize signals.
- Write into `paths.literature` from `.slipbox/config.json`, filename per
  that same config's casing convention for the literature type. The title
  is source/topic-oriented (what the source is about), never claim-shaped
  — it doesn't change as more claims get added. On this note's first
  claim, write the Core Idea line too, directly under the title (see
  `references/writing-a-claim.md`); skip it on a second or later claim,
  it's already there.
- Re-read the target path from disk right before writing (the note may
  already hold earlier claims from this same sitting, or from a prior
  one).
- Assemble and review the claim per `references/writing-a-claim.md` — the
  declarative heading, condensed Evidence, the review checklist, quote
  formatting, and Key Concepts wikilink resolution.
- Filename collision on the note's first claim → stop and ask, never
  auto-disambiguate. On a second or later claim for an existing note, the
  existing file is expected, not a collision.

## Spot terms and entities

Once the sitting ends, one batch pass — never mid-claim. Re-read the
finished note; re-read the source too if this is a resumed session and
it's no longer in context. Compare the two and find anything a claim leans
on — its weight actually resting on it, not just mentioned in passing —
that Key Concepts doesn't yet cover. Wikilink liberally here: this step
doesn't decide what the target will become (Reference note, Person,
Location, Organization, or nothing at all) — that classification happens
downstream, in `find-connections`, once cross-note evidence exists. The
author-exclusion stays unchanged: a source's own author still gets a bare,
unresolved wikilink, never routed toward a Person note through this
pipeline.

For each candidate, also make a quick, cheap read — enough to pick a link
*format*: does this look like a person, place, or organization (real or
fictional), or a concept/term/method? Show the guess alongside each
candidate so the user can correct a misread before anything is written.

Show what was found and why, in one message:

> "Found these worth adding to Key Concepts: [list, each with a one-line
> reason and its guessed kind]. Add all, some, or none — and flag any I've
> read wrong."

On confirmation, run `/write-checks` again and append the confirmed entries
to `## Key Concepts` per `references/writing-a-claim.md`'s wikilink
resolution. Zero found is a complete, valid result.

## Done

The literature note exists on disk with its Core Idea, every claim the
sitting actually produced as its own `## Key Claims` entry, and any
confirmed Key Concepts (partial if the session stopped early — that's a
complete, valid outcome), any flagged tensions are logged in the evergreen
backlog, and the user is told the file path.
```

- [ ] **Step 4: Verify the rewrite**

Run: `grep -c "^name: make-literature-note$" skills/make-literature-note/SKILL.md`
Expected: `1`

Run: `grep -c "menu\|which do you want grounded" skills/make-literature-note/SKILL.md`
Expected: `0` (confirms the shown-menu language is gone)

Run: `grep -c "private backlog" skills/make-literature-note/SKILL.md`
Expected: `2` or more

Run: `test -f skills/make-literature-note/references/qec-theory.md && test -f skills/make-literature-note/references/writing-a-claim.md && echo BOTH_PRESENT`
Expected: `BOTH_PRESENT` (confirms the two reference files moved with the directory and were not touched)

- [ ] **Step 5: Commit**

```bash
git add -A skills/make-literature-note skills/ground-the-claim
git commit -m "refactor(ground-the-claim): rename to make-literature-note, backlog model

Renames ground-the-claim -> make-literature-note (established Zettelkasten
vocabulary over private family jargon). Replaces the shown-menu-then-loop
shape with a private backlog: one continuous conversation on the source,
claims confirmed as they're organically reached rather than pre-selected
from a list, nudge-once-then-defer completion. /grounding's own per-claim
Gate contract is unchanged - only how a claim gets reached is different.

Adds explicit-argument-with-inference-fallback invocation
(/make-literature-note from this article, or bare with context inference).

qec-theory.md and writing-a-claim.md moved with the directory, untouched -
Q/E/C stays this skill's own pre-session/post-session reasoning tool, never
something the engine runs mid-interrogation."
```

---

### Task 14: Rename and rewrite `tests/ground-the-claim/` → `tests/make-literature-note/`

**Files:**
- Modify (via `git mv`): `tests/ground-the-claim/` → `tests/make-literature-note/`
- Modify: `tests/make-literature-note/evals.json`

**Interfaces:**
- Consumes: the redesign from Task 13

- [ ] **Step 1: `git mv` the directory**

```bash
git mv tests/ground-the-claim tests/make-literature-note
```

- [ ] **Step 2: Replace `evals.json`'s full content**

```json
{
  "test_cases": [
    {
      "prompt": "/make-literature-note from resources/2026-08-08-design-tokens.md, a freshly clipped source with no literature note yet",
      "expected_output": "Reads the whole source silently and builds a private backlog of candidate claims plus the Core Idea - never presents this list to the user as a menu to pick from. Runs one continuous, natural conversation about the source, holding the user to it. Whenever the conversation organically produces something matching a backlog candidate (in whatever reshaped form), runs it through grounding's own Gate and writes it incrementally - declarative heading plus condensed Evidence, not batched at the end. Ends with a nudge for anything genuinely untouched in the backlog, then a batch pass finding terms/entities.",
      "assertions": [
        {"type": "not_contains", "text": "which do you want grounded"},
        {"type": "not_contains", "text": "surface-ideas"}
      ]
    },
    {
      "prompt": "make-literature-note on resources/2026-08-08-design-tokens.md, where the literature note already has one confirmed claim from a prior session",
      "expected_output": "Reads the existing literature note's ### claim headings first, excludes them from the private backlog, and does not re-write the Core Idea line.",
      "assertions": [
        {"type": "not_contains", "text": "menu"}
      ]
    },
    {
      "prompt": "make-literature-note, invoked bare with no argument, but a resource was just clipped moments earlier in the same conversation",
      "expected_output": "Infers the source from the just-clipped resource rather than asking the user to name it again.",
      "assertions": [
        {"type": "not_contains", "text": "which article"}
      ]
    },
    {
      "prompt": "make-literature-note, invoked bare with no argument and nothing inferrable from context",
      "expected_output": "Asks the user which source to ground rather than guessing.",
      "assertions": [
        {"type": "contains", "text": "?"}
      ]
    },
    {
      "prompt": "make-literature-note on a source, and the conversation winds down naturally with two backlog candidates never mentioned",
      "expected_output": "Nudges once for the untouched candidates ('you haven't mentioned X - is that not something the source argues, or should we leave it?'), but if the user says 'I think that's everything,' ends the sitting regardless of what the backlog still shows uncovered.",
      "assertions": [
        {"type": "contains", "text": "?"}
      ]
    },
    {
      "prompt": "make-literature-note on a candidate whose derived filename already exists on disk with unrelated content",
      "expected_output": "Stops and asks the user to reword the claim or confirm a genuine duplicate, rather than auto-disambiguating the filename.",
      "assertions": [
        {"type": "contains", "text": "?"}
      ]
    }
  ]
}
```

- [ ] **Step 3: Verify**

Run: `python3 -m json.tool tests/make-literature-note/evals.json > /dev/null && echo VALID`
Expected: `VALID`

- [ ] **Step 4: Commit**

```bash
git add -A tests/make-literature-note tests/ground-the-claim
git commit -m "test(make-literature-note): rename tests dir, rewrite evals for backlog model"
```

---

### Task 15: Rename `ground-my-take` → `make-evergreen-note`, rewrite `SKILL.md`

**Files:**
- Modify (via `git mv`): `skills/ground-my-take/` → `skills/make-evergreen-note/`
- Modify: `skills/make-evergreen-note/SKILL.md`

**Interfaces:**
- Consumes: `/grounding` (unchanged public contract), `references/compass.md` and its three supporting files (now living in `skills/grounding/references/`, per Tasks 8-11)
- Produces: nothing further downstream within this plan

- [ ] **Step 1: Read the current shipped `SKILL.md` in full before rewriting**

Run: `cat skills/ground-my-take/SKILL.md`

- [ ] **Step 2: `git mv` the whole directory**

```bash
git mv skills/ground-my-take skills/make-evergreen-note
```

- [ ] **Step 3: Confirm the directory is now empty of reference files (moved in Tasks 8-11) before proceeding**

Run: `find skills/make-evergreen-note -type f`
Expected: only `skills/make-evergreen-note/SKILL.md` — no `references/` directory at all, since all four files already moved to `grounding/references/` in earlier tasks

- [ ] **Step 4: Rewrite `SKILL.md`'s full content**

```markdown
---
name: make-evergreen-note
description: Ground a hunch into a Take — the user's own synthesized
  position, checked against existing notes it connects, then written as an
  evergreen note.
license: MIT
metadata:
  version: "1.1.0"
---

# Make-evergreen-note

## What these words mean

- **Take** — the user's own position on an idea, requiring synthesis across
  sources or experience. Lives only in an evergreen note — never restates
  a single cited note unchanged.
- **Evergreen note** — the file a confirmed Take gets written into. Unlike
  a literature note, can be revisited: a later session may rewrite its
  content wholesale, not just add to it.

## Prerequisite

Requires `.slipbox/config.json` — same as every skill in this family. If
it's missing, stop and say so. Same check for `.slipbox/bin/slipbox` — if
it doesn't exist or isn't executable, stop and say so too. Every `slipbox`
call below uses this same path, `.slipbox/bin/slipbox` — never bare
`slipbox`, which isn't guaranteed to be on `PATH`.

## Take the material

- **Named directly** → the user names specific existing notes to connect.
- **Bare, just a hunch** → search for anything related before starting; a
  hunch with nothing to check against is still a valid, complete session —
  see `/grounding`'s own handling of "neither present."
- **From the backlog** → query the pending queue:

  ```bash
  .slipbox/bin/slipbox evergreen find --status to-discuss
  ```

  Offer these; let the user choose one. This is how a flagged tension from
  `make-literature-note` — or a spawned Compass sub-idea from a prior
  `make-evergreen-note` sitting — eventually gets picked up and turned
  into a real Take.

## Ground it

Run a `/grounding` session, holding yourself to whatever notes are in
play — the user's own answers are free here: personal experience, memory,
anything not written down anywhere. That freedom is the entire point of a
Take. What must stay grounded is *your* side of the conversation — your
questions and reflections trace to what the retrieved notes actually
establish, never to your own training or memory (same rule as always, just
aimed at yourself instead of the user this time). This is the
Fidelity-direction parameter you supply to `/grounding` when the session
starts.

Orient the take with `references/compass.md` (now living inside
`grounding`, alongside its own supporting techniques) — reach for whichever
direction the conversation calls for, no fixed order. Compass's own
directions may recurse into fresh sub-ideas; an unpursued spawned sub-idea
gets logged to the evergreen backlog the same way any other flagged tension
does (see Compass's own Guardrail).

`/grounding` hands back the confirmed Take, and — only if the user opted
in — a flagged tension. If a tension came back, insert it into the same
evergreen backlog this skill itself reads from:

```bash
.slipbox/bin/slipbox evergreen add --slug <draft-slug> --reason "<tension description>"
```

before moving on to writing.

## Purity check, before writing

Test each sentence in the draft: is it attributable to a single cited
note's claim, unchanged? If yes for any sentence, the conversation isn't
done — keep sharpening until the Take states something none of the
individual notes said on their own.

## Write

- Run a `/write-checks` session on the draft, passing the evergreen field
  list (`type`, `created`, `derived-from`, `updated-at`) — it resolves each
  field's mapping, formatting, and zone placement, and checks the draft's
  style and humanize signals. `updated-at` gets `created`'s own timestamp
  on a first write, and is refreshed to the current time on a revisit.
- Write into `paths.evergreen` from `.slipbox/config.json`, filename per
  that same config's casing convention for the evergreen type.
- Re-read the target path from disk right before writing.
- Assemble the frontmatter from `write-checks`' returned fields and write
  the file — a full rewrite of existing content on a revisit, since unlike
  a literature note this doesn't mean starting a new file.
- Cite every note it draws on, each with a one-line reason. Never link
  silently.
- Every citation also gets written as a links row:

  ```bash
  .slipbox/bin/slipbox links add --source <this-evergreen-slug> --target <cited-note-slug> --rel cites
  ```

  one call per cited note.
- Whether a citation is also rendered as an inline `[[wikilink]]` in the
  note's prose depends on a two-part test: (a) it has this links row (the
  mechanical baseline — only cited notes are ever eligible), and (b) the
  specific sentence containing the mention is actually asserting something
  about that note's subject, not just incidentally naming it while the
  sentence is really about something else.
- Filename collision on a first write → stop and ask, never
  auto-disambiguate. On a revisit, the existing file is expected — not a
  collision.

## Sign-off, shown to the user before finishing

### Concept

These five criteria draw on Matuschak's evergreen-notes practice (verbatim,
primary — `notes.andymatuschak.org`) and Ahrens' permanent-note rules
(*How to Take Smart Notes*), cross-verified independently across two
research passes:

- **Atomic** — "notes which are only about one thing—but which, as much as
  possible, capture the entirety of that thing" (Matuschak). Not a brevity
  rule: both over-broad and over-fragmented notes are failure modes, "a
  bunch of tradeoffs," not a fixed litmus test.
- **Concept-oriented** — factored by idea, never by source/author/project.
  Matuschak's own reasoning: source-factored notes on the same concept
  never accumulate into anything stronger, "just a scattered set of
  notes... perhaps referring to it by different names."
- **Titles as claims** — "declarative or imperative phrases making a
  strong claim... titles are like APIs." Difficulty titling a note is
  itself diagnostic — a sign the thinking is muddy or the note covers more
  than one thing, not a wording problem to push through.
- **Densely linked, every link labeled** — linking is "deliberate
  sense-making pressure," not filing; "prefer labeled associations" over a
  bare "X relates to Y."

**A real tension, not resolved by picking a side quietly**: Ahrens'
permanent-note rule states notes should be written "as if for someone
else — full sentences, precise, clear." Matuschak argues the opposite:
"write notes for yourself by default, disregarding audience" — writing for
a reader during note-writing itself "substantially increases the
overhead... often to the point of producing blockage."

This skill's own "standalone-comprehensible by a future version of the
user" criterion sides with Matuschak, not Ahrens — deliberately: the
audience is explicitly *future you*, not a general reader, which keeps
Ahrens' actual goal (a note that doesn't need the original context to make
sense) without adopting his audience-first framing, which Matuschak argues
creates blockage.

### Criteria

- The title is a complete claim.
- Standalone-comprehensible by a future version of the user with no memory
  of this session.
- About one thing, entirely.
- Every link has a stated reason.
- The note answers, or spawns, a "so what / what's next."

## Done

The Take note exists on disk (or is updated, if revisiting), every cited
note is linked with a reason, any flagged tension is logged as its own
backlog entry, and the user is told the file path.

If this session's material came from the evergreen backlog rather than
being freshly named or a bare hunch, close out the row it drew from:

```bash
.slipbox/bin/slipbox evergreen update <slug> --status discussed --note-path <path>
```

Rename the slug too if this was a first write — same pattern as
`make-literature-note`'s own "Write — new reference" step. Bump
`--iteration` instead if this is a revisit to an existing evergreen note
rather than a first write. The note's own `updated-at` frontmatter field
was already set in the Write section above — `created`'s timestamp on a
first write, refreshed to current time on a revisit.
```

- [ ] **Step 5: Verify the rewrite**

Run: `grep -c "^name: make-evergreen-note$" skills/make-evergreen-note/SKILL.md`
Expected: `1`

Run: `grep -c "references/compass\|references/connect\|references/challenge\|references/distil" skills/make-evergreen-note/SKILL.md`
Expected: `0` (confirms no local `references/` paths are cited — Compass is referenced by name, pointing at `grounding`'s shared copy, not a local file path)

Run: `grep -c "Concept$" skills/make-evergreen-note/SKILL.md`
Expected: `1` (the new cited Sign-off section)

Run: `grep -c "Matuschak\|Ahrens" skills/make-evergreen-note/SKILL.md`
Expected: `3` or more

- [ ] **Step 6: Commit**

```bash
git add -A skills/make-evergreen-note skills/ground-my-take
git commit -m "refactor(ground-my-take): rename to make-evergreen-note

Renames ground-my-take -> make-evergreen-note (established evergreen-note
vocabulary over private family jargon 'Take'). Orchestration unchanged -
Take the material / Ground it / Purity check / Write / Sign-off / Done all
carry forward. References its Compass technique by name now, pointing at
grounding's shared references/ rather than a local copy (moved in Tasks
8-11).

Adds a cited Concept section to Sign-off: Matuschak's five evergreen-note
principles plus Ahrens' permanent-note rules, naming the audience tension
between them explicitly and stating why 'standalone-comprehensible by a
future version of the user' deliberately sides with Matuschak."
```

---

### Task 16: Rename and rewrite `tests/ground-my-take/` → `tests/make-evergreen-note/`

**Files:**
- Modify (via `git mv`): `tests/ground-my-take/` → `tests/make-evergreen-note/`
- Modify: `tests/make-evergreen-note/evals.json`

**Interfaces:**
- Consumes: the rewrite from Task 15

- [ ] **Step 1: `git mv` the directory**

```bash
git mv tests/ground-my-take tests/make-evergreen-note
```

- [ ] **Step 2: Replace `evals.json`'s full content**

```json
{
  "test_cases": [
    {
      "prompt": "make-evergreen-note: does note A on spaced repetition connect to note B on compound interest?",
      "expected_output": "Runs a /grounding session (holding itself to the notes, not the user), orienting the take with compass.md (Connect on West, Challenge on East as needed, plain questions on North/South), running Distil once West and East both produce something. Applies the purity check before writing, writes an evergreen note citing both notes with stated reasons, and runs the sign-off (including its cited Matuschak/Ahrens Concept section) before finishing.",
      "assertions": [
        {"type": "contains", "text": "cites"}
      ]
    },
    {
      "prompt": "make-evergreen-note, just a bare hunch with nothing named yet",
      "expected_output": "Searches for related existing notes before starting; if nothing relevant turns up, treats the ungrounded hunch as a valid, complete session per grounding's own handling of 'neither present.'",
      "assertions": [
        {"type": "not_contains", "text": "cannot proceed"}
      ]
    },
    {
      "prompt": "make-evergreen-note, revisiting an evergreen note written three months ago",
      "expected_output": "Reads the existing note fresh from disk, and the resulting rewrite can replace its existing content wholesale rather than only appending.",
      "assertions": [
        {"type": "not_contains", "text": "append"}
      ]
    },
    {
      "prompt": "make-evergreen-note, and a Compass direction spawns a genuinely new sub-idea partway through that doesn't get pursued in this sitting",
      "expected_output": "Logs the unpursued sub-idea to the evergreen backlog (slipbox evergreen add) rather than losing it or forcing it into the current session's Take.",
      "assertions": [
        {"type": "not_contains", "text": "cannot proceed"}
      ]
    }
  ]
}
```

- [ ] **Step 3: Verify**

Run: `python3 -m json.tool tests/make-evergreen-note/evals.json > /dev/null && echo VALID`
Expected: `VALID`

- [ ] **Step 4: Commit**

```bash
git add -A tests/make-evergreen-note tests/ground-my-take
git commit -m "test(make-evergreen-note): rename tests dir, add Compass-recursion case"
```

---

### Task 17: Update `CONTEXT.md` cross-references

**Files:**
- Modify: `CONTEXT.md`

**Interfaces:**
- Consumes: the renames from Tasks 13 and 15

- [ ] **Step 1: Confirm every place the old names appear**

Run: `grep -n "ground-the-claim\|ground-my-take" CONTEXT.md`

Expected output (verify against the actual file before editing — do not blind-replace without seeing each line, since some occurrences sit inside prose sentences that need to stay grammatically correct after the swap):

```
Literature note (bibliographic note, `ground-the-claim`'s output — internally discussed via `grounding`, source-bound fidelity):
Evergreen note (Zettel / permanent note, `ground-my-take`'s output — internally discussed via `grounding`, notes-bound fidelity):
- `ground-the-claim` and `ground-my-take` both internally invoke the same skill, **`grounding`** ...
- ... routes through `ground-the-claim` first, always — grounding stays at the claim level with no special case for this skill.
```

- [ ] **Step 2: Replace each occurrence**

Run:
```bash
sed -i '' 's/`ground-the-claim`/`make-literature-note`/g; s/`ground-my-take`/`make-evergreen-note`/g' CONTEXT.md
```

- [ ] **Step 3: Verify no old names remain and the new names are present**

Run: `grep -c "ground-the-claim\|ground-my-take" CONTEXT.md`
Expected: `0`

Run: `grep -c "make-literature-note\|make-evergreen-note" CONTEXT.md`
Expected: `4` or more

- [ ] **Step 4: Read the file back to confirm grammatical correctness at each edited spot**

Run: `grep -n "make-literature-note\|make-evergreen-note" CONTEXT.md`

Expected: each line reads correctly in context (e.g., "internally discussed via `grounding`" still follows naturally) — if any line reads awkwardly after the mechanical substitution, fix it by hand now before committing.

- [ ] **Step 5: Commit**

```bash
git add CONTEXT.md
git commit -m "docs(CONTEXT): update cross-references for the two wrapper renames"
```

---

### Task 18: Update `AGENTS.md` structure diagram

**Files:**
- Modify: `AGENTS.md`

**Interfaces:**
- Consumes: the renames from Tasks 13 and 15, the ten-file `references/` set from Tasks 2-11

- [ ] **Step 1: Confirm the current structure-diagram lines**

Run: `grep -n "ground-the-claim\|ground-my-take" AGENTS.md`

Expected:
```
│   ├── grounding/            ← lean interview engine; user-invocable, like grilling
│   ├── ground-me/             ← bare passthrough wrapper, no note-writing
│   ├── ground-the-claim/          ← literature-note wrapper (was write-literature-note)
│   ├── write-reference/       ← Reference-note synthesis wrapper (was ground-term,
│   │                              was write-reference-note); never runs /grounding
│   └── ground-my-take/        ← evergreen-note wrapper (was write-evergreen-note)
```

- [ ] **Step 2: Replace the structure-diagram block**

Find the block above in `AGENTS.md` and replace it with:

```
│   ├── grounding/            ← interview engine, ten named techniques in
│   │                            references/; user-invocable, like grilling
│   ├── ground-me/             ← bare passthrough wrapper, no note-writing
│   ├── make-literature-note/  ← literature-note wrapper (was ground-the-claim,
│   │                              was write-literature-note)
│   ├── write-reference/       ← Reference-note synthesis wrapper (was ground-term,
│   │                              was write-reference-note); never runs /grounding
│   └── make-evergreen-note/   ← evergreen-note wrapper (was ground-my-take,
│                                  was write-evergreen-note)
```

- [ ] **Step 3: Also update the "Cross-skill references" prose paragraph**, which names the wrappers by their old names

Run: `grep -n "ground-the-claim\|ground-my-take" AGENTS.md`

Find the line: `Every other skill (`find-connections`, `ground-the-claim`, `write-reference`, `ground-my-take`, `clip-resource`, `setup-slipbox`) is referenced bare, backtick-only...`

Replace with: `Every other skill (`find-connections`, `make-literature-note`, `write-reference`, `make-evergreen-note`, `clip-resource`, `setup-slipbox`) is referenced bare, backtick-only...`

- [ ] **Step 4: Verify no old names remain**

Run: `grep -c "ground-the-claim\|ground-my-take" AGENTS.md`
Expected: `0`

- [ ] **Step 5: Commit**

```bash
git add AGENTS.md
git commit -m "docs(AGENTS): update structure diagram and cross-skill-reference prose for the two wrapper renames"
```

---

### Task 19: Rename and rewrite the three affected `docs/` pages

**Files:**
- Modify: `docs/grounding.md`
- Modify (via `git mv`): `docs/ground-the-claim.md` → `docs/make-literature-note.md`
- Modify (via `git mv`): `docs/ground-my-take.md` → `docs/make-evergreen-note.md`
- Untouched: `docs/ground-me.md` (no changes to `ground-me` this whole plan)

**Interfaces:**
- Consumes: the mechanism/rename from Tasks 1, 13, 15

- [ ] **Step 1: Read the three current doc pages**

Run: `cat docs/grounding.md docs/ground-the-claim.md docs/ground-my-take.md`

- [ ] **Step 2: Rewrite `docs/grounding.md`'s full content**

```markdown
# grounding

A relentless one-question-at-a-time interview that holds a statement to whatever
material is present — a source, retrieved notes, or nothing at all — until you've
explicitly confirmed it.

## When to use

You won't usually invoke this directly. `ground-me`, `make-literature-note`, and
`make-evergreen-note` each call `/grounding` internally, framing the session with
whatever material they've already gathered. Invoke it directly only if you want the
raw interview loop without any of those wrappers' note-writing.

## How it works

1. **Fidelity** — whichever material is present decides who gets held to it: a source
   present means the user is held to it; retrieved notes present means the agent is
   held to them; neither present means an ungrounded hunch is accepted as a valid,
   complete outcome. A caller can frame which direction to hold before a session starts.
2. **Never your own opinion** — the agent never introduces its own training or memory
   as if it belonged to the material, even when it privately disagrees with a source.
3. **Reading the answer** — every session opens with a plain restatement request, and
   what comes back gets read as confident, hesitant, blank, or confused. A blank answer
   only ever gets a reactive offer (walk through it together, or try explaining first)
   after a first attempt has genuinely failed — never a stated reading-state question
   upfront.
4. **Choosing a technique** — the answer's reading picks the technique: confident routes
   to a source-anchored verification check (escalating to a fuller elenchus pass only on
   a real mismatch), hesitant routes to a Feynman-style explain-and-patch loop, a blank
   answer with a source routes to a passage-by-passage discovery walk, a blank answer
   with no source routes to a maieutic drawing-out session, and a confused answer routes
   to surfacing the specific discrepancy and letting the user reconcile it. Ten named
   techniques live in `references/`, including four (Compass and its Connect/Challenge/
   Distil supporting techniques) reached when a caller orients a session toward
   synthesizing a position rather than probing a single source.
5. **Gate** — the statement only fixes on an explicit, unambiguous confirmation, and
   getting there is hardened two ways: a finished draft is never shown until at least one
   open probe-and-answer round has produced real content, and the confirmation question
   itself always stays open ("what's missing or wrong?") rather than inviting a binary
   yes/no rubber-stamp.
6. **Noticing a tension** — if something in real tension with the material comes up
   mid-session, it's never acted on or leaked into the statement. Once the gate passes,
   the agent asks once whether to flag it for later.

A session opens with one plain line naming the source or topic, then stays silent about
being "in a grounding session" for the rest of the exchange — no repeated marker on
every question.

## Usage

> Let's ground this: [whatever you're working through]

## Installation

```bash
npx skills add andarwaly/slipbox
```

See the [skill source](../../skills/slipbox/grounding/) for the full agent-facing
instructions.
```

- [ ] **Step 3: `git mv` and rewrite `docs/make-literature-note.md`**

```bash
git mv docs/ground-the-claim.md docs/make-literature-note.md
```

Replace its full content:

```markdown
# make-literature-note

Ground a clipped source into one or more Claims — the source's own position, restated in
your own words and checked against the source — writing each as a Key Claim in a shared
literature note for that source.

## When to use

Run this directly on a clipped source: `/make-literature-note from this article` (or a
URL, or a path). Invoked bare with no argument, it infers the source from context — a
just-clipped resource, a pasted URL, an already-open file — and only asks if nothing's
inferrable.

If the note already has claims from a prior session, it only offers what's left.

## How it works

1. **Take the source** — direct capture, checked against existing literature notes'
   `source` field to see if this source has already been (partially) grounded.
2. **Surface pass** — reads the source, using Question/Evidence/Warrant internally to
   identify the Core Idea and a candidate backlog. This backlog is never shown as a
   menu — it's the agent's own private steering tool for the conversation that follows.
3. **One continuous conversation** — rather than looping a separate session per claim,
   you have one natural conversation about the source. Whenever it organically produces
   something matching a backlog candidate — in whatever reshaped form — it goes through
   a full `/grounding` Gate exactly as always.
4. **Write each claim, incrementally** — each confirmed claim lands on disk as a
   declarative heading with condensed Evidence underneath, the moment it's confirmed.
5. **Nudge once, then defer** — once the conversation winds down, anything genuinely
   untouched in the backlog gets one offer to pursue; "I think that's everything" always
   ends the sitting regardless.
6. **Spot terms and entities** — once the sitting ends, one batch pass finds terms and
   load-bearing named entities the claims lean on but `## Key Concepts` doesn't cover yet.

## Usage

> /make-literature-note from [source]

## Installation

```bash
npx skills add andarwaly/slipbox
```

See the [skill source](../../skills/slipbox/make-literature-note/) for the full
agent-facing instructions.
```

- [ ] **Step 4: `git mv` and rewrite `docs/make-evergreen-note.md`**

```bash
git mv docs/ground-my-take.md docs/make-evergreen-note.md
```

Replace its full content:

```markdown
# make-evergreen-note

Ground a hunch into a Take — your own synthesized position, checked against existing
notes it connects — then write it as an evergreen note.

## When to use

Bring specific existing notes you want connected, or just a hunch with nothing named
yet — this skill searches for anything related before starting either way. Unlike a
Claim, a Take can be revisited: a later session may rewrite the note's content wholesale
rather than only appending to it.

## How it works

1. **Take the material** — named notes, a bare hunch to search around, or a pull from
   the evergreen backlog.
2. **Ground it** — a `/grounding` session where your own answers are free (personal
   experience, memory, anything unwritten), but your own questions and reflections must
   trace to what the retrieved notes actually establish, never to your own training.
   Orients with Compass (now living inside `grounding`, alongside its own Connect/
   Challenge/Distil supporting techniques) — reaches for whichever direction the
   conversation calls for. A Compass direction can spawn a fresh sub-idea; anything not
   pursued this sitting gets logged to the evergreen backlog for later.
3. **Purity check** — before writing, every sentence in the draft is tested: does it
   just restate one cited note's claim unchanged? If so, the conversation isn't done.
4. **Write** — cites every note it draws on with a one-line reason; never links
   silently. Can be a full rewrite if revisiting an existing evergreen note.
5. **Sign-off** — checked against five criteria (complete-claim title,
   standalone-comprehensible, about one thing, every link has a reason, answers or
   spawns a "so what"), each grounded in Matuschak's evergreen-note practice and
   Ahrens' permanent-note rules, before the session finishes.

## Usage

> Let's think through how [note A] connects to [note B] — or just: make-evergreen-note

## Installation

```bash
npx skills add andarwaly/slipbox
```

See the [skill source](../../skills/slipbox/make-evergreen-note/) for the full
agent-facing instructions.
```

- [ ] **Step 5: Verify**

Run: `grep -c "ground-the-claim\|ground-my-take" docs/grounding.md docs/make-literature-note.md docs/make-evergreen-note.md`
Expected: `0` across all three files

Run: `test -f docs/ground-the-claim.md && echo STILL_THERE || echo MOVED`
Expected: `MOVED`

Run: `test -f docs/ground-my-take.md && echo STILL_THERE || echo MOVED`
Expected: `MOVED`

- [ ] **Step 6: Commit**

```bash
git add -A docs/grounding.md docs/make-literature-note.md docs/make-evergreen-note.md docs/ground-the-claim.md docs/ground-my-take.md
git commit -m "docs: update grounding.md, rename+rewrite the two wrapper doc pages"
```

---

### Task 20: Final cross-reference sweep

**Files:**
- Modify: any file the sweep below finds that earlier tasks missed

**Interfaces:**
- Consumes: every prior task in this plan — this is the final verification pass

- [ ] **Step 1: Search the whole repo for any remaining old names**

Run: `grep -rn "ground-the-claim\|ground-my-take" --include="*.md" --include="*.json" . | grep -v "^\./\.git/"`

Expected: no hits inside `skills/`, `docs/`, `tests/`, `CONTEXT.md`, `AGENTS.md`. Hits are acceptable only inside `.superpowers/sdd/` (historical review artifacts from an unrelated past refactor, out of scope for this plan) — verify any hit's path before deciding whether it's in scope.

- [ ] **Step 2: If any in-scope hit remains, fix it now**

For each in-scope file the search surfaces, open it, read the surrounding context, and apply the same rename used in Tasks 13/15/17/18/19 — do not blind sed a file not already covered by an earlier task without reading it first.

- [ ] **Step 3: Confirm the full `grounding/references/` set is exactly ten files**

Run: `ls skills/grounding/references/ | sort`

Expected:
```
challenge.md
compass.md
connect.md
discovery-walk.md
distil.md
elenchus.md
feynman.md
maieutic.md
self-explanation.md
verification.md
```

- [ ] **Step 4: Confirm `ground-me` was never touched by this plan**

Run: `git log --oneline --all -- skills/ground-me/ docs/ground-me.md tests/ground-me/`

Expected: no commits from this plan's work appear (only pre-existing history, if any) — `ground-me` was explicitly confirmed kept as-is throughout the discussion.

- [ ] **Step 5: Confirm `qec-theory.md` and `writing-a-claim.md` content is byte-identical to what it was before the rename**

Run: `git diff --stat HEAD~19 -- skills/make-literature-note/references/qec-theory.md skills/make-literature-note/references/writing-a-claim.md`
(adjust the commit range to match how many commits back Task 13 actually landed, if it differs from 19)

Expected: empty output, or a rename-only diff with `0` insertions/deletions — these two files were moved, never edited.

- [ ] **Step 6: Commit any final fixes found in Step 2**

```bash
git add -A
git commit -m "chore: final cross-reference sweep for the grounding-family redesign"
```

If Step 2 found nothing to fix, skip this commit — there's nothing to add.

---

## Self-Review

**Spec coverage** — every item from the original scope maps to a task:
0. Promote the scratchpad into a resolved discussion-topic per `discussion/AGENTS.md`'s own framework → Task 0 (runs in `skill-kojo`, not `the-factory/slipbox`).
1. `grounding/SKILL.md` rewrite → Task 1. Ten `references/` files → Tasks 2-11.
2. `ground-the-claim` → `make-literature-note` rename + backlog redesign → Task 13. Tests → Task 14.
3. `ground-my-take` → `make-evergreen-note` rename + Sign-off Concept section → Task 15. Tests → Task 16.
4. `ground-me` untouched → verified explicitly in Task 20, Step 4.
5. Recognizable-vocabulary directive → applied throughout every rewritten file's prose (Tasks 1-11, 13, 15, 19); config identifiers (`type: literature`, `derived-from`, `slipbox evergreen add`) deliberately left untouched everywhere they appear.
6. `evals.json` updates → Tasks 12, 14, 16.
7. Cross-references (`CONTEXT.md`, `AGENTS.md`, `docs/`) → Tasks 17, 18, 19, swept in Task 20.

**Placeholder scan** — every code/content step above contains complete, final markdown or JSON content, not a description of what to write. No "TBD," no "similar to Task N," no bare descriptions standing in for actual file contents.

**Type/interface consistency** — the five-row dispatch table in Task 1 names exactly the five files created in Tasks 2, 4, 5, 6, 7 plus the escalation-only file in Task 3; every reference file's cross-reference to a sibling file (e.g., `feynman.md` → `self-explanation.md`, `discovery-walk.md` → `feynman.md` + `maieutic.md`, `compass.md` → `connect.md`/`challenge.md`/`distil.md`) names a file this same plan actually creates, with matching filenames throughout.

---

**Plan complete, saved to `docs/superpowers/plans/2026-08-17-grounding-family-redesign.md`.**

**Execution: subagent-driven**, per His Grace's own model split — mechanical tasks (moves, cross-reference sweeps, evals.json rewrites, structural verification) on `claude-haiku-4-5-20251001`, content-writing tasks (`SKILL.md`/`references/` prose) on `claude-sonnet-5`, a final full-plan review on `claude-opus-5` once every task lands.

**Model assignment per task:**
- **Haiku** — Task 0 (Steps 1/3/4/5 — mechanical index/commit work; Step 2's topic-file prose is already fully drafted above, so writing it is copy, not composition), Tasks 12/14/16 (`evals.json` rewrites — content is fully drafted above), Tasks 17/18 (cross-reference substitution), Task 20 (final sweep).
- **Sonnet** — Tasks 1-11 (`grounding/SKILL.md` + all ten `references/` files), Tasks 13/15 (the two wrapper `SKILL.md` rewrites), Task 19 (the three `docs/` pages) — every task where prose needs real judgment even though the content is fully drafted in this plan, since verifying the draft still fits its target file correctly is itself a judgment call.
- **Opus** — one final review pass after Task 20 lands: re-read every touched file against this plan's Global Constraints and the Self-Review checklist above, flag any drift.
