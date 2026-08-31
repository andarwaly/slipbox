# setup-slipbox

One-time onboarding for the slipbox skill family. Discovers your vault's conventions, interviews you for stated note-shape and editing preferences, and installs the `slipbox` CLI that all other skills depend on. Run once per vault; run again only if you want to update conventions or preferences.

## When to use

Run this before using any other slipbox skill. It discovers conventions from your vault structure and existing notes (filename casing, folder paths, Obsidian templates), interviews you about clip preferences (content types and transcript languages), and interviews you for a stated profile of note shape, tone by note type, language, vocabulary, formatting, and editing behavior. It does not infer a voice model from a corpus. If you already have a `.slipbox/config.json`, it can re-run to detect and reconcile drift.

## How it works

1. **Prerequisite check** — verifies `python3` (the CLI's own runtime), `youtube-transcript-api`, and `defuddle` are available (the video-transcript check skippable if you've said you have no interest in clipping video), and checks `firecrawl`'s auth status. The check distinguishes three states, not two — missing, present, or present-but-broken (on `PATH` but failing when run, which counts as missing and is reported with the actual failure text). Asks before installing anything missing; never installs without that ask, and the install itself verifies the dependency is actually usable afterward, so a failed install is never silently treated as done. `firecrawl` is optional — a fallback for blocked fetches, mentioned in passing rather than treated as a blocker. Also checks, detect-and-report only, whether a TinyFish MCP tool is available — TinyFish is MCP-based, not a local dependency, so there's nothing to install for it; if it's missing, you're told once that it adds free fetching and is the only path that can read Threads for Social clips, and setup moves on regardless. No database dependency exists to check for.
2. **Explore** — checks for existing signal: `.obsidian/` templates, any `AGENTS.md` or `CLAUDE.md` files, existing note folders (Literature, Reference, Evergreen), and whether `.slipbox/` already exists. This branches three ways: no `.slipbox/` at all (first run), `.slipbox/` with `config.json` present (triggers a drift-check re-run instead), or `.slipbox/` with `config.json` missing (an interrupted prior run — resumes with a clean restart of the conventions/style steps, since there's no config yet to diff against).
3. **Conventions** — interviews you about filename casing, folder paths, filename/link-target prefixes (optional per-type symbols, e.g. `§`/`※`/`✱`; H1 headings stay clean), note templates, frontmatter field names (with an explicit option to defer any note type's field mapping until you actually write one), and clip config (content types, transcript languages). A newly drafted YouTube Video template includes a deterministic thumbnail cover from `{{video_id}}`; Article, News, and Social templates omit `cover:` because no verified generic image variable exists. Recommends defaults and verifies each one against an actual note before moving on.
4. **Stated note preferences** — interviews you for `.slipbox/style-profile.json`, a user-stated contract for note shape, tone by configured note type, language, vocabulary, formatting, and editing behavior. It does not analyze a corpus or create a separate `stated_style.json` file.
5. **Humanizer workflow snapshot** — copies a fixed, skill-package-versioned `.slipbox/humanize-checklist.json`.
6. **CLI install** — copies `slipbox` (the CLI every other skill uses to talk to `.slipbox/evergreen/`, `.slipbox/links.jsonl`, and `.slipbox/config.json` — no SQLite, plain files) into your vault at `.slipbox/bin/slipbox`, and creates `.slipbox/evergreen/`, `.slipbox/work/`, `.slipbox/cache/source-maps/`, and the links log. Work is always local; source-map cache persistence is asked separately.
7. **Config write** — drafts `.slipbox/config.json` from everything confirmed above, shows it to you, and writes it only after your approval and after it validates against the skill's own config schema.
8. **Copy `GLOSSARY.md` and write `.slipbox/AGENTS.md`** — copies the glossary in unconditionally, then writes `.slipbox/AGENTS.md` last, only once every other artifact above already exists. Its presence is the completion sentinel every other slipbox skill checks for, so a partial run must never leave it behind.

## Usage

Invoke it by name when you're ready to initialize a slipbox:

> Set up my slipbox vault.

Once it completes, every other slipbox skill is ready to use.

Setup reports cache inventory counts for compatible, missing, incompatible, older-compatible, unresolved-source, and orphaned entries. In an existing vault with Literature notes but no cache, it reads each complete Resource first and builds source-owned maps from the source, never from selective Literature content. It reconciles Core Idea, Source Points (or legacy Key Claims), Key Concepts, Mentioned, and Open Questions to source units with private statuses: matched, matched-with-qualification-risk, matched-to-multiple-units, unmatched, or source-support-unclear. Missing Resources block reconciliation and are reported; note semantics are not rewritten automatically. It offers cache choices—build missing + incompatible, a chosen scope, refresh all, or defer—separately from exact-heading `Key Claims` → `Source Points` migration choices (selected, all compatible, lazy/on first access, or defer). Lazy records authorization but performs the exact heading rename only when a compatible note is subsequently opened by a slipbox workflow; defer records no authorization. Unusual structures are skipped and reported. Reference migration is a third, independent authorization: its read-only audit reports prefixed H1s, legacy term/reference fields, aliases and provenance duplicates, Literature links in `sources`, unresolved sources, wrong Literature→Reference edges, and configured zone/type drift. It offers `all`, `selected`, `lazy`, or `defer`; resolvable records are normalized to clean H1s and deduplicated original Resource provenance, while unresolved structures are skipped and reported. Mechanical repair uses append-only ledger tombstones plus corrected Resource→Reference edges. Semantic migration is scoped separately and classifies removed material rather than silently deleting or reclassifying it. It asks for Git policy (`off`, `ask` recommended, or `auto`) only when a repository is detected; no Git-detection boolean is stored. The config schema requires `git` and `cache` objects and rejects tracked `.slipbox/work/`.

## Installation

This skill ships as part of the `andarwaly/slipbox` repo:

```bash
npx skills add andarwaly/slipbox
```

See the [skill source](../skills/setup-slipbox/) for the full agent-facing instructions.

New vaults explicitly choose whether saved notes keep blank lines between adjacent
Markdown blocks (`formatting.blank_lines_between_blocks`). Existing profiles may omit
this optional key and retain the legacy spaced behavior. The installed CLI includes
`slipbox note validate` for pre-write and post-write artifact checks on Literature,
Reference, and Evergreen notes only. Resource captures retain their content subtype
and use `/write-checks` Resource mode when synthesized content needs Style and Humanize checks.
