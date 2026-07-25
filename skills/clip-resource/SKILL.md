---
name: clip-resource
description: Fetch a URL and write it as a frozen Resource, matching Obsidian Web Clipper's output shape — for users without a clipper tool. Fetchable content only; paywalled or login-gated pages are not handled by this skill.
disable-model-invocation: true
license: MIT
metadata:
  version: "1.0.0"
---

# Clip Resource

For the case where the user has no Web Clipper, no Readwise, nothing installed: this skill fetches a URL directly and writes a Resource file that looks like Web Clipper's own output. It never touches `.slipbox/candidates/` or takes part in the candidate pipeline; the one file it reads from that directory is `.slipbox/config.json`, for template paths, filename/frontmatter conventions, and `transcript_languages`, not pipeline bookkeeping. `surface-ideas` reads the Resource file later; this skill's job ends once it's written.

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

Retrieve the page or video content directly. Note what you actually got back: full content, a truncated snippet, or nothing.

For all four types, resolve facts (author, title, published date, etc.) via the same extraction ladder, in order, stopping at the first rung that yields the value:

1. **schema.org JSON-LD** — structured data embedded in the page.
2. **`<meta>` tags** — Open Graph / standard meta tags (`og:title`, `article:author`, etc.).
3. **LLM-read fallback** — read the fetched content directly and infer the value.

There is no CSS-selector extraction rung — this skill has no DOM access (no headless browser). That's a future addition once a headless-browser capability exists in this environment, not something to fake with regex or guesswork today.

### Video is the one exception to "fetch the page"

For Video, don't fetch the page HTML for the transcript. Use the **`youtube-transcript-api`** Python library directly (not the `ytt` CLI wrapper) to pull the transcript. Pass `languages` sourced from `.slipbox/config.json`'s `transcript_languages` ordered list.

Failure taxonomy — these are not interchangeable:

- **`VideoUnavailable`, `TranscriptsDisabled`, `NoTranscriptFound`** — a clean failure. Treat exactly like a paywall or login wall: report it, write nothing, stop.
- **`RequestBlocked`, `IpBlocked`** — a distinct message. This is an environment or rate-limit problem, not "no transcript exists for this video." Say so explicitly; don't conflate the two failure kinds in the report.
- **`import` fails / library not installed** — a third, distinct case, different from both of the above: this isn't about the video at all, it's a missing dependency. `setup-slipbox`'s Step 0 should have caught this already; if it's still missing, stop and tell the user to run `setup-slipbox` to install it — do not attempt `pip install` from inside this skill.

No Whisper fallback, or any other transcription workaround, under any failure condition.

## 4. Transform

Resolve whatever the user's template (see `.slipbox/config.json`) asks for — this skill doesn't dictate template content, it fills in the variables a template uses (see `references/variable-glossary.md`). The shipped/default templates ask for:

- **Frontmatter**: `type` holds the content type directly — `article`, `news`, `social`, or `video`. Never a generic `"resource"` value; being a Resource is implied by folder location. Plus `link`, `author`, `published`, `tags` as usual.
- **Article**: a quoted instruction for a full cleaned rewrite of the source, not bare `{{content}}`.
- **News**: adds a `publisher` frontmatter field. A quoted instruction for a summarized/compressed treatment, not a full rewrite and not bare `{{content}}`.
- **Social/Forum thread**: bare `{{root_post}}` plus `{{continuation}}` — the author's own continuation replies — the thread-as-a-single-post case (e.g. an X/Twitter thread), not top community replies from other participants. `author` is the display name, falling back to handle if no display name is available.
- **Video**: bare `{{transcript}}` pulled in Step 3. `author` is the channel.
- Entity sections where the content supports them: People, Tools, Resources, Definition.

A different template can ask for something else — e.g. a bare, unrewritten Article body — and this skill fills it in exactly the same way, without objecting.

Stop there. Do not add a "Bud candidate" section, a "Further exploration" section, or any other line that names an idea worth pursuing or a conclusion about what the content means. Reading the material and forming an opinion on it is `surface-ideas`'s Socratic stage, run later and separately. A Resource file that already contains a take skips that stage instead of feeding it.

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
