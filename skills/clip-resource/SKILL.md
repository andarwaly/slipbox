---
name: clip-resource
description: Fetch one or more URLs and write each as a frozen Resource, matching Obsidian Web Clipper's output shape. For users without a clipper tool. Fetchable content only; paywalled or login-gated pages are not handled by this skill.
disable-model-invocation: true
license: MIT
metadata:
  version: "1.3.1"
---

# Clip Resource

Bold terms in this file are defined in `GLOSSARY.md`.

For the case where the user has no Web Clipper, no Readwise, nothing installed: this skill fetches a URL directly and writes a Resource file that looks like Web Clipper's own output. It never touches `.slipbox/candidates/` or takes part in the candidate pipeline; it reads template paths via `slipbox config get templates.<type>_path`, filename/frontmatter conventions via `slipbox config get filenames.<type>`, and transcript languages via `slipbox config get transcript_languages`, not pipeline bookkeeping. `make-literature-note` (and other note-writing skills) read the Resource file later; this skill's job ends once it's written.

## Prerequisite: `.slipbox/AGENTS.md` must exist

Check first, before anything else. Its presence confirms `setup-slipbox` completed a full run. Nothing here can proceed without it.

Tell the user to run `setup-slipbox` first, then re-run this skill, if `.slipbox/AGENTS.md` is absent. Do not improvise conventions in its place while waiting.

### Missing dependency: the same shape every time

Defuddle, Firecrawl, `youtube-transcript-api`, and TinyFish each get used somewhere below. Whichever one turns out missing or unauthenticated, the response is identical: stop the affected step, tell the user which dependency is missing and what it's for, point them at `setup-slipbox`, and do not install it yourself — that's `setup-slipbox`'s job alone, never this skill's. Each dependency's own mention further down states only what's different about that one case.

## Take the URL(s)

Ask for one or more URLs: articles, news stories, social/forum threads, or video links, any mix. There is no paste-the-text fallback. If the user hands you raw text instead of a link, tell them this skill only takes URLs and ask for one.

For more than one URL, spawn one subagent per URL. Each subagent runs the full fetch/extract/transform/write pipeline (Detect the content type through Write) independently, in parallel, for its own URL only. If no subagent capability exists in this harness, process each URL sequentially instead. Either way, one URL's failure never blocks or corrupts another's — each is fetched, extracted, transformed, and written on its own, and reported on its own in the Report the outcome step's batch table.

## Detect the content type

Determine which of the four content types applies, in this priority order:

1. **User-stated type**: if the user says "clip this article" or "clip this video," take it as a starting hypothesis, not a final answer.
2. **URL pattern**: domain and path shape. See `references/url-patterns.md` for patterns organized by content type.
3. **schema.org**: `NewsArticle`, `Article`, `DiscussionForumPosting`, `VideoObject`, etc., read off the fetched page.
4. **Conflict check**: compare the user-stated type (if any) against what the URL pattern and schema.org indicate. A real conflict (user says "article," URL is a Reddit thread) gets flagged to the user before anything is written. Never silently override in either direction.
5. **Ask fallback**: if signals disagree with each other or nothing resolves confidently, ask the user which type it is rather than guessing.

The four content types: **Article**, **News**, **Social/Forum thread**, **Video**.

## Fetch and extract

Note what you actually got back: full content, a truncated snippet, or nothing. Extraction splits by content type. Use the reference file matching the type detected in Detect the content type.

| Content type | Reference | Method |
|---|---|---|
| **Article**, **News** | `references/extract-article-news.md` | A two-rung Ladder (see `GLOSSARY.md`): Defuddle first, Firecrawl fallback for blocked fetches |
| **Social/Forum thread** | `references/extract-social.md` | TinyFish or Firecrawl fetch, then the Ladder (see `GLOSSARY.md`) for facts: schema.org JSON-LD, then `<meta>` tags, then LLM-read fallback |
| **Video** | `references/extract-video.md` | `youtube-transcript-api` Python library |

Read the reference file for your type; it covers the full extraction logic, tooling, error taxonomy, and fallback paths specific to that content type.

## Transform

`clip-resource` has no opinion on what any template's body should contain. Every template is 100% user-authored via `setup-slipbox`, and there is no shipped/default treatment implied by content type. This skill resolves bare variables verbatim and executes quoted instructions exactly as written (see `references/variable-glossary.md`), for every content type equally. A template author may write bare `{{content}}` for Article, a quoted cleanup instruction for News, `{{root_post}}` plus `{{continuation}}` for Social, bare `{{transcript}}` for Video, entity sections (People/Tools/Resources/Definition) or none at all — this skill fills in whatever the actual template asks for, without assuming a "typical" shape per type.

Read the template first — its location comes from the `templates.<type>_path` scoped read described above — then resolve its variables and filters against the reference files. Mechanical fields, not content-shape opinions, still apply regardless of template: `type` in frontmatter holds the content type directly — `article`, `news`, `social`, or `video`. Never a generic `"resource"` value; being a Resource is implied by folder location. `author` resolves per type's own definition (byline for Article/News, display name falling back to handle for Social, channel name for Video) — see `references/variable-glossary.md`. `published` resolves via Defuddle's output for Article/News, or the Ladder in Fetch and extract for Social, same as any other bare fact for that type.

`clip-resource` fills in only what the template's own variables and filters ask for — see `references/variable-glossary.md` and `references/filter-glossary.md`. Nothing beyond that: no line naming an idea worth pursuing, no conclusion about what the content means. Reading the material and forming an opinion on it is `make-literature-note`'s surface pass (per its own SKILL.md), run later and separately. A Resource file that already contains a take would skip that analytical step instead of feeding it.

## Variable syntax (summary)

Templates (see `.slipbox/config.json`'s `templates` paths for the four resource templates) use two variable forms, matching Obsidian Web Clipper's own convention. No new syntax invented. Full detail in `references/variable-glossary.md`; filters (`|wikilink`, `|date:"..."`, etc.) in `references/filter-glossary.md`.

- Bare `{{variable}}`: a raw, mechanically-extracted **fact** (e.g. `{{author}}`, `{{title}}`). Each bare variable is resolved by whatever method fits it. Most use the Ladder in Fetch and extract above, but `{{transcript}}` is the exception: it's pulled via `youtube-transcript-api`, never the Ladder.
- Quoted `{{"instruction"}}`: a **synthesis instruction**, freeform natural language executed inline by the same agent running this skill. No separate Interpreter service, no API key. Templates are user-authored (see `.slipbox/config.json`). This skill doesn't dictate what any given template's body variable looks like. A rewritten or summarized Article or News body is a quoted instruction the template's author writes, not something bare `{{content}}` does automatically.
- No template logic layer (`{% if %}`, `{% for %}`): the agent applies judgment directly. A rules-engine layer here would be redundant.

## Write

Save the file using the filename and frontmatter conventions recorded in `.slipbox/config.json`. Once written, treat the file as frozen: this skill does not reopen it to edit, append, or correct it. If the fetch or transform needs a fix, redo the clip and write a fresh file rather than patching the old one.

## Report the outcome

For a single URL, two valid endings, both explicit:

- **Success**: the Resource file exists at its path, shaped per Transform, with the correct `type` in frontmatter.

  ```
  Clip Saved

  **Type:** article
  **URL:** https://example.com/some-post
  **Saved to:** resources/article/some-post.md
  ```

- **Fetch failure**: the fetch returned an error, or returned content but it's a paywall teaser, a login wall, a blocked/rate-limited transcript request, or otherwise not the real article/thread/video. Do not write a partial Resource file, and do not attempt to work around the paywall, login gate, or block. A clear failure report is a complete, correct run of this skill; a half-written Resource file is not.

  ```
  Clip Failed

  **URL:** https://example.com/some-post
  **Type:** article (detected)
  **Reason:** Defuddle and Firecrawl fallback both failed — page returned a login wall.
  ```

For multiple URLs, one batch table covering every URL together, successes and failures alike, matching `find-connections`' batch-present convention:

```
Clip Results — 3 URLs

| URL | Type | Result |
|---|---|---|
| example.com/a | article | Saved to `resources/article/a.md` |
| example.com/b | video | Failed — transcript disabled |
| example.com/c | social | Saved to `resources/social/c.md` |
```

No closing prompt or question after either shape. State the outcome and end.
