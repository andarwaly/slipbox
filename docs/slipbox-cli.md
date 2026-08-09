# slipbox

The CLI every slipbox skill uses to read and write `.slipbox/evergreen/*.md`, `.slipbox/links.jsonl`, and `.slipbox/config.json`. No skill ever hand-parses frontmatter or hand-appends to the links log — everything goes through this one script, installed at `.slipbox/bin/slipbox` by `setup-slipbox`.

This page documents the CLI itself, for anyone reading or auditing the skill family rather than running one skill in particular. It doesn't replace the invocations shown inline in each skill's own `SKILL.md` — those are the ones an agent actually follows.

## Command surface

```
slipbox evergreen add    --slug SLUG --reason "..."
slipbox evergreen find   [--status S]
slipbox evergreen update <slug> [--status S] [--note-path P] [--slug NEW] [--iteration N]
slipbox links add        --source S --target T --rel cites|extends
slipbox links find       [--source S] [--target T] [--rel cites|extends]
slipbox config get       [<dotted.path>]
slipbox config set       <dotted.path> <value>
slipbox humanize check   <file> [--language LANG]
slipbox --help | --version
```

There is no `seeds` table and no `init`/`migrate` command — this CLI has never used a
database. `evergreen` is a flagged tension or sparked idea, one YAML-frontmatter file
per candidate under `.slipbox/evergreen/`, written by `ground-claim`, `ground-term`, or
`find-connections` and read back by `ground-my-take`. `links` is an append-only JSONL
log of typed edges (`cites`, `extends`) — separate from, and in addition to, the
`[[wikilink]]`s a note's own prose uses for Obsidian's backlink pane.

## `humanize check`

`slipbox humanize check <file> [--language LANG]` runs only the checklist's `detection.mechanical` signals. It reads `.slipbox/style-profile.json` only to decide whether English-scoped signals are available; an explicit `--language` overrides the profile for the checked passage. It never reads profile baselines and never falls back to `stated_style.json`. Each signal declares its own `single` or `cluster` threshold. Cross-signal counting uses raw presence from mechanical signals only. Judgment signals are handled by the calling skill. The checklist's declarative rewrite, preference-context, and final-audit phases remain in the JSON; the calling skill executes them.

The JSON result includes per-signal hits, signals that passed their own thresholds, the mechanical cross-signal result, and a reminder that the caller must apply `detection.judgment` separately.

`created_at`/`updated_at` on evergreen candidates are handled automatically — `created_at` on `add`, `updated_at` on any subsequent `update` call. No flag exists to set either directly; nothing needs one.

## Output and error conventions

Every command prints JSON by default. `find`/`get`-family commands accept `--format table` for a human-readable alternative. Exit code `2` means a usage error (bad flags, missing required argument); exit code `1` means a runtime failure (file not found, duplicate slug, etc.).

## Atomicity

`evergreen add` and `evergreen update` write via a temp file in the same directory, then an atomic rename (`os.replace`) — a write either fully lands or doesn't happen at all, never leaves a half-written file behind. `links add` appends a single line, which is atomic at the filesystem level for a line this short.

## Installation

`slipbox` is a bash script wrapping Python 3's standard library — no SQLite, no `PyYAML`, no dependency beyond what's already required for `config get/set` and `humanize check`. It's copied into a vault by `setup-slipbox`, never installed standalone — see [setup-slipbox.md](setup-slipbox.md).
