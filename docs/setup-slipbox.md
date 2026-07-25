# setup-slipbox

One-time onboarding for the slipbox skill family. Discovers your vault's conventions, analyzes your writing style, and initializes the `idea.db` database that all other skills depend on. Run once per vault; run again only if you want to update conventions.

## When to use

Run this before using any other slipbox skill. It discovers conventions from your vault structure and existing notes (filename casing, folder paths, Obsidian templates), interviews you about your clip preferences (content types and transcript languages), and analyzes your writing voice. If you already have a `.slipbox/config.json`, it can re-run to detect and reconcile any drift.

## How it works

1. **Prerequisite check** — verifies `sqlite3` is on your PATH. Stops if it's missing.
2. **Explore** — checks for existing signal: `.obsidian/` templates, any `AGENTS.md` or `CLAUDE.md` files, existing note folders (Literature, Reference, Evergreen), and whether `.slipbox/` already exists (which triggers a drift-check re-run instead).
3. **Conventions** — interviews you about filename casing, folder paths, note templates, frontmatter field names, and clip config (content types, transcript languages). Recommends defaults and verifies each one against an actual note before moving on.
4. **Style analysis** — either analyzes your existing corpus to draft a `.slipbox/style-profile.md` (voice, tone, rhythm, punctuation patterns, vocabulary), or interviews you directly for a greenfield vault.
5. **Humanize checklist** — writes `.slipbox/humanize-checklist.md`, tuned to your voice patterns, to flag passages drifting into generic AI-speak without rewriting anything.
6. **Database init** — initializes `.slipbox/idea.db` with the schema all other skills use.
7. **Config write** — drafts `.slipbox/config.json` from everything confirmed above, shows it to you, and writes it only after your approval.

## Usage

Invoke it by name when you're ready to initialize a slipbox:

> Set up my slipbox vault.

Once it completes, all six other slipbox skills are ready to use.

## Installation

This skill ships as part of the `andarwaly/skills` collection:

```bash
npx skills add andarwaly/skills
```

See the [skill source](../../skills/slipbox/setup-slipbox/) for the full agent-facing instructions.
