---
name: make-literature-note
description: Ground a clipped source into one or more Source Points — the source's
  own position, restated in the user's own words and checked against the
  source — writing each as a Source Point in a shared literature note for that
  source.
license: MIT
metadata:
  version: "1.20.0"
---

# Make-literature-note

Bold terms in this file are defined in `GLOSSARY.md`.

## Prerequisite

- MUST: `.slipbox/AGENTS.md` exists — confirms `setup-slipbox` ran to completion.
- NEVER: proceed without it. Stop and tell the user to run `setup-slipbox` first.
- NEVER: call bare `slipbox` — always `.slipbox/bin/slipbox`, which isn't guaranteed to be on `PATH`.

## Invocation

Start or resume work for the Literature Resource with its source identity, inquiry
context, and known paths `/using-slipbox`.

The caller may identify the Resource explicitly — `/make-literature-note from this
article` (or a URL or path) — or leave it implicit when a just-clipped Resource, pasted
URL, or open file makes the source unambiguous. Ask only when nothing is inferrable.
Pass the source identity, inquiry context, and known paths in that action before
reading or writing. A returning invocation resumes the matching unfinished work item;
it does not start a second interview.

## Take the source

Check whether a literature note for this source already exists: use
`.slipbox/bin/slipbox config get paths.literature` to locate the folder and scan `*.md`
under it — never assume a folder literally named `literature/` — for a note
whose resolved `source` field (per `.slipbox/bin/slipbox config get frontmatter.literature.source.name`)
points at this resource.

- **No note exists yet** — this source hasn't been grounded at all. Proceed
  to build the source and inquiry maps with a fresh session assessment.
- **A note already exists** — read it in full. Its existing `## Source
  Points` `###` headings are Source Points already confirmed; the backlog below
  must not re-offer them.
- Before reading or staging any existing note, inspect
  `.slipbox/config.json` at `migrations.literature_headings`; an absent policy
  is treated as `defer` and never authorizes a rewrite. When its mode is
  `lazy`, and this note has the exact compatible `## Key Claims` heading, make
  first access itself a migration: copy the note into the current
  `/using-slipbox` staged draft, rename only that exact heading to `## Source
  Points`, validate the staged artifact, and publish it with compare-and-swap
  against the fingerprint read at access. Do not edit the note in place, and do
  not scan or rewrite unrelated notes. A changed fingerprint stops recovery;
  report the conflict and leave the legacy note unchanged. After successful CAS,
  continue Literature work from the migrated note.

## Build the source and inquiry maps

Inspect source analysis for the Resource `/using-slipbox`. Load a compatible source map;
otherwise build one from the whole frozen Resource using `references/source-architecture.md`
and `references/qew-theory.md`, then store it as source-owned analysis. For an existing
vault with no cache, source-first construction is mandatory: read the complete Resource
before consulting the Literature note. Never reconstruct a source map from selective
Literature content. Reconcile the existing note's Core Idea, points/legacy claims,
concepts, referents, and Open Questions to source units with private statuses
`matched|matched-with-qualification-risk|matched-to-multiple-units|unmatched|source-support-unclear`.
Missing or unresolved Resources block reconciliation and require repair; reconciliation
never rewrites note semantics automatically. The cache contains source units, posture,
relations, and Core Idea candidates; it never contains the user's
inquiry, reading state, transcript, or a prescriptive queue.

Create a separate session-scoped inquiry map referencing source-unit IDs. Record purpose,
implied purpose, reflection, relevance, learning relevance, interpretive risk, comprehension,
selection, disposition, and draft state. If purpose is absent, ask one natural purpose
question; if the user is exploring, use that as context rather than forcing a fixed goal.
Reassess the map as the conversation changes. Derive the grounding frontier at runtime;
never persist it as an authoritative backlog. On recovery, compare Resource and note
fingerprints through the same work item, reuse prior comprehension evidence and staged points,
and resume at the next unresolved thinking obligation rather than repeating settled questions.

The source-architecture and Q/E/W reasoning below remain internal. Before
or alongside claim discovery, read the source's architecture per
`references/source-architecture.md` — its six optional lenses (Situation &
Starting Point, Problem/Tension, Argument Movement, Support & Boundaries,
Fidelity Signals, Resolution) feed Core Idea formation specifically. A
Core Idea synthesized purely from a bag of already-discovered claims risks
missing the source's own throughline; reading the source's own motivation,
tension, and build-up first is what keeps the Core Idea from just
echoing whichever claim got discovered first. Using
Question/Evidence/Warrant as your own internal reasoning tool (see
`references/qew-theory.md`) — never shown to the user in this form —
identify every distinct claim the source actually supports and the
source's Core Idea, skipping anything an existing literature note (per
Take the source above) already covers. Include the source's own
setup/motivation claims — why it argues what it argues, what it's reacting
to or building on — not just its main framework's mechanics; a source's
justification for its central idea is as load-bearing as the idea itself.
Apply the shared-Warrant merge test
now, before proceeding: two candidates resting on the same inferential move
are one claim, not two.

These source-map candidates measure coverage, not required output — a literature
note may legitimately stay partial (see Knowing when the session is done,
below). It is **your own private backlog, not a menu presented to
the user** — never surfaced as a checklist, never asked "which of these do
you want grounded." It exists only to steer where the conversation still
needs to go and to check coverage once the session winds down. It is
session-scoped only — discard the inquiry assessment at session end; the grounding
frontier is always derived again from current evidence, never persisted as a queue.

## Follow the inquiry — one substantive question at a time

Follow the derived grounding frontier in one continuous conversation. Do not present the
candidate list or ask which point to ground. Apply `references/adaptive-split-gate.md`:
inquiry-central routine units require the user's semantic relation before drafting;
inquiry-central consequential or ambiguous units require reconstruction, ambiguity
discussion, and source verification; supporting/contextual units may be agent-drafted and
verified; supporting/contextual consequential units are source-verified without forced
paraphrase. Ask exactly one substantive question at a time.

For any `/grounding` turn, dispatch Confident to verification and Hesitant to Feynman.
For Blank or not-started reading with a source, first offer the user a choice between
reading alone and working through it collaboratively; dispatch guided reading only when
the user chooses collaboration. If the user chooses to read alone, pause and let them
return. Without a source, Blank uses maieutic. Confused uses self-explanation.
Primary/secondary posture comes from the material and attribution, independently of the
Resource `type`; preserve news allegations as attributed reports with their uncertainty.

When an inquiry-central unit is reconstructed, use `/grounding` for that semantic relation
and its confirmation. Supporting/contextual points do not receive a full Gate by default;
they receive source verification and a final source audit.

If a tension comes back from a Gate pass, insert it into the evergreen
backlog before continuing:

Record an Evergreen candidate with the proposition, reason, and origin paths
`/using-slipbox`.

When the user notices a genuine gap in the source itself — something the
source leaves unclear, ambiguous, or unanswered — offer to record it as an
`## Open Questions` entry. Never invent one unprompted; this only fires on
the user's own noticing. If the user wants a guess at an answer recorded
too, append it as a nested `*Assumption*` bullet, clearly marked as the
user's own guess — the one narrow exception to the note's purity rule,
scoped to this one bullet type under this one section only. Never write an
unmarked personal guess, and never let it read as a Source Point. If the user
names another literature note that already resolves the question, append a
nested `*Answered*` bullet as a wikilink to that Source Point's own heading
(`[[Other Literature Note#the-source-point-that-answers-it]]`) — user-initiated
only, never detected automatically; this family runs no cross-note scan for
outstanding questions. An existing `*Assumption*` bullet stays in place
once `*Answered*` is added alongside it. See
`references/writing-a-source-point.md`'s Open Questions section for the full
format.

## Stage each Source Point

As soon as one Source Point is semantically settled — before continuing toward the next
unresolved inquiry obligation:

- Run a `/write-checks` session with `artifact-kind: note` and `note-type: literature`, passing the literature field
  list (`type`, `created`, `source`) — it resolves each field's mapping,
  formatting, zone placement, and title prefix, and checks the draft's
  style and humanize signals.
- Assemble and review the Source Point per `references/writing-a-source-point.md`. Preserve
  local posture, scope, attribution, and certainty: a news allegation remains an attributed
  report, never the source's own claim.
- Checkpoint work with the inquiry map and complete staged `draft.md` `/using-slipbox`. Run
  `/write-checks` against the staged artifact and repair only mechanical defects. Never
  mutate the final literature path mid-session; publish once at closeout through
  Publish an artifact `/using-slipbox`.
- Derive the intended target in the folder from `.slipbox/bin/slipbox config get paths.literature`, filename per
  `.slipbox/bin/slipbox config get filenames.literature` casing convention. The Literature H1
  preserves the Resource's source title exactly and is always clean/unprefixed; it is never
  replaced with an agent-authored topic label. Links use the exact configured prefix with a
  clean display alias. Construct the complete basename through `.slipbox/bin/slipbox filename format
  --type literature --title "<exact source title>"`, passing each confidently identified
  proper-name span as `--preserve`. The command applies protected names, configured casing,
  filename sanitization, then the configured prefix, and returns the complete basename. If
  protected-name identification is uncertain, show the proposed basename and ask the user
  before writing. On this note's first
  claim, write the Core Idea line too, directly under the title (see
  `references/writing-a-source-point.md`); skip it on a second or later Source Point,
  it's already there.
- Re-read the staged draft and inquiry map right before each checkpoint; do not read or
  overwrite the final target as a session scratchpad.
- Assemble the complete staged draft, then run `/write-checks` artifact validation against
  the explicit `<staged-draft>` path with the complete basename and exact Resource title.
  Repair only mechanical defects; stop and ask for semantic conflicts, collisions, uncertain
  titles, or uncertain protected names.
- Re-read staged state before each checkpoint. A failed post-write check blocks the next
  frontier item and success acknowledgment. The final path is written only by the publish
  action at closeout. A failed staged check blocks the next frontier item and success
  acknowledgment. After publication, run the post-publication check against
  `.slipbox/bin/slipbox note validate --type literature --path <saved-path>
  --basename "<complete basename>.md" --title "<exact Resource title>"`.
- Filename collision on the note's first claim → stop and ask, never
  auto-disambiguate. On a second or later claim for an existing note, the
  existing file is expected, not a collision.
- Once staged, tell the user in one short line that this claim is retained —
  "that's your second claim confirmed" or equivalent — then move to the
  next question, if there is one, on its own line rather than fused into
  the same sentence (same split as `/grounding`'s SKILL.md
  acknowledgment-before-question rule). Not a running counter or a formal
  progress marker, just a natural acknowledgment tied to a real event (a
  claim actually being written), so the user has some sense of where the
  session stands without every turn being labeled.

An `## Open Questions` entry (and any nested `*Assumption*`/`*Answered*`
bullet) is staged with Checkpoint work `/using-slipbox` as soon as it's flagged. It is not
published mid-session; unlike most other sections it can still be appended to
later in a subsequent session.

## Knowing when the session is done

Once the conversation's natural energy winds down, `Done` is a fixed closeout
gate. Run every stage below in order; never declare completion between stages.
Every final Source Point receives a source audit before it is retained. A
user-declined finding that is required for the user's inquiry, the Core Idea, or
non-distortion makes the note deliberately partial. A declined optional
discovery is clean. In either case, discard the inquiry map unless the user
explicitly asks to retain it.

### Checking coverage — the backlog, then the source itself

Check the derived frontier against what actually got covered (in whatever
reshaped form). Each candidate sits in one of three states, and the two
non-covered states get different treatment:

- **Covered** — reached Gate, confirmed, and written. Nothing to do.
- **Drafted but unconfirmed** — raised in the conversation, worded or
  half-worded, sometimes explicitly parked for later, but never taken
  through Gate and never written. This is not the same as untouched, and
  must not be nudged as though it were.
- **Untouched** — never came up at all.

Track the drafted-but-unconfirmed state as the conversation runs, not
retroactively at the close: the moment a candidate gets a draft wording
or a "let's come back to it," it leaves Untouched. Never resolve one by
assuming it got folded into another claim — a Claim exists only if it
passed Gate and was written.

A drafted-but-unconfirmed item gets named specifically, not swept into a
generic closing question:

> "you drafted the clinical light-therapy point earlier and we parked
> it — want to finish that one before we wrap?"

Anything genuinely untouched gets one nudge, never more: "you haven't
mentioned [X] — is that not something the source argues, or should we
leave it for now?"

The user's own "I think that's everything" always ends the session
regardless of what the backlog still shows uncovered — for both non-covered
states: Drafted but unconfirmed and Untouched.
The nudge is a single offer, never an insistence.

Then run a focused integrity sweep over the staged source map and draft. Check
each retained point for source fidelity, attribution, certainty, scope,
chronology, causality, reported-versus-verified status, speaker,
analysis-versus-observation, dispute, and unresolved ambiguity. This targeted
audit catches distortion and qualification drift without treating every
uncaptured proposition as a failure. Use source-unit coverage and integrity
flags to guide any next question; do not run an exhaustive universal
source-to-note audit.

> "Re-reading the source, these look like things it argues that we never
> captured: [list, each with a one-line note on what the source says].
> Want to ground all of them, some, or none?"

Whatever the user picks is routed through the Adaptive Split Gate, not a blanket
per-point Gate. This is one bounded optional discovery batch: the user may choose
all, some, or none. Declining an optional finding is clean; only declining a
finding needed for the inquiry, Core Idea, or non-distortion is reported as
partial. Zero findings is clean. After a material change, re-audit the affected
Source Points before the next stage.

### Checking the shape — density, then the Core Idea

With the Source Point set now final, read the note's `## Source Points` as a whole
and apply the shared-Warrant merge test from `references/qew-theory.md`
once more, this time across confirmed claims rather than Surface-pass
candidates: two claims resting on the same inferential move are one claim
wearing two Questions. Claims split across a source's own list items are
the common case — four bullets from one list usually share one Warrant.

A note landing around six to eight claims is a useful reference point for
this one pass's judgment, nothing more — not a hard gate, not a target to
pad toward, and never a mid-conversation interrupt. A dense source can
honestly support more; a short one can honestly support two. The number
only prompts a harder look at overlap when the count runs well past it.
Where the merge test does fire, offer the merge; if accepted, re-audit the
affected point and checkpoint work with the revised draft `/using-slipbox`.

Then confirm the Core Idea. It was written on the note's first claim,
before most of the conversation existed, so it's the one line on the page
that has never been checked against the session as a whole. Confirming it
is a Gate pass, and Gate's precondition holds: the user has to have said
the thing before you can confirm it. So ask one genuine open question
first, and wait for a real answer:

> "having been through all of it — what do you think is the main idea
> this source is arguing?"

Read the answer as `/grounding` reads any answer. Only a Confident answer
proceeds straight to confirmation; Hesitant and Confused use their named
techniques. Blank or not-started reading first offers reading alone versus
collaboration, dispatching guided reading only for collaboration. There is no shortcut here
because the Core Idea is already on the page.

The final confirmation is open, never binary — the same shape a Claim's
Gate takes. Not "is this still the Core Idea?" but:

> "the note currently opens with [current Core Idea line] — how would you
> put it now?"

If what comes back differs, rewrite the Core Idea line. If it matches,
leave it as it stands.

### Final concepts and mentioned batch

Both sections accumulate during claim writes. After claims, density, and Core
Idea stabilize, re-read the source and note once in a mandatory batch. Surface
load-bearing candidates together, with a guessed section, and obtain the user's
confirmation before appending. The candidate set is the union of support needed
by retained points, concepts/referents relevant to the source-present inquiry,
and explicit user additions. Do not scan unrelated source-map candidates.
`Key Concepts` holds abstract concepts, methods, and frameworks. `Mentioned`
holds concrete named referents: people, places, organizations, books/creative
works, named tools, and events. Downstream
`find-connections --references` classification first checks people, places, and
organizations as surfacing-only entities; non-entities then take the Admission
sequence and may become Reference candidates.

### Closing with the user's own reaction

Last, once the note itself is settled, ask what the user actually thinks only
when the session is interpretive or reflective:

> "what do you think of this article?"

Skip this for a factual session, and also when a real opinion already surfaced
during a `/grounding` session and got routed there — `/grounding`'s persistent-opinion case, where a
restated opinion is already offered to the evergreen backlog. Asking
again after that just re-collects something already handled.

The answer never touches the literature note, in any form — not as a
Claim, not as Evidence, not as an `## Open Questions` entry. A literature
note holds the source's position only. The answer's one possible
destination is the evergreen backlog, as a seed for a future Take.

Offer before logging anything, never auto-save — the same shape as the
persistent-opinion offer:

> "want to capture that as its own idea for the evergreen backlog, or set
> it aside for now?"

Only on a yes, record an Evergreen candidate with the proposition, reason, and origin
paths `/using-slipbox`.

A shrug, a "nothing really," or a decline is a complete, valid end to the
session.

When an Evergreen handoff is warranted and approved, keep it reader-owned and
preserve provenance:

> Record an Evergreen candidate with the proposition, reason, and origin paths
> `/using-slipbox`.

The proposition and reason remain the user's own words; include the source and
literature-note paths as origin paths. There is no mandatory reaction prompt.

## Out-of-band fidelity correction

The third and last exemption to the note's frozen-once-written rule fires
outside any of the flows above, on no fixed schedule — whenever the user,
during this session or a later one, notices that an already-written Source
Point entry misreads, mistranscribes, or misrepresents the source. Like
the other two exemptions, it never fires on the agent's own initiative:
the agent doesn't re-audit written claims against the source looking for
drift, it only acts once the user points at a specific inaccuracy.

The fix this exemption allows is narrow: it exists to move the note
closer to the source, nothing else. Correcting a misquote, a swapped
name, or a claim that quietly drifted from what the source actually said
is in scope; sharpening a claim's phrasing for its own sake, folding in a
nuance the source didn't prompt, or any other new synthesis is not — that
belongs to a new claim through the ordinary Gate-then-write path, not
this one. If what the user is asking for reads as more than a fidelity
fix, say so and route it there instead of stretching this exemption to
cover it.

Once the user has named the inaccuracy and what the corrected wording should say, stage the
correction in the draft and inquiry map with Checkpoint work `/using-slipbox`. Run the corrected wording
through `/grounding`'s Gate, then validate the staged artifact and publish with a
compare-and-swap (CAS) with Publish an artifact `/using-slipbox`, providing the expected final-file
fingerprint. If the CAS detects a concurrent change, stop and recover rather than overwrite.
This is the one case where a published entry may be reopened, and it still never writes the
final path directly.

## Final validation handoff

Run `/write-checks` with `artifact-kind: note` and `note-type: literature` against the complete
staged artifact at `<staged-draft>` after the final batch. Check
required fields, section order, claim headings, Core Idea placement, and both
surfacing sections on the staged artifact. Publish an artifact `/using-slipbox`, then run the
post-publication check on
`.slipbox/bin/slipbox note validate --type literature --path <saved-path>
--basename "<complete basename>.md" --title "<exact Resource title>"`. Validation
is a handoff, not permission to silently rewrite a claim; any material claim
change re-audits the affected points before publication `/using-slipbox`.

### Compact closeout

After publication, give a compact structural closeout rather than reproducing
the full note: show the Core Idea, every retained `### Source Point` heading,
any `## Open Questions`, unresolved discussed items (including
Drafted-but-unconfirmed items), and the saved path. Show the full note only on
request or when the user asks for structural review. This is a handoff, not a
second audit or another discovery batch.

## Done

`Done` fires only after this checklist is true: every final Source Point has
passed source audit (or the user explicitly declined a required finding and the
note is reported partial); density merge was offered and, if accepted, re-audited; final Core
Idea is confirmed; final Key Concepts/Mentioned batch is complete; reaction
and optional Evergreen routing are complete when applicable; artifact validation passes and
the staged draft is published transactionally. The note includes any user-flagged
Open Questions and nested bullets, and flagged tensions are logged in the
evergreen backlog. Then tell the user the file path and partial status when
applicable.

## References

| File | Purpose | Triggering condition |
|---|---|---|
| `references/qew-theory.md` | Question/Evidence/Warrant/Conclusion — per-claim internal reasoning for deciding claim-worthiness and checking a Conclusion before it's finalized | Surface pass claim discovery; reviewing a claim before writing it |
| `references/source-architecture.md` | Six optional whole-source lenses (Situation & Starting Point, Problem/Tension, Argument Movement, Support & Boundaries, Fidelity Signals, Resolution) feeding Core Idea formation | Reading the source's own architecture, before or alongside claim discovery |
| `references/writing-a-source-point.md` | Note structure, Core Idea line placement, the review checklist, quote formatting, and Key Concepts/Mentioned wikilink resolution | Assembling and writing a confirmed Source Point, or resolving any note-type wikilink |
