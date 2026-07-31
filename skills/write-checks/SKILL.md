---
name: write-checks
description: Check a note draft against the vault's own style and humanize checklist, and resolve its frontmatter fields against config.json's field_map — use when another skill in the slipbox family is about to write a note to disk.
license: MIT
metadata:
  version: "1.0.0"
---

# Write-checks

## Prerequisite

Requires `.slipbox/config.json`, `.slipbox/style-profile.json` (or
`.slipbox/stated_style.json`), and `.slipbox/humanize-checklist.json` — all produced by
`setup-slipbox`. If any is missing, stop and say so.

## Style

Prose should read consistent with `.slipbox/style-profile.json` (or
`.slipbox/stated_style.json` if no corpus exists) — voice, tone, punctuation
fingerprint, lexicon, language/code-switching pattern — not a generic register.

## Humanize

After drafting, apply `humanize-checklist.json`'s `judgment` section directly — reading
comprehension, no tool needed — and run its `mechanical` section via
`idea-db humanize check <draft-path>`. If either surfaces a flagged cluster, revise
before writing the file — never write first and check after.

## Invocation modes

Called with a field list, `write-checks` runs Style, Humanize, Frontmatter fields, and
Zone placement — the full pass below. Called with no field list (already-resolved
fields, e.g. a term extension re-using its first write's mapping), it runs Style and
Humanize only, skipping Frontmatter fields and Zone placement entirely.

## Frontmatter fields

Given a note type and its field list (e.g. literature: `type`, `created`, `source`),
resolve each field through `.slipbox/config.json`'s `frontmatter.<type>` map: write
under the mapped property, the standard name if new, or skip if `false`. The field's
own name is never the mapping. Format the value per the entry's recorded `type` (a
`list` type is a YAML array, a `date`/`datetime` type is `YYYY-MM-DD` or a full
timestamp), and wrap in wikilink or markdown-link syntax per the top-level
`links.style` when `wikilink: true`.

## Zone placement

Zone only places newly-created fields — a mapped-onto-existing field stays put. New
`top` fields sit right after the opening `---`; new `bottom` fields sit right before
the closing `---`.

## Done

Hand back: a pass/revise signal for style and humanize (revise before writing if
either flags a cluster), plus — on the full pass only — each resolved field's final
property name, formatted value, and placement (already-positioned, or the zone it
belongs in), so the calling skill never re-derives field_map or zone logic itself. The
checks-only mode hands back the pass/revise signal alone.
