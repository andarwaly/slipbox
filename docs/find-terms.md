# find-terms

Report which terms recur across literature notes' Key Concepts sections but don't have
their own Term note yet.

## When to use

Run this whenever you want to check whether any recurring vocabulary across your
literature notes is worth its own Term note. It's read-only — nothing gets written,
recurrence is recomputed fresh every time from the notes themselves, so there's no
backlog to keep in sync.

## How it works

1. **Scan** — reads every literature note's `## Key Concepts` section, counting how many
   distinct notes wikilink each term.
2. **Report** — lists any term crossing the recurrence threshold (2+ literature notes)
   that has no `term/<slug>.md` file yet. A term already backed by a note is never
   reported, no matter how often it recurs.

## Usage

> Find terms worth grounding.

Then, for anything worth acting on:

> ground-term "the term name"

## Installation

```bash
npx skills add andarwaly/slipbox
```

See the [skill source](../../skills/slipbox/find-terms/) for the full agent-facing
instructions.
