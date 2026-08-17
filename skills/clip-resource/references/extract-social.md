# Social extraction

## Fetch

Try TinyFish first. It's free, and it's the only option here that can read Threads at all — a source no other tool in this family reaches. If TinyFish isn't available or fails, fall back to Firecrawl:

```bash
firecrawl scrape "<url>" --only-main-content
```

Social clipping still fully functions on Firecrawl alone if TinyFish isn't available — TinyFish only adds Threads coverage and a free-first option, it isn't a hard requirement for this content type.

## Extract facts

Defuddle has no concept of `root_post` plus `continuation` (the author's own reply chain, not other participants' replies). It would flatten a thread into one article-shaped blob. Resolve facts for Social via the Ladder (see `GLOSSARY.md`), in order, stopping at the first rung that yields the value:

1. **schema.org JSON-LD**: structured data embedded in the page.
2. **`<meta>` tags**: Open Graph / standard meta tags (`og:title`, `article:author`, etc.).
3. **LLM-read fallback**: read the fetched content directly and infer the value.

There is no CSS-selector extraction rung for Social. This skill has no DOM access for it (no headless browser). That's a future addition once a headless-browser capability exists in this environment, not something to fake with regex or guesswork today.
