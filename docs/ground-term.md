# ground-term

Ground a term into a cumulative Term note — a running, per-term definition that may
draw on multiple sources over separate sessions.

## When to use

Bring a term to this directly (you noticed it recurring, or you're just curious), or
work through the pending queue `surface-ideas` filled (`target_type: 'term'`,
`status: 'to-discuss'`).

## How it works

1. **Take the term** — named directly, or picked from the backlog. Checks whether a
   Term note for it already exists before starting.
2. **Ground it** — a `/grounding` session, holding you to whichever source this
   mention traces back to. If the term note already exists, its current content is
   material too — a new answer has to stay consistent with what's already recorded.
3. **Write, new term** — writes fresh, and renames the originating `seeds` row to the
   term's final slug.
4. **Write, extending** — the trickier path: since `seeds.slug` is a primary key, a
   second mention of an already-recorded term can't rename its own row to the same
   slug the first occurrence already claimed. Instead it keeps its own slug, updates
   in place, and records the relationship as a `links` row (`rel_type: 'extends'`)
   pointing at the canonical row — then folds its contribution into the existing file,
   append-only, never a wholesale overwrite.

## Usage

> Ground the term "confirmation bias" — or just: ground-term

## Installation

```bash
npx skills add andarwaly/slipbox
```

See the [skill source](../../skills/slipbox/ground-term/) for the full agent-facing
instructions.
