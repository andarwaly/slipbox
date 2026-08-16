---
name: make-evergreen-note
description: Ground a hunch into a Take — the user's own synthesized
  position, checked against existing notes it connects, then written as an
  evergreen note.
license: MIT
metadata:
  version: "1.1.0"
---

# Make-evergreen-note

## What these words mean

- **Take** — the user's own position on an idea, requiring synthesis across
  sources or experience. Lives only in an evergreen note — never restates
  a single cited note unchanged.
- **Evergreen note** — the file a confirmed Take gets written into. Unlike
  a literature note, can be revisited: a later session may rewrite its
  content wholesale, not just add to it.

## Prerequisite

Requires `.slipbox/config.json` — same as every skill in this family. If
it's missing, stop and say so. Same check for `.slipbox/bin/slipbox` — if
it doesn't exist or isn't executable, stop and say so too. Every `slipbox`
call below uses this same path, `.slipbox/bin/slipbox` — never bare
`slipbox`, which isn't guaranteed to be on `PATH`.

## Take the material

- **Named directly** → the user names specific existing notes to connect.
- **Bare, just a hunch** → search for anything related before starting; a
  hunch with nothing to check against is still a valid, complete session —
  see `/grounding`'s own handling of "neither present."
- **From the backlog** → query the pending queue:

  ```bash
  .slipbox/bin/slipbox evergreen find --status to-discuss
  ```

  Offer these; let the user choose one. This is how a flagged tension from
  `make-literature-note` — or a spawned Compass sub-idea from a prior
  `make-evergreen-note` sitting — eventually gets picked up and turned
  into a real Take.

## Ground it

Run a `/grounding` session, holding yourself to whatever notes are in
play — the user's own answers are free here: personal experience, memory,
anything not written down anywhere. That freedom is the entire point of a
Take. What must stay grounded is *your* side of the conversation — your
questions and reflections trace to what the retrieved notes actually
establish, never to your own training or memory (same rule as always, just
aimed at yourself instead of the user this time). This is the
Fidelity-direction parameter you supply to `/grounding` when the session
starts.

Orient the take with `references/compass.md` (now living inside
`grounding`, alongside its own supporting techniques) — reach for whichever
direction the conversation calls for, no fixed order. Compass's own
directions may recurse into fresh sub-ideas; an unpursued spawned sub-idea
gets logged to the evergreen backlog the same way any other flagged tension
does (see Compass's own Guardrail).

`/grounding` hands back the confirmed Take, and — only if the user opted
in — a flagged tension. If a tension came back, insert it into the same
evergreen backlog this skill itself reads from:

```bash
.slipbox/bin/slipbox evergreen add --slug <draft-slug> --reason "<tension description>"
```

before moving on to writing.

## Purity check, before writing

Test each sentence in the draft: is it attributable to a single cited note's
claim, unchanged? If yes for any sentence, the conversation isn't done —
keep sharpening until the Take states something none of the individual
notes said on their own.

## Write

- Run a `/write-checks` session on the draft, passing the evergreen field
  list (`type`, `created`, `derived-from`, `updated-at`) — it resolves each
  field's mapping, formatting, and zone placement, and checks the draft's
  style and humanize signals. `updated-at` gets `created`'s own timestamp
  on a first write, and is refreshed to the current time on a revisit.
- Write into `paths.evergreen` from `.slipbox/config.json`, filename per
  that same config's casing convention for the evergreen type.
- Re-read the target path from disk right before writing.
- Assemble the frontmatter from `write-checks`' returned fields and write
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

## Sign-off, shown to the user before finishing

### Concept

These five criteria draw on Matuschak's evergreen-notes practice (verbatim,
primary — `notes.andymatuschak.org`) and Ahrens' permanent-note rules
(*How to Take Smart Notes*), cross-verified independently across two
research passes:

- **Atomic** — "notes which are only about one thing—but which, as much as
  possible, capture the entirety of that thing" (Matuschak). Not a brevity
  rule: both over-broad and over-fragmented notes are failure modes, "a
  bunch of tradeoffs," not a fixed litmus test.
- **Concept-oriented** — factored by idea, never by source/author/project.
  Matuschak's own reasoning: source-factored notes on the same concept
  never accumulate into anything stronger, "just a scattered set of
  notes... perhaps referring to it by different names."
- **Titles as claims** — "declarative or imperative phrases making a
  strong claim... titles are like APIs." Difficulty titling a note is
  itself diagnostic — a sign the thinking is muddy or the note covers more
  than one thing, not a wording problem to push through.
- **Densely linked, every link labeled** — linking is "deliberate
  sense-making pressure," not filing; "prefer labeled associations" over a
  bare "X relates to Y."

**A real tension, not resolved by picking a side quietly**: Ahrens'
permanent-note rule states notes should be written "as if for someone
else — full sentences, precise, clear." Matuschak argues the opposite:
"write notes for yourself by default, disregarding audience" — writing for
a reader during note-writing itself "substantially increases the
overhead... often to the point of producing blockage."

This skill's own "standalone-comprehensible by a future version of the
user" criterion sides with Matuschak, not Ahrens — deliberately: the
audience is explicitly *future you*, not a general reader, which keeps
Ahrens' actual goal (a note that doesn't need the original context to make
sense) without adopting his audience-first framing, which Matuschak argues
creates blockage.

### Criteria

- The title is a complete claim.
- Standalone-comprehensible by a future version of the user with no memory
  of this session.
- About one thing, entirely.
- Every link has a stated reason.
- The note answers, or spawns, a "so what / what's next."

## Done

The Take note exists on disk (or is updated, if revisiting), every cited
note is linked with a reason, any flagged tension is logged as its own
backlog entry, and the user is told the file path.

If this session's material came from the evergreen backlog rather than
being freshly named or a bare hunch, close out the row it drew from:

```bash
.slipbox/bin/slipbox evergreen update <slug> --status discussed --note-path <path>
```

Rename the slug too if this was a first write — same pattern as
`make-literature-note`'s own "Write — new reference" step. Bump
`--iteration` instead if this is a revisit to an existing evergreen note
rather than a first write. The note's own `updated-at` frontmatter field
was already set in the Write section above — `created`'s timestamp on a
first write, refreshed to current time on a revisit.
