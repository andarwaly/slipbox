# clip-resource

Fetch a URL and write it as a frozen Resource file, matching Obsidian Web Clipper's own output shape — for anyone who doesn't have Web Clipper, Readwise, or any other clipper tool installed.

## When to use

Use this when you want to bring an article or video into your vault as a Resource but have no clipper extension set up. It covers fetching, cleaning, and writing the file — nothing else.

It only handles content it can fetch cleanly. Paywalled articles and login-gated pages are explicitly out of scope: the skill reports the failure plainly rather than attempting a workaround.

## How it works

1. **Take the URL** — a single article or video link. No pasted-text fallback; if you hand it raw text, it asks for a URL instead.
2. **Fetch and detect** — retrieves the page or video content directly. Detects content type (article, news clip, social post, or video).
3. **Extract facts** — resolves author, title, publish date, and other metadata via an extraction ladder: schema.org JSON-LD first, then `<meta>` tags (Open Graph and standard), then LLM-read fallback on the fetched content. No CSS-selector extraction — that requires a headless browser, which isn't available here yet.
4. **Transform** — shapes the result into Web Clipper's own format: frontmatter (`type`, `link`, `author`, `published`, `tags`), a cleaned body, entity sections (People/Tools/Resources/Definition) where the content supports them, and a full transcript for video. It deliberately stops there — no "Bud candidate" or "Further exploration" section. Forming an opinion about the content is a separate skill's job (`surface-ideas`), run later.
5. **Write** — saves the file using the conventions `setup-slipbox` recorded. Once written, the file is frozen: this skill never reopens it, and neither does any other skill in the family.
6. **Report** — either the Resource file exists at its path, or the fetch failed (or came back as a paywall teaser/login wall) and that failure is reported plainly. Both are complete, valid outcomes; a half-written Resource file is not.

## Usage

Invoke it by name with a URL:

> Clip this article: https://example.com/some-article

## Installation

This skill ships as part of the `andarwaly/skills` collection:

```bash
npx skills add andarwaly/skills
```

See the [skill source](../../skills/slipbox/clip-resource/) for the full agent-facing instructions.
