---
name: setup-slipbox
description: One-time onboarding for the slipbox skill family — discovers vault conventions, writing style, and clip preferences; installs the slipbox CLI. Run once per vault; re-run only to change conventions.
disable-model-invocation: true
license: MIT
metadata:
  version: "1.5.1"
---

# Setup Slipbox

Bold terms in this file are defined in `GLOSSARY.md`.

Every other skill in this family reads `.slipbox/config.json` before it writes anything, and fails fast with "run setup-slipbox first" if it's absent. This skill produces `config.json` plus the `.slipbox/bin/slipbox` CLI, `style-profile.json`, and `humanize-checklist.json` through the steps below: prerequisite check, explore, Section A (conventions + clip config), Section B (stated note preferences), humanizer workflow snapshot, CLI install, config write. Three of those outputs are built from fixed assets rather than composed fresh each run: `assets/config.schema.json`, `assets/humanize-checklist.json`, and `assets/style-profile.schema.json`. Re-running this skill on different vaults produces structurally consistent files, not just similarly-worded ones. `config.json` can also be edited after this first setup without re-running the whole interview, via the `slipbox config get`/`slipbox config set` CLI (see Done).

## Prerequisites

This is the only place in the slipbox family that installs anything — every other skill that hits a missing dependency stops and points back here rather than installing it inline.

Run `scripts/check-prereqs.sh` and read its report. It checks `python3` (the slipbox CLI's own runtime), `youtube_transcript_api` importability, `defuddle` presence on `PATH` (called directly, never via `npx` — see `clip-resource/SKILL.md`), and `firecrawl`'s auth status — no database dependency exists anymore, so `sqlite3` is not checked. The video-transcript check can be skipped entirely if the user has already said they have no interest in clipping video; otherwise check both by default.

The report distinguishes three states, not two: `missing`, `present`, and present-but-broken — on `PATH` yet failing to run. A broken install counts as missing and is reported with the failure text, so relay that text rather than telling the user the dependency is absent.

For each **required** dependency the report marks missing: stop, tell the user what it's needed for (`youtube-transcript-api` for `clip-resource`'s Video path; `defuddle` for `clip-resource`'s Article and News path), and ask explicitly before doing anything about it — never install without that per-dependency ask. If the user agrees, run `scripts/install-prereqs.sh <dependency>` for just that one dependency; it verifies the dependency is actually usable afterwards, so a nonzero exit means the install did not take — read its message to the user instead of continuing. If they'd rather install it themselves, tell them to re-run this skill once it's in place.

`firecrawl` is **optional**, not required — it's only ever used as `clip-resource`'s fallback when a fetch is blocked by bot detection (e.g. some Medium articles); the skill family works fully without it for the large majority of sources. If the report shows it missing or unauthenticated, mention it once, in passing, without treating it as a blocker: offer to run `scripts/install-prereqs.sh firecrawl` if the binary itself is missing, and point the user at `firecrawl config` for authentication (this script never handles credentials) — then move on regardless of their answer.

**TinyFish** is also **optional**, checked separately from the three dependencies above and never through `scripts/check-prereqs.sh`. TinyFish is an MCP-based tool, not a CLI binary or Python library — there is no local install step for it the way there is for Defuddle, Firecrawl, or `youtube-transcript-api`, so this check is detect-and-report only. Check whether a TinyFish MCP tool is available in the current session. If it is, note it as available for `clip-resource`'s Social fetch path. If it isn't, tell the user once, in passing, that TinyFish adds free fetching and the only path that can read Threads for Social clips, that it's connected outside this skill (an MCP server the user adds to their own harness, not something this script installs), and that Social clipping works fully on Firecrawl alone without it — then move on regardless.

**Done when:** every **required** dependency the report flagged has been either installed, explicitly deferred by the user, or the user has said they'll handle it themselves. `firecrawl` being unauthenticated, and TinyFish being unavailable, are never reasons to hold up completion.

## Explore (no questions yet)

Check the vault for existing signal before asking the user anything:

- `.obsidian/` for a `templates/` folder and Templater plugin config (`.obsidian/plugins/templater-obsidian`), which show the vault's real template location and syntax.
- Root `AGENTS.md` or `CLAUDE.md` for conventions the user already wrote down.
- Existing `Literature`/`Reference`/`Evergreen` (or similarly named) folders — these are a convention signal, plus a general sense of the vault's existing formatting and structure, referenced for context, never analyzed as a sample set.
- Whatever `tags` actually seems to be used for in this vault — note it in plain language for Section A's presentation (e.g. subtype-marker, topic/subject labels, a catch-all, a minimal signal, some mixture, or not used at all). This is descriptive narration only, never a mapping decision, and never forced into a fixed category list — real vaults don't fit a clean taxonomy, so describe what's actually observed. `tags` itself is never mapped onto or written to by any field_map resolution, regardless of what this narration finds.
- An existing `.slipbox/` directory. Its presence branches three ways, not two:
  - `.slipbox/config.json` exists → this is a re-run; switch to the drift-check flow in Re-run semantics.
  - `.slipbox/` exists but `config.json` does not → an interrupted prior run. Check individually for `.slipbox/evergreen/`, `style-profile.json`, and `humanize-checklist.json` — don't assume any one's presence alone tells you how far the prior run got. Tell the user setup was interrupted before completion, then **resume with a clean restart of Sections A/B below** (this and the first-run path are identical from here — there is no partial-answer persistence to resume from, and no existing `config.json` to diff against, so the drift-check mechanics don't apply). Never delete or overwrite whatever partial artifacts already exist until their step is reached normally.
  - No `.slipbox/` at all → first run, proceed below.

**Done when:** you know, for each check above, whether it found something or came up empty, and which of the three branches above applies.

## Section A: conventions

Present what you found, one item at a time. Recommend a default and lead with it — e.g. "No filename convention found. I recommend kebab-case (`my-note-title.md`): sound right, or do you use something else?" Silence is not confirmation; wait for an explicit answer per item before moving to the next.

- **Paths**: `resources/`, `literature/`, `evergreen/`, and the reference notes' folder (`paths.reference`; see `GLOSSARY.md` for the Reference note's admission test).
- **Filename casing** per note type (kebab-case, Title Case, snake_case, or whatever the vault already does).
- **Note-type prefixes**: ask once, for all three note types together — "Want a symbol prefix on note titles, so they're distinguishable at a glance even if they all end up in the same folder? Default: `§` for literature, `※` for reference, `✱` for evergreen. Keep these, pick your own, or skip prefixes entirely?" Record per-type: a string, or `false` for no prefix. Resources never get a prefix — no question asked for that type.
- **Templates**: three note templates (literature, reference, evergreen) plus four resource templates (article, news, social, video) — seven total, each with its own explicit path. These are real Obsidian template files: the core Templates plugin's default location, or Templater's if the user already has it configured. Do not invent a separate agent-native template spec.
  - **The three note templates almost always already exist** — resolve their path and move on, same as any other convention item.
  - **The four resource templates usually don't** — the templates *folder* typically exists (from note-taking), but article/news/social/video `.md` files inside it typically don't, since clipping is a newer concept for most vaults than note-taking. For each one that's missing at its resolved path, offer to draft it together right there rather than asking the user to go write Obsidian template syntax cold:
    1. Tell them which variables apply to this content type and what each does, in plain language — pull this from `variable-glossary.md` and `filter-glossary.md` (bundled with this skill, mirroring `clip-resource`'s own copies), but never point the user at those files directly; you are the interface to that reference, not a librarian handing over a card catalog.
    2. Ask what they want captured in the note and in what order (title, source link, a raw excerpt, a synthesized summary, etc.).
    3. As you propose each variable, explain bare vs. quoted inline, concretely: "`{{content}}` pulls the article body verbatim; if you'd rather have a compressed summary instead, that's a quoted instruction like `{{"a 3-sentence summary of the article"}}` — I'll write whichever one you want here." Do not make the user learn the bare/quoted rule in the abstract before they can make this choice.
    4. Write the draft to the resolved path, show it, and let them edit or approve before moving to the next missing template.
  - This drafting help is conversational, not a fixed asset — template *content* reflects the user's own note structure and is never the same across two vaults, unlike `config.json`/`humanize-checklist.json`/`style-profile.json` elsewhere in this skill.

### field_map

**First, one combined question**: "Want to resolve frontmatter field mappings for all three note types now, or defer any of them until you actually write one?" Any type the user defers gets `{"deferred": true}` recorded for each of its required fields in `config.json`, skipping the branch below entirely for that type — `write-checks` runs this same resolution logic the first time that type is actually written (see `write-checks/SKILL.md`'s "Frontmatter fields" section), and writes the resolved mapping back at that point.

For each required field below, on a type the user chose to resolve now, resolve one of (a) map onto an existing user property, (b) create the standard field, or (c) explicit opt-out. When mapping onto an EXISTING property, read its actual type from the note (Text/List/Number/Checkbox/Date/Date & Time) and record that discovered type in the field_map entry — don't assume a type. When creating a NEW field, assign the type that fits its semantic nature, per this table (still verify+record the discovered type instead when mapping onto an existing property), with a `zone` (top/bottom) alongside each type — zone only governs placement of fields being newly created, never fields mapped onto an existing property:
  - Literature: `type` → text, zone top; `created` → date, zone top; `source` → list + wikilink: true, zone bottom.
  - Reference: `type` → text, zone top; `created` → date, zone top; `sources` → list + wikilink: true, zone bottom; `alt_names` (optional) — default: map onto Obsidian's reserved `aliases` property (type `list`, no wikilink; record `list` directly, skip the live-read-type step since `aliases` is Obsidian-fixed, not vault-specific) — or create fresh as `alt_names` (list, no wikilink, zone bottom) if the user prefers to keep it separate from `aliases`.
  - Evergreen: `type` → text, zone top; `created` → date, zone top; `derived-from` → list + wikilink: true, zone bottom; `updated-at` → datetime (not bare date — multiple revisions can land the same day), no wikilink, zone bottom.

  **`type`-occupancy check**, resolving the `type` field specifically (present in all three note types' field tables): this is a 3-way branch, not a simple create-or-map choice.
  - `type` is absent/unused in existing notes → create fresh with the standard name `type` (today's default, unchanged).
  - `type` already holds exactly the identity value needed (existing notes literally already have `type: literature`/`type: reference`/`type: evergreen`) → map onto the existing `type` property directly, no new field needed.
  - `type` already holds something unrelated (e.g. a base/umbrella value like `note`) → stop and ask: recommend mapping slipbox's own type-identity onto a new, differently-named field (e.g. `note-type`) instead of colliding with the existing `type`, leaving the existing `type` property untouched. Offer the user the choice of field name — don't hardcode `note-type` as the only option, it's just the recommended default.

  **Type-mismatch check**, only for multi-valued fields (`source`s that grow: `sources`,
  `derived-from` — never `source`, which is genuinely single-valued and fits into an
  existing Text property fine): if the existing property's discovered type isn't List,
  it structurally can't hold what the field needs to grow into. Stop and ask, recommending
  mapping onto a new, standard-named List property instead and leaving the existing
  property untouched — the same recommend-a-default pattern as every other item in this
  section. Offer the other two answers too: point at a different existing property, or
  override and accept the mismatch anyway (least recommended, never the silent default).

  Never map any of these onto the reserved `tags`, `aliases`, or `cssclasses` properties — with exactly one named exception: Reference's optional `alt_names` may map onto `aliases`, since the two are semantically identical (both mean "other names for this thing"), and this is in fact the default recommendation for that field (see the Reference row above). No other field, on any note type, gets this carve-out. The required fields themselves, for reference:
  - Literature: `type: literature`, `created`, `source: [[resource]]`.
  - Reference: `type: reference`, `created`, `sources: [...]` (array/multitext — grows with each extension), `alt_names: [...]` (optional).
  - Evergreen: `type: evergreen`, `created`, `derived-from: [[...]]` (bare wikilink list, no reasons attached — reasons stay in the note body), `updated-at` (written on first write, refreshed every time an existing evergreen note is revisited/rewritten).
- **Clip config** (folded into this same flow, not a separate gate):
  - All four resource content-types (article, news, social, video) are on by default. Ask only about exceptions the user wants to turn off.
  - Transcript language: ask which languages are wanted (multi-select). Only ask for a priority order if more than one language is selected.
  - This runs unconditionally, regardless of whether the user already has some other clipper tool in their workflow.

**Done when:** the user has explicitly confirmed or corrected every item above, including the field_map verification reads for any type resolved now (deferred types are explicitly not re-asked about here).

## Section B: stated note preferences

Build one user-stated preference profile at `.slipbox/style-profile.json`. Do not analyze a corpus or infer a voice fingerprint. The profile tells note-writing skills how to shape and edit notes; it is not a sample-mimicry model.

Start from `assets/style-profile.schema.json` and interview the user against its fixed sections:

- `voice`: stated descriptors such as overall quality, verbosity, confidence, hedging, and energy. Record what the user says; never infer these from a corpus.
- `sentence_style`: average length, structure, list preference, paragraph shape, and conclusion placement.
- `tone_by_note`: inspect the actual note types under `config.json`'s `frontmatter` map and ask for the tone of each configured type. Never hardcode unsupported note types. Always asked upfront for every type, regardless of whether that type's `field_map` was deferred above — tone is vault-wide, not tied to any per-type resolution step, and asking it is a single short question, not worth deferring.
- `language`: primary language, secondary language, technical-term preference, and the user's own code-switching description. `code_switching` remains a free string until its vocabulary is settled.
- `vocabulary`: phrases the user says they often use and words or phrases they want avoided.
- `formatting`: bullet use, wikilinks, aliases, headings, quotes, and citation placement.
- `editing_style`: iterative editing, renaming, compression, and redundancy removal preferences.

Show the complete draft to the user. Let them edit or approve it. Verify preference-sensitive shape choices against an actual note where useful, but never treat that note as a corpus to analyze. Validate the approved profile against `assets/style-profile.schema.json` before writing `.slipbox/style-profile.json`.

**Done when:** the user has approved one stated profile, it validates against the fixed schema, and `.slipbox/style-profile.json` is written. No corpus branch exists.

## Write `.slipbox/humanize-checklist.json`

Canonical: copy `assets/humanize-checklist.json` verbatim to `.slipbox/humanize-checklist.json`. The snapshot records humanizer v2.8.0's detection, meaning-preserving rewrite, preference-context, and final-audit phases. Detection remains generic and fixed; it does not read profile baselines. The rewrite phase may read the stated profile through its `preference_context`. Explain that the file flags and guides but never rewrites automatically. Preserve its per-signal thresholds, language gating, false-positive guidance, and judgment-only signals. Re-copy it on every re-run so vaults receive package-level updates.

**Done when:** `.slipbox/humanize-checklist.json` matches `assets/humanize-checklist.json` exactly.

## Install the `slipbox` CLI

Runs identically on every invocation, first run or re-run — no conditional branch:

```bash
mkdir -p .slipbox/bin .slipbox/evergreen
touch .slipbox/links.jsonl
cp skills/setup-slipbox/scripts/slipbox .slipbox/bin/slipbox
chmod +x .slipbox/bin/slipbox
```

The script copy is always overwritten (versioned code, not user data — distinct from `.slipbox/evergreen/*.md`/`config.json`, which are never overwritten by this step). `mkdir -p`/`touch` are no-ops on a re-run — nothing here needs a conditional "does this already exist" branch the way SQLite's schema-version check once did, since there's no schema left to be at a version of.

**Done when:** `.slipbox/bin/slipbox` is installed and executable, and `.slipbox/evergreen/` and `.slipbox/links.jsonl` exist.

## Write `.slipbox/config.json`

Draft the config from everything confirmed in Sections A and B, against the fields defined in `assets/config.schema.json`:

- `paths` — the resources/literature/evergreen/reference (`paths.reference`, renamed from `paths.term`) folder paths from Section A.
- `filenames` — casing per note type (`filenames.reference`, renamed from `filenames.term`).
- `prefixes` — the per-type title prefix (or `false`) from Section A.
- `frontmatter` — the field_map from Section A, per type (literature/reference/evergreen), validated against `assets/config.schema.json` — see that file's own `description` field for the canonical shape each entry can take.
- `links.style` — the link style discovered/confirmed for `derived-from`, `sources`, `source`.
- `templates` — seven explicit paths: `literature_path`, `reference_path`, `evergreen_path`, `article_path`, `news_path`, `social_path`, `video_path`.
- `transcript_languages` — ordered list from Section A's clip config.

Show the draft to the user, let them edit it, then validate the approved draft against `assets/config.schema.json` before writing. If validation fails, fix the draft and re-validate — never write a config that doesn't conform.

**Done when:** `.slipbox/config.json` is written, matches the approved draft, and validates against `assets/config.schema.json`.

## Copy `GLOSSARY.md` and write `.slipbox/AGENTS.md`

Two unconditionally-copied assets, same treatment as `humanize-checklist.json` above:

- Copy `assets/GLOSSARY.md` to `.slipbox/GLOSSARY.md`, verbatim, on every run.
- Copy `assets/AGENTS.md` to `.slipbox/AGENTS.md`, verbatim, but only after every other artifact in this skill (`config.json`, `bin/slipbox`, `evergreen/`, `links.jsonl`, `style-profile.json`, `humanize-checklist.json`, `GLOSSARY.md`) has already succeeded. `.slipbox/AGENTS.md` is written strictly last — its existence is the completion sentinel every other skill in this family checks, so a partial or interrupted run must never leave it behind claiming success.

**Done when:** `.slipbox/GLOSSARY.md` matches `assets/GLOSSARY.md` exactly, and `.slipbox/AGENTS.md` matches `assets/AGENTS.md` exactly and was written only after every other artifact above already exists.

## Done

Tell the user what was created: `.slipbox/config.json`, `.slipbox/bin/slipbox`, `.slipbox/evergreen/`, `.slipbox/links.jsonl`, `.slipbox/style-profile.json`, `.slipbox/humanize-checklist.json`, `.slipbox/GLOSSARY.md`, and `.slipbox/AGENTS.md`. Tell them which skills depend on this having run first: `clip-resource`, `find-connections` (its `--references` mode absorbs what `find-terms` used to do), the note-writing skills that compose notes from sources — `grounding` (the bare engine, invoked directly for ad-hoc grounding), `ground-me` (literature-style passthrough), `make-literature-note` (literature notes), `make-reference-note` (Reference notes), and `make-evergreen-note` (evergreen notes) — and `write-checks`, which every note-writing skill above runs before writing — checking the stated note preferences and humanizer workflow, and resolving each frontmatter field's mapping, formatting, zone placement, and title prefix. Also tell them that individual `config.json` values can be changed later without re-running this whole setup, via `slipbox config set <dotted.path> <value>` (and `slipbox config get` to inspect current values).

Propose (never write silently) a one-line pointer into the vault's own `AGENTS.md`/`CLAUDE.md` — e.g. "This vault uses the slipbox skill family; its CLI lives at `.slipbox/bin/slipbox`." — the same way the vault may already document where to find the `obsidian` CLI. Show the exact line, ask before appending it, and skip this entirely if the user declines.

## Re-run semantics (drift check, manual trigger only)

Triggered only when the user explicitly asks to re-run, or when Explore finds `.slipbox/config.json` already present. Never runs automatically otherwise.

1. Validate the existing `.slipbox/config.json` against `assets/config.schema.json` first, before doing anything else. A file that predates the schema or was hand-edited may not conform — surface any validation errors to the user before proceeding to the diff, rather than feeding a malformed file straight into it.
2. Re-discover conventions and style the same way as Explore/Section A/Section B, using the current state of the vault.
3. Diff the re-discovered conventions against the existing `.slipbox/config.json`.
4. Report specific mismatches, e.g. "config says kebab-case, the last 12 notes are Title Case" — name the field and both values, don't just say something changed.
5. For each mismatch, ask the user which side wins. Do not re-ask questions that didn't drift.
6. **Field_map drift check** — for each *resolved* (non-deferred) `field_map` entry, re-read the mapped-onto property's current type from the vault and compare against what's recorded:
   - **Type changed** (e.g. was List, now reads Text) — report the specific mismatch by field name and both values, ask which side wins: re-resolve to match reality, or override and keep the recorded mapping.
   - **Property gone entirely** (deleted from every note in the vault) — re-trigger the *original* resolution branch for that field (map onto a different property, create fresh, or opt-out); the old mapping now points at nothing.
   - **Deferred entries are skipped by this check entirely** — nothing's resolved yet to drift from; they stay `{"deferred": true}` until `write-checks` resolves them lazily at first write.
7. Update `config.json` with the resolved answers, then re-validate against `assets/config.schema.json` before writing.
8. Refresh `.slipbox/style-profile.json` through the stated preference interview, using the current configured note types and current notes only for verification. Show the old/new profile diff and ask before overwriting it.
9. Re-copy `assets/humanize-checklist.json` to `.slipbox/humanize-checklist.json`, overwriting the existing copy — this picks up any skill-package-level update to the canonical workflow snapshot since the vault was last set up.
10. Re-copy `assets/GLOSSARY.md` to `.slipbox/GLOSSARY.md` and `assets/AGENTS.md` to `.slipbox/AGENTS.md`, unconditionally, same category as `humanize-checklist.json` — both pick up any skill-package-level update. Neither is on the "never overwrite" list below; they're routine refreshes, not user-owned state. Write `.slipbox/AGENTS.md` last, after every other re-copy and write in this list has succeeded, same ordering guarantee as a first run.
11. Check whether the vault's `AGENTS.md`/`CLAUDE.md` already carries the `.slipbox/bin/slipbox` pointer from Done. If it's missing (a vault set up before that step existed, or the user declined it previously), propose adding it now the same way, ask before writing, skip if declined.

**Never** overwrite `.slipbox/evergreen/*.md`, `.slipbox/discussions/`, or any existing note during a re-run.

**Done when:** `config.json` reflects only the mismatches the user resolved (including field_map drift) and re-validates against `assets/config.schema.json`, the user has seen the stated-profile diff, `.slipbox/humanize-checklist.json` matches the current `assets/humanize-checklist.json`, and `.slipbox/GLOSSARY.md`/`.slipbox/AGENTS.md` match their current package assets.
