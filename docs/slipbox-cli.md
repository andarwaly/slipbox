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
slipbox filename format  --type TYPE --title TITLE [--preserve NAME]... [--uncertain NAME]...
slipbox note validate    --type literature|reference|evergreen --path PATH [--basename NAME] [--title TITLE]
slipbox humanize check   <file> [--language LANG]
slipbox work create  --kind KIND --activity ACTIVITY [--source PATH] [--target PATH]
slipbox work list    [--status STATUS] [--format table]
slipbox work inspect WORK_ID [--format table]
slipbox work update  WORK_ID [--status STATUS] [--activity ACTIVITY]
slipbox work resume  WORK_ID
slipbox work discard WORK_ID [--yes] [--no-input]
slipbox --help | --version
```

There is no `seeds` table and no `init`/`migrate` command — this CLI has never used a
database. `evergreen` is a flagged tension or sparked idea, one YAML-frontmatter file
per candidate under `.slipbox/evergreen/`, written by `make-literature-note`, `make-reference-note`, or
`find-connections` and read back by `make-evergreen-note`. `links` is an append-only JSONL
log of typed edges (`cites`, `extends`) — separate from, and in addition to, the
`[[wikilink]]`s a note's own prose uses for Obsidian's backlink pane.

## `note validate`

Validate the complete assembled draft before writing and again after re-reading the
saved path. It checks the complete basename and prefix position, mapped fields, YAML
quoting and list serialization, frontmatter zones, Markdown structure, and exactly one
terminal newline. Exit `0` means valid; exit `1` reports validation errors. Accepted
types are exactly `literature`, `reference`, and `evergreen`. Resource content
subtypes (`article`, `news`, `social`, `video`) are not validator types; Resource-mode
`/write-checks` checks synthesized content without this command. It does not
auto-disambiguate collisions or resolve semantic conflicts.

## `humanize check`

`slipbox humanize check <file> [--language LANG]` runs only the checklist's `detection.mechanical` signals. It reads `.slipbox/style-profile.json` only to decide whether English-scoped signals are available; an explicit `--language` overrides the profile for the checked passage. It never reads profile baselines and never falls back to `stated_style.json`. Each signal declares its own `single` or `cluster` threshold. Cross-signal counting uses raw presence from mechanical signals only. Judgment signals are handled by the calling skill. The checklist's declarative rewrite, preference-context, and final-audit phases remain in the JSON; the calling skill executes them.

The JSON result includes per-signal hits, signals that passed their own thresholds, the mechanical cross-signal result, and a reminder that the caller must apply `detection.judgment` separately.

`created_at`/`updated_at` on evergreen candidates are handled automatically — `created_at` on `add`, `updated_at` on any subsequent `update` call. No flag exists to set either directly; nothing needs one.

## Slug rules

A slug names a file inside `.slipbox/evergreen/`, never a path: `evergreen add` and `evergreen update` accept only letters, digits, dot, underscore, and hyphen, up to 128 characters, with no leading dot and no `..` segment. Anything else is a usage error rather than a normalized path, so a slug proposed from clipped source text can't place a file outside that directory. `--iteration` must be a non-negative integer.

## Output and error conventions

Every command prints JSON by default. `find`/`get`-family commands accept `--format table` for a human-readable alternative. Exit code `2` means a usage error (bad flags, missing required argument); exit code `1` means a runtime failure (file not found, duplicate slug, etc.).

Every failure prints one JSON object on stderr — `{"error": "..."}`, message-escaped so a path or slug containing a quote still leaves stderr parseable. Nothing ever reaches the caller as a raw Python traceback: unreadable and non-UTF-8 files, unparsable `config.json`/`humanize-checklist.json`/`style-profile.json`, malformed evergreen frontmatter, a corrupt `links.jsonl` line (named by line number), an uncompilable checklist regex (named by signal id), and a write into an unwritable directory each become one of these.

A survivable problem — one that doesn't invalidate the result — prints `{"warning": "..."}` on stderr and still exits `0`. Two cases exist: `evergreen find` skipping a file whose frontmatter won't parse, and `humanize check` meeting a signal type it doesn't implement (that signal is reported as `"skipped": "unsupported_type"` in the result, never counted as zero hits). A corrupt `links.jsonl`, by contrast, fails outright — a silently filtered edge would leave the caller a plausible-looking but incomplete result set with no way to notice.

An unrecognized flag, a misspelled one, a stray positional argument, a flag given without a value, a non-integer `--iteration`, and a `--format` other than `json`/`table` are all usage errors. None of them is ignored: `evergreen find --stat to-discuss` exits `2` rather than quietly dropping the filter and returning every row.

## `work`

Recoverable work is isolated in `.slipbox/work/<work_id>/manifest.json`. `work create`
records the kind (`resource`, `literature`, `reference`, `evergreen`, or `migration`),
activity, UTC timestamps, source/target identities and SHA-256 starting fingerprints,
and affected paths. Work IDs are sortable 26-character Crockford-Base32 identifiers.
The manifest is inspectable with `work inspect` and enumerable with `work list`; both
default to JSON, while `--format table` is an explicit opt-in.

`work update` checkpoints status (`active`, `blocked`, `failed`, `ready-to-finalize`,
`commit-failed`, or `repair-required`) and metadata. `work resume` compares the
recorded source and target fingerprints with their current files and returns a
`resumable` state; a mismatch marks the work `blocked`. It does not resume a
conversation. `work discard` deletes only the selected work directory and requires
`--yes` for non-interactive callers (use `--no-input` to make that requirement
explicit). Work is never deleted by age.

## Atomicity

`evergreen add`, `evergreen update`, and `config set` write via a temp file in the same directory, then an atomic rename (`os.replace`) — a write either fully lands or doesn't happen at all, never leaves a half-written file or a truncated `config.json` behind. A failed write cleans up its own temp file. `links add` appends a single line, which is atomic at the filesystem level for a line this short.

The one non-atomic step left is `evergreen update --slug NEW`, a write of the new file followed by a delete of the old one. If the delete fails, the command reports that both slugs now exist instead of reporting a clean rename.

## Installation

`slipbox` is a bash script wrapping Python 3's standard library — no SQLite, no `PyYAML`, no dependency beyond what's already required for `config get/set` and `humanize check`. It's copied into a vault by `setup-slipbox`, never installed standalone — see [setup-slipbox.md](setup-slipbox.md).

Because the install unit is that one file, shared code lives inside it rather than in a repo-level module an installed skill would never receive: every command's Python body runs through the `py` wrapper, which prepends one prelude holding the single implementation of error/warning exits, frontmatter parse/serialize, atomic write, row printing, and dotted-path lookup. On the shell side, flag reading, `--format`/`--rel` validation, and `<group> <action>` dispatch are shared the same way, so each of the error messages above exists in exactly one place.
