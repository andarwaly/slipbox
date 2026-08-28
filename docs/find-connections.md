# find-connections

Scan existing notes for recurring Reference or Mentioned candidates, missing
links, and sparked ideas — takes an explicit `--references` or `--evergreen` mode flag.
Absorbs the former `find-terms` skill entirely (that skill no longer exists).

## When to use

Run this whenever you want to sit down and see what your vault has been quietly building
toward — recurring concepts that haven't been promoted to a note yet, connections between
existing notes that were never made explicit, or ideas that only emerge when two notes
are read together. This is a heavier, whole-corpus pass, not something tied to any single
capture.

## Prerequisite

Requires that `setup-slipbox` has already run — it checks for `.slipbox/AGENTS.md`
before doing anything, and stops with a pointer back to `setup-slipbox` if it's missing.
Every `slipbox` CLI call this skill makes uses the full `.slipbox/bin/slipbox` path,
never a bare `slipbox`, since it isn't guaranteed to be on `PATH`.

## Pick a mode

An explicit mode flag is required — `--references` or `--evergreen`. Neither given means
the skill stops and asks which mode is meant, rather than guessing.

- **`--references`** — absorbed `find-terms` behavior. Scans for recurring Reference and
  concrete Mentioned candidates: candidates that show up across 2+ notes but have no
  note of their own yet.
- **`--evergreen`** — the original `find-connections` behavior, unchanged: mechanical
  link suggestions and sparked ideas.

## Scope

Both modes read across all available notes by default. Naming one or more specific notes
as an argument (e.g. `/find-connections --references [[Some Note]]`) narrows the scope to
connections relating to just those notes, instead of a whole-vault scan.

## How `--references` works

1. **Scan** — reads literature notes' `## Key Concepts` and `## Mentioned` sections and
   other mentions of the same or similar things elsewhere in notes' bodies, not just
   formally wikilinked entries — the same idea can surface under different labels in
   different notes (`[[UI Design]]` vs. `[[User Interface Design]]`). This scan does
   not extend to `## Open Questions` — that section is read back directly by the user,
   not surfaced through this skill.
2. **Cluster before counting** — semantic clustering runs first, grouping variant labels
   that refer to the same underlying thing into one cluster. Recurrence is then counted
   per cluster, not per exact string, so two single-mention variant labels can jointly
   cross the threshold together, with the variant labels themselves carried forward as
   `alt_names` candidates on write.
3. **Classify each cluster crossing threshold** — entity-check first (is this a person,
   place, or organization, real or fictional?), then the reusability test (deletion test
   + declarative-title test) for anything that isn't an entity, including named books/
   creative works, tools, and events.
4. **Present as a batch** — every candidate crossing threshold (Reference and concrete
   Mentioned candidates alike) shown together, never auto-written. For an approved
   Reference candidate, the user invokes `/make-reference-note` themselves — this skill never
   writes one directly. Person/Location/Organization candidates remain surfacing-only;
   this family has no write skill for those three types.
5. Zero clusters crossing threshold is a complete, valid result, not an error.

## How `--evergreen` works

1. **Scan** — reads across literature, reference, and evergreen notes for two distinct
   things: link candidates (mechanical) and sparked ideas (generative). Before
   suggesting a link, checks `.slipbox/bin/slipbox links find --source <slug>` first,
   so an already-linked pair is never re-suggested.
2. **Link suggestions, presented as a batch** — every candidate shown together, approved
   or rejected in one pass, never one-at-a-time. Each approved link is written with
   `.slipbox/bin/slipbox links add --source <slug> --target <slug> --rel cites`.
3. **Sparked ideas, routed to the evergreen backlog** — never written as a note directly;
   logged with `.slipbox/bin/slipbox evergreen add --slug <draft-slug> --reason "<the
   spark, described>" --origin-kind note-connection --origin-path "<each actual
   participating note path>"`, repeating `--origin-path` for every note in the spark.
   `make-evergreen-note` picks them up from there later.

## Done

`--references` reports every cluster crossing threshold, classified and never written.
`--evergreen` writes every approved link and logs every sparked idea to the backlog,
then reports what was added and what was routed.

## Usage

> Find connections in my vault.
>
> /find-connections --references
>
> /find-connections --evergreen [[Some Note]]

## Installation

```bash
npx skills add andarwaly/slipbox
```

See the [skill source](../skills/find-connections/) for the full agent-facing
instructions.
# Find connections

Provenance uses `origin_kind: note-connection` and includes every note participating in a spark in `origin_paths`.
