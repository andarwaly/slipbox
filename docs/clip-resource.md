# clip-resource

Fetch one or more URLs and write each as a frozen Resource file, matching Obsidian Web Clipper's own output shape — for anyone who doesn't have Web Clipper, Readwise, or any other clipper tool installed.

## When to use

Use this when you want to bring an article or video into your vault as a Resource but have no clipper extension set up. It covers fetching, cleaning, and writing the file — nothing else.

It only handles content it can fetch cleanly. Paywalled articles and login-gated pages are explicitly out of scope: the skill reports the failure plainly rather than attempting a workaround.

For Article and News, if the default fetcher gets blocked by bot detection (some Medium articles, for example) rather than the page genuinely not existing, it retries once via Firecrawl before giving up — optional, only used for this one case, most sources never need it.

## Prerequisite

This skill won't run until `setup-slipbox` has completed: it needs `.slipbox/AGENTS.md` to exist, plus every dependency `setup-slipbox` checks for (Defuddle, Firecrawl, `youtube-transcript-api`, TinyFish). If either is missing, it stops and points you at `setup-slipbox` rather than improvising a convention or installing anything itself.

## How it works

1. **Take the URL(s)** — one or more article or video links, any mix of content types, each checked to be a plain `http`/`https` URL before it reaches a fetch command. No pasted-text fallback; if you hand it raw text, it asks for a URL instead. Handed several URLs, it spawns one subagent per URL and works through them in parallel, falling back to a plain sequential pass if the harness has no subagent capability. Either way, one URL's failure never blocks or corrupts another's.
2. **Start recoverable work, then fetch and detect** — starts one `resource`/`clip` work item per URL with Start or resume work `/using-slipbox`, then retrieves the page or video content (Article/News fall back to Firecrawl once if the default fetch is blocked, never for content that simply doesn't exist). Detects content type (article, news clip, social post, or video) and checkpoints `manifest.json` plus `extraction.json`, including method, metadata, status, and failure details.
3. **Extract facts** — resolves author, title, publish date, and other metadata, but the method differs by content type rather than following one universal recipe. Article and News go through a two-rung ladder: Defuddle first, Firecrawl as fallback when the fetch is blocked; the `published` date for these two comes straight out of Defuddle's own output, not from any further extraction step. Social/Forum threads go through a separate three-rung ladder instead: schema.org JSON-LD first, then `<meta>` tags (Open Graph and standard), then LLM-read fallback on the fetched content. No CSS-selector extraction for either path — that requires a headless browser, which isn't available here yet.
4. **Transform** — fills in whatever your own template asks for: mechanical frontmatter (`type`, `link`, `author`, `published`, `tags`) always applies, but the body itself has no built-in default — verbatim content, a rewrite, a summary, entity sections, none of it is assumed by this skill. It only does what your template's variables tell it to. The active Video path is YouTube-specific, so a Video template may construct a deterministic thumbnail `cover:` from `{{video_id}}`; Article, News, and Social omit `cover:` because there is no verified generic image variable. It deliberately stops there — no "Bud candidate" or "Further exploration" section. Forming an opinion about the content is a separate skill's job (`make-literature-note`), run later. `make-literature-note` does its own surface pass over the source to identify discussion-worthy claims.
5. **Checkpoint and publish** — reads `paths.resources` from configuration and joins it with the resolved filename to form the exact vault-relative target. Missing or invalid configuration blocks publication; a resumed target that differs from the configured destination requires resolution. It resolves the template into `draft.md` (including bare-variable captures), then Checkpoint work and Publish an artifact `/using-slipbox` with create-only semantics and the target's expected fingerprint. If the template resolved a quoted instruction — meaning the agent synthesized or rewrote content rather than dropping it in verbatim — `/write-checks` runs first with `artifact-kind: resource`, checking Style and Humanize only. It does not invoke `note validate`, because that CLI accepts only `literature`, `reference`, and `evergreen`. A collision or concurrent target change fails without replacement. Failed work remains resumable or explicitly discardable; no partial Resource is published. Once published, the file is frozen and never reopened.
6. **Report** — for a single URL, either the Resource file exists at its path, or the fetch failed (or came back as a paywall teaser/login wall) and that failure is reported plainly. Both are complete, valid outcomes; a half-written Resource file is not. When several URLs were clipped in one run, the outcomes are reported together as one batch table — URL, detected type, and result (saved path or failure reason) for each — rather than as separate reports per URL.

The skill's own reference files spell out the extraction ladders, variable syntax, and filter vocabulary in full; see the [skill source](../skills/clip-resource/) for that listing.

## Usage

Invoke it by name with a URL:

> Clip this article: https://example.com/some-article

It also takes several URLs at once:

> Clip these: https://example.com/a, https://example.com/b, https://example.com/c

## Installation

This skill ships as part of the `andarwaly/slipbox` repo:

```bash
npx skills add andarwaly/slipbox
```

See the [skill source](../skills/clip-resource/) for the full agent-facing instructions.
