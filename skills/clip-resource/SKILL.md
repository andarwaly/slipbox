---
name: clip-resource
description: Fetch a URL and write it as a frozen Resource, matching Obsidian Web Clipper's output shape. For users without a clipper tool. Fetchable content only; paywalled or login-gated pages are not handled by this skill.
disable-model-invocation: true
license: MIT
metadata:
  version: "1.2.0"
---

# Clip Resource

Bold terms in this file are defined in `GLOSSARY.md`.

For the case where the user has no Web Clipper, no Readwise, nothing installed: this skill fetches a URL directly and writes a Resource file that looks like Web Clipper's own output. It never touches `.slipbox/candidates/` or takes part in the candidate pipeline; it reads template paths via `slipbox config get templates.<type>_path`, filename/frontmatter conventions via `slipbox config get filenames.<type>`, and transcript languages via `slipbox config get transcript_languages`, not pipeline bookkeeping. `make-literature-note` (and other note-writing skills) read the Resource file later; this skill's job ends once it's written.

## 0. Prerequisite: `.slipbox/AGENTS.md` must exist

Check first, before anything else. Its presence confirms `setup-slipbox` completed a full run. Nothing here can proceed without it.

If `.slipbox/AGENTS.md` is absent: stop. Do not proceed to any other step, and do not improvise conventions in its place. Tell the user to run `setup-slipbox` first, then re-run this skill.

## 1. Take the URL

Ask for a single URL: an article, news story, social/forum thread, or video link. There is no paste-the-text fallback. If the user hands you raw text instead of a link, tell them this skill only takes URLs and ask for one.

## 2. Detect the content type

Determine which of the four content types applies, in this priority order:

1. **User-stated type**: if the user says "clip this article" or "clip this video," take it as a starting hypothesis, not a final answer.
2. **URL pattern**: domain and path shape. See `references/url-patterns.md` for patterns organized by content type.
3. **schema.org**: `NewsArticle`, `Article`, `DiscussionForumPosting`, `VideoObject`, etc., read off the fetched page.
4. **Conflict check**: compare the user-stated type (if any) against what the URL pattern and schema.org indicate. A real conflict (user says "article," URL is a Reddit thread) gets flagged to the user before anything is written. Never silently override in either direction.
5. **Ask fallback**: if signals disagree with each other or nothing resolves confidently, ask the user which type it is rather than guessing.

The four content types: **Article**, **News**, **Social/Forum thread**, **Video**.

## 3. Fetch and extract

Note what you actually got back: full content, a truncated snippet, or nothing. Extraction splits by content type. Use the reference file matching the type you detected in Step 2.

| Content type | Reference | Method |
|---|---|---|
| **Article**, **News** | `references/extract-article-news.md` | Defuddle (primary) with Firecrawl fallback for blocked fetches |
| **Social/Forum thread** | `references/extract-social.md` | Extraction ladder: schema.org JSON-LD, then `<meta>` tags, then LLM-read fallback |
| **Video** | `references/extract-video.md` | `youtube-transcript-api` Python library |

Read the reference file for your type; it covers the full extraction logic, tooling, error taxonomy, and fallback paths specific to that content type.

## 4. Transform

`clip-resource` has no opinion on what any template's body should contain. Every template is 100% user-authored via `setup-slipbox`, and there is no shipped/default treatment implied by content type. This skill resolves bare variables verbatim and executes quoted instructions exactly as written (see `references/variable-glossary.md`), for every content type equally. A template author may write bare `{{content}}` for Article, a quoted cleanup instruction for News, `{{root_post}}` plus `{{continuation}}` for Social, bare `{{transcript}}` for Video, entity sections (People/Tools/Resources/Definition) or none at all — this skill fills in whatever the actual template asks for, without assuming a "typical" shape per type.

Mechanical fields, not content-shape opinions, still apply regardless of template: `type` in frontmatter holds the content type directly — `article`, `news`, `social`, or `video`. Never a generic `"resource"` value; being a Resource is implied by folder location. `author` resolves per type's own definition (byline for Article/News, display name falling back to handle for Social, channel name for Video) — see `references/variable-glossary.md`. `published` resolves via Defuddle's output for Article/News, or the extraction ladder in Step 3 for Social, same as any other bare fact for that type.

Stop there. Do not add a "Bud candidate" section, a "Further exploration" section, or any other line that names an idea worth pursuing or a conclusion about what the content means. Reading the material and forming an opinion on it is `make-literature-note`'s surface pass (per its own SKILL.md), run later and separately. A Resource file that already contains a take would skip that analytical step instead of feeding it.

## 5. Variable syntax (summary)

Templates (see `.slipbox/config.json`'s `templates` paths for the four resource templates) use two variable forms, matching Obsidian Web Clipper's own convention. No new syntax invented. Full detail in `references/variable-glossary.md`; filters (`|wikilink`, `|date:"..."`, etc.) in `references/filter-glossary.md`.

- Bare `{{variable}}`: a raw, mechanically-extracted **fact** (e.g. `{{author}}`, `{{title}}`). Each bare variable is resolved by whatever method fits it. Most use the extraction ladder in Step 3 above, but `{{transcript}}` is the exception: it's pulled via `youtube-transcript-api`, never the ladder.
- Quoted `{{"instruction"}}`: a **synthesis instruction**, freeform natural language executed inline by the same agent running this skill. No separate Interpreter service, no API key. Templates are user-authored (see `.slipbox/config.json`). This skill doesn't dictate what any given template's body variable looks like. A rewritten or summarized Article or News body is a quoted instruction the template's author writes, not something bare `{{content}}` does automatically.
- No template logic layer (`{% if %}`, `{% for %}`): the agent applies judgment directly. A rules-engine layer here would be redundant.

## 6. Write

Save the file using the filename and frontmatter conventions recorded in `.slipbox/config.json`. Once written, treat the file as frozen: this skill does not reopen it to edit, append, or correct it, and no other skill in this family does either. If the fetch or transform needs a fix, redo the clip and write a fresh file rather than patching the old one.

## 7. Report the outcome

Two valid endings, both explicit:

- **Success**: the Resource file exists at its path, shaped per Step 4, with the correct `type` in frontmatter. Tell the user where it landed.
- **Fetch failure**: the fetch returned an error, or returned content but it's a paywall teaser, a login wall, a blocked/rate-limited transcript request, or otherwise not the real article/thread/video. Report plainly what came back and why it looks incomplete, and stop there. Do not write a partial Resource file, and do not attempt to work around the paywall, login gate, or block. A clear failure report is a complete, correct run of this skill; a half-written Resource file is not.
