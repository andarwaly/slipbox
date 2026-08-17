# Article and News extraction

Do not fetch the page with a general-purpose web-fetch tool for these two types. A tool that runs fetched content through an intermediate summarizing model will silently drop content on long pages before this skill ever sees it. This actually happened once: an image gallery, a subsection, and a full walkthrough section vanished from an Article clip with no error reported. Bare `{{content}}` must reproduce what Defuddle extracted, not a pre-summarized version of it.

Run:

```bash
defuddle parse "<url>" --markdown
```

Call the `defuddle` binary directly, not via `npx`. `npx`'s own resolution/caching has been observed to be unreliable across working directories (inconsistent version output, occasional `enoent` failures) even when `defuddle` is correctly installed and on `PATH`.

Take `content`, `title`, `author`, and any schema.org-derived metadata directly from Defuddle's output. This replaces the Ladder (see `GLOSSARY.md`) that Social relies on for these two types — Defuddle's own output stands in for schema.org / `<meta>` tag / LLM-read rungs entirely. Defuddle parses via a DOM implementation (not a real browser), so it still won't see JS-rendered or lazy-loaded content that only appears after client-side execution. That ceiling is unchanged; it's just no longer masked by an upstream summarizing pass. If `defuddle` is missing: same shared shape as `SKILL.md`'s Step 0, except don't attempt `npm install`.

**On a blocked fetch, fall back to Firecrawl.** Defuddle has no headers, cookie, or proxy overrides. Some sites (confirmed: Medium) reject its bare fetch outright with a bot-detection block, different from the JS-rendering ceiling above. Tell the difference by Defuddle's error shape: an HTTP-response-level failure (a real status code, like `Failed to fetch: 403`) is worth retrying. A network-level failure (`fetch failed`, no status code, meaning a dead domain or typo) is not, since no fetch method resolves a domain that doesn't exist.

On an HTTP-response-level failure, retry once via Firecrawl:

```bash
firecrawl scrape "<url>" --only-main-content
```

If `firecrawl` is missing or unauthenticated: same shared shape as `SKILL.md`'s Step 0, except don't attempt an install or `firecrawl config` — and mention that Firecrawl is optional here, needed only for this fallback.

Take `content`, `title`, `author`, and metadata from Firecrawl's markdown output the same way as Defuddle's, once it succeeds. If the fetched content itself reads as a login, paywall, or registration wall (Medium's member-only stories land here even after the bot-block clears), that's `clip-resource`'s existing "paywalled or login-gated pages are not handled" rule, not a new case. Report it and write nothing, same as any other paywall hit today.

Fallback-only, never preemptive. Defuddle stays the default path for every Article/News source regardless of domain. No domain list routes straight to Firecrawl. A second Firecrawl failure is a clean stop, same as any other unfetchable page. No third attempt.
