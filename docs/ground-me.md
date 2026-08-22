# ground-me

A bare, freeform grounding session — no note-type commitment, no sibling routing.

## When to use

Reach for this when you just want to think something through out loud, with no
intention (yet, or ever) of turning it into a Claim, a Reference note, or a Take. It's the
`grilling`-family equivalent of `grill-me`: no classification, no offering another
skill, no backlog-checking.

## How it works

Requires that `setup-slipbox` has already run — it checks for `.slipbox/AGENTS.md`
before doing anything, and stops with a pointer back to `setup-slipbox` if it's missing.

Runs a `/grounding` session on whatever you hand it — an idea, notes, a source, an
article, anything at all. If you give it nothing, it asks what you want to work
through.

Once the session settles, it closes with a plain "Crystalized Thought" card: a
**Core Thesis** line quoting the confirmed statement verbatim, an optional
**Flagged for later** line for a tension the session surfaced — left out entirely
when nothing was flagged, never shown as an empty placeholder — and one closing
question asking whether to keep exploring, move on, or call it done.

## Usage

> ground me on this: [an idea, a pasted article, a half-formed hunch]

## Installation

```bash
npx skills add andarwaly/slipbox
```

See the [skill source](../skills/ground-me/) for the full agent-facing
instructions.
