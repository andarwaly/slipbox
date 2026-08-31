# make-reference-note

Synthesize an already-grounded Reference note from the literature notes that
wikilink to it. There is no `/grounding` session in this skill — the
citation-discipline work already happened upstream, at the claim level, inside
whichever literature notes' `## Key Concepts` section wikilinks to this
reference (`make-literature-note`'s job). `make-reference-note` pulls those
already-grounded characterizations back out, reconciles them into one
definition and writes the completed result.

The resulting body is a bounded lookup entry: a clean H1, one concise definition,
essential characteristics/components, and optional disambiguation only where a common
confusion materially impairs lookup. It adapts to concepts, frameworks, tools, events,
and creative works without subtype-specific headings. Provenance stays in configured
frontmatter: Literature `source` links are resolved to their original Resources,
verified against the Resource/source map, and deduplicated. The body does not contain a
source dossier or mandatory `Sources`, mechanism, application, implications, or `Open
Questions` sections.

## When to use

Run this whenever a reference is named directly — whether the user thought of
it themselves, or because `find-connections --references` surfaced it as a
recurrence candidate. There's no backlog this skill pulls from itself;
recurrence is derived on demand by `find-connections`, not surfaced into a
queue this skill owns.

## How it works

- **Prerequisite** — requires `.slipbox/AGENTS.md` to exist, confirming
  `setup-slipbox` has run; every `slipbox` CLI call throughout this skill goes
  through `.slipbox/bin/slipbox`, never bare `slipbox`.
- **Take the candidate** — named directly, checked against
  `.slipbox/config.json`'s `paths.reference` (and `filenames.reference` casing
  convention) to see if this is a new reference or an extension of an existing
  one.
- **Gather the grounded characterizations** — find every literature note whose
  `## Key Concepts` wikilinks to this candidate, and read each one's already-
  grounded treatment of it. Resolve each configured Literature `source` to the
  original Resource, verify it against the Resource/source map, and deduplicate
  Resource links. No re-interviewing the user — that's settled
  already, at the claim level. A source that hasn't been through
  `make-literature-note` yet is stopped here and the user is told it needs to go
  through `make-literature-note` first — synthesis continues from whatever
  already-grounded sources exist rather than blocking the whole write on one.
- **Synthesize and resolve ambiguity** — reconcile agreeing or complementary
  characterizations into one coherent definition. Surface genuine conflicts,
  naming issues, or scope ambiguity for resolution; the user's explicit invocation
  already confirms selection, so do not ask for a ceremonial second confirmation.
  Report the completed result and path after writing.
- **Write — new reference** — running `/write-checks` with `artifact-kind: note` and
  `note-type: reference` for full field
  resolution, then writing the fresh note. A configured Reference title prefix also
  adds the unprefixed concept display name to the mapped `alt_names`/`aliases` list;
  explicit alternate names are merged case-insensitively, with the user's casing kept.
- **Write — extending an existing reference** — the collision-safe path:
  running `/write-checks` with `artifact-kind: note` and `note-type: reference` in
  checks-only mode (no field list, since the
  reference's fields were already resolved on its first write), appending the
  new source(s) to the `sources` array without ever overwriting the file
  wholesale, then recording a typed `links` edge (`rel_type: 'extends'`)
  connecting the new resource to the reference note.

The file on disk ends up reflecting either the confirmed new definition, or
every source that has ever fed the note (old and new); any flagged tension is
logged to the evergreen backlog, and the user is told the file path.

## Usage

> make-reference-note "confirmation bias"

## Installation

```bash
npx skills add andarwaly/slipbox
```

See the [skill source](../skills/make-reference-note/) for the full
agent-facing instructions.
