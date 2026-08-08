# ground-term

Ground a term into a cumulative Term note — a running, per-term definition that may
draw on multiple sources over separate sessions.

## When to use

Run this whenever you (or `find-terms`) name a term worth its own note. There's no
backlog to check first — you name the term directly, every time.

## How it works

1. **Take the term** — named directly, checked against existing term notes to see if
   this is a new term or an extension.
2. **Ground it** — a `/grounding` session, holding you to whichever source backs this
   particular mention.
3. **Write** — a fresh term note on first occurrence, or an in-place extension
   (append-only, never overwritten wholesale) on repeat mentions, with a typed `links`
   edge connecting the two.

## Usage

> ground-term "confirmation bias"

## Installation

```bash
npx skills add andarwaly/slipbox
```

See the [skill source](../../skills/slipbox/ground-term/) for the full agent-facing
instructions.
