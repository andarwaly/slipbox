---
name: make-evergreen-note
description: Ground a hunch into a Take — the user's own synthesized
  position, checked against existing notes it connects, then written as an
  evergreen note.
license: MIT
metadata:
  version: "1.7.0"
---

# Make-evergreen-note

Bold terms in this file are defined in `GLOSSARY.md`.

## Prerequisite

- MUST: `.slipbox/AGENTS.md` exists — confirms `setup-slipbox` ran to completion.
- NEVER: proceed without it. Stop and tell the user to run `setup-slipbox` first.
- NEVER: call bare `slipbox` — always `.slipbox/bin/slipbox`, which isn't guaranteed to be on `PATH`.

## Workflow

### 01 - Take the material

- **Named directly** → the user names specific existing notes to connect.
- **Bare, just a hunch** → search for anything related before starting; a
  hunch with nothing to check against is still a valid, complete session —
  see `/grounding`'s own handling of "neither present."
- **From the backlog** → query the pending queue. The installed
  `.slipbox/AGENTS.md` is the canonical reference for backlog semantics and
  lifecycle; this skill retains the command it executes:

  ```bash
  .slipbox/bin/slipbox evergreen find --status to-discuss
  ```

  Offer these; let the user choose one. This is how a flagged tension from
  `make-literature-note` — or a spawned Compass sub-idea from a prior
  `make-evergreen-note` session — eventually gets picked up and turned
  into a real Take.

### 02 - Ground it

Run a `/grounding` session, holding yourself to whatever notes are in
play — the user's own answers are free here: personal experience, memory,
anything not written down anywhere. That freedom is the entire point of a
Take. What must stay grounded is *your* side of the conversation — your
questions and reflections trace to what the retrieved notes actually
establish, never to your own training or memory (same rule as always, just
aimed at yourself instead of the user this time). This is the
Fidelity-direction parameter you supply to `/grounding` when the session
starts.

Orient the take with the Compass technique — reach for whichever direction
the conversation calls for, no fixed order. Compass's own
directions may recurse into fresh sub-ideas; an unpursued spawned sub-idea
gets logged to the evergreen backlog (see Compass's own Guardrail).

`/grounding` hands back the confirmed Take, and — only if the user opted
in — a flagged tension. If a tension came back, insert it into the evergreen
backlog:

```bash
.slipbox/bin/slipbox evergreen add --slug <draft-slug> --reason "<tension description>"
```

before moving on to writing.

Before writing, run a purity check on the draft: test each sentence — is it
attributable to a single cited note's claim, unchanged? If yes for any
sentence, the conversation isn't done — keep sharpening until the Take
states something none of the individual notes said on their own.

### 03 - Write

- Run a `/write-checks` session on the draft, passing the evergreen field
  list (`type`, `created`, `derived-from`, `updated-at`) — it resolves each
  field's mapping, formatting, and zone placement, and checks the draft's
  style and humanize signals. `updated-at` gets `created`'s own timestamp
  on a first write, and is refreshed to the current time on a revisit.
- Write into the folder from `.slipbox/bin/slipbox config get paths.evergreen`, filename per
  `.slipbox/bin/slipbox config get filenames.evergreen` casing convention.
- Re-read the target path from disk right before writing.
- Assemble the frontmatter from `/write-checks`' returned fields and write
  the file — a full rewrite of existing content on a revisit, since unlike
  a literature note this doesn't mean starting a new file.
- Cite every note it draws on, each with a one-line reason. Never link
  silently.
- Every citation also gets written as a links row:

  ```bash
  .slipbox/bin/slipbox links add --source <this-evergreen-slug> --target <cited-note-slug> --rel cites
  ```

  one call per cited note.
- Whether a citation is also rendered as an inline `[[wikilink]]` in the
  note's prose depends on a two-part test: (a) it has this links row (the
  mechanical baseline — only cited notes are ever eligible), and (b) the
  specific sentence containing the mention is actually asserting something
  about that note's subject, not just incidentally naming it while the
  sentence is really about something else.
- Filename collision on a first write → stop and ask, never
  auto-disambiguate. On a revisit, the existing file is expected — not a
  collision.

### 04 - Sign-off, shown to the user before finishing

- The title is a complete claim.
- Standalone-comprehensible by a future version of the user with no memory
  of this session.
- About one thing, entirely.
- Every link has a stated reason.
- The note answers, or spawns, a "so what / what's next."

These five criteria draw on Matuschak's and Ahrens' evergreen/permanent-note
theory, including a real tension between the two the skill deliberately
sides on — see `references/sign-off-theory.md` for the rationale.

## Done

The Take note exists on disk (or is updated, if revisiting), every cited
note is linked with a reason, any flagged tension is logged as its own
backlog entry, and the user is told the file path.

If this session's material came from the evergreen backlog rather than
being freshly named or a bare hunch, close out the row it drew from:

```bash
.slipbox/bin/slipbox evergreen update <slug> --status discussed --note-path <path>
```

Apply the installed `.slipbox/AGENTS.md` Backlog contract for lifecycle details,
including first-write slug renames, revisit iteration bumps, and the candidate's
note-path/updated-at bookkeeping. The note's own `updated-at` frontmatter field
was already set in the Write section above.

## References

| File | Purpose | Triggering condition |
|---|---|---|
| `references/sign-off-theory.md` | Matuschak's/Ahrens' evergreen/permanent-note theory the Sign-off criteria draw on, including the audience-tension the skill deliberately sides on | Rationale lookup when a Sign-off criterion needs justifying, not routine sign-off itself |
