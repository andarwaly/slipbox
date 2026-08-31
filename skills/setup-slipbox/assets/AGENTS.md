# Slipbox — machine-facing workflow reference

This file exists only after a fully successful `setup-slipbox` run. Its presence is the completion sentinel every other skill in this family checks before doing anything: if `.slipbox/AGENTS.md` doesn't exist, `setup-slipbox` hasn't finished, and no other skill should proceed.

This is separate from the vault's own root `AGENTS.md`/`CLAUDE.md`. That file carries a human-facing, opt-in one-line pointer proposed by `setup-slipbox`'s Done section ("This vault uses the slipbox skill family..."), written only if the user agrees to it. This file is unconditional, always present after setup, and written for an agent reading it mid-task, not for a human onboarding to the vault.

## Workflow

A vault typically moves through these skills in this order, though any skill can be invoked directly once `.slipbox/config.json` exists:

- `setup-slipbox` — one-time onboarding. Discovers vault conventions, writing style, and clip preferences; installs the `slipbox` CLI and writes every file listed below. Re-run only to change conventions.
- `clip-resource` — fetches a URL and writes a frozen Resource. The starting point for anything pulled in from outside the vault.
- `make-literature-note` — grounds a clipped Resource into one or more Source Points, written in a shared literature note for that source.
- `make-reference-note` — synthesizes a Reference note from the literature notes that already wikilink to it. Never runs `/grounding` itself; grounding already happened upstream, at the Source Point level.
- `find-connections` — scans existing notes, in one of two modes. `--references` surfaces recurring Reference or Mentioned candidates; people, places, and organizations remain surfacing-only, while reusable non-entities can be acted on with `make-reference-note`. `--evergreen` surfaces missing links and sparked ideas, writing mechanical links directly and routing sparked ideas to the evergreen backlog.
- `make-evergreen-note` — grounds a hunch, or a backlog entry, into a Take: the user's own synthesized position, checked against existing notes it connects, written as an evergreen note.
- `grounding` and `ground-me` — the bare interview engine and its passthrough wrapper. Composable into any of the skills above, and directly invocable on their own for ad-hoc grounding with no note-type commitment.
- `write-checks` — the shared gate every note-writing skill above runs on the complete
  assembled draft before saving: style, humanize signals, frontmatter field
  resolution, zone placement, title prefix, and artifact validation. The caller writes
  only after that pre-write gate passes, then re-reads the saved path and runs
  `slipbox note validate --type literature|reference|evergreen --path PATH [--basename NAME] [--title TITLE]`;
  a failed post-write validation blocks success. Resource captures are not accepted
  validator types; their frontmatter `type` remains the content subtype.

## `.slipbox/` folder structure

- `config.json` — vault conventions: paths, filename/link-target casing and prefixes, frontmatter field mappings, clip settings, template paths, Git policy, and source-map cache persistence. `git.mode` is `off`, `ask`, or `auto`; `git.commit_style.mode` is `detected` or `fallback`; no Git-detection boolean is stored. Work manifests capture per-path Git baselines, and `work commit` uses an isolated index with exact published-path allowlisting. `cache.source_maps.persistence` is `local` or `tracked`. Every other skill reads this before writing anything.
- Note filenames and link targets use the exact configured per-type prefix; Literature, Reference, and Evergreen H1 headings remain clean/unprefixed, and any `|` display alias is clean. Resources have no prefix.
- `bin/slipbox` — the CLI binary. Always invoked by its full path, `.slipbox/bin/slipbox`, never bare `slipbox`.
- `evergreen/` — the persistent backlog of pending evergreen candidates, read and written through `slipbox evergreen add/find/update`.
- `links.jsonl` — the append-only mechanical link event ledger between notes, read and written through `slipbox links add/remove/find`. Legacy rows without `op` are treated as adds; removals are tombstones.
- `work/` — recoverable transient setup/runtime work; always local and never tracked.
- `cache/source-maps/` — source-map cache entries, local or tracked according to `config.json`.
- `style-profile.json` — the user's stated note-shape and editing preferences, interviewed once by `setup-slipbox` and consulted by `write-checks`.
- `humanize-checklist.json` — the humanizer workflow snapshot `write-checks` runs against a draft before it's saved.

Setup migration inventory reports compatible, missing, incompatible, older-compatible, unresolved-source, and orphaned cache entries. Build scopes are independently authorized: missing + incompatible, a chosen scope, refresh all, or defer. Cache migration authorization is separate from note-format migration authorization.
- `GLOSSARY.md` — the term reference below.
- `AGENTS.md` — this file.

`GLOSSARY.md` and this file are copied verbatim from `setup-slipbox`'s own bundled assets on every run, first run or re-run alike, so a vault always carries the current package version of both.

## Evergreen backlog contract

The vault's `.slipbox/AGENTS.md` is the canonical runtime reference for shared
evergreen-backlog semantics. The `evergreen` CLI maintains candidates through
their lifecycle:

- `evergreen add --slug <slug> --reason "<reason>"` records a pending candidate.
- `evergreen find --status to-discuss` lists candidates available for discussion.
- Any `evergreen update` automatically refreshes the candidate's `updated_at`.
- After a first write, close and rename the candidate with
  `evergreen update <current-slug> --slug <final-slug> --status discussed
  --note-path <path>`.
- On a revisit, close the candidate with
  `evergreen update <slug> --status discussed --note-path <path> --iteration
  <next-number>`.

Skills may retain the exact commands they execute, but defer shared semantics,
status meanings, and lifecycle rules to this section rather than duplicating
that explanation.

## When a `slipbox` command fails

Check the exit code of every `.slipbox/bin/slipbox` call before using its output, and read stderr when it's nonzero — the CLI prints one JSON object there, `{"error": "..."}`, and never a bare traceback.

- Exit `2` is a usage error: the invocation was wrong (bad flag, missing value, unknown dotted path). Fix the invocation; don't retry it unchanged and don't route around it by editing `.slipbox/` files by hand.
- Exit `1` is a runtime failure: something on disk is missing, corrupt, or unwritable. Stop the step that needed it and tell the user what the error said, verbatim. Never treat a failed `evergreen add`/`links add` as recorded, and never continue a note-write on the assumption that bookkeeping landed.
- Exit `0` with a `{"warning": "..."}` line on stderr means the command succeeded on incomplete input — a corrupt evergreen candidate was skipped, or a checklist signal wasn't evaluated. Use the result, and surface the warning to the user in the same breath rather than reporting a clean run.

## Terms

Every bolded term used across this skill family (Resource, Literature note, Reference note, Evergreen note, Claim, Take, Session, Backlog, Candidate, Gate, and the rest) is defined in `.slipbox/GLOSSARY.md`. Read it before treating any bolded term as self-explanatory.
