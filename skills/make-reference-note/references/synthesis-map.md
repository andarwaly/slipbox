# Reference synthesis map

`synthesis-map.json` is transient, per-work evidence state for a Reference
operation. It lives beside `manifest.json` and `draft.md` under
`.slipbox/work/<work_id>/`; it is never published as note content and is not a
permanent synthesis cache.

The map records:

- `candidate` — the clean concept identity and target Reference path/slug;
- `literature` — every contributing final Literature-note path and its grounded characterization;
- `resources` — deduplicated canonical Resource paths/links, each with its source-map fingerprint when available;
- `admission` — the ordered checks, evidence, and admitted/unresolved result;
- `agreements` — claims or facets supported across inputs;
- `conflicts` — materially competing definitions, with the user decision or unresolved status;
- `proposed_changes` — exact body/frontmatter changes and whether activity is `extend-provenance` or `recompose`; and
- `checkpoint` — the latest semantic boundary and selection or ambiguity-resolution state.

A source that only strengthens warrant changes `resources`, provenance, and the
Resource→Reference link; it must not cause body bytes to change. A source that
changes the definition boundary may change only the required bounded body
fields. Re-read and fingerprint the target immediately before staging and let
`work finalize` compare-and-swap it; a concurrent target change blocks the
operation and leaves the work resumable.
