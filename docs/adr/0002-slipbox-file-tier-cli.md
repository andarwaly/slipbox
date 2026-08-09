---
status: accepted
---

# slipbox CLI: SQLite retired, file-tier evergreen/links, renamed from idea-db

Supersedes [0001-idea-db-cli.md](0001-idea-db-cli.md). `idea-db`'s `seeds` table (and the `surface-ideas` skill that fed it) is retired entirely — literature/term tracking is now derived on demand from existing notes' own frontmatter and wikilinks. `evergreen` and `links` no longer need SQLite as their storage engine once `seeds` is gone, since every remaining SQL touchpoint only existed because it shared a database with `seeds`.

## Decisions

1. **SQLite dropped entirely.** `evergreen` becomes one YAML-frontmatter file per candidate under `.slipbox/evergreen/`, written atomically (`tempfile.mkstemp` + `os.replace`). `links` becomes an append-only `.slipbox/links.jsonl` log — edges have no natural filename, so a directory-per-edge doesn't fit; a flat log costs nothing given `links` was already confirmed write-only (nothing reads it back until `find-connections` needed to, which is why `links find` was added in this same pass). `config`/`humanize check` were never SQL-backed and are untouched.
2. **Runtime stays bash wrapping Python 3 stdlib — the same split the SQLite-era script already had.** `config get/set` and `humanize check` already shelled out to `python3` for JSON handling before this rewrite; the same split now extends to `evergreen`'s YAML-frontmatter read/write. Considered switching the whole CLI to Python given SQL (bash's original reason for existing) is gone — rejected: the frontmatter here is flat `key: value`, and Python has no YAML parser in its stdlib either (`PyYAML` would be a new dependency, the same category of cost SQLite's removal was trying to avoid). Bash-wrapping-Python was already the shape for two of the CLI's commands; extending it to a third is zero new surface, not a new pattern.
3. **`init`/`migrate` dropped as subcommands entirely.** Their whole remaining job — ensuring `.slipbox/evergreen/`/`links.jsonl` exist, checking a schema version — either shrinks to two trivial filesystem operations (`mkdir -p`, `touch`, done inline by `setup-slipbox`) or disappears outright (no schema left to have a version).
4. **Renamed `idea-db` → `slipbox`.** The old name described a database that no longer exists. Checked the obvious naming collision (a CLI named the same as the whole skill family) against real precedent (`git`, `docker`) and found it's not a problem — the binary is always invoked by full path (`.slipbox/bin/slipbox`), never bare on `PATH`.

## Considered options

- **Keep SQLite, drop only `seeds`** — rejected; once `seeds`' tables/triggers/FTS5 index are gone, nothing else in the schema needs a relational engine at all, and keeping one around for two remaining tables that fit trivially into flat files would be exactly the kind of leftover machinery the broader `setup-slipbox` overengineering audit exists to catch.
- **Rewrite the whole CLI in Python** — rejected; no SQL left to justify the switch, and Python doesn't avoid a dependency here either (no stdlib YAML parser).
- **Keep the name `idea-db`** — rejected; actively misleading once there's no database.

## Consequences

- Every skill touching evergreen candidates or links talks to them exclusively through `slipbox`; none hand-parses frontmatter or hand-appends to `links.jsonl`.
- `setup-slipbox`'s prerequisite check drops `sqlite3` entirely — one fewer dependency a new user needs already installed.
- `.slipbox/evergreen/*.md` and `.slipbox/links.jsonl` are plain text, git-mergeable, sync-native — no binary-diff risk under any sync mechanism (git, Obsidian Sync, iCloud), unlike a WAL-mode SQLite file.
