# find-connections

Scan existing notes for missing links and sparked ideas — splits mechanical link
suggestions (batch-confirmed) from generative ideas (routed to the evergreen backlog).

## When to use

Run this whenever you want to sit down and see what your vault has been quietly building
toward — connections between existing notes that were never made explicit, or ideas that
only emerge when two notes are read together. This is a heavier, whole-corpus pass, not
something tied to any single capture.

## How it works

1. **Scan** — reads across literature/term/evergreen notes for two distinct things: link
   candidates (mechanical) and sparked ideas (generative).
2. **Link suggestions, presented as a batch** — every candidate shown together, approved
   or rejected in one pass, never one-at-a-time.
3. **Sparked ideas, routed to the evergreen backlog** — never written as a note
   directly; `ground-my-take` picks them up later.

## Usage

> Find connections in my vault.

## Installation

```bash
npx skills add andarwaly/slipbox
```

See the [skill source](../../skills/slipbox/find-connections/) for the full agent-facing
instructions.
