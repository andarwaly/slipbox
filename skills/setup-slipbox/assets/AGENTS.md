# Slipbox — machine-facing workflow reference

This file exists only after a fully successful `setup-slipbox` run. Its presence is the completion sentinel every other skill in this family checks before doing anything: if `.slipbox/AGENTS.md` doesn't exist, `setup-slipbox` hasn't finished, and no other skill should proceed.

This is separate from the vault's own root `AGENTS.md`/`CLAUDE.md`. That file carries a human-facing, opt-in one-line pointer proposed by `setup-slipbox`'s Done section ("This vault uses the slipbox skill family..."), written only if the user agrees to it. This file is unconditional, always present after setup, and written for an agent reading it mid-task, not for a human onboarding to the vault.

## Workflow

A vault typically moves through these skills in this order, though any skill can be invoked directly once `.slipbox/config.json` exists:

- `setup-slipbox` — one-time onboarding. Discovers vault conventions, writing style, and clip preferences; installs the `slipbox` CLI and writes every file listed below. Re-run only to change conventions.
- `clip-resource` — fetches a URL and writes a frozen Resource. The starting point for anything pulled in from outside the vault.
- `make-literature-note` — grounds a clipped Resource into one or more Claims, written as Key Claims in a shared literature note for that source.
- `make-reference-note` — synthesizes a Reference note from the literature notes that already wikilink to it. Never runs `/grounding` itself; grounding already happened upstream, at the claim level.
- `find-connections` — scans existing notes, in one of two modes. `--references` surfaces Reference/Person/Location/Organization recurrence for the user to act on with `make-reference-note`. `--evergreen` surfaces missing links and sparked ideas, writing mechanical links directly and routing sparked ideas to the evergreen backlog.
- `make-evergreen-note` — grounds a hunch, or a backlog entry, into a Take: the user's own synthesized position, checked against existing notes it connects, written as an evergreen note.
- `grounding` and `ground-me` — the bare interview engine and its passthrough wrapper. Composable into any of the skills above, and directly invocable on their own for ad-hoc grounding with no note-type commitment.
- `write-checks` — the shared pre-write gate every note-writing skill above runs before saving a draft: style, humanize signals, frontmatter field resolution, zone placement, and title prefix.

## `.slipbox/` folder structure

- `config.json` — vault conventions: paths, filename casing, note-type prefixes, frontmatter field mappings, clip settings, and template paths. Every other skill reads this before writing anything.
- `bin/slipbox` — the CLI binary. Always invoked by its full path, `.slipbox/bin/slipbox`, never bare `slipbox`.
- `evergreen/` — the persistent backlog of pending evergreen candidates, read and written through `slipbox evergreen add/find/update`.
- `links.jsonl` — the mechanical link ledger between notes, read and written through `slipbox links add/find`.
- `style-profile.json` — the user's stated note-shape and editing preferences, interviewed once by `setup-slipbox` and consulted by `write-checks`.
- `humanize-checklist.json` — the humanizer workflow snapshot `write-checks` runs against a draft before it's saved.
- `GLOSSARY.md` — the term reference below.
- `AGENTS.md` — this file.

`GLOSSARY.md` and this file are copied verbatim from `setup-slipbox`'s own bundled assets on every run, first run or re-run alike, so a vault always carries the current package version of both.

## When a `slipbox` command fails

Check the exit code of every `.slipbox/bin/slipbox` call before using its output, and read stderr when it's nonzero — the CLI prints one JSON object there, `{"error": "..."}`, and never a bare traceback.

- Exit `2` is a usage error: the invocation was wrong (bad flag, missing value, unknown dotted path). Fix the invocation; don't retry it unchanged and don't route around it by editing `.slipbox/` files by hand.
- Exit `1` is a runtime failure: something on disk is missing, corrupt, or unwritable. Stop the step that needed it and tell the user what the error said, verbatim. Never treat a failed `evergreen add`/`links add` as recorded, and never continue a note-write on the assumption that bookkeeping landed.
- Exit `0` with a `{"warning": "..."}` line on stderr means the command succeeded on incomplete input — a corrupt evergreen candidate was skipped, or a checklist signal wasn't evaluated. Use the result, and surface the warning to the user in the same breath rather than reporting a clean run.

## Terms

Every bolded term used across this skill family (Resource, Literature note, Reference note, Evergreen note, Claim, Take, Session, Backlog, Candidate, Gate, and the rest) is defined in `.slipbox/GLOSSARY.md`. Read it before treating any bolded term as self-explanatory.
