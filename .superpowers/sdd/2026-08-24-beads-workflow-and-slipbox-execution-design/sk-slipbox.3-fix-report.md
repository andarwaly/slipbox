# sk-slipbox.3 fix report

## Scope

Addressed only the three findings in `sk-artifact-validation-review-report.md`.
The root gitlink, commit `494034a`, unrelated changes, and both user-owned
untracked plan files were preserved.

## Fixes

- Reordered the fresh Evergreen, fresh Reference, and extending Reference
  procedures so the complete temporary draft passes `/write-checks` before any
  write, followed by re-read and saved-artifact validation.
- Made `note validate` reject quoted `date`/`datetime` values and parse list
  fields as actual JSON/YAML-compatible arrays instead of checking delimiters.
- Added regressions for malformed list serialization and quoted dates.
- Updated the shipped setup runtime `AGENTS.md` with the `note validate` and
  post-write contract, and bumped `write-checks` from `1.4.0` to `1.5.0`.

## Verification

- `bash -n skills/setup-slipbox/scripts/slipbox`
- `bash -n tests/setup-slipbox/slipbox.sh`
- `bash tests/setup-slipbox/slipbox.sh` — ALL PASS
- JSON parsing for `tests/write-checks/evals.json` and
  `skills/setup-slipbox/assets/style-profile.schema.json`
- `quick_validate.py` passes for `write-checks` and `make-evergreen-note`.
- `quick_validate.py` reports the existing supported
  `disable-model-invocation` key for `setup-slipbox` and
  `make-reference-note`; those keys were preserved and are unrelated to this
  fix.
- `git diff --check` — PASS
