---
name: make-literature-note
description: Ground a clipped source into one or more Claims — the source's
  own position, restated in the user's own words and checked against the
  source — writing each as a Key Claim in a shared literature note for that
  source.
license: MIT
metadata:
  version: "1.17.0"
---

# Make-literature-note

Bold terms in this file are defined in `GLOSSARY.md`.

## Prerequisite

- MUST: `.slipbox/AGENTS.md` exists — confirms `setup-slipbox` ran to completion.
- NEVER: proceed without it. Stop and tell the user to run `setup-slipbox` first.
- NEVER: call bare `slipbox` — always `.slipbox/bin/slipbox`, which isn't guaranteed to be on `PATH`.

## Invocation

Named directly — `/make-literature-note from this article` (or a URL, or
a path) — grounds that specific source. A bare `/make-literature-note`
with no argument falls back to inferring the source from context: a
just-clipped Resource, a URL pasted earlier in the conversation, or an
already-open file. Ask only if nothing's inferrable — never guess silently
and never require the argument when the source is obvious from context.

## Take the source

Check whether a literature note for this source already exists: use
`.slipbox/bin/slipbox config get paths.literature` to locate the folder and scan `*.md`
under it — never assume a folder literally named `literature/` — for a note
whose resolved `source` field (per `.slipbox/bin/slipbox config get frontmatter.literature.source.name`)
points at this resource.

- **No note exists yet** — this source hasn't been grounded at all. Proceed
  to the Surface pass below with a fresh Private backlog.
- **A note already exists** — read it in full. Its existing `## Key
  Claims` `###` headings are claims already confirmed; the backlog below
  must not re-offer them.

## Surface pass — builds a private backlog, never a shown menu

Read the whole source yourself — this is your own judgment, not a
`/grounding` call; `/grounding` was never built for open-ended "what does
this cover" scanning, only for probing something already anchored. Before
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

This candidate list measures coverage, not required output — a literature
note may legitimately stay partial (see Knowing when the session is done,
below). It is **your own private backlog, not a menu presented to
the user** — never surfaced as a checklist, never asked "which of these do
you want grounded." It exists only to steer where the conversation still
needs to go and to check coverage once the session winds down. It is
session-scoped only — discarded once the session ends, regardless of how
much of it got covered.

## Ground the source — one continuous conversation, not one session per claim

Run a single, continuous `/grounding` session on the source, holding the
user to it (`/grounding`'s own default Fidelity direction for a
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
.slipbox/bin/slipbox evergreen add --slug source-tension \
  --reason "The source treats coordination as free" \
  --origin-kind source \
  --origin-path "resources/design-tokens.md"
```

Before the first Literature write, use the actual vault-relative Resource path
already accepted during Take the source. After the Literature file exists, use
that exact saved path for a reaction or tension:

```bash
.slipbox/bin/slipbox evergreen add --slug literature-reaction \
  --reason "I think coordination cost is the real bottleneck" \
  --origin-kind literature-note \
  --origin-path "Notes/§ Design Tokens.md"
```

These paths must be the files actually read or written in this session; never
reconstruct them from `paths.*`, `filenames.*`, or configured prefixes.

When the user notices a genuine gap in the source itself — something the
source leaves unclear, ambiguous, or unanswered — offer to record it as an
`## Open Questions` entry. Never invent one unprompted; this only fires on
the user's own noticing. If the user wants a guess at an answer recorded
too, append it as a nested `*Assumption*` bullet, clearly marked as the
user's own guess — the one narrow exception to the note's purity rule,
scoped to this one bullet type under this one section only. Never write an
unmarked personal guess, and never let it read as a Claim. If the user
names another literature note that already resolves the question, append a
nested `*Answered*` bullet as a wikilink to that claim's own heading
(`[[Other Literature Note#the-claim-that-answers-it]]`) — user-initiated
only, never detected automatically; this family runs no cross-note scan for
outstanding questions. An existing `*Assumption*` bullet stays in place
once `*Answered*` is added alongside it. See
`references/writing-a-claim.md`'s Open Questions section for the full
format.

## Write each claim, incrementally

As soon as one claim is confirmed — before continuing the conversation
toward the next one, if there is a next one:

- Run a `/write-checks` session with `artifact-kind: note` and `note-type: literature`, passing the literature field
  list (`type`, `created`, `source`) — it resolves each field's mapping,
  formatting, zone placement, and title prefix, and checks the draft's
  style and humanize signals.
- Write into the folder from `.slipbox/bin/slipbox config get paths.literature`, filename per
  `.slipbox/bin/slipbox config get filenames.literature` casing convention. The Literature H1
  preserves the Resource's source title exactly; it is never replaced with an agent-authored
  topic label. Construct the complete basename through `.slipbox/bin/slipbox filename format
  --type literature --title "<exact source title>"`, passing each confidently identified
  proper-name span as `--preserve`. The command applies protected names, configured casing,
  filename sanitization, then the configured prefix, and returns the complete basename. If
  protected-name identification is uncertain, show the proposed basename and ask the user
  before writing. On this note's first
  claim, write the Core Idea line too, directly under the title (see
  `references/writing-a-claim.md`); skip it on a second or later claim,
  it's already there.
- Re-read the target path from disk right before writing (the note may
  already hold earlier claims from this same session, or from a prior
  one).
- Assemble and review the claim per `references/writing-a-claim.md` — the
  declarative heading, condensed Evidence, the review checklist, quote
  formatting, and Key Concepts wikilink resolution.
- Assemble the complete temporary draft, then run `/write-checks` artifact validation
  with the complete basename and exact Resource title. Repair only mechanical defects;
  stop and ask for semantic conflicts, collisions, uncertain titles, or uncertain
  protected names.
- Write the assembled draft, re-read the saved path, and run
  `.slipbox/bin/slipbox note validate --type literature --path <saved-path>
  --basename "<complete basename>.md" --title "<exact Resource title>"`. A failed
  post-write check blocks the next claim and the success acknowledgment.
- Filename collision on the note's first claim → stop and ask, never
  auto-disambiguate. On a second or later claim for an existing note, the
  existing file is expected, not a collision.
- Once written, tell the user in one short line that this claim landed —
  "that's your second claim confirmed" or equivalent — then move to the
  next question, if there is one, on its own line rather than fused into
  the same sentence (same split as `/grounding`'s SKILL.md
  acknowledgment-before-question rule). Not a running counter or a formal
  progress marker, just a natural acknowledgment tied to a real event (a
  claim actually being written), so the user has some sense of where the
  session stands without every turn being labeled.

An `## Open Questions` entry (and any nested `*Assumption*`/`*Answered*`
bullet) writes to disk the same way, as soon as it's flagged — it isn't
held back for the batch pass below, and unlike most other sections it can
still be appended to later in a subsequent session, one of the note's
three narrowly-scoped exemptions from the otherwise frozen-once-written
rule (full list under Checking the shape, below).

## Knowing when the session is done

Once the conversation's natural energy winds down, `Done` is a fixed closeout
gate. Run every stage below in order; never declare completion between stages.
The source audit is convergent: any material claim-set change, including a
density merge, returns to the complete audit and the loop continues until the
audit is clean. A user-declined valid finding makes the note deliberately
partial; report that status and discard the private backlog unless the user
explicitly asks to retain it.

### Checking coverage — the backlog, then the source itself

Check the private backlog against what actually got covered (in whatever
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

Then **always** re-read the complete source and compare it against the
finished note. The audit explicitly checks missing arguments, claims that
became too narrow or too broad, overlapping claims, and qualifications or
gray areas lost during compression. Present findings as one batch.

> "Re-reading the source, these look like things it argues that we never
> captured: [list, each with a one-line note on what the source says].
> Want to ground all of them, some, or none?"

Whatever the user picks goes through `/grounding`'s Gate exactly as any other
claim and gets written the same way. A declined valid finding is reported as
partial. Zero findings is clean. After every material change, restart this
whole audit; only a clean pass permits the next stage.

### Checking the shape — density, then the Core Idea

With the claim set now final, read the note's `## Key Claims` as a whole
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
Where the merge test does fire, offer the merge rather than performing
it — the merged claim is a new statement, so it goes through Gate like
any other. This session-close density merge is a third, narrowly-scoped
exemption to the literature note's frozen-once-written rule — distinct
from the out-of-band fidelity correction (covered next) and from the
`## Open Questions` append-only exemption above, and reaching no further
than this one pass. If the
user confirms the merge, the superseded claim's own `## Key Claims`
heading is removed and its content folded into the surviving merged
claim, which then gets its own fresh Gate confirmation as the new
statement it is.

Then confirm the Core Idea. It was written on the note's first claim,
before most of the conversation existed, so it's the one line on the page
that has never been checked against the session as a whole. Confirming it
is a Gate pass, and Gate's precondition holds: the user has to have said
the thing before you can confirm it. So ask one genuine open question
first, and wait for a real answer:

> "having been through all of it — what do you think is the main idea
> this source is arguing?"

Read the answer as `/grounding` reads any answer. Only a Confident answer
proceeds straight to confirmation; Hesitant, Blank, or Confused falls
back to `/grounding`'s full reading-state dispatch table and runs the
technique it names, exactly as anywhere else. There is no shortcut here
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
load-bearing candidates together, with a guessed section, and obtain the
user's confirmation before appending. `Key Concepts` holds abstract concepts,
methods, and frameworks. `Mentioned` holds concrete named referents: people,
places, organizations, books/creative works, named tools, and events. Downstream
`find-connections --references` classification first checks people, places, and
organizations as surfacing-only entities; non-entities then take the reusability
test and may become Reference candidates.

### Closing with the user's own reaction

Last, once the note itself is settled, ask what the user actually thinks:

> "what do you think of this article?"

Skip this only when a real opinion already surfaced during a `/grounding`
session and got routed there — `/grounding`'s persistent-opinion case, where a
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

Only on a yes:

```bash
.slipbox/bin/slipbox evergreen add --slug <draft-slug> --reason "<the user's own reaction, in their words>"
```

A shrug, a "nothing really," or a decline is a complete, valid end to the
session.

## Out-of-band fidelity correction

The third and last exemption to the note's frozen-once-written rule fires
outside any of the flows above, on no fixed schedule — whenever the user,
during this session or a later one, notices that an already-written Key
Claim entry misreads, mistranscribes, or misrepresents the source. Like
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

Once the user has named the inaccuracy and what the corrected wording
should say, run that corrected wording through `/grounding`'s Gate exactly
as any other claim gets confirmed — a correction earns no shortcut past
the discipline every other statement in the note holds to. Only once Gate
confirms it, edit the existing `## Key Claims` entry in place: this is the
one case in the whole file where an already-written entry is legitimately
reopened rather than superseded by a new heading.

## Final validation handoff

Run `/write-checks` with `artifact-kind: note` and `note-type: literature` against the complete artifact after the final batch. Check
required fields, section order, claim headings, Core Idea placement, and both
surfacing sections on the file already written. Then run
`.slipbox/bin/slipbox note validate --type literature --path <saved-path>
--basename "<complete basename>.md" --title "<exact Resource title>"`. Validation
is a handoff, not permission to silently rewrite a claim; any material claim
change returns to the convergent source audit.

## Done

`Done` fires only after this checklist is true: the convergent source audit
is clean (or the user explicitly declined findings and the note is reported
partial); density merge was offered and, if accepted, re-audited; final Core
Idea is confirmed; final Key Concepts/Mentioned batch is complete; reaction
and optional Evergreen routing are complete; and artifact validation confirms
the note already written incrementally. The note includes any user-flagged
Open Questions and nested bullets, and flagged tensions are logged in the
evergreen backlog. Then tell the user the file path and partial status when
applicable.

## References

| File | Purpose | Triggering condition |
|---|---|---|
| `references/qew-theory.md` | Question/Evidence/Warrant/Conclusion — per-claim internal reasoning for deciding claim-worthiness and checking a Conclusion before it's finalized | Surface pass claim discovery; reviewing a claim before writing it |
| `references/source-architecture.md` | Six optional whole-source lenses (Situation & Starting Point, Problem/Tension, Argument Movement, Support & Boundaries, Fidelity Signals, Resolution) feeding Core Idea formation | Reading the source's own architecture, before or alongside claim discovery |
| `references/writing-a-claim.md` | Note structure, Core Idea line placement, the review checklist, quote formatting, and Key Concepts/Mentioned wikilink resolution | Assembling and writing a confirmed claim, or resolving any note-type wikilink |
