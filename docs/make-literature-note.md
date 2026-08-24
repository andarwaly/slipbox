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

The Literature H1 remains the exact Resource/source title. A configured Literature
prefix belongs in the generated filename and link target, not in that H1.

## How it works

1. **Prerequisite** — requires `.slipbox/AGENTS.md` to exist, confirming `setup-slipbox`
   has run; every `slipbox` CLI call throughout this skill goes through
   `.slipbox/bin/slipbox`, never bare `slipbox`.
2. **Take the source** — direct capture, checked against existing literature notes'
   `source` field to see if this source has already been (partially) grounded.
3. **Surface pass** — reads the source, using Question/Evidence/Warrant internally to
   identify the Core Idea and a candidate backlog. This backlog is never shown as a
   menu — it's the agent's own private steering tool for the conversation that follows.
4. **One continuous conversation** — rather than looping a separate session per claim,
   you have one natural conversation about the source. Whenever it organically produces
   something matching a backlog candidate — in whatever reshaped form — it goes through
   a full `/grounding` Gate exactly as always.
5. **Write each claim, incrementally** — each confirmed claim lands on disk as a
   declarative heading with condensed Evidence underneath, the moment it's confirmed.
6. **Knowing when the session is done** — coverage first, then shape, then the user's own
   reaction. Coverage means checking the backlog against three states (covered / drafted
   but unconfirmed / genuinely untouched, each nudged differently, at most once) and,
   as a judgment call rather than a mandatory step, considering a fresh full re-read of
   the source to catch what neither the Surface pass nor the conversation caught. Shape
   means a density-merge pass across the confirmed claims and a re-confirmation of the
   Core Idea against the session as a whole. Last, the user is asked what they think of
   the source — routed to the evergreen backlog as a seed for a future Take if they want
   it recorded, never into the literature note itself. "I think that's everything" always
   ends the sitting at any point.
7. **Out-of-band fidelity correction** — at any time, in this session or a later one, the
   user can point at an already-written Key Claim that misreads the source; a narrowly
   scoped fix (moves the note closer to the source, nothing else) goes through the same
   Gate as any other claim, then edits that entry in place — the one case where a
   written entry is legitimately reopened.
8. **Spot terms and entities** — once the sitting ends, one batch pass finds terms and
   load-bearing named entities the claims lean on but `## Key Concepts` doesn't cover yet.

The finished note, any logged tension, and the file path are reported once the session
ends (partial coverage is a complete, valid outcome). Three reference files —
`qew-theory.md`, `source-architecture.md`, `writing-a-claim.md` — cover the internal
claim-worthiness reasoning, whole-source reading lenses, and note-writing mechanics
respectively; see the skill's own `## References` table for exactly when each applies.

## Usage

> /make-literature-note from [source]

## Installation

```bash
npx skills add andarwaly/slipbox
```

See the [skill source](../skills/make-literature-note/) for the full
agent-facing instructions.
