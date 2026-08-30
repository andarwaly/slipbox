# Source-map cache

Source maps are analysis of frozen Resources, keyed by the Resource SHA-256. Store contract version, producer version, source fingerprint, known paths, and timestamps with each map. Cache persistence is independently `local` or `tracked`; `.slipbox/work/` remains local and untracked in either case.

Before reuse, inspect compatibility and provenance. Refresh may target missing or incompatible maps, a scope, or all maps. Report compatible, missing, incompatible, older-compatible, unresolved-source, and orphaned counts separately. Cache refresh never authorizes note-format migration.

Use the CLI's `cache status`, `inspect`, `store`, and `remove` help for exact flags and output formats.
