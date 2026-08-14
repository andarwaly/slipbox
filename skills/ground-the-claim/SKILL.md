---
name: ground-the-claim
description: Ground a clipped source into one or more Claims — the source's own
  position, restated in the user's own words and checked against the source — writing
  each as a Key Claim in a shared literature note for that source.
disable-model-invocation: true
license: MIT
metadata:
  version: "1.0.1"
---

# Ground-the-claim

## What these words mean

- **Claim** — the source's own position on one specific question the source answers,
  restated in the user's words and checked for fidelity, written as a declarative
  sentence. Never the user's opinion — an object of understanding, not agreement. A
  source usually holds several.
- **Core Idea** — the source's central argument, one declarative sentence, every Claim
  in the note in service of it. Distinct from a Claim: a Claim is one thing the source
  argues, the Core Idea is what the source is *for*. Written once per note, on its first
  Claim.
- **Literature note** — the file a source's confirmed Claims get written into. One per
  source clip, holding as many Key Claims as the source actually supports — written
  incrementally as each is confirmed, never revisited afterward once written except
  out-of-band manual fidelity corrections: fixing a misreading, a transcription error,
  or wording that misrepresents the source. Reaction, stance, or synthesis never enters;
  a correction must move the note closer to the source. Slugs stay final once written.

## Prerequisite

Requires `.slipbox/config.json` — same as every skill in this family. If it's missing,
stop and say so. Same check for `.slipbox/bin/slipbox` — if it doesn't exist or isn't
executable, stop and say so too. Every `slipbox` call below uses this same path,
`.slipbox/bin/slipbox` — never bare `slipbox`, which isn't guaranteed to be on `PATH`.

## Take the source

Direct capture only — no candidate backlog to pull from. Take the resource the user
names, or the one just clipped by `/clip-resource`.

Check whether a literature note for this source already exists: read `paths.literature`
from `.slipbox/config.json` and scan `*.md` under that folder — never assume a folder
literally named `literature/` — for a note whose resolved `source` field (per
`frontmatter.literature.source.name` in the same config) points at this resource.

- **No note exists yet** — this source hasn't been grounded at all. Proceed to the
  surface pass below with a fresh candidate list.
- **A note already exists** — read it in full. Its existing `## Key Claims` `###`
  headings are claims already confirmed; the surface pass below must not re-offer them.

## Surface pass

Read the whole source yourself — this is your own judgment, not a `/grounding` call;
`/grounding` was never built for open-ended "what does this cover" scanning, only for
probing something already anchored. Using Question/Evidence/Warrant as your own internal
reasoning tool (`references/qec-theory.md`) — never shown to the user in this form —
identify every distinct claim the source actually supports and the source's Core Idea,
skipping anything an existing literature note (per Take the source above) already
covers. Apply the shared-Warrant merge test now, before presenting anything: two
candidates resting on the same inferential move are one claim, not two.

Present the right-sized list to the user before grounding anything:

> "This source's core idea seems to be [X]. It's talking about these: [list]. Which do
> you want grounded — or is there something I missed, or something here that should be
> combined or split differently?"

The user can pick any subset, all of them, name a claim you didn't surface, or reshape
the list itself — combine two, split one, drop one that doesn't hold enough weight. This
candidate list and Core Idea are session-scoped only — nothing gets written to disk from
this step, and it's discarded once the session ends regardless of how many claims got
picked.

## Ground each selected claim

For every claim the user picked (in the order they picked, one at a time), run a fully
independent `/grounding` session — no shared state between calls, no memory of a
previous claim in this same sitting. Hold the user to the source.

`/grounding` hands back one confirmed statement (its own contract — see
`grounding/SKILL.md`'s Done section — not a Question/Evidence/Conclusion triplet), and —
only if the user opted in — a flagged tension. Before writing, run the Warrant self-check
from `references/qec-theory.md` against the confirmed statement: state the "why" in one
sentence — if that sentence and the statement would say the same thing, the statement is
still restating Evidence, go back and probe further rather than writing it as-is.

If a tension came back, insert it into the evergreen backlog before moving on to writing
this claim:

```bash
.slipbox/bin/slipbox evergreen add --slug <draft-slug> --reason "<tension description>"
```

## Write each claim, incrementally

As soon as one claim is confirmed — before starting the next one, if there is a next
one:

- Run a `/write-checks` session on the draft, passing the literature field list
  (`type`, `created`, `source`) — it resolves each field's mapping, formatting, zone
  placement, and title prefix, and checks the draft's style and humanize signals.
- Write into `paths.literature` from `.slipbox/config.json`, filename per that same
  config's casing convention for the literature type. The title is source/topic-oriented
  (what the source is about), never claim-shaped — it doesn't change as more claims get
  added. On this note's first claim, write the Core Idea line too, directly under the
  title (see `references/writing-a-claim.md`); skip it on a second or later claim, it's
  already there.
- Re-read the target path from disk right before writing (the note may already hold
  earlier claims from this same session, or from a prior one).
- Assemble and review the claim per `references/writing-a-claim.md` — the declarative
  heading, condensed Evidence, the review checklist, quote formatting, and Key Concepts
  wikilink resolution — read it (and `references/qec-theory.md` for what backs the
  checklist) before writing the first claim in a session.
- Filename collision on the note's first claim → stop and ask, never auto-disambiguate.
  On a second or later claim for an existing note, the existing file is expected, not a
  collision.

Repeat for the next selected claim, if any — a fresh `/grounding` call, then this same
write step, until every selected claim is written.

## Spot terms and entities

Once every selected claim for this sitting is written, one batch pass — never mid-claim.
Re-read the finished note; re-read the source too if this is a resumed session and it's
no longer in context. Compare the two and find anything a claim leans on — its weight
actually resting on it, not just mentioned in passing — that Key Concepts doesn't yet
cover. Wikilink liberally here: this step doesn't decide what the target will become
(Reference note, Person, Location, Organization, or nothing at all) — that classification
happens entirely downstream, in `find-connections`, once cross-note evidence exists. The
author-exclusion stays unchanged: a source's own author still gets a bare, unresolved
wikilink, never routed toward a Person note through this pipeline.

Show what was found and why, in one message:

> "Found these worth adding to Key Concepts: [list, each with a one-line reason]. Add
> all, some, or none?"

On confirmation, run `/write-checks` again and append the confirmed entries to
`## Key Concepts` per `references/writing-a-claim.md`'s wikilink resolution. Zero found
is a complete, valid result — say so, don't manufacture one to fill the step.

## Done

The literature note exists on disk with its Core Idea, every selected claim as its own
`## Key Claims` entry, and any confirmed Key Concepts (partial if the session stopped
early — that's a complete, valid outcome, not a failure), any flagged tensions are
logged in the evergreen backlog, and the user is told the file path.
