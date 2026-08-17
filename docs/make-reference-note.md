# make-reference-note

Synthesize an already-grounded Reference note from the literature notes that
wikilink to it. There is no `/grounding` session in this skill — the
citation-discipline work already happened upstream, at the claim level, inside
whichever literature notes' `## Key Concepts` section wikilinks to this
reference (`make-literature-note`'s job). `make-reference-note` pulls those
already-grounded characterizations back out, reconciles them into one
definition, presents for confirmation, and writes.

## When to use

Run this whenever a reference is named directly — whether the user thought of
it themselves, or because `find-connections --references` surfaced it as a
recurrence candidate. There's no backlog this skill pulls from itself;
recurrence is derived on demand by `find-connections`, not surfaced into a
queue this skill owns.

## How it works

- **Take the candidate** — named directly, checked against
  `.slipbox/config.json`'s `paths.reference` (and `filenames.reference` casing
  convention) to see if this is a new reference or an extension of an existing
  one.
- **Gather the grounded characterizations** — find every literature note whose
  `## Key Concepts` wikilinks to this candidate, and read each one's already-
  grounded treatment of it. No re-interviewing the user — that's settled
  already, at the claim level. A source that hasn't been through
  `make-literature-note` yet is skipped here and routed there first.
- **Synthesize and confirm** — reconcile agreeing, complementary, or
  conflicting characterizations into one coherent definition; surface
  conflicts rather than silently picking one; present for confirmation before
  writing anything to disk.
- **Write** — a fresh reference note on first occurrence (running a
  `/write-checks` session for field resolution), or an in-place extension
  (append-only, never overwritten wholesale) on repeat mentions, with a typed
  `links` edge (`rel_type: 'extends'`) connecting the new resource to the
  reference note.

## Usage

> make-reference-note "confirmation bias"

## Installation

```bash
npx skills add andarwaly/slipbox
```

## Open

Whether extending an existing Reference note with a source that hasn't gone
through `make-literature-note` yet should be auto-routed there by this skill, or
this skill should just stop and tell the user to run it separately, is still
unresolved — see
`discussion/slipbox/discussion-topics/find-terms-find-connections-merge.md`.

See the [skill source](../skills/make-reference-note/) for the full
agent-facing instructions.
