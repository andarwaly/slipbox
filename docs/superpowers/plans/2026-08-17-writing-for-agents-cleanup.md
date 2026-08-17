# Slipbox Writing-for-Agents Cleanup — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply every confirmed decision from the two resolved discussion topics to the actual `slipbox` skill family — ship `GLOSSARY.md`/`.slipbox/AGENTS.md` as real runtime assets, collapse duplicated/dead pointers, fix the `config.json` full-file-read pattern, redesign `clip-resource`, and correct the family's documentation to match its own shipped frontmatter.

**Architecture:** Nine independent Claude Code skills under `skills/`, each a self-contained `SKILL.md` + optional `references/`/`assets/` bundle, installed individually via `npx skills add`. No skill's installed copy ever contains anything outside its own `skills/{{name}}/` folder or the shared runtime state at `.slipbox/` that `setup-slipbox` writes into the user's vault. Every cross-skill fact this plan wires up resolves through that shared runtime state (`.slipbox/GLOSSARY.md`, `.slipbox/AGENTS.md`), never through an authoring-time path into a sibling skill's own bundle — the one exception (`make-evergreen-note` naming the Compass technique) states zero path at all, by design.

**Tech Stack:** Markdown (`SKILL.md`, `references/*.md`, `docs/*.md`), JSON (`config.schema.json`, `evals.json`), the bundled `scripts/slipbox` CLI (bash). No app code changes.

**Spec:** [`discussion/slipbox/discussion-topics/runtime-glossary-and-agents-md.md`](../../../../../discussion/slipbox/discussion-topics/runtime-glossary-and-agents-md.md) and [`discussion/slipbox/discussion-topics/grounding-family-writing-for-agents-review.md`](../../../../../discussion/slipbox/discussion-topics/grounding-family-writing-for-agents-review.md) in the outer `skill-kojo` workspace — both `status: resolved`, both hold every ratified decision this plan executes. This plan does not re-derive or re-litigate any finding; it only sequences and mechanizes what those two files already settled.

## Global Constraints

- **No skill points outside its own bundled files at authoring time**, except through `.slipbox/GLOSSARY.md` / `.slipbox/AGENTS.md` — files that exist only in the installed vault's runtime state (written by `setup-slipbox`), never inside another skill's own `skills/{{name}}/` folder. A reference to a sibling skill's `references/*.md` by path is out of bounds; naming a sibling skill or one of its techniques by name, with no path, is fine (confirmed: `make-evergreen-note`'s Compass reference).
- **No numbered step-headings** in any `SKILL.md` — named, descriptive headings only (root `AGENTS.md`, Skill-writing conventions).
- **"You"/"your" always means the agent**; the user is spelled out as "the user," never an implicit "you," except inside quoted dialogue the agent speaks aloud.
- **High-weight terms, leading words, and vocabulary stay consistent** across every file in the family — the same term (Session, not Sitting; Backlog vs. Candidate; Take capitalized only for the confirmed written artifact; Ladder for every ordered-fallback-check sequence) is used the same way everywhere it appears, per the drift-case resolutions in `runtime-glossary-and-agents-md.md`.
- **`disable-model-invocation: true` frontmatter is never touched by this plan** — only the prose describing what the flag means (root `AGENTS.md`'s Cross-skill-references section) changes; the flag itself, already correct on five skills, stays as shipped.
- **Prose gets a humanizer pass** before each commit in Phases 3–7: no em dash overuse, grammatically clean, no filler ("It's worth noting that…", "In order to…").
- **`metadata.version` stays under `1.x`** for every touched skill (bucket not yet declared stable) — bump the minor version on any skill whose mechanism changes (Prerequisite check collapse, `clip-resource` redesign, config-read pattern change count as mechanism changes), patch-bump on wording-only fixes.

---

## File Structure

New files this plan creates:

- `skills/setup-slipbox/assets/GLOSSARY.md` — the ~50-term family glossary, ships to `.slipbox/GLOSSARY.md`.
- `skills/setup-slipbox/assets/AGENTS.md` — machine-facing workflow doc, ships to `.slipbox/AGENTS.md`, written last as the completion sentinel.
- `skills/clip-resource/references/url-patterns.md` — URL-pattern-by-content-type table, extracted from Step 2.
- `skills/clip-resource/references/extract-article-news.md`, `extract-social.md`, `extract-video.md` — the three Step 3 branches, extracted out of `SKILL.md`.

Files this plan modifies (every `SKILL.md` in the family, plus `references/*.md` siblings and root `AGENTS.md`) are listed per-task below with the exact change, not restated here.

Each task in Phases 3–7 is scoped to one skill (or one tightly-coupled cluster inside `clip-resource`) so a reviewer can accept or reject one skill's cleanup independently of another's.

---

## Task 0: Branch

**Files:** none (git only)

- [ ] **Step 1: Confirm current branch and clean tree**

Run: `git -C the-factory/slipbox status --short && git -C the-factory/slipbox branch --show-current`
Expected: clean tree, `feat/grounding-family-redesign`.

- [ ] **Step 2: Branch**

```bash
git -C the-factory/slipbox checkout -b chore/writing-for-agents-cleanup
```

- [ ] **Step 3: Verify**

Run: `git -C the-factory/slipbox branch --show-current`
Expected: `chore/writing-for-agents-cleanup`.

---

## Task 1: Sweep — build the findings table before any edit

**Files:** none (read-only; produces the working list Tasks 2–8 execute against)

**Produces:** a confirmed file:line list for every pointer/pattern below, checked into the agent's own working notes (not committed) — Tasks 2–8 read this list, they do not re-derive it.

- [ ] **Step 1: Run every sweep grep**

```bash
cd the-factory/slipbox
grep -rn "CONTEXT.md" skills/
grep -rn "reference-note-admission-contract" skills/
grep -rln "config.json" skills/*/SKILL.md
grep -rln "Prerequisite" skills/*/SKILL.md
grep -rn "stated_style" skills/
grep -rn "disable-model-invocation" skills/*/SKILL.md
grep -n "field_map\|zone\|deferred" skills/setup-slipbox/SKILL.md skills/write-checks/SKILL.md
grep -n "ladder" skills/clip-resource/SKILL.md
grep -n "npx skills add\|full clone" AGENTS.md
```

- [ ] **Step 2: Record every hit as `file:line — planned action`**, cross-checked against the confirmed dispositions in both resolved discussion topics. Do not act on any hit not named in one of those two files — if the sweep surfaces something new, stop and flag it back to the user before touching it (per this workspace's own root `CLAUDE.md`: preview before writing).

- [ ] **Step 3: Confirm no hit is missing** — the sweep in Task 1 exists specifically because the resolved topics warn several findings touch more sites than where they were originally noticed (the `config.json` fix touches six skills; the `GLOSSARY.md` pointer rollout touches every skill's Prerequisite section). Cross-count against the "Sweep" table already enumerated in this plan's own Global Constraints and Task descriptions below — every named skill must appear in the grep output.

---

## Task 2: `setup-slipbox` — `GLOSSARY.md` and `.slipbox/AGENTS.md` assets (dependency root)

**Files:**
- Create: `skills/setup-slipbox/assets/GLOSSARY.md`
- Create: `skills/setup-slipbox/assets/AGENTS.md`
- Modify: `skills/setup-slipbox/SKILL.md` (Done section, re-run section, `metadata.version`)

**Interfaces:**
- Produces: `.slipbox/GLOSSARY.md` (flat alphabetical term list, `**Term**` / one-or-two-sentence IS-statement / `_Avoid_` field format) and `.slipbox/AGENTS.md` (machine-facing workflow doc), both written into the vault by `setup-slipbox`'s Done section on every run. `.slipbox/AGENTS.md`'s existence is the completion sentinel every other skill's Prerequisite section checks in Task 3 onward.
- Consumes: nothing new from other tasks.

This task has no dependency on any other task in this plan and must land before Task 3, since every other skill's Prerequisite/pointer rewrite assumes `GLOSSARY.md` and `.slipbox/AGENTS.md` already exist as real bundled assets.

- [ ] **Step 1: Draft `GLOSSARY.md`**

Source every entry from `CONTEXT.md`'s existing Language section plus the mechanism/borrowed-academic terms named in the resolved topic (Gate, Backlog, Session, Fidelity direction, Core Idea, Ladder, steelmanning, ZPD/scaffolding, principle of charity, Collector's Fallacy, and the rest of the ~50-term inventory). Apply every drift-case resolution verbatim:

- **Session** canonical, **Sitting** dropped entirely.
- **Backlog** and **Candidate** each get their own entry, cross-referencing each other, not merged.
- **Private backlog** named for its distinguishing property (never shown, never persisted), not "candidate backlog."
- **Take** — one capitalized entry for the confirmed written artifact; lowercase mid-conversation usage is the same concept, not a second entry.
- **Ladder** — one entry describing the ordered-fallback-check pattern generically, cited by both of `clip-resource`'s sequences (fixed in Task 6).
- **Admission test** (alias: reusability test) — its own entry, distinct from **Origin test**, which gets an entry only to name it retired/superseded, one line.
- **Resource** — entry gains the frozen/never-reopened-or-edited fact moved from `clip-resource/SKILL.md:108` (Task 6 removes it from there).

Format, every entry:

```markdown
**Term**
One or two sentences — what the term IS, never how it's used or what to do with it.
_Avoid_: Rejected-name (same thing — say Term); Neighbor concept (a different thing — one-clause reason why it's not this).
```

Flat, alphabetical, no letter-group subheadings. Reuse already-coined glossary terms inside later definitions (e.g. Backlog's definition uses Candidate, Session, Evergreen note).

- [ ] **Step 2: Run humanizer pass on the drafted `GLOSSARY.md`**

Invoke `/humanizer` against the draft. Fix any em dash overuse, passive voice, or filler phrasing before saving.

- [ ] **Step 3: Save and verify format**

Run: `grep -c "^\*\*" skills/setup-slipbox/assets/GLOSSARY.md` — expect roughly 50.
Run: `grep -c "_Avoid_" skills/setup-slipbox/assets/GLOSSARY.md` — expect the same count as the term count (every entry has one).

- [ ] **Step 4: Draft `.slipbox/AGENTS.md`**

Content: the skill suite's workflow (which skill does what, in what order a vault typically uses them), the `.slipbox/` folder structure (`config.json`, `bin/slipbox`, `evergreen/`, `links.jsonl`, `style-profile.json`, `humanize-checklist.json`, `GLOSSARY.md`, `AGENTS.md` itself), and a closing pointer to `GLOSSARY.md` for terms. Machine-facing — write for an agent reading it mid-task, not a human onboarding to the vault. Explicitly state: this file exists only after a fully successful `setup-slipbox` run, and is separate from the vault's own root `AGENTS.md`/`CLAUDE.md` one-line opt-in pointer (that one stays human-facing, untouched by this task).

- [ ] **Step 5: Run humanizer pass on the drafted `.slipbox/AGENTS.md`**, same as Step 2.

- [ ] **Step 6: Read `skills/setup-slipbox/SKILL.md`'s current Done section and re-run section**, to locate the exact insertion points for the new copy-asset steps.

- [ ] **Step 7: Edit the Done section** to add: copy `assets/GLOSSARY.md` → `.slipbox/GLOSSARY.md` and `assets/AGENTS.md` → `.slipbox/AGENTS.md`, same unconditional-copy treatment already given to `humanize-checklist.json`. State explicitly: `.slipbox/AGENTS.md` is written strictly last, after every other artifact (`config.json`, `bin/slipbox`, `evergreen/`, `links.jsonl`, `style-profile.json`, `humanize-checklist.json`, `GLOSSARY.md`) has succeeded — its presence is the completion sentinel.

- [ ] **Step 8: Edit the re-run section** to state both new files are unconditionally re-copied on every re-run (same category as `humanize-checklist.json` — "picks up any skill-package-level update"), explicitly not on the "never overwrite" list (`.slipbox/evergreen/*.md`, `.slipbox/discussions/`, existing notes).

- [ ] **Step 9: Bump `metadata.version`** on `skills/setup-slipbox/SKILL.md` — minor bump (new mechanism: two new unconditionally-copied assets, a new completion-sentinel ordering guarantee).

- [ ] **Step 10: Verify no path outside the skill's own bundle was introduced**

Run: `grep -n "\.\./\|discussion/" skills/setup-slipbox/assets/GLOSSARY.md skills/setup-slipbox/assets/AGENTS.md`
Expected: no output. Both files are entirely self-contained prose with zero outbound paths.

- [ ] **Step 11: Commit**

```bash
git -C the-factory/slipbox add skills/setup-slipbox/
git -C the-factory/slipbox commit -m "feat(setup-slipbox): ship GLOSSARY.md and .slipbox/AGENTS.md as runtime assets"
```

---

## Task 3: Family-wide Prerequisite collapse and `GLOSSARY.md` first-line pointer

**Files (one skill per sub-step, all modified in this single task since the edit is mechanically identical across all nine):**
- `skills/grounding/SKILL.md`
- `skills/ground-me/SKILL.md`
- `skills/clip-resource/SKILL.md`
- `skills/make-literature-note/SKILL.md`
- `skills/write-reference/SKILL.md`
- `skills/setup-slipbox/SKILL.md` (Prerequisite section only — its Done/re-run sections were already handled in Task 2)
- `skills/write-checks/SKILL.md`
- `skills/make-evergreen-note/SKILL.md`
- `skills/find-connections/SKILL.md`

**Interfaces:**
- Consumes: `.slipbox/AGENTS.md`'s existence as completion sentinel, `.slipbox/GLOSSARY.md`'s existence as term source — both produced by Task 2. **This task cannot start before Task 2 is committed.**

**Depends on:** Task 2.

- [ ] **Step 1: For each of the nine `SKILL.md` files, read its current Prerequisite section**

Every current Prerequisite section performs two checks (`.slipbox/config.json` existence, `.slipbox/bin/slipbox` existence). Locate the exact text.

- [ ] **Step 2: Replace with the single collapsed check**

New Prerequisite text (adapt phrasing per skill's existing voice, keep the check identical): "Requires `.slipbox/AGENTS.md` to exist — its presence confirms `setup-slipbox` completed a full run. If missing, tell the user to run `/setup-slipbox` first; do not proceed." This replaces both prior checks — `.slipbox/AGENTS.md` is written strictly last in `setup-slipbox`'s Done section (Task 2), so its presence alone proves everything else succeeded too.

- [ ] **Step 3: Add the first-line `GLOSSARY.md` pointer**

Immediately after the skill's own H1/frontmatter, before any other prose: a one-line pointer stating bold terms in this file are defined in `GLOSSARY.md` (referring to the runtime `.slipbox/GLOSSARY.md`, not a bundled path — no file path in the sentence itself, name only, matching the Global Constraints rule on cross-skill references).

- [ ] **Step 4: `make-literature-note/SKILL.md` only** — delete the entire inline "What these words mean" section this task's source finding was about. The new first-line pointer (Step 3) replaces it.

- [ ] **Step 5: Repoint dead `CONTEXT.md` references** at the three named sites:

- `write-reference/SKILL.md:20`
- `make-literature-note/references/qec-theory.md:21`
- `make-literature-note/references/writing-a-claim.md:64`

Each currently reads as a pointer into `CONTEXT.md` (which never ships). Change each to point at `GLOSSARY.md` by name, no path.

- [ ] **Step 6: Repoint `[[reference-note-admission-contract]]` wikilinks**

- `find-connections/SKILL.md:71` — the cited fact (surfacing-only, never writes Person/Location/Organization) is already covered by `GLOSSARY.md`'s Language section (ported from `CONTEXT.md` in Task 2). Repoint to `GLOSSARY.md`, no new content needed.
- `make-literature-note/references/writing-a-claim.md:128` — this site cites a rule genuinely missing from `CONTEXT.md`'s current admission-test paragraph (the Ship30 case: same string resolves to a Reference note as a method, an Organization as the entity running it). **Before repointing this site**, add that clause to `CONTEXT.md`'s Language section's admission-test entry, and to `GLOSSARY.md`'s corresponding entry (both — `CONTEXT.md` is the author-time canonical source, `GLOSSARY.md` is what actually ships; Task 2's `GLOSSARY.md` draft already reflects `CONTEXT.md` as of Task 2's commit, so this is a follow-up edit to both, in the same commit as this step). Then repoint the site to `GLOSSARY.md`.

- [ ] **Step 7: `setup-slipbox/SKILL.md` line 45 only** — this site currently duplicates the `paths.term`→`paths.reference` rename note already stated at lines 134–135, and additionally cites the dead `discussion/slipbox/discussion-topics/reference-note-admission-contract.md` path directly. Cut the duplicated rename note here (keep the one at 134–135, since the historical fact doesn't change either site's actual instruction), and repoint the dead discussion-topic citation to `GLOSSARY.md`.

- [ ] **Step 8: Run humanizer pass** on every file touched this task.

- [ ] **Step 9: Verify — no dangling `CONTEXT.md` or wikilink references remain**

Run: `grep -rn "CONTEXT.md" skills/`
Expected: zero hits inside any `SKILL.md` or `references/*.md` (`CONTEXT.md` itself, at repo root, is untouched and keeps its authoring-time role).

Run: `grep -rn "reference-note-admission-contract" skills/`
Expected: zero hits.

Run: `grep -rln "\.slipbox/bin/slipbox" skills/*/SKILL.md`
Expected: zero hits (the old two-check Prerequisite text is gone everywhere).

- [ ] **Step 10: Bump `metadata.version`** (minor) on every one of the nine skills touched this task — the Prerequisite check is a mechanism change.

- [ ] **Step 11: Commit**

```bash
git -C the-factory/slipbox add skills/ CONTEXT.md
git -C the-factory/slipbox commit -m "refactor(family): collapse Prerequisite to single AGENTS.md check, point terms at GLOSSARY.md"
```

---

## Task 4: `config.json` scoped-read fix

**Files:**
- `skills/clip-resource/SKILL.md`
- `skills/make-literature-note/SKILL.md`
- `skills/write-reference/SKILL.md`
- `skills/make-evergreen-note/SKILL.md`
- `skills/write-checks/SKILL.md`

**Interfaces:** none — independent of Tasks 2–3, can run in parallel with either, but sequenced here after Task 3 for a clean diff history.

- [ ] **Step 1: Read the current `.slipbox/config.json` phrasing** in each of the five files (already located by Task 1's sweep).

- [ ] **Step 2: `clip-resource/SKILL.md`** — replace the generic "reads template paths… from `.slipbox/config.json`" phrasing with named calls: `slipbox config get templates.<type>_path`, `slipbox config get filenames.<type>`, `slipbox config get transcript_languages`.

- [ ] **Step 3: `make-literature-note/SKILL.md`** — replace with: `slipbox config get paths.literature`, `slipbox config get filenames.literature`, `slipbox config get frontmatter.literature.source.name`.

- [ ] **Step 4: `write-reference/SKILL.md`** — replace with: `slipbox config get paths.reference`, `slipbox config get filenames.reference`.

- [ ] **Step 5: `make-evergreen-note/SKILL.md`** — replace with: `slipbox config get paths.evergreen`, `slipbox config get filenames.evergreen`.

- [ ] **Step 6: `write-checks/SKILL.md`** — replace with the read-side calls (`slipbox config get frontmatter.<type>.<field>`, `slipbox config get links.style`, `slipbox config get prefixes.<type>`) and the write-back call for resolving a deferred mapping (`slipbox config set frontmatter.<type>.<field> <value>`).

- [ ] **Step 7: `find-connections/SKILL.md`** — no edit. Confirmed exempt (its design deliberately avoids needing scoped `paths.*` config). Add nothing.

- [ ] **Step 8: Run humanizer pass** on all five edited files.

- [ ] **Step 9: Verify no full-file-read phrasing remains**

Run: `grep -n "reads.*from \.slipbox/config.json\|whole.*config.json\|entire.*config.json" skills/clip-resource/SKILL.md skills/make-literature-note/SKILL.md skills/write-reference/SKILL.md skills/make-evergreen-note/SKILL.md skills/write-checks/SKILL.md`
Expected: zero hits.

Run: `grep -c "slipbox config get\|slipbox config set" skills/clip-resource/SKILL.md skills/make-literature-note/SKILL.md skills/write-reference/SKILL.md skills/make-evergreen-note/SKILL.md skills/write-checks/SKILL.md`
Expected: each file has at least as many hits as fields named in Steps 2–6 above.

- [ ] **Step 10: Bump `metadata.version`** (minor) on all five skills — the read/write mechanism named changed.

- [ ] **Step 11: Commit**

```bash
git -C the-factory/slipbox add skills/clip-resource/SKILL.md skills/make-literature-note/SKILL.md skills/write-reference/SKILL.md skills/make-evergreen-note/SKILL.md skills/write-checks/SKILL.md
git -C the-factory/slipbox commit -m "refactor(config): name scoped slipbox config get/set calls instead of full-file reads"
```

---

## Task 5: `clip-resource` — split Step 3 into reference files, add `url-patterns.md`

**Files:**
- Create: `skills/clip-resource/references/url-patterns.md`
- Create: `skills/clip-resource/references/extract-article-news.md`
- Create: `skills/clip-resource/references/extract-social.md`
- Create: `skills/clip-resource/references/extract-video.md`
- Modify: `skills/clip-resource/SKILL.md` (Step 2, Step 3)

**Interfaces:**
- Produces: three extraction-branch reference files and one URL-pattern reference file, all named from `SKILL.md`'s new Step 2/Step 3 dispatch tables. `Task 6` and `Task 7` add content on top of what this task extracts — do not skip straight to those tasks' edits before this extraction lands, since they edit the *content* of files this task creates.

- [ ] **Step 1: Read `clip-resource/SKILL.md`'s current Step 2 and Step 3 in full.**

- [ ] **Step 2: Extract Step 2's URL-pattern branch (branch 2 of the five-branch detection logic) into `references/url-patterns.md`**, categorized by content type. The core five-branch logic stays inline in `SKILL.md`'s Step 2, unchanged — only the URL-pattern table moves out.

- [ ] **Step 3: Extract each of Step 3's three content-type branches verbatim into its own file** — `extract-article-news.md`, `extract-social.md`, `extract-video.md`. Preserve existing instructions exactly; this step is a pure move, not a rewrite (Tasks 6 and 7 layer the actual content changes on top).

- [ ] **Step 4: Collapse `SKILL.md`'s Step 3 to a thin dispatch table** naming which reference file each branch (decided in Step 2) reaches — matching the existing pattern already used correctly by Step 5 (Variable syntax: full vocabulary in `references/variable-glossary.md`/`filter-glossary.md`, a short two-form summary kept inline).

- [ ] **Step 5: Verify the extraction is complete and lossless**

Run: `wc -l skills/clip-resource/SKILL.md` — expect roughly 50 fewer lines than before this task (the ~50 lines originally inline across the three branches, per the resolved finding).
Run: `ls skills/clip-resource/references/` — expect `url-patterns.md`, `extract-article-news.md`, `extract-social.md`, `extract-video.md` present alongside the existing `filter-glossary.md`, `variable-glossary.md`.

- [ ] **Step 6: Run humanizer pass** on all four new files and the edited `SKILL.md`.

- [ ] **Step 7: Commit**

```bash
git -C the-factory/slipbox add skills/clip-resource/
git -C the-factory/slipbox commit -m "refactor(clip-resource): extract Step 3 branches and URL patterns to references/"
```

---

## Task 6: `clip-resource` — content redesign (multi-URL, Social fetcher, Resource-frozen move, Ladder naming, install-warning consolidation, report format)

**Files:**
- Modify: `skills/clip-resource/SKILL.md`
- Modify: `skills/clip-resource/references/extract-social.md`
- Modify: `skills/clip-resource/references/variable-glossary.md`
- Modify: `skills/setup-slipbox/SKILL.md` (TinyFish prerequisite check, detect-and-report-only)
- Modify: `skills/setup-slipbox/assets/GLOSSARY.md` (Resource entry gains the frozen fact — see Step 8)

**Depends on:** Task 5 (this task edits files Task 5 creates) and Task 2 (this task edits `GLOSSARY.md`, already committed by Task 2 but reopened here for one addition).

- [ ] **Step 1: Step 1 (Multi-URL handling)** — currently accepts one URL only. Add: spawn one subagent per URL, each running the fetch/extract/transform/write pipeline independently and in parallel; explicit stated fallback line — "if no subagent capability exists in this harness, process each URL sequentially instead."

- [ ] **Step 2: Step 0** — reorder so the positive directive ("tell the user to run `/setup-slipbox`…") leads. Cut "do not proceed to any other step" (pure restatement of "stop"). Keep "do not improvise conventions in its place" (a distinct, subtler guard: not advancing, but still fabricating a convention while waiting).

- [ ] **Step 3: Step 4 (Transform)** — state the sequencing explicitly: read the template first (location via the `templates.<type>_path` scoped read from Task 4), then resolve its variables/filters against the reference files. Replace the "Bud candidate"/"Further exploration" legacy jargon (confirmed dead vocabulary from the retired `idea.db`/`surface-ideas` pipeline) with the positive current-design statement: "`clip-resource` fills in only what the template's own variables and filters ask for — see `references/variable-glossary.md` and `references/filter-glossary.md`. Nothing beyond that: no line naming an idea worth pursuing, no conclusion about what the content means." Keep the existing `make-literature-note` handoff rationale that follows it, unchanged.

- [ ] **Step 4: `references/extract-social.md`** — the current file names no fetch tool for Social, only the extraction ladder run against whatever was already fetched. Add: TinyFish first (free, the only option that can read Threads), Firecrawl as fallback. State explicitly: Social clipping still fully functions Firecrawl-only if TinyFish isn't available.

- [ ] **Step 5: `setup-slipbox/SKILL.md`** — add a TinyFish prerequisite check: detect-and-report only, no install attempt (TinyFish is an MCP-based tool, not a CLI binary or Python library like the other three dependencies — no local install step exists for it). State this distinction explicitly in the check's own text, so a reader doesn't expect the same install-script treatment as Defuddle/Firecrawl/youtube-transcript-api.

- [ ] **Step 6: Ladder naming** — `clip-resource/SKILL.md` currently calls the same fact-extraction sequence "the schema.org / meta tag / LLM-read ladder" in one place and "the same extraction ladder as before" in another. Name both instances consistently as the Ladder pattern, referencing `GLOSSARY.md`'s Ladder entry (from Task 2) by name. Also fix the Article/News Defuddle→Firecrawl sequence, which currently is only described as "replaces the… ladder," never itself named one — name it a Ladder instance too, consistently with the Social sequence.

- [ ] **Step 7: Install-warning trio consolidation** — the "do not install X yourself" warning is restated three times (Defuddle/`npm install`, Firecrawl/`firecrawl config`, youtube-transcript-api/`pip install`). State the shared shape once (missing dependency → stop, point to `/setup-slipbox`, never self-install), in a single dedicated note or at Step 0. Each dependency's own site keeps only what's unique to it: "same as above, except don't attempt `<command>`."

- [ ] **Step 8: Resource-frozen clause move** — delete the family-wide clause currently at `clip-resource/SKILL.md:108` (which restates root `AGENTS.md`'s Guardrail verbatim). Confirm `GLOSSARY.md`'s Resource entry (drafted in Task 2) already carries this fact as a property of what a Resource is; if Task 2's draft doesn't yet state it precisely as "no skill in this family reopens it to edit, append, or correct it," add that exact clause to the Resource entry now. `clip-resource/SKILL.md` keeps only its own local instruction ("this skill does not reopen it…"), dropping the family-wide framing. Root `AGENTS.md:59` stays as-is (source of the fact, unchanged).

- [ ] **Step 9: `references/variable-glossary.md`** — delete its restated "not supported (yet)" filter list. Point to `filter-glossary.md`'s own section instead, using the same pointer convention `variable-glossary.md` already applies two lines above ("See `filter-glossary.md` for the filter vocabulary…").

- [ ] **Step 10: Step 6 (Report) — new card format.** Single URL, success:

```
Clip Saved

**Type:** article
**URL:** https://example.com/some-post
**Saved to:** resources/article/some-post.md
```

Single URL, failure:

```
Clip Failed

**URL:** https://example.com/some-post
**Type:** article (detected)
**Reason:** Defuddle and Firecrawl fallback both failed — page returned a login wall.
```

Multiple URLs (batch table, not stacked single-URL cards, matching `find-connections`' existing batch-present convention):

```
Clip Results — 3 URLs

| URL | Type | Result |
|---|---|---|
| example.com/a | article | Saved to `resources/article/a.md` |
| example.com/b | video | Failed — transcript disabled |
| example.com/c | social | Saved to `resources/social/c.md` |
```

No closing prompt or question after either shape — the report states the outcome and ends.

- [ ] **Step 11: Run humanizer pass** on every file touched this task.

- [ ] **Step 12: Verify**

Run: `grep -n "Bud candidate\|Further exploration" skills/clip-resource/SKILL.md`
Expected: zero hits.

Run: `grep -c "do not install\|don't install" skills/clip-resource/SKILL.md`
Expected: exactly 1 (the consolidated shared-shape statement) plus per-dependency short callbacks — confirm by reading, not just counting, since the per-dependency lines legitimately reference the shape without repeating "do not install" verbatim.

Run: `grep -n "not supported (yet)" skills/clip-resource/references/variable-glossary.md`
Expected: zero hits.

Run: `grep -n "AGENTS.md.*Guardrail\|reopen.*edit.*append.*correct" skills/clip-resource/SKILL.md`
Expected: only the skill's own local instruction remains, not the family-wide clause.

- [ ] **Step 13: Bump `metadata.version`** (minor) on `clip-resource` and `setup-slipbox` — both gained new mechanisms (multi-URL fan-out, TinyFish check).

- [ ] **Step 14: Commit**

```bash
git -C the-factory/slipbox add skills/clip-resource/ skills/setup-slipbox/
git -C the-factory/slipbox commit -m "feat(clip-resource): multi-URL fan-out, TinyFish Social fetch, Ladder naming, report card redesign"
```

---

## Task 7: Grounding family — "Never finish it for them"

**Files:**
- Modify: `skills/grounding/SKILL.md`
- Modify: `skills/grounding/references/feynman.md`
- Modify: `skills/grounding/references/maieutic.md`
- Modify: `skills/grounding/references/self-explanation.md`
- Modify: `skills/grounding/references/connect.md`
- Modify: `skills/grounding/references/challenge.md`
- Modify: `skills/grounding/references/distil.md`

**Interfaces:**
- Produces: a new heading "Never finish it for them" in `grounding/SKILL.md`, placed directly after the existing "Never your own opinion" heading. All six reference files below cite this heading by name (same-package reference, no path needed — all ship together inside `skills/grounding/`).

- [ ] **Step 1: Read `grounding/SKILL.md`'s current "Never your own opinion" heading and surrounding text** to find the exact insertion point.

- [ ] **Step 2: Add the new heading**, stating the previously-unnamed shared principle: the completion/candidate/connection/counter-argument is always the user's to supply, never the agent's to hand over. Place it immediately after "Never your own opinion" (the two are easy to conflate — that conflation is what caused `challenge.md`'s original misattribution).

- [ ] **Step 3: Trim `feynman.md`, `maieutic.md`, `self-explanation.md`, `connect.md`** — each currently states its own local version of this principle in full. Trim each to a one-line citation of the new heading, plus that technique's own remaining technique-specific rationale (do not cut anything genuinely specific to the technique, only the restated shared principle).

- [ ] **Step 4: Correct `challenge.md`'s citation** — it currently cites "the same 'never your own opinion' rule," which is a factual misattribution (that heading covers the agent's own prior-knowledge disagreement with a source, routed via Noticing a tension — a different, narrower rule with nothing to do with withholding a completion from the user). Change the citation to point at the new "Never finish it for them" heading instead.

- [ ] **Step 5: `distil.md`** — cut the two sentences it currently copies from `SKILL.md`'s Gate rule (already stated via its own pointer, "Gate applies at full force here"). Keep the pointer only. Confirm during this edit that `distil.md`'s own handling (reflecting the technique combination back as a question the user must confirm via the Gate, never asserting it) already satisfies "Never finish it for them" without needing its own new citation — it's structurally consistent already, not an exception requiring separate treatment.

- [ ] **Step 6: Run humanizer pass** on all seven files.

- [ ] **Step 7: Verify**

Run: `grep -n "never your own opinion" skills/grounding/references/challenge.md`
Expected: zero hits (citation corrected to point elsewhere).

Run: `grep -c "Never finish it for them" skills/grounding/SKILL.md skills/grounding/references/feynman.md skills/grounding/references/maieutic.md skills/grounding/references/self-explanation.md skills/grounding/references/connect.md skills/grounding/references/challenge.md`
Expected: at least 1 in each of the six files (the heading itself in `SKILL.md`, a citation in each reference file).

- [ ] **Step 8: Bump `metadata.version`** (minor) on `grounding` — new heading is a mechanism-level addition (a new named guardrail).

- [ ] **Step 9: Commit**

```bash
git -C the-factory/slipbox add skills/grounding/
git -C the-factory/slipbox commit -m "feat(grounding): add Never finish it for them heading, unify five techniques' shared principle"
```

---

## Task 8: Remaining scattered fixes

**Files:**
- Modify: `skills/make-literature-note/SKILL.md`
- Modify: `skills/setup-slipbox/SKILL.md`
- Modify: `skills/write-checks/SKILL.md`
- Modify: `skills/ground-me/SKILL.md`
- Modify: `skills/make-evergreen-note/SKILL.md`
- Modify: `AGENTS.md` (repo root)

- [ ] **Step 1: `make-literature-note/SKILL.md:59`** — capitalize "surface pass" to match the already-capitalized occurrences at lines 64 and 95.

- [ ] **Step 2: `setup-slipbox/SKILL.md:154`** — correct the re-run trigger wording. Line 154 currently says the trigger is `.slipbox/` existing; line 35 establishes the precise rule (`.slipbox/config.json` existing triggers the re-run/drift-check flow; bare `.slipbox/` with no `config.json` routes to a clean restart of Sections A/B instead). Rewrite line 154 to: "Triggered only when the user explicitly asks to re-run, or when Explore finds `.slipbox/config.json` already present."

- [ ] **Step 3: `setup-slipbox/SKILL.md:32`** — reword to drop "corpus" entirely. Current text calls existing note folders "a style corpus for Section B," which plants the exact temptation line 93's prohibition later corrects. New wording: "a general sense of the vault's existing formatting and structure, referenced for context, never analyzed as a sample set." Line 93's prohibition (the `stated_style.json`/voice-fingerprint guardrail) stays as reinforcement, not walked back.

- [ ] **Step 4: Cut `stated_style.json` everywhere** — `setup-slipbox/SKILL.md` lines 93 and 107 (the clause specifically, not the surrounding corpus-voice guardrail from Step 3), and `write-checks/SKILL.md` line 26. Confirmed dev-only artifact from an earlier development version, never shipped by any real version of the skill.

- [ ] **Step 5: `write-checks/SKILL.md` lines 25–26** — precision fix, not a negation rewrite. Current text claims "It never reads profile baselines." Replace with: "It reads `style-profile.json` only for language-gating; it never uses the profile's voice, tone, or formatting fields as a detection threshold." (The CLI's `cmd_humanize_check` does read the profile's `language` field to gate which signals apply.)

- [ ] **Step 6: `ground-me/SKILL.md` frontmatter description** — drop "no sibling routing" entirely (confirmed: no sibling skill in the family performs hand-off routing today; the phrase negates a behavior nothing has). Rewrite "no note-type commitment" as a positive statement: "a freeform interview with no note produced."

- [ ] **Step 7: `make-evergreen-note/SKILL.md`'s Compass pointer** — remove the incorrect bare path (`references/compass.md`, which doesn't exist inside `make-evergreen-note`'s own bundle — it has no `references/` folder) and the migration-history parenthetical. Replace with a name-only reference, no path at all: "Orient the take with the Compass technique — reach for whichever direction the conversation calls for, no fixed order." This relies on `/grounding` already being invoked as the engine (its own dispatch table in `grounding/SKILL.md` names every technique, including a correct same-package pointer to `compass.md`) — `make-evergreen-note` never needs to reach across the package boundary itself.

- [ ] **Step 8: `setup-slipbox/SKILL.md:137` and `write-checks/SKILL.md` lines 48–58** — trim the field_map schema shape restatement (name/type/wikilink/zone/deferred/bare-string forms) to a pointer at `assets/config.schema.json`'s own `description` field, the canonical machine-validated definition both skills already validate against directly. `setup-slipbox`'s own resolution-process guidance (the type-occupancy check, the interactive three-way branch) is untouched — that's how to resolve a mapping, not what the final stored shape is.

- [ ] **Step 9: Root `AGENTS.md` line 43** — correct the install-mechanism claim. Current text overstates the case ("keeps `CONTEXT.md` out of individual installs" implies a per-skill-only exemption, and claims "a full clone of the repo" reaches the user). Rewrite: neither `tests/` nor `CONTEXT.md` ever ships under any `npx skills add` invocation, because the install unit is always one skill's own directory — `skills add owner/repo` included. The `git clone` the CLI performs is discovery staging only, deleted after copying whichever skill directories were requested. Add a cross-reference to `.slipbox/AGENTS.md`/`GLOSSARY.md` as the actual mechanism that closes the runtime-reachability gap this line was gesturing at.

- [ ] **Step 10: Root `AGENTS.md`'s Cross-skill-references section** — rewrite to state the real `disable-model-invocation` rule: the flag marks "runs only when the user explicitly asks," not "is an engine skill." Drop the false `disable-model-invocation: true` parenthetical currently attached to `/grounding`/`/write-checks` (neither carries the flag — confirmed against shipped frontmatter). State the actual pattern: the five skills that do carry the flag (`clip-resource`, `find-connections`, `ground-me`, `setup-slipbox`, `write-reference`) are each a leaf action meant to run only on explicit user request, never the model's own suggestion. `grounding`/`write-checks` structurally cannot carry the flag, since the family's architecture depends on other skills freely invoking them mid-procedure. `make-literature-note`/`make-evergreen-note` correctly lack it too.

- [ ] **Step 11: Run humanizer pass** on all six files.

- [ ] **Step 12: Verify**

Run: `grep -rn "stated_style" skills/`
Expected: zero hits.

Run: `grep -n "no sibling routing" skills/ground-me/SKILL.md`
Expected: zero hits.

Run: `grep -n "disable-model-invocation: true" AGENTS.md`
Expected: zero hits (the false parenthetical is gone; the real frontmatter values, unaffected by this task, remain only inside each skill's own `SKILL.md`).

Run: `grep -n "references/compass.md" skills/make-evergreen-note/SKILL.md`
Expected: zero hits.

- [ ] **Step 13: Bump `metadata.version`** (patch, since these are wording/precision fixes, not mechanism changes) on `make-literature-note`, `setup-slipbox`, `write-checks`, `ground-me`, `make-evergreen-note`.

- [ ] **Step 14: Commit**

```bash
git -C the-factory/slipbox add skills/make-literature-note/SKILL.md skills/setup-slipbox/SKILL.md skills/write-checks/SKILL.md skills/ground-me/SKILL.md skills/make-evergreen-note/SKILL.md AGENTS.md
git -C the-factory/slipbox commit -m "fix(family): correct stated_style.json, Compass path, AGENTS.md install-mechanism claims"
```

---

## Task 9: Regression check

**Files:** none created or modified (verification only, plus the eval design noted in Step 3)

**Depends on:** Tasks 2–8, all committed.

- [ ] **Step 1: Full-repo dangling-reference sweep**

```bash
cd the-factory/slipbox
grep -rn "CONTEXT.md" skills/                          # expect: zero
grep -rn "reference-note-admission-contract" skills/   # expect: zero
grep -rn "stated_style" skills/                        # expect: zero
grep -rln "\.slipbox/bin/slipbox" skills/*/SKILL.md     # expect: zero
grep -rn "references/compass.md" skills/                # expect: zero
grep -n "Bud candidate\|Further exploration" skills/clip-resource/SKILL.md   # expect: zero
```

- [ ] **Step 2: `GLOSSARY.md` term-coverage check**

For every bolded term across every `SKILL.md` and `references/*.md` in `skills/`, confirm a matching entry exists in `skills/setup-slipbox/assets/GLOSSARY.md`. For every entry in `GLOSSARY.md`, confirm it's reachable from at least one skill's own text or explicitly marked general family vocabulary (not orphaned). This is a manual read-through, not a single grep — bolded terms are markdown emphasis used for other purposes too, so a naive `grep "\*\*"` will over-match; cross-check by eye against the `_Avoid_` entries drafted in Task 2.

- [ ] **Step 3: Eval status per touched skill**

For each of the nine `tests/{{skill}}/evals.json` files, note whether the skill's behavior changed enough to need re-running:

- `clip-resource` — structural redesign (Task 5, Task 6). Re-run `tests/clip-resource/evals.json` against the redesigned skill in a clean context, with and without the skill, per root `AGENTS.md`'s Evals convention. This is the one skill whose existing fixtures cannot be assumed still valid — the report format, Step 3 dispatch, and Social fetcher all changed. **If `tests/clip-resource/evals.json` doesn't yet cover the new multi-URL and TinyFish-fetch paths, design 2–3 new prompts for those cases now** (one multi-URL clip, one Social-type clip) before re-running, per root `AGENTS.md`'s "start with 2-3 varied prompts including one edge case" guidance.
- `grounding` — new heading added, no behavior change to existing techniques. Spot-check `tests/grounding/evals.json` prompts still produce the same completion-withholding behavior; no new eval needed.
- `setup-slipbox`, `write-checks`, `make-literature-note`, `write-reference`, `make-evergreen-note`, `ground-me`, `find-connections` — wording/pointer/config-read-pattern fixes only, no behavior change an eval would catch differently. Note as "no eval re-run needed, verified by the grep sweep in Step 1 instead" rather than fabricating a pass.

- [ ] **Step 4: Confirm no skill's install-time bundle references anything outside itself**, per this plan's own Global Constraints.

```bash
for d in skills/*/; do
  echo "=== $d ==="
  grep -rn "\.\./\|/skills/[a-z-]*/" "$d" | grep -v "^Binary" || echo "  (clean)"
done
```

Expected: every hit is either a bare skill-name reference with no path (e.g. "run `/grounding`"), or refers to a file inside that same skill's own folder. Any hit naming another skill's `references/`/`assets/` path directly is a violation — fix before merging.

- [ ] **Step 5: Final tree check**

```bash
git -C the-factory/slipbox status --short
git -C the-factory/slipbox log --oneline feat/grounding-family-redesign..chore/writing-for-agents-cleanup
```

Expected: clean tree, 7 commits (Tasks 2 through 8), one per phase, each independently reviewable.

- [ ] **Step 6: Report back to the user** with the eval re-run results (Step 3), the cross-reference sweep results (Steps 1–2, 4), and the commit list (Step 5) — do not merge or open a PR without explicit go-ahead, per this workspace's confirmation-threshold rule.

---

## Self-Review Notes

**Spec coverage:** every confirmed disposition in both resolved discussion topics maps to a task above — `GLOSSARY.md`/`.slipbox/AGENTS.md` (Task 2), Prerequisite collapse and pointer rollout (Task 3), config scoped-read (Task 4), `clip-resource` structural extraction (Task 5) and content redesign (Task 6), grounding family heading (Task 7), and the fourteen remaining scattered fixes (Task 8). Nothing in either resolved file's "Confirmed fix" language is left unassigned.

**Placeholder scan:** every task names the exact file, the exact old behavior, and the exact new text or mechanism — no "add appropriate handling," no "similar to Task N" without repeating the actual content.

**Cross-task consistency:** `GLOSSARY.md`'s Resource entry (Task 2) is the single source Task 6 Step 8 depends on: if Task 2's initial draft doesn't yet carry the exact frozen-Resource clause, Task 6 Step 8 adds it there before removing it from `clip-resource/SKILL.md` — sequenced so the fact is never simultaneously absent from both places mid-plan. `.slipbox/AGENTS.md`'s completion-sentinel role (Task 2) is consumed identically by all nine Prerequisite rewrites in Task 3 — same check, same wording pattern, verified by the Task 3 Step 9 grep.
