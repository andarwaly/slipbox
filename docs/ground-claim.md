# ground-claim

Ground a surfaced idea into a Claim — the source's own position, restated in your own
words and checked against the source — then write it as a literature note.

## When to use

Run this once `surface-ideas` has already surfaced candidates from a Resource. It picks
a pending candidate (or takes one you hand it directly), runs the grounding interview
against that candidate's source, and writes the confirmed Claim to disk.

If you hand it a raw, unprocessed source instead, it won't try to work with it — it'll
tell you to run `surface-ideas` first.

## How it works

1. **Take the idea** — a pending `idea.db` candidate (`target_type: 'literature'`), or
   one you hand it directly.
2. **Ground it** — a `/grounding` session, holding you to the source. Any term that
   comes up gets proposed as a link to its own Term note, one at a time, never linked
   silently.
3. **Write** — the confirmed Claim becomes a literature note, filename/frontmatter per
   `.slipbox/config.json`. One-shot: written once, never revisited. A filename
   collision stops and asks rather than auto-disambiguating.
4. **Close the backlog row** — the original `seeds` row flips to `discussed`, with the
   note's path attached.

## Usage

> Ground a claim from [candidate/resource], or just: ground-claim

## Installation

```bash
npx skills add andarwaly/slipbox
```

See the [skill source](../../skills/slipbox/ground-claim/) for the full agent-facing
instructions.
