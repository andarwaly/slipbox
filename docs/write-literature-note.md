# write-literature-note

Turn a candidate idea surfaced from a source into a finished, single-claim literature note — via a Socratic discussion grounded entirely against that source. Reads ideas `surface-ideas` found; can run in a separate session.

## When to use

Use this when you have a candidate idea from `surface-ideas` that you want to think through and commit to a note. The idea becomes a single Claim — a statement grounded against the source that prompted it, not your own reaction or connection. If you want to explore connections across multiple notes instead, use `write-evergreen-note`.

## How it works

1. **Resume check** — before offering new work, checks `.slipbox/discussions/` for any in-progress literature-note sessions. Offers to pick up where you left off if any exist.
2. **Pick a candidate** — queries your pending backlog of candidates surfaced by `surface-ideas`. Lets you choose one to discuss, or dismiss one without discussing if you've changed your mind. 
3. **Discuss** — runs a Socratic conversation grounded against the one source the idea came from. Holds you to the author's claim; flags drift.
4. **Write the note** — once the Claim is confirmed, writes the finished literature note with correct filename (derived from the Claim text) and frontmatter (`type: literature`, `created`, `source: [[resource]]`).
5. **Update the database** — flips the candidate row in `idea.db` from "to discuss" to "discussed" and records the note's path.

## Usage

Invoke it by name to start discussing a candidate idea:

> Discuss a literature idea.

Or resume an in-progress session:

> Resume my literature note.

## Installation

This skill ships as part of the `andarwaly/skills` collection:

```bash
npx skills add andarwaly/skills
```

See the [skill source](../../skills/slipbox/write-literature-note/) for the full agent-facing instructions.
