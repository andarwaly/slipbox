---
name: find-terms
description: Report which terms recur across literature notes' Key Concepts sections but don't have their own Term note yet. Pure read/report — writes nothing to disk.
disable-model-invocation: true
license: MIT
metadata:
  version: "1.0.0"
---

# Find-terms

Read-only. This skill never writes anything — not a note, not a backlog entry, not a
database row. If the user wants to act on what it reports, they invoke `ground-term`
themselves, right after seeing the report.

## Scan

Read every literature note's `## Key Concepts` section. Each entry wikilinks a term
(`[[<term-note-filename>|Term Name]]`, resolved from `.slipbox/config.json`'s
`paths.term`, `filenames.term`, and `prefixes.term` together — never assume a `term/`
folder, kebab-case slug, or no prefix) with a 1-line gloss of what that specific source
said about it. For every distinct wikilink target, count how many different literature
notes link to it.

## Report

For each term where the link count crosses a recurrence threshold (two or more distinct
literature notes) and its resolved term-note file does not already exist on disk at
`.slipbox/config.json`'s configured `paths.term` (checked per the same `paths.term` /
`filenames.term` / `prefixes.term` resolution `ground-term` uses to check for an
existing note — a prefixed filename like `※ Term Name.md` still counts as existing),
list it — the term name, the count, and which literature notes mention it. Terms
already backed by an existing term note are not reported, regardless of recurrence
count; nothing here checks whether an existing term note needs extending, only whether
one needs creating.

Zero terms crossing the threshold is a complete, valid result — report it as such, not as
an error or an empty failure.

## Done

The user has seen the report. Nothing was written. If they want to act on any of it,
they run `/ground-term` themselves, naming the term directly.
