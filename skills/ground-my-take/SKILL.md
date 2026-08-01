---
name: ground-my-take
description: Ground a hunch into a Take — the user's own synthesized position, checked
  against existing notes it connects, then written as an evergreen note.
disable-model-invocation: true
license: MIT
metadata:
  version: "1.0.0"
---

# Ground-my-take

## What these words mean

- **Take** — the user's own position on an idea, requiring synthesis across sources or
  experience. Lives only in an evergreen note — never restates a single cited note
  unchanged.
- **Evergreen note** — the file a confirmed Take gets written into. Unlike a Claim,
  can be revisited: a later session may rewrite its content wholesale, not just add to
  it.

## Prerequisite

Requires `.slipbox/config.json` — same as every skill in this family. If it's missing,
stop and say so. Same check for `.slipbox/bin/idea-db` — if it doesn't exist or isn't
executable, stop and say so too. Every `idea-db` call below uses this same path,
`.slipbox/bin/idea-db` — never bare `idea-db`, which isn't guaranteed to be on `PATH`.

## Take the material

- **Named directly** → the user names specific existing notes to connect.
- **Bare, just a hunch** → search for anything related before starting; a hunch with
  nothing to check against is still a valid, complete session — see /grounding's own
  handling of "neither present."
- **From the backlog** → query the pending queue:

  ```bash
  .slipbox/bin/idea-db evergreen find --status to-discuss
  ```

  Offer these; let the user choose one. This is how a flagged tension from
  ground-claim or ground-term eventually gets picked up and turned into a real Take.

## Ground it

Run a /grounding session, holding yourself to whatever notes are in play — the user's
own answers are free here: personal experience, memory, anything not written down
anywhere. That freedom is the entire point of a Take. What must stay grounded is *your*
side of the conversation — your questions and reflections trace to what the retrieved
notes actually establish, never to your own training or memory (same rule as always,
just aimed at yourself instead of the user this time).

Orient the take with Compass (`references/compass.md`) — reach for whichever
direction the conversation calls for, no fixed order. If West (Connect) and East
(Challenge) both turn up something, run Distil (`references/distil.md`) next to
combine the two into a new position — never before both directions have produced
something to combine.

/grounding hands back the confirmed Take, and — only if the user opted in — a flagged
tension. If a tension came back, insert it into the same evergreen backlog this skill
itself reads from — ground-my-take, mid-synthesis, might notice its own tension needing
yet more grounding later:

```bash
.slipbox/bin/idea-db evergreen add --slug <draft-slug> --reason "<tension description>"
```

before moving on to writing.

## Purity check, before writing

Test each sentence in the draft: is it attributable to a single cited note's claim,
unchanged? If yes for any sentence, the conversation isn't done — keep sharpening until
the Take states something none of the individual notes said on their own.

## Write

- Run a /write-checks session on the draft, passing the evergreen field list (`type`,
  `created`, `derived-from`, `updated-at`) — it resolves each field's mapping,
  formatting, and zone placement, and checks the draft's style and humanize signals.
  `updated-at` gets `created`'s own timestamp on a first write, and is refreshed to the
  current time on a revisit.
- Filename per `.slipbox/config.json`'s casing convention for the evergreen type.
- Re-read the target path from disk right before writing.
- Assemble the frontmatter from write-checks' returned fields and write the file — a
  full rewrite of existing content on a revisit, since unlike a Claim this doesn't mean
  starting a new file.
- Cite every note it draws on, each with a one-line reason. Never link silently.
- Every citation also gets written as a links row:

  ```bash
  .slipbox/bin/idea-db links add --source <this-evergreen-slug> --target <cited-note-slug> --rel cites
  ```

  one call per cited note.
- Whether a citation is also rendered as an inline `[[wikilink]]` in the note's prose
  depends on a two-part test: (a) it has this links row (the mechanical baseline — only
  cited notes are ever eligible), and (b) the specific sentence containing the mention
  is actually asserting something about that note's subject, not just incidentally
  naming it while the sentence is really about something else.
- Filename collision on a first write → stop and ask, never auto-disambiguate. On a
  revisit, the existing file is expected — not a collision.

## Sign-off, shown to the user before finishing

- The title is a complete claim.
- Standalone-comprehensible by a future version of the user with no memory of this
  session.
- About one thing, entirely.
- Every link has a stated reason.
- The note answers, or spawns, a "so what / what's next."

## Done

The Take note exists on disk (or is updated, if revisiting), every cited note is linked
with a reason, any flagged tension is logged as its own backlog entry, and the user is
told the file path.

If this session's material came from the evergreen backlog rather than being freshly
named or a bare hunch, close out the row it drew from:

```bash
.slipbox/bin/idea-db evergreen update <slug> --status discussed --note-path <path>
```

Rename the slug too if this was a first write — same pattern as ground-term's own
"Write — new term" step. Bump `--iteration` instead if this is a revisit to an existing
evergreen note rather than a first write. The note's own `updated-at` frontmatter field
was already set in the Write section above — `created`'s timestamp on a first write,
refreshed to current time on a revisit.
