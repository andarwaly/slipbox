---
name: setup-slipbox
description: One-time onboarding for the slipbox skill family — discovers vault conventions, writing style, and clip preferences; initializes idea.db. Run once per vault; re-run only to change conventions.
disable-model-invocation: true
license: MIT
metadata:
  version: "1.0.0"
---

# Setup Slipbox

Every other skill in this family reads `.slipbox/config.json` before it writes anything, and fails fast with "run setup-slipbox first" if it's absent. This skill produces `config.json` plus `idea.db`, `style-profile.md`, and `humanize-checklist.md` through the steps below: prerequisite check, explore, Section A (conventions + clip config), Section B (style), humanize checklist, idea.db init, config write.

## 0. Prerequisites

This is the only place in the slipbox family that installs anything — every other skill that hits a missing dependency stops and points back here rather than installing it inline.

Run `scripts/check-prereqs.sh` and read its report. It checks `sqlite3` on PATH, `youtube_transcript_api` importability, and `defuddle` resolvability via `npx`, and only detects — it never installs anything itself. The video-transcript check can be skipped entirely if the user has already said they have no interest in clipping video; otherwise check all three by default.

For each dependency the report marks missing: stop, tell the user what it's needed for (`sqlite3` for initializing `idea.db`; `youtube-transcript-api` for `clip-resource`'s Video path; `defuddle` for `clip-resource`'s Article and News path), and ask explicitly before doing anything about it — never install without that per-dependency ask. If the user agrees, run `scripts/install-prereqs.sh <dependency>` for just that one dependency (`sqlite3`, `youtube-transcript-api`, or `defuddle`). If they'd rather install it themselves, tell them to re-run this skill once it's in place.

## 1. Explore (no questions yet)

Check the vault for existing signal before asking the user anything:

- `.obsidian/` for a `templates/` folder and Templater plugin config (`.obsidian/plugins/templater-obsidian`), which show the vault's real template location and syntax.
- Root `AGENTS.md` or `CLAUDE.md` for conventions the user already wrote down.
- Existing `Literature`/`Reference`/`Evergreen` (or similarly named) folders — these are both a convention signal and a style corpus for Section B.
- An existing `.slipbox/` directory — its presence means this is a re-run; switch to the drift-check flow in Step 8 instead of the first-run flow below.

**Done when:** you know, for each check above, whether it found something or came up empty.

## 2. Section A: conventions

Present what you found, one item at a time. Recommend a default and lead with it — e.g. "No filename convention found. I recommend kebab-case (`my-note-title.md`): sound right, or do you use something else?" Silence is not confirmation; wait for an explicit answer per item before moving to the next.

- **Paths**: `resources/`, `literature/`, `evergreen/`, and the reference notes' folder.
- **Filename casing** per note type (kebab-case, Title Case, snake_case, or whatever the vault already does).
- **Templates**: three note templates (literature, reference, evergreen) plus four resource templates (article, news, social, video) — seven total, each with its own explicit path. These are real Obsidian template files: the core Templates plugin's default location, or Templater's if the user already has it configured. Do not invent a separate agent-native template spec.
- **`field_map`**: for each required field below, resolve one of (a) map onto an existing user property, (b) create the standard field, or (c) explicit opt-out. Then **verify** by reading one real note of that type and confirming the property round-trips (present, correctly typed, not silently dropped by the template). Never map any of these onto the reserved `tags`, `aliases`, or `cssclasses` properties.
  - Literature: `type: literature`, `created`, `source: [[resource]]`.
  - Reference: `type: reference`, `created`, `sources: [...]` (array/multitext — grows with each extension), `aliases: [...]` (optional).
  - Evergreen: `type: evergreen`, `created`, `derived-from: [[...]]` (bare wikilink list, no reasons attached — reasons stay in the note body).
- **Clip config** (folded into this same flow, not a separate gate):
  - All four resource content-types (article, news, social, video) are on by default. Ask only about exceptions the user wants to turn off.
  - Transcript language: ask which languages are wanted (multi-select). Only ask for a priority order if more than one language is selected.
  - This runs unconditionally, regardless of whether the user already has some other clipper tool in their workflow.

**Done when:** the user has explicitly confirmed or corrected every item above, including the field_map verification reads.

## 3. Section B: style (corpus-gated)

Check whether Step 1 found a real note corpus (the user's own notes only — exclude `resources/` and exclude formal/academic writing that isn't representative of their voice).

- **Corpus exists:** analyze it deeply and draft `.slipbox/style-profile.md` with exactly these 8 sections:
  1. Voice summary
  2. Tone on NN/g's four tone-of-voice axes (funny–serious, formal–casual, respectful–irreverent, matter-of-fact–enthusiastic) — one row per register if the corpus shows more than one
  3. Sentence & rhythm patterns
  4. Punctuation fingerprint
  5. Lexicon, plus a personalized forbidden-vocabulary list (words/phrases the corpus never uses)
  6. Structure & mechanics
  7. Stance & metadiscourse
  8. 3–5 verbatim exemplar snippets pulled directly from the corpus

  Show the draft to the user. They edit or approve it. Only write `.slipbox/style-profile.md` after approval.

- **Greenfield (no corpus):** interview the user directly about voice and tone (first person or third, terse or exploratory, technical or conversational, etc.) and record the answers as a `stated_style` fallback in place of a style profile.

These two paths are mutually exclusive — never run both, and never produce a style-profile.md that mixes a stated fallback with corpus analysis.

**Done when:** either `.slipbox/style-profile.md` is approved and written, or the greenfield interview's `stated_style` is confirmed and recorded for Step 7.

## 4. Write `.slipbox/humanize-checklist.md`

This file is not user-negotiable — write it regardless of preference, and explain why: it protects the user's own words from drifting into generic AI patterns, it doesn't rewrite anything on its own. Register-match its thresholds against the style profile's punctuation fingerprint (or the greenfield `stated_style` if no corpus exists). Structure it in three tiers:

- **T1 — structural/durable tics**: negative parallelism ("not x, but y"), significance-inflation words ("crucial", "pivotal"), rule-of-three constructions. These don't decay — check every time.
- **T2 — era-specific signals**: em-dash density relative to the user's own corpus baseline, versioned AI-vocabulary lists (words currently over-represented in AI writing).
- **T3 — decaying word lists**: versioned, pruned on each re-run as vocabulary trends shift.

Require a cluster of 2 or more signals before flagging a passage — a single hit is not enough. This checklist only flags; it never auto-rewrites.

**Done when:** `.slipbox/humanize-checklist.md` exists with all three tiers and the cluster-of->=2 rule stated explicitly.

## 5. Initialize `idea.db`

Only if `.slipbox/idea.db` does not already exist:

```bash
mkdir -p .slipbox
sqlite3 .slipbox/idea.db < skills/slipbox/setup-slipbox/assets/schema.sql
```

Never overwrite an existing `idea.db` — if it's already there, leave it untouched and say so.

**Done when:** `.slipbox/idea.db` exists and contains the schema's tables.

## 6. Write `.slipbox/config.json`

Draft the config from everything confirmed in Sections A and B, show it to the user, let them edit it, and only write it after approval. Fields:

- `paths` — the resources/literature/evergreen/reference folder paths from Step 2.
- `filenames` — casing per note type.
- `frontmatter` — the field_map from Step 2, per type (literature/reference/evergreen).
- `links.style` — the link style discovered/confirmed for `derived-from`, `sources`, `source`.
- `templates` — seven explicit paths: `literature_path`, `reference_path`, `evergreen_path`, `article_path`, `news_path`, `social_path`, `video_path`.
- `transcript_languages` — ordered list from Step 2's clip config.

**Done when:** `.slipbox/config.json` is written and matches the approved draft.

## 7. Done

Tell the user what was created: `.slipbox/config.json`, `.slipbox/idea.db`, `.slipbox/style-profile.md` (or the greenfield `stated_style` record), `.slipbox/humanize-checklist.md`. Tell them which skills depend on this having run first: `clip-resource`, `surface-ideas`, `write-literature-note`, `write-reference-note`, `write-evergreen-note`.

## 8. Re-run semantics (drift check, manual trigger only)

Triggered only when the user explicitly asks to re-run, or when Step 1 finds an existing `.slipbox/`. Never runs automatically otherwise.

1. Re-discover conventions and style the same way as Steps 1–3, using the current state of the vault.
2. Diff the re-discovered conventions against the existing `.slipbox/config.json`.
3. Report specific mismatches, e.g. "config says kebab-case, the last 12 notes are Title Case" — name the field and both values, don't just say something changed.
4. For each mismatch, ask the user which side wins. Do not re-ask questions that didn't drift.
5. Update `config.json` with the resolved answers.
6. Refresh `.slipbox/style-profile.md` from the larger corpus, diff old vs. new, and show the user what changed before overwriting it.

**Never** overwrite `idea.db`, `.slipbox/discussions/`, or any existing note during a re-run.

**Done when:** `config.json` reflects only the mismatches the user resolved, and the user has seen the style-profile diff (if any).
