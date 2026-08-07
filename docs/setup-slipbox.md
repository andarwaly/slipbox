# setup-slipbox

One-time onboarding for the slipbox skill family. Discovers your vault's conventions, interviews you for stated note-shape and editing preferences, and initializes the `idea.db` database that all other skills depend on. Run once per vault; run again only if you want to update conventions or preferences.

## When to use

Run this before using any other slipbox skill. It discovers conventions from your vault structure and existing notes (filename casing, folder paths, Obsidian templates), interviews you about clip preferences (content types and transcript languages), and interviews you for a stated profile of note shape, tone by note type, language, vocabulary, formatting, and editing behavior. It does not infer a voice model from a corpus. If you already have a `.slipbox/config.json`, it can re-run to detect and reconcile drift.

## How it works

1. **Prerequisite check** — verifies `sqlite3`, `youtube-transcript-api`, and `defuddle` are available (the last skippable if you've said you have no interest in clipping video). Asks before installing anything missing; never installs without that ask.
2. **Explore** — checks for existing signal: `.obsidian/` templates, any `AGENTS.md` or `CLAUDE.md` files, existing note folders (Literature, Reference, Evergreen), and whether `.slipbox/` already exists. This branches three ways: no `.slipbox/` at all (first run), `.slipbox/` with `config.json` present (triggers a drift-check re-run instead), or `.slipbox/` with `config.json` missing (an interrupted prior run — resumes with a clean restart of the conventions/style steps, since there's no config yet to diff against).
3. **Conventions** — interviews you about filename casing, folder paths, note templates, frontmatter field names, and clip config (content types, transcript languages). Recommends defaults and verifies each one against an actual note before moving on. Your three note templates (literature, reference, evergreen) usually already exist and just get their path confirmed — but the four clip templates (article, news, social, video) usually don't yet, since clipping is newer than note-taking for most vaults. For any of those that are missing, it drafts one with you conversationally: explaining which variables are available and what each one does in plain language as it goes, rather than pointing you at a reference file to figure out on your own.
4. **Stated note preferences** — interviews you for `.slipbox/style-profile.json`, a user-stated contract for note shape, tone by configured note type, language, vocabulary, formatting, and editing behavior. It does not analyze a corpus or create a separate `stated_style.json` file.
5. **Humanizer workflow snapshot** — copies a fixed, skill-package-versioned `.slipbox/humanize-checklist.json`. It contains detection, false-positive guidance, meaning-preserving rewrite instructions, stated-profile preference context, and final audit rules. Mechanical detection is language-gated and per-pattern; the snapshot never rewrites a note automatically and refreshes on re-run.
6. **CLI install and database init** — copies `idea-db` (the CLI every other skill uses to talk to `.slipbox/idea.db` and `.slipbox/config.json`) into your vault at `.slipbox/bin/idea-db`, then initializes `idea.db` through it.
7. **Config write** — drafts `.slipbox/config.json` from everything confirmed above, shows it to you, and writes it only after your approval and after it validates against the skill's own config schema.

**Platform note**: `idea-db` is a bash script wrapping `sqlite3`. macOS ships both by default. On Windows, run it through WSL or Git Bash, and install `sqlite3.exe` yourself first — it isn't preinstalled the way it is on macOS. On Linux, install `sqlite3` via your distro's package manager (`apt`, `dnf`, etc.) if the prerequisite check reports it missing.

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
