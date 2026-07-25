---
name: write-reference-note
description: Manually-triggered, definitional note for a term or source that recurs across your notes, or that you're simply curious about — via a real Socratic discussion. Not tied to any single clip's outcome; grows over time as more resources touch it.
disable-model-invocation: true
license: MIT
metadata:
  version: "1.0.0"
---

# Write Reference Note

This skill writes or extends a reference note: a definition of a term, answering "what is X." No detector watches for recurrence and this skill never fires on its own — it starts only from one of the two trigger paths below. The actual conversation that produces the definition happens inside `discussion`, mode `reference`; this skill's job is framing that call correctly and handling the `seeds`/`links` bookkeeping around it.

## 0. Prerequisite: `.slipbox/config.json` must exist

Check first, before anything else. This skill queries `.slipbox/idea.db`, which only exists once `setup-slipbox` has run.

If `.slipbox/config.json` is absent: stop. Do not proceed to any other step. Tell the user to run `setup-slipbox` first, then re-run this skill.

## 1. Resume check, first

Before offering either trigger path below, list `.slipbox/discussions/` for files with `mode: reference` in their frontmatter. If any exist, offer to resume one before offering to start something new.

**If resuming:** read `idea_slug` and `resource` straight off the resume file's frontmatter — the term and its named resource(s) — instead of running Step 2's trigger paths or Step 3's existing-note check from scratch. Pass them to `discussion` as the session's starting context per Step 4, along with the resume file's `phase`/draft/open-threads content.

**Done when:** either a resume file was picked up (with its `idea_slug` and `resource` in hand) and handed to `discussion`, or none exist / the user declined and you're proceeding to Step 2 below.

## 2. Trigger

Two paths in:

- **Named directly.** The user brings a term to this skill themselves — noticed it recurring, or just curious. Ask which term if it isn't already obvious from context.
- **Pending reference candidates.** The user works through the queue: `SELECT * FROM seeds WHERE target_type='reference' AND status='to-discuss'` — the same mechanism `write-literature-note` uses for its own picks. Offer these; let the user choose one.

**Done when:** you have one term to work from, and (if from the candidate path) its `seeds` row.

## 3. Check existing

Per `.slipbox/config.json`'s filename/casing convention, look for an existing reference note for this term.

- **New term:** no note exists — proceed planning to create one.
- **Extending:** a note already exists — read it in full now. You'll ground the discussion against it and fold the new resource into it later; don't re-read its historical resource list, the file's own accumulated text is the working summary of everything before it.

## 4. Invoke `discussion`

Run a `/discussion` session, mode `reference` (see `discussion/references/mode-reference.md`), framed inline as: "definitional, one or more named resources. The user stays grounded to the definition; the agent flags drift into personal opinion. Gate: definition confirmed." Pass in:

- the term
- the resource(s) named for it
- if extending: the existing note's current content, read fresh in Step 3

## 5. On completion — new term

Write fresh. Filename = the term as the user writes it, per `.slipbox/config.json` conventions. Frontmatter: `type: reference`, `created`, `sources: [[resource]]`, plus `aliases: [...]` if any were given.

`seeds` bookkeeping — rename-in-place, same as literature, because this really is the term's first occurrence:

```sql
UPDATE seeds
SET type = 'reference', status = 'discussed', note_path = '<new-path>', slug = '<final-slug>'
WHERE slug = '<original-slug>';
```

## 6. On completion — extending an existing term

**This is the PK-collision-safe path. Follow it exactly.**

The trap: this row's slug cannot be renamed to the term's final slug, because that slug is already claimed — the term's first occurrence already renamed *its* row to it in Step 5, and `seeds.slug` is the primary key. Renaming this row to the same value would collide with that existing row. So this row keeps its own original slug, permanently.

1. **Update this row in place — do not touch its slug:**

   ```sql
   UPDATE seeds
   SET type = 'reference', status = 'discussed', note_path = '<the EXISTING note''s path>'
   WHERE slug = '<this row's original, unchanged slug>';
   ```

2. **Insert a `links` row recording the relationship** — this row's own (unchanged) slug is the source, the existing reference row's slug is the target:

   ```sql
   INSERT INTO links (source_id, target_id, rel_type)
   VALUES ('<this row's slug>', '<existing reference row's slug>', 'extends');
   ```

3. **Fold the new resource's contribution into the existing file.** Re-read the file from disk immediately before writing (state can have changed between Step 3's read and now). Append/extend only — add the new resource to the `sources` frontmatter array, and fold in whatever the new resource adds or complicates about the term. Never overwrite the file wholesale.

Why this is correct: exactly one `seeds` row per term ever holds the term's "canonical" final slug (the first occurrence, renamed in Step 5). Every subsequent extending resource keeps its own distinct, never-renamed slug, and is connected to the canonical row purely through the `links` table (`rel_type: 'extends'`) — never by trying to share or reassign the primary key.

## 7. Done when

- The file on disk reflects the confirmed definition and every resource that has ever fed it, old and new.
- New term: the `seeds` row is renamed and flipped to `type='reference', status='discussed'`.
- Extension: the extending row is flipped in place (unchanged slug, `note_path` pointing at the existing file) and a `links` row (`rel_type: 'extends'`) connects it to the canonical row.
