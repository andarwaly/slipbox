# write-checks

Checks a note draft against the vault's own style and humanize checklist, and resolves
its frontmatter fields against `config.json`'s field map — run just before any
note-writing skill commits a draft to disk.

## When to use

You won't invoke this directly. `make-literature-note`, `make-reference-note`, and
`make-evergreen-note` each run a `/write-checks` session on their own draft internally,
right before writing — the same way they each run `/grounding` internally for the
Socratic side of the work. There is no reason to invoke it standalone.

## How it works

1. **Prerequisite** — requires `.slipbox/AGENTS.md`, `.slipbox/config.json`,
   `.slipbox/style-profile.json`, and `.slipbox/humanize-checklist.json` to all exist,
   confirming `setup-slipbox` ran to completion.
2. **Invocation modes** — called with a field list, it runs the full pass: Style,
   Humanize, Frontmatter fields, and Zone placement. Called with no field list (fields
   already resolved from an earlier write, e.g. extending a Reference note), it runs
   Style and Humanize only.
3. **Style** — reads the vault's own stated style-profile as a contract, never as a
   humanizer detection baseline and never inferred from a corpus.
4. **Humanize** — runs the checklist's mechanical detection through the `slipbox`
   CLI, then judgment-based detection by reading comprehension; a flagged pattern gets
   rewritten (never deleted) and re-audited before writing proceeds.
5. **Frontmatter fields** — resolves each field against the vault's config: an
   already-mapped field just writes under its resolved name; a field being written for
   this note type for the first time goes through the same interactive resolution
   `setup-slipbox` itself uses, and the result gets written back so every later write of
   that type finds it already resolved.
6. **Note-type prefix** — resolves whether this note type's title gets a configured
   prefix character or stays unprefixed.
7. **Zone placement** — a newly-created field lands at the top or bottom of the
   frontmatter block, per its configured zone; a field mapped onto something that
   already exists stays where it already is.

On the full pass, it hands back a pass/revise signal plus each field's resolved name,
formatted value, and placement — so the calling skill never re-derives any of that
itself. On the checks-only pass, it hands back the pass/revise signal alone.

## Installation

```bash
npx skills add andarwaly/slipbox
```

See the [skill source](../skills/write-checks/) for the full agent-facing instructions.

## Artifact validation

The complete assembled temporary draft and complete basename are validated before
writing, then the saved path is re-read and validated again. Checks cover mapped fields,
YAML serialization, field zones, Markdown structure, block spacing, prefix position, and
exactly one terminal newline. Only unambiguous mechanical defects may be repaired;
collisions, uncertain titles, uncertain protected names, and semantic conflicts stop for
the user's decision. When `formatting.blank_lines_between_blocks` is `false`, notes use
compact Markdown; an absent key preserves the legacy spaced behavior.
