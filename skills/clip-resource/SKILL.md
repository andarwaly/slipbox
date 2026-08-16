---
name: clip-resource
description: Fetch a URL and write it as a frozen Resource, matching Obsidian Web Clipper's output shape — for users without a clipper tool. Fetchable content only; paywalled or login-gated pages are not handled by this skill.
disable-model-invocation: true
license: MIT
metadata:
  version: "1.0.0"
---

# Clip Resource

For the case where the user has no Web Clipper, no Readwise, nothing installed: this skill fetches a URL directly and writes a Resource file that looks like Web Clipper's own output. It never touches `.slipbox/candidates/` or takes part in the candidate pipeline; the one file it reads from that directory is `.slipbox/config.json`, for template paths, filename/frontmatter conventions, and `transcript_languages`, not pipeline bookkeeping. `make-literature-note` (and other note-writing skills) read the Resource file later; this skill's job ends once it's written.

## 0. Prerequisite: `.slipbox/config.json` must exist

Check first, before anything else. This skill reads template paths, filename/frontmatter conventions, and `transcript_languages` from `.slipbox/config.json` — nothing here can proceed without it.

If `.slipbox/config.json` is absent: stop. Do not proceed to any other step, and do not improvise conventions in its place. Tell the user to run `setup-slipbox` first, then re-run this skill.

## 1. Take the URL

Ask for a single URL: an article, news story, social/forum thread, or video link. There is no paste-the-text fallback. If the user hands you raw text instead of a link, tell them this skill only takes URLs and ask for one.

## 2. Detect the content type

Determine which of the four content types applies, in this priority order:

1. **User-stated type** — if the user says "clip this article" or "clip this video," take it as a starting hypothesis, not a final answer.
2. **URL pattern** — domain and path shape (e.g. `youtube.com/watch`, `reddit.com/r/.../comments/`, a news outlet's domain).
3. **schema.org** — `NewsArticle`, `Article`, `DiscussionForumPosting`, `VideoObject`, etc., read off the fetched page.
4. **Conflict check** — compare the user-stated type (if any) against what the URL pattern and schema.org indicate. A real conflict (user says "article," URL is a Reddit thread) gets flagged to the user before anything is written — never silently overridden in either direction.
5. **Ask fallback** — if signals disagree with each other or nothing resolves confidently, ask the user which type it is rather than guessing.

The four content types: **Article**, **News**, **Social/Forum thread**, **Video**.

## 3. Fetch and extract

Note what you actually got back: full content, a truncated snippet, or nothing. Extraction splits by type — Article and News go through Defuddle; Social and Video each have their own path below.

### Article and News: use the `defuddle` CLI

Do not fetch the page with a general-purpose web-fetch tool for these two types — a tool that runs fetched content through an intermediate summarizing model will silently drop content on long pages before this skill ever sees it (this is what caused a real verbatim-content bug: an image gallery, a subsection, and a full walkthrough section disappeared from an Article clip with no error reported). Bare `{{content}}` must reproduce what Defuddle extracted, not a pre-summarized version of it.

Run:

```bash
defuddle parse "<url>" --markdown
```

Call the `defuddle` binary directly, not via `npx` — `npx`'s own resolution/caching has been observed to be unreliable across working directories (inconsistent version output, occasional `enoent` failures) even when `defuddle` is correctly installed and on `PATH`.

Take `content`, `title`, `author`, and any schema.org-derived metadata directly from Defuddle's output — this replaces the schema.org / `<meta>` tag / LLM-read ladder for these two types. Defuddle parses via a DOM implementation (not a real browser), so it still won't see JS-rendered or lazy-loaded content that only appears after client-side execution — that ceiling is unchanged, it's just no longer masked by an upstream summarizing pass. If `defuddle` is missing, stop and tell the user to run `setup-slipbox` to install it — do not attempt `npm install` from inside this skill.

**On a blocked fetch, fall back to Firecrawl.** Defuddle has no headers/cookie/proxy override of any kind — some sites (confirmed: Medium) reject its bare fetch outright with a bot-detection block, distinct from the JS-rendering ceiling above. Distinguish by Defuddle's own error shape: an HTTP-response-level failure (a real status code, e.g. `Failed to fetch: 403`) is worth retrying; a network-level failure (`fetch failed`, no status code — a dead domain, a typo) is not, since no fetch method resolves a domain that doesn't exist.

On an HTTP-response-level failure, retry once via Firecrawl:

```bash
firecrawl scrape "<url>" --only-main-content
```

If `firecrawl` is missing or unauthenticated, treat this exactly like Defuddle's own missing-binary case — stop, tell the user Firecrawl is optional and only needed for this fallback, and point them at `setup-slipbox`. Never attempt an install or `firecrawl config` from inside this skill.

Take `content`/`title`/`author`/metadata from Firecrawl's markdown output the same way as Defuddle's, once it succeeds. If the fetched content itself reads as a login/paywall/registration wall (Medium's member-only stories land here even after the bot-block clears) — this is `clip-resource`'s existing "paywalled or login-gated pages are not handled" rule, not a new case: report it and write nothing, same as any other paywall hit today.

Fallback-only, never preemptive: Defuddle stays the default path for every Article/News source regardless of domain — no domain list routes straight to Firecrawl. A second Firecrawl failure is a clean stop, same as any other unfetchable page — no third attempt.

### Social: extraction ladder (unchanged)

Defuddle has no concept of `root_post` plus `continuation` (the author's own reply chain, not other participants' replies) — it would flatten a thread into one article-shaped blob. Resolve facts for Social via the same extraction ladder as before, in order, stopping at the first rung that yields the value:

1. **schema.org JSON-LD** — structured data embedded in the page.
2. **`<meta>` tags** — Open Graph / standard meta tags (`og:title`, `article:author`, etc.).
3. **LLM-read fallback** — read the fetched content directly and infer the value.

There is no CSS-selector extraction rung for Social — this skill has no DOM access for it (no headless browser). That's a future addition once a headless-browser capability exists in this environment, not something to fake with regex or guesswork today.

### Video is the one exception to "fetch the page"

For Video, don't fetch the page HTML for the transcript. Use the **`youtube-transcript-api`** Python library directly (not the `ytt` CLI wrapper) to pull the transcript. Pass `languages` sourced from `.slipbox/config.json`'s `transcript_languages` ordered list.

Failure taxonomy — these are not interchangeable:

- **`VideoUnavailable`, `TranscriptsDisabled`, `NoTranscriptFound`** — a clean failure. Treat exactly like a paywall or login wall: report it, write nothing, stop.
- **`RequestBlocked`, `IpBlocked`** — a distinct message. This is an environment or rate-limit problem, not "no transcript exists for this video." Say so explicitly; don't conflate the two failure kinds in the report.
- **`import` fails / library not installed** — a third, distinct case, different from both of the above: this isn't about the video at all, it's a missing dependency. `setup-slipbox`'s Step 0 should have caught this already; if it's still missing, stop and tell the user to run `setup-slipbox` to install it — do not attempt `pip install` from inside this skill.

No Whisper fallback, or any other transcription workaround, under any failure condition.

## 4. Transform

`clip-resource` has no opinion on what any template's body should contain — every template is 100% user-authored via `setup-slipbox`, and there is no shipped/default treatment implied by content type. This skill resolves bare variables verbatim and executes quoted instructions exactly as written (see `references/variable-glossary.md`), for every content type equally. A template author may write bare `{{content}}` for Article, a quoted cleanup instruction for News, `{{root_post}}` plus `{{continuation}}` for Social, bare `{{transcript}}` for Video, entity sections (People/Tools/Resources/Definition) or none at all — this skill fills in whatever the actual template asks for, without assuming a "typical" shape per type.

Mechanical fields, not content-shape opinions, still apply regardless of template: `type` in frontmatter holds the content type directly — `article`, `news`, `social`, or `video`. Never a generic `"resource"` value; being a Resource is implied by folder location. `author` resolves per type's own definition (byline for Article/News, display name falling back to handle for Social, channel name for Video) — see `references/variable-glossary.md`. `published` resolves via Defuddle's output for Article/News, or the extraction ladder in Step 3 for Social, same as any other bare fact for that type.

Stop there. Do not add a "Bud candidate" section, a "Further exploration" section, or any other line that names an idea worth pursuing or a conclusion about what the content means. Reading the material and forming an opinion on it is `make-literature-note`'s surface pass (per its own SKILL.md), run later and separately. A Resource file that already contains a take would skip that analytical step instead of feeding it.

## 5. Variable syntax (summary)

Templates (see `.slipbox/config.json`'s `templates` paths for the four resource templates) use two variable forms, matching Obsidian Web Clipper's own convention — no new syntax invented. Full detail in `references/variable-glossary.md`; filters (`|wikilink`, `|date:"..."`, etc.) in `references/filter-glossary.md`.

- Bare `{{variable}}` — a raw, mechanically-extracted **fact** (e.g. `{{author}}`, `{{title}}`). Each bare variable is resolved by whatever method fits it — most via the extraction ladder in Step 3 above, but `{{transcript}}` is the exception: it's pulled via `youtube-transcript-api`, never the ladder.
- Quoted `{{"instruction"}}` — a **synthesis instruction**, freeform natural language executed inline by the same agent running this skill. No separate Interpreter service, no API key. Templates are user-authored (see `.slipbox/config.json`); this skill doesn't dictate what any given template's body variable looks like — a rewritten/summarized Article or News body is a quoted instruction the template's author writes, not something bare `{{content}}` does automatically.
- No template logic layer (`{% if %}`, `{% for %}`) — the agent applies judgment directly; a rules-engine layer here would be redundant.

## 6. Write

Save the file using the filename and frontmatter conventions recorded in `.slipbox/config.json`. Once written, treat the file as frozen: this skill does not reopen it to edit, append, or correct it, and no other skill in this family does either. If the fetch or transform needs a fix, redo the clip and write a fresh file rather than patching the old one.

## 7. Report the outcome

Two valid endings, both explicit:

- **Success**: the Resource file exists at its path, shaped per Step 4, with the correct `type` in frontmatter. Tell the user where it landed.
- **Fetch failure**: the fetch returned an error, or returned content but it's a paywall teaser, a login wall, a blocked/rate-limited transcript request, or otherwise not the real article/thread/video. Report plainly what came back and why it looks incomplete, and stop there. Do not write a partial Resource file, and do not attempt to work around the paywall, login gate, or block. A clear failure report is a complete, correct run of this skill; a half-written Resource file is not.
