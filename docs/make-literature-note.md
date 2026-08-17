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
