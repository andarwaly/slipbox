---
name: write-literature-note
description: From a candidate idea and its source to a finished, Claim-only literature note, via a real Socratic discussion. Reads ideas surfaced earlier by surface-ideas; can run in a separate session.
disable-model-invocation: true
license: MIT
metadata:
  version: "1.0.0"
---

# Write Literature Note

This skill turns one `surface-ideas` candidate into a finished literature note: a single Claim, grounded against the one source it came from. It does not surface candidates itself (`surface-ideas`'s job) and it does not hold the conversation itself (`discussion`'s job, mode `literature`) — it picks the candidate, frames the session, and handles everything before and after the conversation: writing the note and flipping the `seeds` row.

## 0. Prerequisite: `.slipbox/config.json` must exist

Check first, before anything else. This skill queries `.slipbox/idea.db`, which only exists once `setup-slipbox` has run.

If `.slipbox/config.json` is absent: stop. Do not proceed to any other step. Tell the user to run `setup-slipbox` first, then re-run this skill.

## 1. Resume check, first

Before offering any new work, list `.slipbox/discussions/` for files with `mode: literature` in their frontmatter. If any exist, offer to resume one before offering to start something new.

**If resuming:** the resume file's frontmatter carries `idea_slug` and `resource` — read both off the file directly rather than re-querying `seeds`. Pass them to `discussion` as the session's starting context exactly as Step 3 describes, along with the resume file's own `phase`/draft/open-threads content, so the conversation continues with the same source it was grounded against before the pause. Skip Step 2 entirely in this branch; there is no new candidate to pick.

**Done when:** either a resume file was picked up (with its `idea_slug` and `resource` in hand) and handed to `discussion`, or none exist / the user declined and you're proceeding to Step 2.

## 2. Pick a candidate

Query `seeds` for the pending backlog:

```sql
SELECT * FROM seeds WHERE target_type='literature' AND status='to-discuss';
```

Scope to one resource by default if the user named one; run the full cross-resource backlog on request; order by `created_at` on request. Present the candidates and let the user pick.

The user may also dismiss a candidate without discussing it: set `status: 'dismissed'`, leave `reason` untouched, done — no `discussion` invocation for a dismissal.

**Done when:** one candidate row is picked to discuss, or the user dismissed one and there's nothing further to do this run.

## 3. Invoke `discussion`

Run a `/discussion` session (mode `literature`, see `discussion/references/mode-literature.md`), framed as: source-bound, one idea against its one source. The user stays grounded to the author's claim; flag drift, log to `idea.db`. Gate: Claim confirmed.

Pass the picked row's `slug`, `resource`, and `reason` as the session's starting context.

**Done when:** `discussion` returns control with a confirmed Claim.

## 4. On completion, write the note

`discussion` hands back a confirmed Claim. Write the literature note:

- **Filename**: derived from the confirmed claim text, casing per `.slipbox/config.json`, no author prefix.
- **Frontmatter** (per `setup-slipbox`'s field_map): `type: literature`, `created`, `source: [[resource]]`.

**Filename collision:** stop and ask — reword the claim, or confirm this is a genuine duplicate. Never auto-disambiguate the filename.

Re-read the file from disk immediately before writing, even for a brand-new filename — this catches a collision created moments earlier in the same session.

**Done when:** the note file exists on disk with the confirmed Claim and correct frontmatter.

## 5. Flip the `seeds` row

Rename-in-place, one row, ever:

```sql
UPDATE seeds
SET type='literature', status='discussed', note_path=<path>, slug=<final-claim-slug>
WHERE slug=<original-slug>;
```

**Done when:** the row now reflects the written note's path and final slug.

## 6. Delete the resume file

`discussion` should have already deleted `.slipbox/discussions/<slug>.md` on completion. Confirm it's actually gone; delete it here if it somehow wasn't.

**Done when:** no resume file remains for this candidate.

## 7. Done when

- The note on disk matches the confirmed Claim, with correct frontmatter.
- The `seeds` row is flipped (`type`, `status`, `note_path`, `slug`).
- The resume file is gone.
- The user has been told the note's path.
