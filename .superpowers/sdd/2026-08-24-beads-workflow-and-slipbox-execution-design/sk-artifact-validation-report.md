# sk-artifact-validation report

## Scope

Implemented Slice D for `sk-artifact-validation` in the `the-factory/slipbox`
submodule. Root files, the root gitlink, `sk-final-review`, and the two user-owned
untracked plan files under `docs/superpowers/plans/` were left untouched.

## Delivered

- Added `slipbox note validate --type TYPE --path PATH [--basename NAME] [--title TITLE]`.
- Validates complete note artifacts for:
  - final basename and configured prefix position;
  - mapped frontmatter fields and unresolved mappings;
  - scalar quoting and list serialization;
  - top/bottom field ordering;
  - one H1 in first-body position;
  - compact-profile block spacing;
  - exactly one terminal newline and no empty trailing paragraph.
- Added post-write re-read and validation requirements to `/write-checks` and all three
  note-writing callers.
- Defined repair boundaries: mechanical quoting, placement, spacing, prefix ordering,
  and trailing-blank-line defects may be repaired and revalidated; collisions,
  semantic conflicts, uncertain titles, and uncertain protected names stop for the user.
- Added optional `formatting.blank_lines_between_blocks` to the style-profile schema.
  Missing preserves legacy spaced behavior; setup explicitly asks new vaults.
- Updated affected skill versions, docs, and eval cases.

## Verification

Passed:

- `bash -n skills/setup-slipbox/scripts/slipbox`
- `bash tests/setup-slipbox/slipbox.sh` — `ALL PASS`
- JSON parsing for `tests/write-checks/evals.json` and
  `skills/setup-slipbox/assets/style-profile.schema.json`
- `quick_validate.py` for `write-checks`, `make-literature-note`, and
  `make-evergreen-note`
- `git diff --check`

The bundled `quick_validate.py` rejects the pre-existing supported
`disable-model-invocation` frontmatter key in `setup-slipbox` and
`make-reference-note`. Those keys were preserved as required by the skill contract.

## Commit

The implementation is committed atomically in the slipbox submodule with
`sk-artifact-validation` in the commit message.
