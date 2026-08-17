---
name: write-reference
description: Synthesize an already-grounded Reference note from the literature
  notes that wikilink to it — pulls in each note's grounded characterization,
  reconciles them into one definition, presents for confirmation, writes.
disable-model-invocation: true
license: MIT
metadata:
  version: "1.3.0"
---

# Write-reference

Bold terms in this file are defined in `GLOSSARY.md`.

## What these words mean

- **Reference** — a named concept, method, tool, framework, or stable fact with a
  reusable label, independent of any one source (e.g. "confirmation bias," "CRDT,"
  "Zettelkasten Method") — admission is a reusability test (does the note survive if
  the source disappears; can it compress into a declarative, subject+verb title with
  no "According to X..."), not an origin test. See `GLOSSARY.md` for the full type
  shape and the admission test's detail.
- **Reference note** — the cumulative file a reference's definition lives in. Unlike a
  Claim, never one-shot: extended across however many sources touch this reference,
  over however many separate sessions. Only ever appends or extends — never
  overwrites what's already there.

## This skill never runs /grounding

Grounding — holding the user to a source for a claim, via a `/grounding` session —
already happened upstream, at the claim level, inside whichever literature notes'
`## Key Concepts` section wikilinks to this reference. That's `make-literature-note`'s
job, not this skill's. `write-reference`'s own job starts after that: pull the
already-grounded characterizations back out of those literature notes, reconcile them
into one definition, present for confirmation, write.

No exception to this. If a source that touches this reference hasn't been through
`make-literature-note` yet, it doesn't belong in this skill's synthesis step at all —
route it through `make-literature-note` first, exactly like any other new source, and
only come back here once its relevant claim (and Key Concepts wikilink) exists. See
"Extending an existing Reference note" below.

## Prerequisite

Requires `.slipbox/AGENTS.md` to exist — its presence confirms `setup-slipbox` completed
a full run. If missing, stop and say so. Every `slipbox` call below uses this same path,
`.slipbox/bin/slipbox` — never bare `slipbox`, which isn't guaranteed to be on `PATH`.

## Take the candidate

Named directly, only — the user says which reference they want written, whether they
thought of it themselves or because `find-connections --references` surfaced it as a
recurrence candidate. There is no backlog this skill pulls from itself; recurrence is
derived on demand by `find-connections`, not surfaced into a queue this skill owns.

Use `slipbox config get paths.reference` to locate the folder, checking for
a Reference note for this candidate there — not an assumed `reference/` folder —
before writing. Apply the `slipbox config get filenames.reference` casing convention:

- **New reference** — no note exists. Proceed to gather characterizations.
- **Extending** — a note already exists. Read it in full now. Its accumulated text is
  the working synthesis of everything before it, not just a resource list to append
  to.

## Gather the grounded characterizations

Find every literature note whose `## Key Concepts` wikilinks to this candidate (this
is what `find-connections --references` already surfaced recurrence over — re-derive
or reuse that same set here). For each one:

- Read the literature note's own grounded treatment of the term — the characterization
  the user was already held to via `make-literature-note`'s `/grounding` session for that
  note. Do not re-interview the user about it; it's already settled at the claim
  level.
- Note where two or more literature notes' characterizations agree, add distinct
  facets to each other, or appear to conflict.

If a source touching this candidate has not gone through `make-literature-note` (no
literature note with a grounded Key Concepts wikilink to it exists yet) — stop that
source here, do not synthesize from it, and tell the user it needs to go through
`make-literature-note` first. Continue synthesizing from whatever already-grounded sources
do exist; don't block the whole write on one ungrounded source unless it's the only
one.

## Synthesize and confirm

Reconcile the gathered characterizations into one definition:

- Where characterizations agree or add distinct facets, merge them into one coherent
  definition rather than listing each source's phrasing separately.
- Where characterizations conflict, surface the conflict to the user rather than
  silently picking one — resolve it the same way any other flagged tension in this
  family gets handled: if the user opts in to flagging it rather than resolving it now,
  insert it into the evergreen backlog before moving on to writing:

  ```bash
  .slipbox/bin/slipbox evergreen add --slug <draft-slug> --reason "<tension description>"
  ```

- Present the synthesized definition to the user for confirmation before writing
  anything to disk. If extending an existing note, the user's confirmation must keep
  the result consistent with what's already recorded — not silently contradict it.

## Write — new reference

Write fresh:

- Run a /write-checks session on the draft, passing the Reference field list (`type`,
  `created`, `sources`, plus `alt_names` if any were given) — it resolves each field's
  mapping, formatting, zone placement, and title prefix, and checks the draft's style
  and humanize signals.
- Write into the folder from `slipbox config get paths.reference`, filename per
  `slipbox config get filenames.reference` casing convention.
- Re-read the target path from disk right before writing.
- Assemble the frontmatter from write-checks' returned fields and write the file.
- Filename collision → stop and ask, never auto-disambiguate.

## Write — extending an existing reference

**This is the collision-safe path. Follow it exactly.**

`sources` already has its resolved mapping and formatting from the reference's first
write — no field resolution needed here.

1. Run a /write-checks session on the draft in its checks-only mode (no field list).
2. Re-read the file from disk immediately before writing (state can have changed since
   the read in "Take the candidate").
3. Append the new resource(s) to the `sources` frontmatter array, formatted per the
   note's existing recorded `type` (list) and `wikilink` flag, and write the file.
   Never overwrite the file wholesale.
4. Insert a `links` row recording the relationship — this reference's own note is the
   target, the resource being folded in is the source:

   ```bash
   .slipbox/bin/slipbox links add --source <this-resource-slug> --target <reference-note-slug> --rel extends
   ```

## Done

- New reference: the file on disk reflects the confirmed, synthesized definition.
- Extension: the file on disk reflects every source that has ever fed it, old and new;
  a `links` row (`rel_type: 'extends'`) connects the new resource to the reference
  note.
- Any flagged tension is logged in the evergreen backlog.
- The user is told the file path.

## Open

- **Still unresolved as of this writing**: whether extending an existing Reference note
  with a source that hasn't gone through `make-literature-note` yet routes there
  automatically (this skill triggering that flow itself) versus this skill simply
  stopping and telling the user to run it separately. This SKILL.md takes the
  stop-and-tell reading above as the safer default given the "no exception" rule, but
  the discussion record — `discussion/slipbox/discussion-topics/find-terms-find-connections-merge.md`
  — flags the routing mechanics themselves as open, not just the principle. Revisit
  once that's settled.
