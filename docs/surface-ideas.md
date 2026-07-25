# surface-ideas

Surface 5-10 discussion-worthy candidate ideas from a clipped Resource. An explore pass, not an exploit pass — it produces open questions, never conclusions, and never writes a literature note itself.

## When to use

Run this against a Resource file (written by `clip-resource`, or dropped in by an external clipper tool) once you're ready to see what's worth discussing in it. It's the step between clipping a source and actually sitting down to think about one idea from it in `write-literature-note`.

## How it works

1. **Take the Resource** — reads an already-captured, frozen Resource file. Never edits it.
2. **Surface pass** — surfaces 5-10 candidates, each a question plus its motivation. Neither half is allowed to be a conclusion: a candidate that already states what an idea means has skipped past exploration into the discussion `write-literature-note` is supposed to have later. A candidate like *"Knowledge is most useful when broken into atomic, standalone ideas"* gets rejected and rewritten as a question instead — something like *"What would it mean to treat a note as a single reusable idea rather than a container for everything related to a topic?"*
3. **Diversity check** — uses the Idea Compass to ensure candidates spread across multiple dimensions: Origin (what led the source to this idea?), Similar (what else resembles this?), Competes (what's the strongest counter-argument?), and Leads to (what does this imply next?). A surface pass where every candidate points in the same direction isn't diverse enough, even if each one is individually well-formed.
4. **Dismiss at surface time** — some candidates aren't worth keeping at all (too thin, too redundant). These are dropped silently, leaving no trace — different from a candidate dismissed later during `write-literature-note`'s pick step, which does get recorded.
5. **Write** — inserts surviving candidates as `seeds` rows in `.slipbox/idea.db`, one row per candidate. Zero surviving candidates is a valid, complete outcome, not a failure.

## Usage

Invoke it by name, pointing at a Resource:

> Surface ideas from this article: [path or link to the Resource]

`write-literature-note` reads what this skill writes, and can run in a separate session entirely.

## Installation

This skill ships as part of the `andarwaly/skills` collection:

```bash
npx skills add andarwaly/skills
```

## Reference

- [candidate-schema.md](../../skills/slipbox/surface-ideas/references/candidate-schema.md) — the CSV schema this skill writes to, and the query patterns for reading it back

See the [skill source](../../skills/slipbox/surface-ideas/) for the full agent-facing instructions.
