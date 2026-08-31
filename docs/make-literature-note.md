# make-literature-note

Ground a clipped source into one or more Source Points — source-owned propositions, restated in
your own words and checked against the source — writing each as a Source Point in a shared
literature note for that source.

## When to use

Start or resume Literature work for the Resource `/using-slipbox`. The source may be
explicit (`/make-literature-note from this article`) or inferred from a just-clipped
Resource, pasted URL, or open file; ask only when nothing is inferrable.

If the note already has Source Points from a prior session, it only offers what's left.

The Literature H1 remains the exact Resource/source title. A configured Literature
prefix belongs in the generated filename and link target, not in that H1.

## How it works

1. **Prerequisite** — requires `.slipbox/AGENTS.md` to exist, confirming `setup-slipbox`
   has run; every `slipbox` CLI call throughout this skill goes through
   `.slipbox/bin/slipbox`, never bare `slipbox`.
2. **Load or build source analysis** — `/using-slipbox` reads or creates a reusable source
   map keyed by the Resource fingerprint; it stays source-owned and separate from inquiry.
3. **Create inquiry context** — build a session-scoped inquiry map with purpose, reflection,
   source-unit IDs, comprehension, relevance, risk, and draft state. Derive the grounding
   frontier at runtime; never store an authoritative queue.
4. **Follow the inquiry** — ask one substantive question at a time. The Adaptive Split Gate
   requires semantic reconstruction for inquiry-central work, while supporting/contextual
   work may be agent-drafted; consequential material is source-verified without forced
   paraphrase. Confident, Hesitant, Blank, and Confused reading states dispatch normally.
5. **Stage Source Points** — checkpoint the inquiry map and `draft.md` through
   `/using-slipbox`; every final point receives a source audit. The final path is untouched
   until closeout publication.
6. **Knowing when the session is done** — coverage first, then shape, then the user's own
   reaction. Coverage means checking the backlog against three states (covered / drafted
   but unconfirmed / genuinely untouched, each nudged differently, at most once) and,
   targeted integrity checks against source units. Shape means a density-merge pass across
   the confirmed points and a re-confirmation of the
   Core Idea against the session as a whole. Last, the user is asked what they think of
   the source — routed to the evergreen backlog as a seed for a future Take if they want
   it recorded, never into the literature note itself. "I think that's everything" always
   ends the sitting at any point.
7. **Out-of-band fidelity correction** — at any time, in this session or a later one, the
   user can point at an already-written Source Point that misreads the source; a narrowly
   scoped fix (moves the note closer to the source, nothing else) goes through the same
   Gate as any other claim, then edits that entry in place — the one case where a
   written entry is legitimately reopened.
8. **Spot terms and entities** — once the sitting ends, one batch pass finds terms and
   load-bearing named entities the claims lean on but `## Key Concepts` doesn't cover yet.

The finished note, any logged tension, and the file path are reported once the session
ends (partial coverage is a complete, valid outcome). Three reference files —
`qew-theory.md`, `source-architecture.md`, `writing-a-source-point.md` — cover the internal
claim-worthiness reasoning, whole-source reading lenses, and note-writing mechanics
respectively; see the skill's own `## References` table for exactly when each applies.

## Usage

> /make-literature-note from [source]

## Installation

```bash
npx skills add andarwaly/slipbox
```

See the [skill source](../skills/make-literature-note/) for the full
agent-facing instructions.
