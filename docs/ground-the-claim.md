# ground-the-claim

Ground a clipped source into one or more Claims — the source's own position, restated in
your own words and checked against the source — writing each as a Key Claim in a shared
literature note for that source.

## When to use

Run this directly on a clipped source — no `surface-ideas` step required. It reads the
whole source, surfaces the source's Core Idea and the claims it actually supports, lets
you pick which to ground (or reshape the list — combine, split, drop), then runs a
grounding interview per claim and writes each one to the literature note as soon as it's
confirmed.

If the note already has claims from a prior session, it only offers what's left.

## How it works

1. **Take the source** — direct capture, checked against existing literature notes'
   `source` field to see if this source has already been (partially) grounded.
2. **Surface pass** — reads the source, using Question/Evidence/Warrant internally to
   identify the Core Idea and a right-sized candidate list (merging claims that share the
   same underlying reasoning before you ever see them), then lets you pick a subset, all
   of them, add your own, or reshape what's offered.
3. **Ground each selected claim** — a fully independent `/grounding` session per claim,
   holding you to the source.
4. **Write each claim, incrementally** — each confirmed claim lands on disk as a
   declarative heading (the claim itself) with condensed Evidence underneath, the moment
   it's confirmed, not batched at the end. The note's Core Idea is written once, on the
   first claim. A filename collision on the note's first claim stops and asks rather than
   auto-disambiguating.
5. **Spot terms and entities** — once every claim picked for this sitting is written, one
   batch pass finds terms and load-bearing named entities (people, tools, frameworks) the
   claims lean on but `## Key Concepts` doesn't cover yet, shows what it found and why,
   and appends what you confirm.

## Usage

> Ground the claim on [source], or just: ground-the-claim

## Installation

```bash
npx skills add andarwaly/slipbox
```

See the [skill source](../../skills/slipbox/ground-the-claim/) for the full agent-facing
instructions.
