---
name: ground-claim
description: Ground a clipped source into one or more Claims — the source's own
  position, restated in the user's own words and checked against the source — writing
  each as a Key Claim in a shared literature note for that source.
disable-model-invocation: true
license: MIT
metadata:
  version: "1.0.0"
---

# Ground-claim

## What these words mean

- **Claim** — the source's own position on one specific question the source answers,
  restated in the user's words and checked for fidelity. Never the user's opinion — an
  object of understanding, not agreement. A source usually holds several.
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
probing something already anchored. Identify every distinct claim the source actually
supports, skipping anything an existing literature note (per Take the source above)
already covers.

Present the list to the user before grounding anything:

> "This source is talking about these: [list]. Which do you want grounded — or is there
> something I missed?"

The user can pick any subset, all of them, or name a claim you didn't surface. This
candidate list is session-scoped only — nothing gets written to disk from this step, and
it's discarded once the session ends regardless of how many claims got picked.

## Ground each selected claim

For every claim the user picked (in the order they picked, one at a time), run a fully
independent `/grounding` session — no shared state between calls, no memory of a
previous claim in this same sitting. Hold the user to the source. If a term comes up
mid-session that already has (or could start) its own Term note, propose linking it with
a one-line reason — the user accepts or rejects each one individually, never linked
silently.

`/grounding` hands back the confirmed Claim as a Question/Evidence/Conclusion triplet,
and — only if the user opted in — a flagged tension. If a tension came back, insert it
into the evergreen backlog before moving on to writing this claim:

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
  added.
- Re-read the target path from disk right before writing (the note may already hold
  earlier claims from this same session, or from a prior one).
- Assemble and review the claim per `references/qec-theory.md` (what Question, Evidence,
  and Conclusion each are, with good/bad examples) and `references/writing-a-claim.md`
  (the `###` structure, the review checklist, quote formatting, and Key Concepts
  wikilink resolution) — read both before writing the first claim in a session.
- Filename collision on the note's first claim → stop and ask, never auto-disambiguate.
  On a second or later claim for an existing note, the existing file is expected, not a
  collision.

Repeat for the next selected claim, if any — a fresh `/grounding` call, then this same
write step, until every selected claim is written.

## Done

The literature note exists on disk with every selected claim as its own `## Key Claims`
entry (partial if the session stopped early — that's a complete, valid outcome, not a
failure), any flagged tensions are logged in the evergreen backlog, and the user is told
the file path.
