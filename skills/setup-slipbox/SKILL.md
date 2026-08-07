---
name: setup-slipbox
description: One-time onboarding for the slipbox skill family — discovers vault conventions, writing style, and clip preferences; initializes idea.db. Run once per vault; re-run only to change conventions.
disable-model-invocation: true
license: MIT
metadata:
  version: "1.0.0"
---

# Setup Slipbox

Every other skill in this family reads `.slipbox/config.json` before it writes anything, and fails fast with "run setup-slipbox first" if it's absent. This skill produces `config.json` plus `idea.db`, `style-profile.json`, and `humanize-checklist.json` through the steps below: prerequisite check, explore, Section A (conventions + clip config), Section B (stated note preferences), humanizer workflow snapshot, idea.db init, config write. Three of those outputs are built from fixed assets rather than composed fresh each run: `assets/config.schema.json`, `assets/humanize-checklist.json`, and `assets/style-profile.schema.json`. Re-running this skill on different vaults produces structurally consistent files, not just similarly-worded ones. `config.json` can also be edited after this first setup without re-running the whole interview, via the `idea-db config get`/`idea-db config set` CLI (see Step 7).

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
- Whatever `tags` actually seems to be used for in this vault — note it in plain language for Section A's presentation (e.g. subtype-marker, topic/subject labels, a catch-all, a minimal signal, some mixture, or not used at all). This is descriptive narration only, never a mapping decision, and never forced into a fixed category list — real vaults don't fit a clean taxonomy, so describe what's actually observed. `tags` itself is never mapped onto or written to by any field_map resolution, regardless of what this narration finds.
- An existing `.slipbox/` directory. Its presence branches three ways, not two:
  - `.slipbox/config.json` exists → this is a re-run; switch to the drift-check flow in Step 8.
  - `.slipbox/` exists but `config.json` does not → an interrupted prior run. Check individually for `idea.db`, `style-profile.json`, and `humanize-checklist.json` — don't assume `idea.db`'s presence alone tells you how far the prior run got. Tell the user setup was interrupted before completion, then **resume with a clean restart of Sections A/B below** (this and the first-run path are identical from here — there is no partial-answer persistence to resume from, and no existing `config.json` to diff against, so Step 8's drift-check mechanics don't apply). Never delete or overwrite whatever partial artifacts already exist until their step is reached normally.
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
### field_map

For each required field below, resolve one of (a) map onto an existing user property, (b) create the standard field, or (c) explicit opt-out. When mapping onto an EXISTING property, read its actual type from the note (Text/List/Number/Checkbox/Date/Date & Time) and record that discovered type in the field_map entry — don't assume a type. When creating a NEW field, assign the type that fits its semantic nature, per this table (still verify+record the discovered type instead when mapping onto an existing property), with a `zone` (top/bottom) alongside each type — zone only governs placement of fields being newly created, never fields mapped onto an existing property:
  - Literature: `type` → text, zone top; `created` → date, zone top; `source` → list + wikilink: true, zone bottom.
  - Term: `type` → text, zone top; `created` → date, zone top; `sources` → list + wikilink: true, zone bottom; `alt_names` (optional) — default: map onto Obsidian's reserved `aliases` property (type `list`, no wikilink; record `list` directly, skip the live-read-type step since `aliases` is Obsidian-fixed, not vault-specific) — or create fresh as `alt_names` (list, no wikilink, zone bottom) if the user prefers to keep it separate from `aliases`.
  - Evergreen: `type` → text, zone top; `created` → date, zone top; `derived-from` → list + wikilink: true, zone bottom; `updated-at` → datetime (not bare date — multiple revisions can land the same day), no wikilink, zone bottom.

  **`type`-occupancy check**, resolving the `type` field specifically (present in all three note types' field tables): this is a 3-way branch, not a simple create-or-map choice.
  - `type` is absent/unused in existing notes → create fresh with the standard name `type` (today's default, unchanged).
  - `type` already holds exactly the identity value needed (existing notes literally already have `type: literature`/`type: term`/`type: evergreen`) → map onto the existing `type` property directly, no new field needed.
  - `type` already holds something unrelated (e.g. a base/umbrella value like `note`) → stop and ask: recommend mapping slipbox's own type-identity onto a new, differently-named field (e.g. `note-type`) instead of colliding with the existing `type`, leaving the existing `type` property untouched. Offer the user the choice of field name — don't hardcode `note-type` as the only option, it's just the recommended default.

  **Type-mismatch check**, only for multi-valued fields (`source`s that grow: `sources`,
  `derived-from` — never `source`, which is genuinely single-valued and fits into an
  existing Text property fine): if the existing property's discovered type isn't List,
  it structurally can't hold what the field needs to grow into. Stop and ask, recommending
  mapping onto a new, standard-named List property instead and leaving the existing
  property untouched — the same recommend-a-default pattern as every other item in this
  section. Offer the other two answers too: point at a different existing property, or
  override and accept the mismatch anyway (least recommended, never the silent default).

  Never map any of these onto the reserved `tags`, `aliases`, or `cssclasses` properties — with exactly one named exception: Term's optional `alt_names` may map onto `aliases`, since the two are semantically identical (both mean "other names for this thing"), and this is in fact the default recommendation for that field (see the Term row above). No other field, on any note type, gets this carve-out. The required fields themselves, for reference:
  - Literature: `type: literature`, `created`, `source: [[resource]]`.
  - Term: `type: term`, `created`, `sources: [...]` (array/multitext — grows with each extension), `alt_names: [...]` (optional).
  - Evergreen: `type: evergreen`, `created`, `derived-from: [[...]]` (bare wikilink list, no reasons attached — reasons stay in the note body), `updated-at` (written on first write, refreshed every time an existing evergreen note is revisited/rewritten — mirrors `schema.sql`'s own `evergreen.updated_at` column, now also surfaced into the note's own frontmatter).
- **Clip config** (folded into this same flow, not a separate gate):
  - All four resource content-types (article, news, social, video) are on by default. Ask only about exceptions the user wants to turn off.
  - Transcript language: ask which languages are wanted (multi-select). Only ask for a priority order if more than one language is selected.
  - This runs unconditionally, regardless of whether the user already has some other clipper tool in their workflow.

**Done when:** the user has explicitly confirmed or corrected every item above, including the field_map verification reads.

## 3. Section B: stated note preferences

Build one user-stated preference profile at `.slipbox/style-profile.json`. Do not analyze a corpus, infer a voice fingerprint, or create `stated_style.json`. The profile tells note-writing skills how to shape and edit notes; it is not a sample-mimicry model.

Start from `assets/style-profile.schema.json` and interview the user against its fixed sections:

- `voice`: stated descriptors such as overall quality, verbosity, confidence, hedging, and energy. Record what the user says; never infer these from a corpus.
- `sentence_style`: average length, structure, list preference, paragraph shape, and conclusion placement.
- `tone_by_note`: inspect the actual note types under `config.json`'s `frontmatter` map and ask for the tone of each configured type. Never hardcode unsupported note types.
- `language`: primary language, secondary language, technical-term preference, and the user's own code-switching description. `code_switching` remains a free string until its vocabulary is settled.
- `vocabulary`: phrases the user says they often use and words or phrases they want avoided.
- `formatting`: bullet use, wikilinks, aliases, headings, quotes, and citation placement.
- `editing_style`: iterative editing, renaming, compression, and redundancy removal preferences.

Show the complete draft to the user. Let them edit or approve it. Verify preference-sensitive shape choices against an actual note where useful, but never treat that note as a corpus to analyze. Validate the approved profile against `assets/style-profile.schema.json` before writing `.slipbox/style-profile.json`.

**Done when:** the user has approved one stated profile, it validates against the fixed schema, and `.slipbox/style-profile.json` is written. No corpus branch and no `stated_style.json` output exist.

## 4. Write `.slipbox/humanize-checklist.json`

Canonical: copy `assets/humanize-checklist.json` verbatim to `.slipbox/humanize-checklist.json`. The snapshot records humanizer v2.8.0's detection, meaning-preserving rewrite, preference-context, and final-audit phases. Detection remains generic and fixed; it does not read profile baselines. The rewrite phase may read the stated profile through its `preference_context`. Explain that the file flags and guides but never rewrites automatically. Preserve its per-signal thresholds, language gating, false-positive guidance, and judgment-only signals. Re-copy it on every re-run so vaults receive package-level updates.

**Done when:** `.slipbox/humanize-checklist.json` matches `assets/humanize-checklist.json` exactly.

## 5. Install `idea-db` and initialize `idea.db`

Runs identically on every invocation, first run or re-run — no conditional branch:

```bash
mkdir -p .slipbox/bin
cp skills/setup-slipbox/scripts/idea-db .slipbox/bin/idea-db
chmod +x .slipbox/bin/idea-db
.slipbox/bin/idea-db init
```

The script copy is always overwritten (versioned code, not user data — distinct from `idea.db`/`config.json`, which are never overwritten). `idea-db init` owns the "does `idea.db` already exist" decision itself: it creates the db fresh if absent, succeeds as a no-op if already at the current schema version, and refuses with a pointer to `idea-db migrate` if the existing db is at an older schema version — never silently overwriting or self-healing. `setup-slipbox` never touches `sqlite3` directly.

**Done when:** `.slipbox/bin/idea-db` is installed and executable, and `.slipbox/idea.db` exists at the current schema version.

## 6. Write `.slipbox/config.json`

Draft the config from everything confirmed in Sections A and B, against the fields defined in `assets/config.schema.json`:

- `paths` — the resources/literature/evergreen/term folder paths from Step 2.
- `filenames` — casing per note type.
- `frontmatter` — the field_map from Step 2, per type (literature/term/evergreen); each entry carries `name`/`type`/`wikilink`/`zone` (or the bare string/`false` shorthand, where `zone` defaults to `top`), validated against the updated `assets/config.schema.json`.
- `links.style` — the link style discovered/confirmed for `derived-from`, `sources`, `source`.
- `templates` — seven explicit paths: `literature_path`, `term_path`, `evergreen_path`, `article_path`, `news_path`, `social_path`, `video_path`.
- `transcript_languages` — ordered list from Step 2's clip config.

Show the draft to the user, let them edit it, then validate the approved draft against `assets/config.schema.json` before writing. If validation fails, fix the draft and re-validate — never write a config that doesn't conform.

**Done when:** `.slipbox/config.json` is written, matches the approved draft, and validates against `assets/config.schema.json`.

## 7. Done

Tell the user what was created: `.slipbox/config.json`, `.slipbox/idea.db`, `.slipbox/style-profile.json`, and `.slipbox/humanize-checklist.json`. Tell them which skills depend on this having run first: `clip-resource`, `surface-ideas`, the ground-family skills that write notes from it — `grounding` (the bare engine, invoked directly for ad-hoc grounding), `ground-me` (literature-style passthrough), `ground-claim` (literature notes), `ground-term` (term notes), and `ground-my-take` (evergreen notes) — and `write-checks`, which every note-writing skill above runs before writing — checking the stated note preferences and humanizer workflow, and resolving each frontmatter field's mapping, formatting, and zone placement. Also tell them that individual `config.json` values can be changed later without re-running this whole setup, via `idea-db config set <dotted.path> <value>` (and `idea-db config get` to inspect current values).

Propose (never write silently) a one-line pointer into the vault's own `AGENTS.md`/`CLAUDE.md` — e.g. "This vault uses the slipbox skill family; its CLI lives at `.slipbox/bin/idea-db`." — the same way the vault may already document where to find the `obsidian` CLI. Show the exact line, ask before appending it, and skip this entirely if the user declines.

## 8. Re-run semantics (drift check, manual trigger only)

Triggered only when the user explicitly asks to re-run, or when Step 1 finds an existing `.slipbox/`. Never runs automatically otherwise.

1. Validate the existing `.slipbox/config.json` against `assets/config.schema.json` first, before doing anything else. A file that predates the schema or was hand-edited may not conform — surface any validation errors to the user before proceeding to the diff, rather than feeding a malformed file straight into it.
2. Re-discover conventions and style the same way as Steps 1–3, using the current state of the vault.
3. Diff the re-discovered conventions against the existing `.slipbox/config.json`.
4. Report specific mismatches, e.g. "config says kebab-case, the last 12 notes are Title Case" — name the field and both values, don't just say something changed.
5. For each mismatch, ask the user which side wins. Do not re-ask questions that didn't drift.
6. Update `config.json` with the resolved answers, then re-validate against `assets/config.schema.json` before writing.
7. Refresh `.slipbox/style-profile.json` through the stated preference interview, using the current configured note types and current notes only for verification. Show the old/new profile diff and ask before overwriting it.
8. Re-copy `assets/humanize-checklist.json` to `.slipbox/humanize-checklist.json`, overwriting the existing copy — this picks up any skill-package-level update to the canonical workflow snapshot since the vault was last set up.
9. Check whether the vault's `AGENTS.md`/`CLAUDE.md` already carries the `.slipbox/bin/idea-db` pointer from Step 7. If it's missing (a vault set up before that step existed, or the user declined it previously), propose adding it now the same way Step 7 does — ask before writing, skip if declined.

**Never** overwrite `idea.db`, `.slipbox/discussions/`, or any existing note during a re-run.

**Done when:** `config.json` reflects only the mismatches the user resolved and re-validates against `assets/config.schema.json`, the user has seen the stated-profile diff, and `.slipbox/humanize-checklist.json` matches the current `assets/humanize-checklist.json`.
