---
name: find-connections
description: Scan existing notes for missing links, sparked ideas, and Reference/Person/Location/Organization recurrence — takes an explicit --references or --evergreen mode flag.
disable-model-invocation: true
license: MIT
metadata:
  version: "1.1.0"
---

# Find-connections

## Prerequisite

Requires `.slipbox/config.json` and `.slipbox/bin/slipbox` — same as every skill in this
family. Every `slipbox` call below uses this same path, `.slipbox/bin/slipbox` — never
bare `slipbox`.

## Pick a mode

This skill takes an explicit mode flag: `--references` or `--evergreen`. If neither is
given, stop and ask the user which mode they mean — do not guess or default to one.

- `--references` — absorbs `find-terms` entirely (that skill no longer exists). Scans
  for Reference/Person/Location/Organization recurrence.
- `--evergreen` — the original `find-connections` behavior, unchanged: mechanical link
  suggestions and sparked ideas.

## Scope

Both modes read across all available notes by default. If the user names one or more
specific notes as an argument (e.g. `/find-connections --references [[Some Note]]`),
narrow scope to connections relating to just those notes, instead of a whole-vault scan.

---

## `--references` mode

### Scan

Scan literature notes' `## Key Concepts` sections **and** other mentions of the
same or similar things elsewhere in notes' bodies — not just formally wikilinked Key
Concepts entries. The same underlying idea can surface under different labels in
different notes (`[[UI Design]]` in one note, `[[User Interface Design]]` in another)
without either note's author intending them as distinct concepts, so a Key-Concepts-only
scan would miss that.

### Cluster before counting

Semantic clustering runs **first**, before any threshold check — this order matters.
Group variant labels that refer to the same underlying thing into one cluster (e.g.
`[[UI Design]]` and `[[User Interface Design]]` cluster together). Recurrence is then
counted **per cluster**, not per exact string: a cluster made of two labels that each
appear once still jointly crosses a 2+ threshold as one candidate, carrying its variant
labels forward as `alt_names` candidates on write. Running the threshold check first,
on exact strings, would miss exactly this case — neither label alone reaches 2+, so
a dedup pass gated behind the threshold would never get the chance to run.

### Classify each cluster crossing threshold

For each cluster that crosses the recurrence threshold (2+ distinct notes), classify
in this order — entity-check first, then the reusability test:

1. **Entity-check.** Is this a person, place, or organization — real or fictional?
   Check via a vault-wide, folder-agnostic filename lookup (the same way Obsidian's
   own wikilink resolution works) to see whether a note already exists — no
   `paths.*` config needed; a single configured path per type would wrongly flag an
   already-noted entity as broken if the vault splits these across multiple folders
   (e.g. `coworkers/`, `family/`, `authors/`).
   - If yes: this is a Person/Location/Organization candidate. Surfacing only —
     `find-connections` never writes one of these three types, real or fictional
     (per [[reference-note-admission-contract]]). Report it the same way as a
     Reference candidate (recurrence threshold, batch-presented), just without ever
     attempting a write.
   - Entity-status is checked first even though a person's name can technically also
     pass the reusability test below (e.g. "Niklas Luhmann" survives independent of
     any one source) — that's a coincidental technicality, not what the reusability
     test exists to check. What kind of thing this is comes before whether it's a
     reusable concept.
2. **Reusability test** (only if not an entity). Apply both halves:
   - **Deletion test** — does the note survive if the source disappears?
   - **Declarative-title test** — can it compress into a subject+verb claim, no
     "According to X..."?
   - Passes both: Reference-note candidate.
   - Fails either, or the check is never reached (cluster never crosses threshold):
     stays an unresolved broken wikilink indefinitely. This is a legitimate resting
     state, not a defect to resolve.

### Present as a batch

Batch-present every candidate crossing threshold — Reference candidates and
Person/Location/Organization candidates alike — never auto-write. This matches the
existing mechanical-links batch-presentation discipline below. For each cluster, show
its variant labels (`alt_names`), the count, and which notes mention it.

For each approved Reference candidate, the user invokes `/write-reference` themselves,
naming the candidate directly — `find-connections` does not write it.

Zero clusters crossing the threshold is a complete, valid result — report it as such,
not as an error or an empty failure.

---

## `--evergreen` mode

Read across existing literature, reference, and evergreen notes for two genuinely
different things — don't conflate them:

- **A link worth adding** — two notes are related but not yet wikilinked. Check
  `.slipbox/bin/slipbox links find --source <slug>` first; never re-suggest a pair that
  already has a `links` row.
- **A sparked idea** — noticing two or more existing notes together produces something
  neither one states alone. This is generative, not mechanical — it needs full
  `ground-my-take` grounding before it's a real Take, not a citation edit.

### Present link suggestions as a batch

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

### Route sparked ideas to the evergreen backlog

For each sparked idea, insert it as its own candidate — never write a note directly, and
never fold it into a link suggestion:

```bash
.slipbox/bin/slipbox evergreen add --slug <draft-slug> --reason "<the spark, described>"
```

`ground-my-take` picks these up from its own backlog read, same as any other flagged
tension.

---

## Done

**`--references`**: every cluster crossing threshold is reported — classified as
Reference, Person, Location, or Organization — with its variant labels and source
notes. Nothing is written; the user invokes `/write-reference` themselves for any
approved Reference candidate. A cluster that fails classification, or never reaches
threshold, stays a broken wikilink — expected, not an error.

**`--evergreen`**: every approved link is written (both the `links` row and, where the
criterion is met, the inline wikilink); every sparked idea is logged in the evergreen
backlog, not written as a note. The user is told what was added and what was routed to
the backlog.
