---
name: write-evergreen-note
description: Turn a connective aha or an open-ended "let's think this through" into a new, purely original evergreen note — via a real Socratic discussion, grounded in retrieved existing notes. Can be revisited across sessions; the note may evolve.
disable-model-invocation: true
license: MIT
metadata:
  version: "1.0.0"
---

# Write Evergreen Note

This skill writes or evolves an evergreen note: a connection that states something none of the individually cited notes said on their own, produced through a real Socratic discussion grounded against what's actually retrieved from `idea.db`. It does not run the discussion itself — `discussion` (mode `evergreen`) handles the FTS5 retrieval, the Socratic techniques, the grounding rule, the purity rule, and the sign-off rubric internally. This skill owns the `evergreen` row lifecycle, the note file, and the `links` rows.

## 0. Prerequisite: `.slipbox/config.json` must exist

Check first, before anything else. This skill retrieves from and writes to `.slipbox/idea.db`, which only exists once `setup-slipbox` has run.

If `.slipbox/config.json` is absent: stop. Do not proceed to any other step. Tell the user to run `setup-slipbox` first, then re-run this skill.

## 1. No fixed trigger

Starts whenever the user wants to think something through — one or more named notes, a rough hunch, or both. There's no required shape to how they bring it: "does X connect to Y," "I keep coming back to this idea," "let's think through Z." Don't ask for a specific format; take whatever they open with.

## 2. Resume check, first

Before anything else, list `.slipbox/discussions/` for files with `mode: evergreen`. Offer to resume any found before offering to start new work.

- **Resuming:** the resume file names the still-provisional (draft-prefixed) slug. Load the existing placeholder `evergreen` row by that slug and continue the discussion from where the resume file left off. Treat any previously-retrieved notes as possibly stale — the session may have paused for days — and have `discussion` re-verify them against `idea.db` rather than trusting the resume file's summary of their content; a note cited earlier could have been edited or reworded since.
- **Not resuming:** proceed to Step 3.

**Done when:** you know whether this is a resume or a new session.

## 3. New session: insert the placeholder row

After the first substantive exchange (the user has actually answered the first question, not merely been asked it), insert the placeholder row:

```sql
INSERT INTO evergreen (slug, status, note_path, iteration)
VALUES (<draft-prefixed-slug>, 'discussing', NULL, 1);
```

The slug is provisional at this point — draft-prefixed (e.g. `draft-tool-shapes-cognition-atomic-ideas`), not yet the final claim-style slug. This is also the point at which `discussion`'s resume-file discipline creates `.slipbox/discussions/<slug>.md` — see that skill's shared rules.

## 4. Invoke `discussion`, mode evergreen

Run a `/discussion` session, mode `evergreen` (see `discussion/references/mode-evergreen.md`), framed as: retrieval-bound, drawing on `idea.db` for related literature/reference notes. The agent stays grounded to what's retrieved; the user answers freely. Gate: Take confirmed.

`discussion` handles the FTS5 retrieval, the Socratic techniques, the grounding rule, the purity rule, and the sign-off rubric internally (per its evergreen mode). This skill does not re-implement any of that — do not query `seeds_fts` directly, do not apply the purity rule yourself, do not run the sign-off rubric yourself. Hand off to `discussion` and wait for it to report the Take fixed.

## 5. On completion: update the row, write the note

Once `discussion` reports the Take fixed:

```sql
UPDATE evergreen
SET slug = <final-claim-style-slug>, note_path = <path>, status = 'discussed'
WHERE slug = <draft-prefixed-slug>;
```

The draft prefix is stripped; the provisional slug is replaced by the final claim-style slug.

Write the note:

- **Frontmatter:** `type: evergreen`, `created`, `derived-from: [...]` as a bare list of every feeding note's slug.
- **Body:** cites each feeding note with a one-line stated reason, in prose — not relegated to frontmatter. Every link needs its reason stated where a reader will actually see it.

**Filename collision:** stop and ask the user to reword the claim, or confirm this is a genuine duplicate. Never auto-disambiguate the filename.

**Done when:** the file is written, the `evergreen` row reflects the final slug/path/status, and the resume file for this session is gone (per `discussion`'s lifecycle-end rule: the calling skill deletes it, not `discussion` itself).

## 6. `links` rows

For every note cited in the write-up, insert one row, only now, at write time — never earlier in the conversation:

```sql
INSERT INTO links (source_id, target_id, rel_type)
VALUES (<this evergreen slug>, <cited slug>, 'cites');
```

One `INSERT` per cited note.

## 7. Revisiting an existing evergreen note

The user can bring an already-discussed evergreen note back for new thinking at any later session:

1. `status` moves back to `discussing`.
2. Re-read the note file from disk — fresh, not from memory of a prior session.
3. Run `discussion` (mode `evergreen`) again, same as Step 4.
4. On completion, the rewrite **can replace the note's existing content wholesale** — unlike reference notes, which only append. This is the one place in the slipbox family where a full rewrite is allowed.
5. `iteration` increments; `status` returns to `discussed`; `updated_at` bumps via the trigger (no manual update needed for `updated_at`).
6. Re-run Step 6 for whatever set of notes the rewritten version actually cites — this may add, drop, or leave unchanged the prior citation set.

## 8. Done when

- The note on disk reflects the confirmed connection.
- Every feeding note is cited with a stated reason.
- The write passes `discussion`'s sign-off rubric.
- No sentence in the note merely restates one cited note's claim un-transformed (the purity rule, enforced by `discussion`, held all the way through to the final write).
- The `evergreen` row is correct: final slug, `note_path`, `status: discussed`, correct `iteration`.
- `links` rows are correct: one `cites` row per note actually cited in the final text.
- The resume file for this session is gone.
