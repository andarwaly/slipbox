---
name: setup-slipbox
description: One-time onboarding for the slipbox skill family — discovers vault conventions, writing style, and clip preferences; initializes idea.db. Run once per vault; re-run only to change conventions.
disable-model-invocation: true
license: MIT
metadata:
  version: "1.0.0"
---

# Setup Slipbox

Every other skill in this family reads `.slipbox/config.json` before it writes anything, and fails fast with "run setup-slipbox first" if it's absent. This skill produces `config.json` plus `idea.db`, `style-profile.json`, and `humanize-checklist.json` through the steps below: prerequisite check, explore, Section A (conventions + clip config), Section B (style), humanize checklist, idea.db init, config write. Four of those outputs are built from fixed assets rather than composed fresh each run — `assets/config.schema.json`, `assets/humanize-checklist.json`, `assets/style-profile.schema.json`, and `assets/stated-style.schema.json` — so re-running this skill on different vaults produces structurally consistent files, not just similarly-worded ones. `config.json` can also be edited after this first setup without re-running the whole interview, via the `idea-db config get`/`idea-db config set` CLI (see Step 7).

## 0. Prerequisites

This is the only place in the slipbox family that installs anything — every other skill that hits a missing dependency stops and points back here rather than installing it inline.

Run `scripts/check-prereqs.sh` and read its report. It checks `sqlite3` on PATH, `youtube_transcript_api` importability, and `defuddle` resolvability via `npx`, and only detects — it never installs anything itself. The video-transcript check can be skipped entirely if the user has already said they have no interest in clipping video; otherwise check all three by default.

For each dependency the report marks missing: stop, tell the user what it's needed for (`sqlite3` for initializing `idea.db`; `youtube-transcript-api` for `clip-resource`'s Video path; `defuddle` for `clip-resource`'s Article and News path), and ask explicitly before doing anything about it — never install without that per-dependency ask. If the user agrees, run `scripts/install-prereqs.sh <dependency>` for just that one dependency (`sqlite3`, `youtube-transcript-api`, or `defuddle`). If they'd rather install it themselves, tell them to re-run this skill once it's in place.

**Done when:** every dependency the report flagged has been either installed, explicitly deferred by the user, or the user has said they'll handle it themselves.

## 1. Explore (no questions yet)

Check the vault for existing signal before asking the user anything:

- `.obsidian/` for a `templates/` folder and Templater plugin config (`.obsidian/plugins/templater-obsidian`), which show the vault's real template location and syntax.
- Root `AGENTS.md` or `CLAUDE.md` for conventions the user already wrote down.
- Existing `Literature`/`Term`/`Evergreen` (or similarly named) folders — these are both a convention signal and a style corpus for Section B.
- An existing `.slipbox/` directory. Its presence branches three ways, not two:
  - `.slipbox/config.json` exists → this is a re-run; switch to the drift-check flow in Step 8.
  - `.slipbox/` exists but `config.json` does not → an interrupted prior run. Check individually for `idea.db`, `style-profile.json`/`stated_style.json`, and `humanize-checklist.json` — don't assume `idea.db`'s presence alone tells you how far the prior run got. Tell the user setup was interrupted before completion, then **resume with a clean restart of Sections A/B below** (this and the first-run path are identical from here — there is no partial-answer persistence to resume from, and no existing `config.json` to diff against, so Step 8's drift-check mechanics don't apply). Never delete or overwrite whatever partial artifacts already exist until their step is reached normally.
  - No `.slipbox/` at all → first run, proceed below.

**Done when:** you know, for each check above, whether it found something or came up empty, and which of the three branches above applies.

## 2. Section A: conventions

Present what you found, one item at a time. Recommend a default and lead with it — e.g. "No filename convention found. I recommend kebab-case (`my-note-title.md`): sound right, or do you use something else?" Silence is not confirmation; wait for an explicit answer per item before moving to the next.

- **Paths**: `resources/`, `literature/`, `evergreen/`, and the term notes' folder.
- **Filename casing** per note type (kebab-case, Title Case, snake_case, or whatever the vault already does).
- **Templates**: three note templates (literature, term, evergreen) plus four resource templates (article, news, social, video) — seven total, each with its own explicit path. These are real Obsidian template files: the core Templates plugin's default location, or Templater's if the user already has it configured. Do not invent a separate agent-native template spec.
  - **The three note templates almost always already exist** — resolve their path and move on, same as any other convention item.
  - **The four resource templates usually don't** — the templates *folder* typically exists (from note-taking), but article/news/social/video `.md` files inside it typically don't, since clipping is a newer concept for most vaults than note-taking. For each one that's missing at its resolved path, offer to draft it together right there rather than asking the user to go write Obsidian template syntax cold:
    1. Tell them which variables apply to this content type and what each does, in plain language — pull this from `../clip-resource/references/variable-glossary.md` and `../clip-resource/references/filter-glossary.md`, but never point the user at those files directly; you are the interface to that reference, not a librarian handing over a card catalog.
    2. Ask what they want captured in the note and in what order (title, source link, a raw excerpt, a synthesized summary, etc.).
    3. As you propose each variable, explain bare vs. quoted inline, concretely: "`{{content}}` pulls the article body verbatim; if you'd rather have a compressed summary instead, that's a quoted instruction like `{{"a 3-sentence summary of the article"}}` — I'll write whichever one you want here." Do not make the user learn the bare/quoted rule in the abstract before they can make this choice.
    4. Write the draft to the resolved path, show it, and let them edit or approve before moving to the next missing template.
  - This drafting help is conversational, not a fixed asset — template *content* reflects the user's own note structure and is never the same across two vaults, unlike `config.json`/`humanize-checklist.json`/`style-profile.json` elsewhere in this skill.
- **`field_map`**: for each required field below, resolve one of (a) map onto an existing user property, (b) create the standard field, or (c) explicit opt-out. When mapping onto an EXISTING property, read its actual type from the note (Text/List/Number/Checkbox/Date/Date & Time) and record that discovered type in the field_map entry — don't assume a type. When creating a NEW field, assign the type that fits its semantic nature, per this table (still verify+record the discovered type instead when mapping onto an existing property):
  - Literature: `type` → text, `created` → date, `source` → list + wikilink: true.
  - Term: `type` → text, `created` → date, `sources` → list + wikilink: true, `aliases` (optional) → list, no wikilink.
  - Evergreen: `type` → text, `created` → date, `derived-from` → list + wikilink: true.

  Never map any of these onto the reserved `tags`, `aliases`, or `cssclasses` properties. The required fields themselves, for reference:
  - Literature: `type: literature`, `created`, `source: [[resource]]`.
  - Term: `type: term`, `created`, `sources: [...]` (array/multitext — grows with each extension), `aliases: [...]` (optional).
  - Evergreen: `type: evergreen`, `created`, `derived-from: [[...]]` (bare wikilink list, no reasons attached — reasons stay in the note body).
- **Clip config** (folded into this same flow, not a separate gate):
  - All four resource content-types (article, news, social, video) are on by default. Ask only about exceptions the user wants to turn off.
  - Transcript language: ask which languages are wanted (multi-select). Only ask for a priority order if more than one language is selected.
  - This runs unconditionally, regardless of whether the user already has some other clipper tool in their workflow.

**Done when:** the user has explicitly confirmed or corrected every item above, including the field_map verification reads.

## 3. Section B: style (corpus-gated)

Check whether Step 1 found a real note corpus (the user's own notes only — exclude `resources/` and exclude formal/academic writing that isn't representative of their voice).

- **Corpus exists:** start from `assets/style-profile.schema.json` — its 9 required top-level fields (`voice_summary`, `tone`, `sentence_rhythm`, `punctuation_fingerprint`, `lexicon`, `structure_mechanics`, `stance`, `language`, `exemplar_snippets`) are fixed and must not be renamed, reordered, merged, or split. Analyze the corpus deeply and fill in each field per the schema's own field descriptions and enums, including `language` (`primary`, `additional`, `code_switching: none|register-gated|free-mixing`) — detect this directly from the corpus, the same way you'd detect sentence rhythm or punctuation habits. Show the draft to the user. They edit or approve it. Only write `.slipbox/style-profile.json` after approval, validated against `assets/style-profile.schema.json`.

- **Greenfield (no corpus):** start from `assets/stated-style.schema.json` — its required fields (`person`, `pacing`, `register`, `tone`, `forbidden_vocabulary`) are fixed. Interview the user directly against each field, asking about `language` (primary language, any additional ones, and code-switching behavior) the same way you'd ask about person/pacing/register/tone, and record their answers as `.slipbox/stated_style.json` in place of a style profile.

These two paths are mutually exclusive — never run both, and never produce a `style-profile.json` that mixes a stated fallback with corpus analysis.

**Done when:** either `.slipbox/style-profile.json` is approved and written, or the greenfield interview's `stated_style.json` is confirmed and recorded for Step 7.

## 4. Write `.slipbox/humanize-checklist.json`

Canonical: copy `assets/humanize-checklist.json` verbatim to `.slipbox/humanize-checklist.json`. Do not edit its content, tiers, or wording — it is versioned at the skill-package level (updated centrally as AI-vocabulary trends shift, shipped with skill releases), not per-vault. Explain to the user why it exists regardless of preference: it protects their own words from drifting into generic AI patterns, and it never rewrites anything on its own — it only flags a cluster of 2 or more signals in the same passage, per its own stated rule. The checklist itself points at `.slipbox/style-profile.json`/`stated_style.json` for register context at application time — that pointer is fixed data in the copied file, not something this step fills in.

**Done when:** `.slipbox/humanize-checklist.json` matches `assets/humanize-checklist.json` exactly.

## 5. Initialize `idea.db`

Only if `.slipbox/idea.db` does not already exist:

```bash
mkdir -p .slipbox
sqlite3 .slipbox/idea.db < skills/setup-slipbox/assets/schema.sql
```

Never overwrite an existing `idea.db` — if it's already there, leave it untouched and say so.

**Done when:** `.slipbox/idea.db` exists and contains the schema's tables.

## 6. Write `.slipbox/config.json`

Draft the config from everything confirmed in Sections A and B, against the fields defined in `assets/config.schema.json`:

- `paths` — the resources/literature/evergreen/term folder paths from Step 2.
- `filenames` — casing per note type.
- `frontmatter` — the field_map from Step 2, per type (literature/term/evergreen); each entry carries `name`/`type`/`wikilink` (or the bare string/`false` shorthand), validated against the updated `assets/config.schema.json`.
- `links.style` — the link style discovered/confirmed for `derived-from`, `sources`, `source`.
- `templates` — seven explicit paths: `literature_path`, `term_path`, `evergreen_path`, `article_path`, `news_path`, `social_path`, `video_path`.
- `transcript_languages` — ordered list from Step 2's clip config.

Show the draft to the user, let them edit it, then validate the approved draft against `assets/config.schema.json` before writing. If validation fails, fix the draft and re-validate — never write a config that doesn't conform.

**Done when:** `.slipbox/config.json` is written, matches the approved draft, and validates against `assets/config.schema.json`.

## 7. Done

Tell the user what was created: `.slipbox/config.json`, `.slipbox/idea.db`, `.slipbox/style-profile.json` (or the greenfield `stated_style.json` record), `.slipbox/humanize-checklist.json`. Tell them which skills depend on this having run first: `clip-resource`, `surface-ideas`, the ground-family skills that write notes from it — `grounding` (the bare engine, invoked directly for ad-hoc grounding), `ground-me` (literature-style passthrough), `ground-claim` (literature notes), `ground-term` (term notes), and `ground-my-take` (evergreen notes) — and `write-checks`, which every note-writing skill above runs against `style-profile.json`/`stated_style.json` and `humanize-checklist.json` before writing. Also tell them that individual `config.json` values can be changed later without re-running this whole setup, via `idea-db config set <dotted.path> <value>` (and `idea-db config get` to inspect current values).

## 8. Re-run semantics (drift check, manual trigger only)

Triggered only when the user explicitly asks to re-run, or when Step 1 finds an existing `.slipbox/`. Never runs automatically otherwise.

1. Validate the existing `.slipbox/config.json` against `assets/config.schema.json` first, before doing anything else. A file that predates the schema or was hand-edited may not conform — surface any validation errors to the user before proceeding to the diff, rather than feeding a malformed file straight into it.
2. Re-discover conventions and style the same way as Steps 1–3, using the current state of the vault.
3. Diff the re-discovered conventions against the existing `.slipbox/config.json`.
4. Report specific mismatches, e.g. "config says kebab-case, the last 12 notes are Title Case" — name the field and both values, don't just say something changed.
5. For each mismatch, ask the user which side wins. Do not re-ask questions that didn't drift.
6. Update `config.json` with the resolved answers, then re-validate against `assets/config.schema.json` before writing.
7. Refresh `.slipbox/style-profile.json` from the larger corpus (still against the fixed `assets/style-profile.schema.json` shape — the diff below depends on both versions sharing that structure), diff old vs. new, and show the user what changed before overwriting it.
8. Re-copy `assets/humanize-checklist.json` to `.slipbox/humanize-checklist.json`, overwriting the existing copy — this picks up any skill-package-level update to the canonical checklist since the vault was last set up.

**Never** overwrite `idea.db`, `.slipbox/discussions/`, or any existing note during a re-run.

**Done when:** `config.json` reflects only the mismatches the user resolved and re-validates against `assets/config.schema.json`, the user has seen the style-profile diff (if any), and `.slipbox/humanize-checklist.json` matches the current `assets/humanize-checklist.json`.
