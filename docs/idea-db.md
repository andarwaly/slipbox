# idea-db

The CLI every slipbox skill uses to read and write `.slipbox/idea.db` and `.slipbox/config.json`. No skill ever touches either file with raw SQL or direct JSON edits — everything goes through this one script, installed at `.slipbox/bin/idea-db` by `setup-slipbox`.

This page documents the CLI itself, for anyone reading or auditing the skill family rather than running one skill in particular. It doesn't replace the invocations shown inline in each skill's own `SKILL.md` — those are the ones an agent actually follows.

## Command surface

```
idea-db init
idea-db migrate
idea-db seeds find     [--target-type T] [--status S] [--resource R] [--query Q]
idea-db seeds add      --resource R --type T --target-type TT --reason "..."
idea-db seeds update   <slug> [--status S] [--note-path P] [--slug NEW] [--discussion-path P] [--type T]
idea-db evergreen add    --slug SLUG --reason "..."
idea-db evergreen find   [--status S]
idea-db evergreen update <slug> [--status S] [--note-path P] [--slug NEW] [--iteration N]
idea-db links add        --source S --target T --rel cites|extends
idea-db config get       [<dotted.path>]
idea-db config set       <dotted.path> <value>
idea-db humanize check   <file>
idea-db --help | --version
```

`seeds` and `evergreen` are the two backlog tables — a candidate idea or term surfaced by `surface-ideas` lands in `seeds`; a flagged tension from `ground-claim`, `ground-term`, or `ground-my-take` lands in `evergreen`. `links` records typed edges between written notes (`cites`, `extends`) for CLI/programmatic queries — separate from, and in addition to, the `[[wikilink]]`s a note's own prose uses for Obsidian's backlink pane.

`created_at`/`updated_at` on both backlog tables are handled automatically — `created_at` on insert, `updated_at` on any subsequent `update` call, via triggers (`trg_seeds_updated_at`, `trg_evergreen_updated_at`). No flag exists to set either directly; nothing needs one.

## Output and error conventions

Every command prints JSON by default. `find`/`get`-family commands accept `--format table` for a human-readable alternative. Exit code `2` means a usage error (bad flags, missing required argument); exit code `1` means a runtime failure (constraint violation, missing file, etc.).

## `--query`'s matching semantics

`seeds find --query` runs against a SQLite FTS5 index (`seeds_fts`) over the `reason` column, not a `LIKE` substring scan. That means:

- Matching is **exact-token, case-insensitive** — `--query confirm` will not match a row whose `reason` contains "confirmation." Pass the term's own plain name, not a partial word.
- No stemming — `--query CRDTs` will not match a row containing only "CRDT."
- Explicit prefix matching is available via a trailing `*` (`--query "confirm*"`), if a skill ever needs it — none currently do.

This matters anywhere a skill used to describe a raw `LIKE '%...%'` lookup: the substitute `seeds find --query` call is not a drop-in behavioral match, just a drop-in syntactic one.

## Installation

`idea-db` is a bash script wrapping `sqlite3`. macOS ships both by default. On Windows, run it through WSL or Git Bash and install `sqlite3.exe` yourself first. On Linux, install `sqlite3` via your distro's package manager if `setup-slipbox`'s prerequisite check reports it missing.

It's copied into a vault by `setup-slipbox`, never installed standalone — see [setup-slipbox.md](setup-slipbox.md).
