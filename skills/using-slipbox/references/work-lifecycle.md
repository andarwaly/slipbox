# Work lifecycle

Work is local and untracked under `.slipbox/work/`, independent of source-map cache persistence. Use the installed `.slipbox/bin/slipbox` lifecycle commands; consult its `--help` output for exact flags. A work manifest records its ID, kind, activity, status, UTC timestamps, source/target identity and starting fingerprints, and affected paths. Resource work uses activity `clip`, is create-only, and its directory stages `extraction.json` and the complete template-resolved `draft.md`; record detected type, extraction method, metadata, and failure details there. Resource extraction state is transient work state, not a permanent extraction cache. Reference work uses activities `create`, `recompose`, and `extend-provenance`; its directory also stages `synthesis-map.json` and a complete `draft.md`.

Evergreen work uses activities `create` and `revise`; its directory stages `synthesis-map.json` and the complete `draft.md`. The map records contributing notes, the user's confirmed Take, flagged tensions (as pending candidate objects with proposition, reason, and origin paths), citations, origin candidate details, and pending side effects. It is transient work state, never published as note content.

The lifecycle is resumable: inspect before resume, verify fingerprints, checkpoint after meaningful boundaries, and preserve failed state for repair. Publication is transactional and must pass `/write-checks` before the CLI writes. A specialist stages `mutations.json` (or `manifest.mutations`) and moves the manifest to `ready-to-finalize`; `work finalize <work-id>` validates every replacement and expected fingerprint before taking sorted per-path locks. Targets are compare-and-swapped, so collisions and concurrent changes cannot overwrite them. Partial application is compensated from byte backups; ledger additions use append-only link tombstones. Successful work becomes `published`, rollback becomes `failed`, and unsuccessful compensation becomes `repair-required` with diagnostics. Discard requires explicit confirmation and affects only the selected work directory.

For Reference synthesis, checkpoint the reconciled map and bounded draft at admission and again after any ambiguity or conflict is resolved. An `extend-provenance` operation keeps existing body bytes stable when a new source adds warrant only; it stages provenance and the Resource→Reference edge. A `recompose` operation stages only the bounded body fields required by a material boundary change. Re-read and fingerprint the target immediately before staging. Any concurrent target change blocks finalization; it never overwrites the user's newer synthesis. The synthesis map is transient and is not published.

The concrete publication hand-off is: write the complete candidate to `draft.md`,
stage `mutations.json` with the artifact replacement and all related side effects,
include each target's `expected_fingerprint`, then move the manifest to
`ready-to-finalize` and call `work finalize <work_id>` once. For Evergreen work,
the same mutation list contains the note replacement, exactly one `ledger-events`
mutation containing every `cites` event, and, when applicable, one atomic backlog
mutation. A first-write backlog rename is a create-new-row plus remove/tombstone-old-row
operation in that mutation; a revision updates the existing row and iteration.
The mutation uses `kind: "backlog-events"`, `path` for the old candidate,
`new_path` for the new candidate, `operation: "rename"|"update"`, and a staged
`replacement_path`; both paths are locked and compare-and-swapped together.
The CLI validates all replacements and applies them as one compare-and-swap transaction. If any
validation, preflight, or finalize step fails, retain the work directory and
diagnostics; inspect and resume or repair only after fingerprint checks, and never
report publication success. Discard still requires explicit user confirmation.

CLI output is JSON by default. Table output is opt-in with `--format table` where supported. Every usage failure exits 2 and writes one JSON error object to stderr; runtime failures exit 1 with the same error shape, never a traceback.
