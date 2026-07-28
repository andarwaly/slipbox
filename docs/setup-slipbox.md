# setup-slipbox

One-time onboarding for the slipbox skill family. Discovers your vault's conventions, analyzes your writing style, and initializes the `idea.db` database that all other skills depend on. Run once per vault; run again only if you want to update conventions.

## When to use

Run this before using any other slipbox skill. It discovers conventions from your vault structure and existing notes (filename casing, folder paths, Obsidian templates), interviews you about your clip preferences (content types and transcript languages), and analyzes your writing voice. If you already have a `.slipbox/config.json`, it can re-run to detect and reconcile any drift.

## How it works

1. **Prerequisite check** — verifies `sqlite3`, `youtube-transcript-api`, and `defuddle` are available (the last skippable if you've said you have no interest in clipping video). Asks before installing anything missing; never installs without that ask.
2. **Explore** — checks for existing signal: `.obsidian/` templates, any `AGENTS.md` or `CLAUDE.md` files, existing note folders (Literature, Reference, Evergreen), and whether `.slipbox/` already exists. This branches three ways: no `.slipbox/` at all (first run), `.slipbox/` with `config.json` present (triggers a drift-check re-run instead), or `.slipbox/` with `config.json` missing (an interrupted prior run — resumes with a clean restart of the conventions/style steps, since there's no config yet to diff against).
3. **Conventions** — interviews you about filename casing, folder paths, note templates, frontmatter field names, and clip config (content types, transcript languages). Recommends defaults and verifies each one against an actual note before moving on. Your three note templates (literature, reference, evergreen) usually already exist and just get their path confirmed — but the four clip templates (article, news, social, video) usually don't yet, since clipping is newer than note-taking for most vaults. For any of those that are missing, it drafts one with you conversationally: explaining which variables are available and what each one does in plain language as it goes, rather than pointing you at a reference file to figure out on your own.
4. **Style analysis** — either analyzes your existing corpus to draft a `.slipbox/style-profile.md`, or interviews you directly for a greenfield vault. Both paths fill in a fixed section skeleton (8 headings for the corpus path, 5 fields for the greenfield path) rather than composing structure freely, so every vault's profile is organized the same way.
5. **Humanize checklist** — copies a fixed, skill-package-versioned `.slipbox/humanize-checklist.md` into your vault to flag passages drifting into generic AI-speak, without rewriting anything. It's the same checklist for every vault (not tuned per-voice); it points at your own `style-profile.md`/stated style for register context when applying its rules, and gets refreshed automatically on any re-run.
6. **Database init** — initializes `.slipbox/idea.db` with the schema all other skills use.
7. **Config write** — drafts `.slipbox/config.json` from everything confirmed above, shows it to you, and writes it only after your approval and after it validates against the skill's own config schema.

## Usage

Invoke it by name when you're ready to initialize a slipbox:

> Set up my slipbox vault.

Once it completes, all five other slipbox skills are ready to use.

## Installation

This skill ships as part of the `andarwaly/slipbox` repo:

```bash
npx skills add andarwaly/slipbox
```

See the [skill source](../skills/setup-slipbox/) for the full agent-facing instructions.
