# make-reference-note

Synthesize an already-grounded Reference note from the literature notes that
wikilink to it. There is no `/grounding` session in this skill — the
citation-discipline work already happened upstream, at the claim level, inside
whichever literature notes' `## Key Concepts` section wikilinks to this
reference (`make-literature-note`'s job). `make-reference-note` pulls those
already-grounded characterizations back out, reconciles them into one
explanatory lookup, and writes the completed result.

The resulting body is an explanatory practical lookup: a clean H1 and concise
definition followed by precise headings selected for the user's inquiry. Established
characteristics, causes, mechanisms, examples, applications, or guidance may be
included when they materially improve the lookup. It adapts to concepts, frameworks,
tools, events, and creative works without subtype-specific headings, and organizes
material by conceptual logic across sources. Provenance stays in configured frontmatter:
Literature `source` links are resolved to their original Resources, verified against the
Resource/source map, and deduplicated. Source-specific claims remain in Literature
notes; personal judgments and novel recommendations route to Evergreen.

Presentation follows your stated style profile. Prose, bullets, Markdown tables, and
Mermaid diagrams are available; an explicit request for a table or diagram takes
priority when it represents the grounded material accurately. Otherwise, either visual
form is used only when it clearly improves comprehension and replaces redundant prose.
It cannot broaden the subject or supply unsupported content. Stable competing accounts
may be compared when the disagreement is necessary to understand the lookup; a conflict
that prevents a stable definition blocks the note.

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
  one. A supplied lookup inquiry guides the sections; naming only the subject
  defaults to a general explanatory lookup.
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
  characterizations into one coherent explanation organized by the concept's
  dependencies and the lookup inquiry, never by source order. Surface genuine conflicts,
  naming issues, or scope ambiguity for resolution; the user's explicit invocation
  explicitly invokes the skill, so proceed unless a genuine ambiguity requires
  resolution; do not add a ceremonial approval step.
  Report the completed result and path after writing.
- **Write — new reference** — running `/write-checks` with `artifact-kind: note` and
  `note-type: reference` for full field
  resolution, then writing the fresh note. A configured Reference title prefix also
  adds the unprefixed concept display name to the mapped `alt_names`/`aliases` list;
  explicit alternate names are merged case-insensitively, with the user's casing kept.
- **Write — extending an existing reference** — the collision-safe path:
  running `/write-checks` with `artifact-kind: note` and `note-type: reference` in
  checks-only mode (no field list, since the
  reference's fields were already resolved on its first write). A warrant-only
  addition preserves the body; newly grounded explanatory content needed by the
  inquiry may transactionally recompose only the affected sections. Both paths append
  the new source(s) to the `sources` array and record a typed `links` edge (`rel_type: 'extends'`)
  connecting the new resource to the reference note.

The file on disk ends up reflecting either the explicitly invoked explanatory lookup, or
every source that has ever fed the note (old and new); any flagged tension is
logged to the evergreen backlog, and the user is told the file path.

Existing compact Reference notes are left untouched until explicitly revisited or
extended. There is no automatic bulk expansion.

## Usage

> make-reference-note "confirmation bias"

## Installation

```bash
npx skills add andarwaly/slipbox
```

See the [skill source](../skills/make-reference-note/) for the full
agent-facing instructions.
## Provenance

Provenance uses `origin_kind: note-connection` and includes the actual vault-relative paths of all participating Literature notes in `origin_paths`.
