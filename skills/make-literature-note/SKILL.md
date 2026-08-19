---
name: make-literature-note
description: Ground a clipped source into one or more Claims — the source's
  own position, restated in the user's own words and checked against the
  source — writing each as a Key Claim in a shared literature note for that
  source.
license: MIT
metadata:
  version: "1.8.0"
---

# Make-literature-note

Bold terms in this file are defined in `GLOSSARY.md`.

## Prerequisite

Requires `.slipbox/AGENTS.md` to exist — its presence confirms `setup-slipbox`
completed a full run. If missing, stop and say so. Every `slipbox` call below
uses this same path, `.slipbox/bin/slipbox` — never bare `slipbox`, which
isn't guaranteed to be on `PATH`.

## Invocation

Named directly — `/make-literature-note from this article` (or a URL, or
a path) — grounds that specific source. A bare `/make-literature-note`
with no argument falls back to inferring the source from context: a
just-clipped Resource, a URL pasted earlier in the conversation, or an
already-open file. Ask only if nothing's inferrable — never guess silently
and never require the argument when the source is obvious from context.

## Take the source

Check whether a literature note for this source already exists: use
`slipbox config get paths.literature` to locate the folder and scan `*.md`
under it — never assume a folder literally named `literature/` — for a note
whose resolved `source` field (per `slipbox config get frontmatter.literature.source.name`)
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

## Knowing when the session is done

Once the conversation's natural energy winds down, check the private
backlog against what actually got covered (in whatever reshaped form).
Anything genuinely untouched gets one nudge, never more: "you haven't
mentioned [X] — is that not something the source argues, or should we
leave it for now?" The user's own "I think that's everything" always ends
the session regardless of what the backlog still shows uncovered — the
nudge is a single offer, never an insistence.

## Write each claim, incrementally

As soon as one claim is confirmed — before continuing the conversation
toward the next one, if there is a next one:

- Run a `/write-checks` session on the draft, passing the literature field
  list (`type`, `created`, `source`) — it resolves each field's mapping,
  formatting, zone placement, and title prefix, and checks the draft's
  style and humanize signals.
- Write into the folder from `slipbox config get paths.literature`, filename per
  `slipbox config get filenames.literature` casing convention. The title
  is source/topic-oriented (what the source is about), never claim-shaped
  — it doesn't change as more claims get added. On this note's first
  claim, write the Core Idea line too, directly under the title (see
  `references/writing-a-claim.md`); skip it on a second or later claim,
  it's already there.
- Re-read the target path from disk right before writing (the note may
  already hold earlier claims from this same session, or from a prior
  one).
- Assemble and review the claim per `references/writing-a-claim.md` — the
  declarative heading, condensed Evidence, the review checklist, quote
  formatting, and Key Concepts wikilink resolution.
- Filename collision on the note's first claim → stop and ask, never
  auto-disambiguate. On a second or later claim for an existing note, the
  existing file is expected, not a collision.
- Once written, tell the user in one short line that this claim landed —
  "that's your second claim confirmed" or equivalent — then move to the
  next question, if there is one, on its own line rather than fused into
  the same sentence (same split as `grounding/SKILL.md`'s
  acknowledgment-before-question rule). Not a running counter or a formal
  progress marker, just a natural acknowledgment tied to a real event (a
  claim actually being written), so the user has some sense of where the
  session stands without every turn being labeled.

An `## Open Questions` entry (and any nested `*Assumption*`/`*Answered*`
bullet) writes to disk the same way, as soon as it's flagged — it isn't
held back for the batch pass below, and unlike every other section it can
still be appended to later in a subsequent session, since it's the one
section exempt from the note's otherwise frozen-once-written rule.

## Spot terms and entities

Once the session ends, one batch pass — never mid-claim. Re-read the
finished note; re-read the source too if this is a resumed session and
it's no longer in context. Compare the two and find anything a claim leans
on — its weight actually resting on it, not just mentioned in passing —
that neither `## Key Concepts` nor `## Mentioned` yet covers. This scan is
type-blind: a person passing the load-bearing test (e.g. Niklas Luhmann, in
a claim about the Zettelkasten method's origins) is found the same
automatic way a concept is, in the same pass — never held back for the
user to ask about separately. Wikilink liberally here: this step
doesn't decide what the target will become (Reference note, Person,
Location, Organization, or nothing at all) — that classification happens
downstream, in `find-connections`, once cross-note evidence exists. The
author-exclusion stays unchanged: a source's own author still gets a bare,
unresolved wikilink, never routed toward a Person note through this
pipeline.

For each candidate, also make a quick, cheap read — enough to pick a
*section and link format*: does this look like a person, place, or
organization (real or fictional) — bound for `## Mentioned` — or a
concept/term/method — bound for `## Key Concepts`? Show the guess alongside
each candidate so the user can correct a misread before anything is written.

Show what was found and why, in one message:

> "Found these worth adding: [list, each with a one-line reason, its
> guessed kind, and which section it's headed for]. Add all, some, or
> none — and flag any I've read wrong."

On confirmation, run `/write-checks` again and append the confirmed entries
to `## Key Concepts` or `## Mentioned`, per candidate type, per
`references/writing-a-claim.md`'s wikilink resolution. Zero found is a
complete, valid result.

## Done

The literature note exists on disk with its Core Idea, every claim the
session actually produced as its own `## Key Claims` entry, any confirmed
Key Concepts and Mentioned entries, and any user-flagged `## Open
Questions` entries with their `*Assumption*`/`*Answered*` bullets (partial
if the session stopped early — that's a complete, valid outcome), any
flagged tensions are logged in the evergreen backlog, and the user is told
the file path.
