---
name: find-connections
description: Scan existing notes for missing links, sparked ideas, and recurring Reference or Mentioned candidates — takes an explicit --references or --evergreen mode flag.
disable-model-invocation: true
license: MIT
metadata:
  version: "1.5.0"
---

# Find-connections

Bold terms in this file are defined in `.slipbox/GLOSSARY.md`.
At runtime, resolve that glossary from the installed vault path `.slipbox/GLOSSARY.md`;
the repository `CONTEXT.md` is authoring-only and is not runtime input.

## Prerequisite

- MUST: `.slipbox/AGENTS.md` exists — confirms `setup-slipbox` ran to completion.
- NEVER: proceed without it. Stop and tell the user to run `setup-slipbox` first.
- NEVER: call bare `slipbox` — always `.slipbox/bin/slipbox`, which isn't guaranteed to be on `PATH`.

## Pick a mode

This skill takes an explicit mode flag: `--references` or `--evergreen`. If neither is
given, stop and ask the user which mode they mean — do not guess or default to one.

- `--references` — absorbs `find-terms` entirely (that skill no longer exists). Scans
  for recurring Reference and concrete Mentioned candidates.
- `--evergreen` — the original `find-connections` behavior, unchanged: mechanical link
  suggestions and sparked ideas.

## Scope

Both modes read across all available notes by default. If the user names one or more
specific notes as an argument (e.g. `/find-connections --references [[Some Note]]`),
narrow scope to connections relating to just those notes, instead of a whole-vault scan.

---

## `--references` mode

### Scan

Read the final Literature notes' `## Key Concepts` **and** `## Mentioned` sections,
plus relevant retained prose — not just one source's cache or an unretained candidate.
Source-map caches may verify a selected candidate, but never surface a candidate that
was not retained in a Literature note. This scan does not extend to `##
Open Questions`: no cross-note tracking or indexing exists for open questions, deferred
by design — that section is read back directly by the user, not surfaced through this
skill. The same underlying idea can surface under different labels in
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
in this order — entity exclusion first, followed by the remaining Admission sequence:

1. **Entity-check.** Is this a person, place, or organization — real or fictional?
   Check via a vault-wide, folder-agnostic filename lookup (the same way Obsidian's
   own wikilink resolution works) to see whether a note already exists — no
   `paths.*` config needed; a single configured path per type would wrongly flag an
   already-noted entity as broken if the vault splits these across multiple folders
   (e.g. `coworkers/`, `family/`, `authors/`).
   - If yes: this is a surfacing-only entity candidate. `find-connections` never
     writes people, places, or organizations, real or fictional (per `.slipbox/GLOSSARY.md`).
     Report it the same way as a Reference candidate (recurrence threshold,
     batch-presented), just without ever attempting a write.
   - Entity-check runs first (see `.slipbox/GLOSSARY.md` for the classification-order rationale).
2. **Admission sequence** (only if not an entity; see `.slipbox/GLOSSARY.md`): stable
   lookup identity, source independence, boundedness, adaptive
   evidence sufficiency, and natural-unit scope. Apply evidence sufficiency after the
   other checks, not as a reward for recurrence: one authoritative primary source can
   support a settled standard, while otherwise two independently grounded sources are
   required. Duplicated, syndicated, or otherwise non-independent sources count as one
   support path. Materially contested variants remain unresolved until independent support
   covers the competing definitions or the user resolves the conflict. A candidate that
   fails any check, or never reaches threshold, stays an unresolved broken wikilink
   indefinitely.

Non-entity books/creative works, named tools, and events continue through the same
Admission gates. If all applicable gates pass, report them as Reference-note candidates
and state why the evidence is sufficient. If any gate fails, report the candidate as
`unresolved`, name the missing support, and leave the wikilink untouched as an unresolved
Mentioned link. Never equate a recurrence count with warrant, and never create a
provisional Reference artifact or a `work_id` from this read-only scan.

### Present as a batch

Batch-present every candidate crossing threshold — Reference candidates and
surfacing-only entity candidates alike — never auto-write. This matches the
existing mechanical-links batch-presentation discipline below. For each cluster, show
its variant labels (`alt_names`), the count, and which notes mention it.

For each approved Reference candidate, the user invokes `make-reference-note` themselves,
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
  `make-evergreen-note` grounding before it's a real Take, not a citation edit.

### Present link suggestions as a batch

Show every candidate link together, not one at a time — there's no dependency chain
between suggestions the way `/grounding`'s Socratic questions have, so reviewing them
together is strictly less friction than one full turn per candidate. The user approves,
rejects, or edits each one in one pass.

For each approved suggestion:

Record the link with its exact source, target, relation, and provenance
`/using-slipbox`.

Then add the matching `[[wikilink]]` in whichever note's prose the connection belongs
to, per the existing two-part criterion: it needs the `links` row above as a mechanical
baseline, and the specific sentence must actually assert something about the linked
note's subject, not just incidentally name it.

### Route sparked ideas to the evergreen backlog

For each sparked idea, insert it as its own candidate — never write a note directly, and
never fold it into a link suggestion:

Record an Evergreen candidate with the proposition, reason, and origin paths
`/using-slipbox`.

`make-evergreen-note` picks these up from its own backlog read, same as any other flagged
tension.

---

## Done

**`--references`**: every cluster crossing threshold is reported — classified as
Reference, Person, Location, or Organization — with its variant labels and source
notes. Nothing is written; the user invokes `make-reference-note` themselves for any
approved Reference candidate. A cluster that fails classification, or never reaches
threshold, stays a broken wikilink — expected, not an error.

**`--evergreen`**: every approved link is written (both the `links` row and, where the
criterion is met, the inline wikilink); every sparked idea is logged in the evergreen
backlog, not written as a note. The user is told what was added and what was routed to
the backlog.

Reference candidates are handed off only after the user approves a batch item:
invoke `make-literature-note` for any source that is not yet grounded, then
invoke `make-reference-note` once its Literature note has a grounded `Key
Concepts` link. Discovery remains read-only while preserving the
Literature-first boundary.
