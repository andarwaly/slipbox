# Source-map cache

Source maps are analysis of frozen Resources, keyed by the Resource SHA-256. A cache document must contain `schema_version`, `map_contract_version`, `producer_version`, `source`, `contract`, `posture`, `source_spine`, `source_units`, `relations`, `core_idea_candidates`, `integrity_flags`, `concept_candidates`, `referent_candidates`, `created_at`, and `updated_at`. `source` contains the `sha256:` fingerprint and `known_paths`; semantic arrays may be empty while analysis is progressive. Unknown top-level keys (including transcripts) are rejected.

Agents build and refresh semantic maps. The CLI only validates, stores, inspects, reports compatibility, and removes them. Store verifies the Resource bytes and atomically writes `<sha256>.json`; identical bytes therefore share one entry even after a path rename. Cache persistence is independently `local` or `tracked`; `.slipbox/work/` remains local and untracked in either case.

Before reuse, inspect compatibility and provenance. Refresh may target missing or incompatible maps, a scope, or all maps. Report compatible, missing, incompatible, older-compatible, unresolved-source, and orphaned counts separately. Cache refresh never authorizes note-format migration.

Use the CLI's `cache status`, `inspect`, `store`, and `remove` help for exact flags and output formats.
