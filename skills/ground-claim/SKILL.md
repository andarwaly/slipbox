---
name: ground-claim
description: Ground a surfaced idea into a Claim — the source's own position, restated
  in the user's own words and checked against the source, then written as a literature note.
disable-model-invocation: true
license: MIT
metadata:
  version: "1.0.0"
---

# Ground-claim

## What these words mean

- **Idea** — a candidate question surfaced from a source, not yet anything more
  specific. What you're handed at the start.
- **Claim** — the source's own position on that idea, restated in the user's words and
  checked for fidelity. Never the user's opinion — an object of understanding, not
  agreement.
- **Literature note** — the file a confirmed Claim gets written into. One-shot: written
  once, never revisited.

## Prerequisite

Requires `.slipbox/config.json` — same as every skill in this family. If it's missing,
stop and say so.

## Take the idea

- **Bare invocation** → pick a pending candidate from `idea.db`
  (`target_type: 'literature'`, `status: 'to-discuss'`).
- **Handed material directly** → take the specific idea and its source.

This skill only ever accepts an already-surfaced idea. If given a raw, unprocessed
source with nothing singled out yet, say so:

> "this hasn't been surfaced yet — run `/surface-ideas` first"

Never attempt to process a raw source here.

## Ground it

Run a /grounding session, holding the user to the source. If a term comes up
mid-session that already has (or could start) its own Term note, propose linking it with
a one-line reason — the user accepts or rejects each one individually, never linked
silently.

/grounding hands back two things when it finishes: the confirmed Claim, and — only if
the user opted in — a flagged tension. If a tension came back, insert it into the
evergreen backlog:

```bash
idea-db evergreen add --slug <draft-slug> --reason "<tension description>"
```

before moving on to writing.

## Write

Once confirmed:

- Run a /write-checks session on the draft before writing.
- Re-read the target path from disk right before writing.
- Filename per `.slipbox/config.json`'s casing convention for the literature type.
- For each literature field (`type`, `created`, `source`), look up its mapping in
  `.slipbox/config.json`'s `frontmatter.literature`: write it under whichever existing
  property that field maps onto, or under the standard name if newly created — skip the
  field entirely if it's mapped to `false`. Never assume the field name is the mapping.
  Format the value per the entry's recorded `type` (e.g. a `list` type is a YAML array,
  a `date` type is `YYYY-MM-DD`), and if `wikilink: true`, wrap each value per
  `config.json`'s top-level `links.style` (wikilink or markdown link — don't hardcode).
- One-shot — write once, never revisit.
- Filename collision → stop and ask, never auto-disambiguate.

## Close the backlog row

Flip the original `seeds` row: `status` → `'discussed'`, note path attached.

## Done

The Claim note exists on disk, the backlog row is closed, any flagged tension is logged
in the evergreen backlog, and the user is told the file path.
