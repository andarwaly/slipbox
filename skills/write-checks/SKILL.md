---
name: write-checks
description: Check a note draft against the vault's own style and humanize checklist, and resolve its frontmatter fields against config.json's field_map — use when another skill in the slipbox family is about to write a note to disk.
license: MIT
metadata:
  version: "1.1.0"
---

# Write-checks

Bold terms in this file are defined in `GLOSSARY.md`.

## Prerequisite

Requires `.slipbox/AGENTS.md` to exist — its presence confirms `setup-slipbox` completed a full run, producing `.slipbox/config.json`, `.slipbox/style-profile.json`, and `.slipbox/humanize-checklist.json` along with it. If missing, stop and say so.

## Style

Read `.slipbox/style-profile.json` as the user's stated note-shape and editing preference contract. Follow its sentence shape, configured note-type tone, formatting, vocabulary, and editing preferences. Do not infer or mimic a corpus voice, and do not use the profile as a humanizer detection baseline.

## Humanize

Run the checklist's `detection.mechanical` section through
`.slipbox/bin/slipbox humanize check <draft-path>`. When the draft or passage language is known,
pass `--language LANG` so language-scoped signals skip non-English passages; without
the override, the CLI uses the profile's configured languages. It never reads profile
baselines and never dual-reads `stated_style.json`. Apply `detection.judgment` with
reading comprehension. Respect each signal's `single` or `cluster` policy, and keep
judgment signals out of CLI cross-signal counting.

If detection or judgment surfaces a flag, execute the checklist's declared
`rewrite` phase before writing: rewrite rather than delete, preserve meaning, and follow
the stated profile through `workflow.preference_context`. Then execute the required
`audit` phase and revise again if the audit finds a remaining pattern. The checklist
guides the workflow; it never rewrites a file automatically.

## Invocation modes

Called with a field list, `write-checks` runs Style, Humanize, Frontmatter fields, and
Zone placement — the full pass below. Called with no field list (already-resolved
fields, e.g. a Reference-note extension re-using its first write's mapping), it runs Style and
Humanize only, skipping Frontmatter fields and Zone placement entirely.

## Frontmatter fields

Given a note type and its field list (e.g. literature: `type`, `created`, `source`),
resolve each field through `.slipbox/config.json`'s `frontmatter.<type>` map:

- **Already resolved** (a bare string, `false`, or a full `{name, type, wikilink, zone}`
  object) — write under the mapped property, the standard name if new, or skip if
  `false`. No interactive step; this is the common case for every field `setup-slipbox`
  already resolved upfront.
- **Deferred** (`{"deferred": true}`) — this is the first time this note type is being
  written. Run the same interactive resolution `setup-slipbox`'s own field_map step
  would run: check whether an existing user property already holds this field's data
  (reading its actual discovered type — Text/List/Number/Checkbox/Date/Date & Time —
  never assuming one), and resolve one of map-onto-existing, create-standard-field, or
  explicit opt-out, following the same reserved-property guardrail (never `tags`,
  `aliases`, `cssclasses`, except Reference's `alt_names`→`aliases` carve-out) and the same
  type-mismatch check for multi-valued fields (`sources`, `derived-from`) that
  `setup-slipbox` uses. Write the resolved mapping back into `.slipbox/config.json`'s
  `frontmatter.<type>.<field>` before continuing — every subsequent write for this note
  type finds it already resolved and skips this branch entirely.

The field's own name is never the mapping. Format the value per the entry's recorded
`type` (a `list` type is a YAML array, a `date`/`datetime` type is `YYYY-MM-DD` or a full
timestamp), and wrap in wikilink or markdown-link syntax per the top-level
`links.style` when `wikilink: true`.

## Note-type prefix

Check `.slipbox/config.json`'s `prefixes.<type>` for this note type. If it's a string,
prepend it to the note's title (e.g. `§ Design Tokens`, not `Design Tokens`). If it's
`false`, the title stays unprefixed. Never touch `resources/` — no prefix key exists for
that type.

## Zone placement

Zone only places newly-created fields — a mapped-onto-existing field stays put. New
`top` fields sit right after the opening `---`; new `bottom` fields sit right before
the closing `---`.

## Done

Hand back: a pass/revise signal for style and humanize (revise before writing if
either flags a cluster), plus — on the full pass only — each resolved field's final
property name, formatted value, and placement (already-positioned, or the zone it
belongs in), and the resolved title prefix (or none), so the calling skill never
re-derives field_map, zone, or prefix logic itself. The checks-only mode hands back the
pass/revise signal alone.
