# Source-map contract

The source map is a reusable, source-owned cache keyed by the Resource SHA-256. It
supports later Literature sessions without becoming note content. The agent may build or
refresh it; `/using-slipbox` and the CLI only validate, store, inspect, and remove it.

## Required shape

The cache has the required top-level sections `source`, `contract`, `posture`,
`source_spine`, `source_units`, `relations`, `core_idea_candidates`, `integrity_flags`,
`concept_candidates`, `referent_candidates`, plus schema/producer versions and timestamps.
Progressive density is intentional: arrays may start empty and gain detail as reading
continues. The source identity contains a `sha256:<64 lowercase hex>` fingerprint and
vault-relative `known_paths`.

- `source`: title, content type, fingerprint, and known paths; no reader context.
- `contract`: map grain, versioned semantics, and explicit exclusions.
- `posture`: source mode, commitment, attribution, and uncertainty as applicable.
- `source_spine`: 3–8 ordered conceptual moves, each with an ID, label, and concise
  source-grounded summary. Fewer moves are allowed while the map is incomplete.
- `source_units`: independently addressable passages or propositions. Each has a stable
  ID and source text/summary; `epistemic_status`, `confidence`, and `evidence` are local
  fields and may be omitted until known.
- `relations`: typed edges between unit or move IDs.
- `core_idea_candidates`: plural, source-grounded candidate sentences with supporting IDs
  and posture; selection is deferred to the Literature session.
- `integrity_flags`: source-integrity warnings or observations, scoped to IDs where useful.
- `concept_candidates` and `referent_candidates`: load-bearing abstract concepts and
  concrete named referents, each tied to source-unit IDs.

The map must not contain user inquiry, reading-state assessments, session transcript,
chain-of-thought, or reader-owned Evergreen synthesis. Unknown top-level fields are
invalid. A map never stores a prescriptive backlog or authoritative grounding order.

## Relationship vocabulary

Every relation uses exactly one of these types:

`supports`, `explains`, `qualifies`, `contrasts-with`, `depends-on`, `example-of`,
`evidence-for`, `counterargument-to`, `disputes`, `defines`, `causes`, `precedes`,
`restates`.

Relations preserve source structure; they do not assert that the user accepts the
proposition. Local epistemic metadata belongs on the unit or posture that warrants it,
not in a reader-facing note.

## Inquiry map and derived frontier

An inquiry map is session-scoped and separate from the source cache. It records reading
context/state and per-unit relevance, learning relevance, interpretive risk,
comprehension, selection, disposition, and draft state. Every assessment references a
`source_units` ID; it never copies a free-floating source claim as its identity.

The grounding frontier is derived at runtime from the inquiry map, current note, and
conversation. It is not stored as an authoritative list in either map. Recompute it when
context, comprehension, selection, or note coverage changes.
