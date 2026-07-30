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
stop and say so.

## Take the term

- **Named directly** → the user says which term they want grounded.
- **From the backlog** → query the pending queue:

  ```bash
  idea-db seeds find --target-type term --status to-discuss
  ```

  Offer these; let the user choose one.

Per `.slipbox/config.json`'s filename/casing convention, check whether a Term note for
this term already exists before grounding:

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
flagged tension. If a tension came back, insert it as its own `seeds` row
(`target_type: 'literature'`, since a term-grounding tension is source-facing, not a
personal synthesis) before moving on to writing:

```bash
idea-db seeds add --resource <resource> --type raw --target-type literature --reason "<tension description>"
```

## Write — new term

Write fresh:

- Prose should read consistent with `.slipbox/style-profile.json` (or `.slipbox/stated_style.json`
  if no corpus exists) — voice, tone, punctuation fingerprint, lexicon, language/code-switching
  pattern — not a generic register.
- After drafting, apply `humanize-checklist.json`'s `judgment` section directly and run its
  `mechanical` section via `idea-db humanize check <draft-path>`; if either flags a cluster, revise
  before writing the file, don't write first and check after.
- Re-read the target path from disk right before writing.
- Filename and frontmatter per `.slipbox/config.json`'s conventions for the Term type:
  `type: term`, `created`, `sources: [[resource]]`, plus `aliases: [...]` if any were
  given.

Flip the `seeds` row in place — this really is the term's first occurrence, so the slug
can be renamed:

```bash
idea-db seeds update <original-slug> --type term --status discussed --note-path <new-path> --slug <final-slug>
```

## Write — extending an existing term

**This is the PK-collision-safe path. Follow it exactly.**

The trap: this row's slug cannot be renamed to the term's final slug, because that slug
is already claimed — the term's first occurrence already renamed *its* row to it, and
`seeds.slug` is the primary key. Renaming this row to the same value would collide with
that existing row. So this row keeps its own original slug, permanently.

1. **Update this row in place — do not touch its slug:**

   ```bash
   idea-db seeds update <this-row-original-slug> --type term --status discussed --note-path <existing-note-path>
   ```

2. **Insert a `links` row recording the relationship** — this row's own (unchanged)
   slug is the source, the existing term row's slug is the target:

   ```bash
   idea-db links add --source <this-row-slug> --target <existing-term-row-slug> --rel extends
   ```

3. **Fold the new resource's contribution into the existing file.** Re-read the file
   from disk immediately before writing (state can have changed since the read in
   "Take the term"). Append/extend only — add the new resource to the `sources`
   frontmatter array, and fold in whatever the new resource adds or complicates about
   the term. Never overwrite the file wholesale.

Why this is correct: exactly one `seeds` row per term ever holds the term's
"canonical" final slug (the first occurrence). Every subsequent extending resource
keeps its own distinct, never-renamed slug, connected to the canonical row purely
through the `links` table (`rel_type: 'extends'`) — never by sharing or reassigning the
primary key.

## Done

- New term: the file on disk reflects the confirmed definition; the `seeds` row is
  renamed and flipped (`type='term'`, `status='discussed'`).
- Extension: the file on disk reflects every resource that has ever fed it, old and
  new; the extending row is flipped in place (unchanged slug, `note_path` pointing at
  the existing file); a `links` row (`rel_type: 'extends'`) connects it to the
  canonical row.
- Any flagged tension is logged as its own `seeds` row.
- The user is told the file path.
