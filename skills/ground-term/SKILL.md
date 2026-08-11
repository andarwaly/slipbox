---
name: ground-term
description: Ground a term into a cumulative Term note — a running, per-term
  definition that may draw on multiple sources over separate sessions.
disable-model-invocation: true
license: MIT
metadata:
  version: "1.0.0"
---

# Ground-term

## What these words mean

- **Term** — a named concept, method, tool, or bias with a stable label, independent of
  any one source (e.g. "confirmation bias," "CRDT") — not a source's own argued
  organizing scheme.
- **Term note** — the cumulative file a term's definition lives in. Unlike a Claim,
  never one-shot: extended across however many sources touch this term, over however
  many separate sessions. Only ever appends or extends — never overwrites what's
  already there.

## Prerequisite

Requires `.slipbox/config.json` — same as every skill in this family. If it's missing,
stop and say so. Same check for `.slipbox/bin/slipbox` — if it doesn't exist or isn't
executable, stop and say so too. Every `slipbox` call below uses this same path,
`.slipbox/bin/slipbox` — never bare `slipbox`, which isn't guaranteed to be on `PATH`.

## Take the term

Named directly, only — the user says which term they want grounded, whether they
thought of it themselves or because `/find-terms` suggested it. There is no backlog to
pull from; term recurrence is derived on demand, not surfaced into a queue.

Per `.slipbox/config.json`'s `paths.term` and filename/casing convention for the Term
type, check whether a Term note for this term already exists — under that configured
folder, not an assumed `term/` folder — before grounding:

- **New term** — no note exists. Proceed planning to create one.
- **Extending** — a note already exists. Read it in full now. You'll ground the
  discussion against it and fold the new resource into it later; the file's own
  accumulated text is the working summary of everything before it, not its historical
  resource list.

## Ground it

Run a /grounding session, holding the user to whichever source (or sources) this
particular mention of the term traces back to. If the term note already exists, treat
its current content as material too — the user's new answer must stay consistent with
what's already recorded, not contradict it silently.

/grounding hands back the confirmed definition, and — only if the user opted in — a
flagged tension. If a tension came back, insert it into the evergreen backlog before
moving on to writing:

```bash
.slipbox/bin/slipbox evergreen add --slug <draft-slug> --reason "<tension description>"
```

## Write — new term

Write fresh:

- Run a /write-checks session on the draft, passing the Term field list (`type`,
  `created`, `sources`, plus `alt_names` if any were given) — it resolves each field's
  mapping, formatting, zone placement, and title prefix, and checks the draft's style
  and humanize signals.
- Write into `paths.term` from `.slipbox/config.json`, filename per that same config's
  casing convention for the Term type.
- Re-read the target path from disk right before writing.
- Assemble the frontmatter from write-checks' returned fields and write the file.
- Filename collision → stop and ask, never auto-disambiguate.

## Write — extending an existing term

**This is the collision-safe path. Follow it exactly.**

`sources` already has its resolved mapping and formatting from the term's first write —
no field resolution needed here.

1. Run a /write-checks session on the draft in its checks-only mode (no field list).
2. Re-read the file from disk immediately before writing (state can have changed since
   the read in "Take the term").
3. Append the new resource to the `sources` frontmatter array, formatted per its
   existing recorded `type` (list) and `wikilink` flag, and write the file. Never
   overwrite the file wholesale.
4. Insert a `links` row recording the relationship — this term's own note is the target,
   the resource being folded in is the source:

   ```bash
   .slipbox/bin/slipbox links add --source <this-resource-slug> --target <term-note-slug> --rel extends
   ```

## Done

- New term: the file on disk reflects the confirmed definition.
- Extension: the file on disk reflects every resource that has ever fed it, old and
  new; a `links` row (`rel_type: 'extends'`) connects the new resource to the term note.
- Any flagged tension is logged in the evergreen backlog.
- The user is told the file path.
