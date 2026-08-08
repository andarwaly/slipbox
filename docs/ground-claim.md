# ground-claim

Ground a clipped source into one or more Claims — the source's own position, restated in
your own words and checked against the source — writing each as a Key Claim in a shared
literature note for that source.

## When to use

Run this directly on a clipped source — no `surface-ideas` step required. It reads the
whole source, surfaces the claims it actually supports, lets you pick which to ground,
then runs a grounding interview per claim and writes each one to the literature note as
soon as it's confirmed.

If the note already has claims from a prior session, it only offers what's left.

## How it works

1. **Take the source** — direct capture, checked against existing literature notes'
   `source` field to see if this source has already been (partially) grounded.
2. **Surface pass** — reads the source, proposes a candidate list of claims, lets you
   pick a subset, all of them, or add your own.
3. **Ground each selected claim** — a fully independent `/grounding` session per claim,
   holding you to the source.
4. **Write each claim, incrementally** — each confirmed claim lands on disk as its own
   Question/Evidence/Conclusion entry the moment it's confirmed, not batched at the end.
   A filename collision on the note's first claim stops and asks rather than
   auto-disambiguating.

## Usage

> Ground claims from [source], or just: ground-claim

## Installation

```bash
npx skills add andarwaly/slipbox
```

See the [skill source](../../skills/slipbox/ground-claim/) for the full agent-facing
instructions.
