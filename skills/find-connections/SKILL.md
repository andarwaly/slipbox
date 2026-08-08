---
name: find-connections
description: Scan existing notes for missing links and sparked ideas — splits mechanical link suggestions (batch-confirmed) from generative ideas (routed to the evergreen backlog).
disable-model-invocation: true
license: MIT
metadata:
  version: "1.0.0"
---

# Find-connections

## Prerequisite

Requires `.slipbox/config.json` and `.slipbox/bin/slipbox` — same as every skill in this
family. Every `slipbox` call below uses this same path, `.slipbox/bin/slipbox` — never
bare `slipbox`.

## Scan

Read across existing literature, term, and evergreen notes for two genuinely different
things — don't conflate them:

- **A link worth adding** — two notes are related but not yet wikilinked. Check
  `.slipbox/bin/slipbox links find --source <slug>` first; never re-suggest a pair that
  already has a `links` row.
- **A sparked idea** — noticing two or more existing notes together produces something
  neither one states alone. This is generative, not mechanical — it needs full
  `ground-my-take` grounding before it's a real Take, not a citation edit.

## Present link suggestions as a batch

Show every candidate link together, not one at a time — there's no dependency chain
between suggestions the way `/grounding`'s Socratic questions have, so reviewing them
together is strictly less friction than one full turn per candidate. The user approves,
rejects, or edits each one in one pass.

For each approved suggestion:

```bash
.slipbox/bin/slipbox links add --source <slug> --target <slug> --rel cites
```

Then add the matching `[[wikilink]]` in whichever note's prose the connection belongs
to, per the existing two-part criterion: it needs the `links` row above as a mechanical
baseline, and the specific sentence must actually assert something about the linked
note's subject, not just incidentally name it.

## Route sparked ideas to the evergreen backlog

For each sparked idea, insert it as its own candidate — never write a note directly, and
never fold it into a link suggestion:

```bash
.slipbox/bin/slipbox evergreen add --slug <draft-slug> --reason "<the spark, described>"
```

`ground-my-take` picks these up from its own backlog read, same as any other flagged
tension.

## Done

Every approved link is written (both the `links` row and, where the criterion is met,
the inline wikilink); every sparked idea is logged in the evergreen backlog, not written
as a note. The user is told what was added and what was routed to the backlog.
