---
name: write-checks
description: Check a note draft against the vault's own style and humanize checklist, and resolve its frontmatter fields against config.json's field_map — use when another skill in the slipbox family is about to write a note to disk.
license: MIT
metadata:
  version: "1.5.0"
---

# Write-checks

Bold terms in this file are defined in `GLOSSARY.md`.

## Prerequisite

- MUST: `.slipbox/AGENTS.md`, `.slipbox/config.json`, `.slipbox/style-profile.json`, and `.slipbox/humanize-checklist.json` all exist — confirms `setup-slipbox` ran to completion.
- NEVER: proceed without all four. Stop and tell the user to run `setup-slipbox` first.

## Invocation modes

Called with a field list, `write-checks` runs Style, Humanize, Frontmatter fields, and
Zone placement — the full pass below. Called with no field list (already-resolved
fields, e.g. a Reference-note extension re-using its first write's mapping), it runs Style and
Humanize only, skipping Frontmatter fields and Zone placement entirely. Both modes then
validate the assembled artifact; checks-only mode validates the caller's complete draft
without resolving fields.

## Artifact validation

The caller supplies the complete draft, its note type, the intended final basename, and
the exact H1/title before writing. Run the bundled validator against that temporary file:

```bash
.slipbox/bin/slipbox note validate --type TYPE --path <temporary-draft> \
  --basename "<complete basename>.md" --title "<exact H1>"
```

The validator is the final authority for the assembled output. It checks the complete
basename and configured prefix position, mapped property names, YAML quoting and list
serialization, top/bottom field zones, one H1 and body order, and exactly one terminal
newline with no empty trailing paragraph. A failed result blocks writing until repaired.

Repair only unambiguous mechanical defects: prefix ordering, required scalar quoting,
mapped-field placement, configured block spacing, and extra trailing blank lines. Re-run
validation after every repair. Stop and ask the user for semantic conflicts, filename
collisions, uncertain titles, or uncertain protected names; never auto-disambiguate or
rewrite a claim to make validation pass.

After writing, re-read the exact saved path and run the same validation command against
the saved artifact. Do not report success when this post-write pass fails. If a caller
writes incrementally, validate the complete file after every claim that changes its
frontmatter or Markdown structure, and always run the final post-write pass after the
last closeout batch.

## Style

Read `.slipbox/style-profile.json` as the user's stated note-shape and editing preference contract. Follow its sentence shape, configured note-type tone, formatting, vocabulary, and editing preferences. If `formatting.blank_lines_between_blocks` is `false`, save compact Markdown: retain blank lines only for genuine semantic paragraph breaks or where Markdown parsing requires one. Do not insert them merely between a heading and prose, consecutive prose lines, prose and a list, list items and the next heading, or other adjacent blocks. If the key is absent, preserve the existing spaced behavior for compatibility. Do not infer or mimic a corpus voice, and do not use the profile as a humanizer detection baseline.

## Humanize

Run the checklist's `detection.mechanical` section through
`.slipbox/bin/slipbox humanize check <draft-path>`. When the draft or passage language is known,
pass `--language LANG` so language-scoped signals skip non-English passages; without
the override, the CLI uses the profile's configured languages. It reads `.slipbox/style-profile.json` only for language-gating (see Style section above for the rationale). Apply `detection.judgment` with
reading comprehension. Respect each signal's `single` or `cluster` policy, and keep
judgment signals out of CLI cross-signal counting.

If detection or judgment surfaces a flag, execute the checklist's declared
`rewrite` phase before writing: rewrite rather than delete, preserve meaning, and follow
the stated profile through `workflow.preference_context`. Then execute the required
`audit` phase and revise again if the audit finds a remaining pattern. The checklist
guides the workflow; it never rewrites a file automatically.

## Frontmatter fields

Given a note type and its field list (e.g. literature: `type`, `created`, `source`),
resolve each field via `.slipbox/bin/slipbox config get frontmatter.<type>.<field>`. The stored
shape for a resolved entry is defined canonically in `skills/setup-slipbox/assets/config.schema.json`'s
own `description` field — not restated here.

- **Already resolved** — write under the mapped property, the standard name if new,
  or skip per the schema's opt-out form. No interactive step; this is the common
  case for every field `setup-slipbox` already resolved upfront.
- **Deferred** (`{"deferred": true}`) — this is the first time this note type is being
  written. Run the same interactive resolution `setup-slipbox`'s own field_map step
  would run: check whether an existing user property already holds this field's data
  (reading its actual discovered type — Text/List/Number/Checkbox/Date/Date & Time —
  never assuming one), and resolve one of map-onto-existing, create-standard-field, or
  explicit opt-out, following the same reserved-property guardrail (never `tags`,
  `aliases`, `cssclasses`, except Reference's `alt_names`→`aliases` carve-out) and the same
  type-mismatch check for multi-valued fields (`sources`, `derived-from`) that
  `setup-slipbox` uses. Write the resolved mapping back via
  `.slipbox/bin/slipbox config set frontmatter.<type>.<field> <value>` before continuing — every subsequent write for this note
  type finds it already resolved and skips this branch entirely.

The field's own name is never the mapping. Format the value per the entry's recorded
`type` (a `list` type is a YAML array, a `date`/`datetime` type is `YYYY-MM-DD` or a full
timestamp, written bare/unquoted — never `"YYYY-MM-DD"` — consistent across every note
of that type), and wrap in wikilink or markdown-link syntax per
`.slipbox/bin/slipbox config get links.style` when `wikilink: true`.

## Note-type prefix

Check `.slipbox/bin/slipbox config get prefixes.<type>` for this note type. If it's a string,
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
re-derives field_map, zone, or prefix logic itself. Include the artifact-validation
result for the complete draft. The checks-only mode hands back the pass/revise signal
and validation result, with no resolved-field data.
