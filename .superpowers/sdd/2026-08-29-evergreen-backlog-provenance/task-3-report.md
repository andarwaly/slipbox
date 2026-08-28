# Task 3 report

## Result

Implemented the runtime contract and human-facing documentation for immutable Evergreen backlog queue-entry provenance.

## Files

- `skills/setup-slipbox/assets/AGENTS.md`
- `skills/setup-slipbox/assets/GLOSSARY.md`
- `docs/slipbox-cli.md`
- `docs/setup-slipbox.md`
- `docs/make-literature-note.md`
- `docs/make-reference-note.md`
- `docs/find-connections.md`
- `docs/make-evergreen-note.md`
- `docs/grounding.md`

The installed contract now includes the exact provenance capture command, all five kinds, repeated path cardinality, configured-path semantics, capture-time existence checks, stale-path reads, legacy defaults, immutability, duplicate behavior, and explicit separation from Evergreen `derived-from`. Producer pages document their concrete origin mapping without adding template/config fields.

## Checks

- Contract consistency `rg` checks passed: provenance fields occur in every required contract/page; `derived-from` is explicitly separated; no prohibited template provenance fields were found.
- `git diff --check` passed.

## Commit

`fc6401a01491dcbbb7f7d7c566fe02bd3fc52a39` — `docs: define evergreen backlog provenance contract`

## Self-review

- Scope is limited to the nine files assigned in Task 3.
- No producer skills, evals, CLI implementation, or tests were changed.
- Documentation preserves legacy/default and stale-read behavior and does not imply mutable provenance.

## Concerns

None. The commit required elevated Git permission because the submodule worktree lock resides in the parent repository’s external worktree metadata.
