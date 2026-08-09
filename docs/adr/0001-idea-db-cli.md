---
status: superseded-by-0002
---

# idea-db CLI: schema ownership, bash runtime, per-vault install, JSON-first output

Every skill touching `idea.db` (`surface-ideas`, `ground-claim`, `ground-term`, `ground-my-take`, `write-checks`) used to embed raw `sqlite3`/SQL directly in its own prose. We built `idea-db`, a single bash script wrapping `sqlite3`, as the one shared interface every skill talks to `idea.db` through instead.

## Decisions

1. **Schema ownership is full and CLI-side.** `idea-db init`/`idea-db migrate` own schema creation and migration end-to-end; `setup-slipbox` no longer runs `sqlite3 < schema.sql` directly. `init` refuses on a schema-version mismatch (tracked via `PRAGMA user_version`) and points at `migrate` rather than self-healing silently.
2. **Runtime is bash wrapping `sqlite3`, not Node or Python** — despite `npx`-based installs already guaranteeing a Node runtime on every target OS. Writing cost for this scope outweighed the cross-platform-consistency benefit Node would have given for free.
3. **Install location is per-vault, not a shared cross-skill path.** `setup-slipbox` copies the canonical script into `.slipbox/bin/idea-db` on every run (always overwritten — it's versioned code, not user data). Rejected referencing the script via a relative path into `setup-slipbox`'s own folder (e.g. `../setup-slipbox/scripts/idea-db`): `npx skills add` supports installing a single skill alone, so a path assuming sibling skill folders isn't guaranteed to resolve.
4. **Output is JSON by default (`--format table` optional), with no TTY detection.** Exit 2 for usage errors, exit 1 for runtime failures. Deviates from the standard CLI convention of detecting TTY and defaulting to human-readable output, because the primary caller is always a skill mid-run, never a human at a prompt — the default should never change based on caller.

## Considered options

- **Node or Python CLI** — rejected; bash's lower writing cost won out for this scope.
- **Cross-skill relative path to one shared script** — rejected; breaks under single-skill `npx skills add` installs.
- **TTY-detected human-readable default** — rejected; no real interactive-human caller exists for this tool.

## Consequences

- Every skill touching `idea.db` talks to it exclusively through `idea-db`; none embeds raw SQL.
- Windows and Linux users need their own `sqlite3` install path noted in `setup-slipbox`'s docs — bash-wrapping assumes a Mac-like environment that isn't guaranteed elsewhere.
