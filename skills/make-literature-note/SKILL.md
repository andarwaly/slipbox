---
name: make-literature-note
description: Ground a clipped source into one or more Claims — the source's
  own position, restated in the user's own words and checked against the
  source — writing each as a Key Claim in a shared literature note for that
  source.
license: MIT
metadata:
  version: "1.3.0"
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
