# Social extraction

Defuddle has no concept of `root_post` plus `continuation` (the author's own reply chain, not other participants' replies). It would flatten a thread into one article-shaped blob. Resolve facts for Social via the same extraction ladder as before, in order, stopping at the first rung that yields the value:

1. **schema.org JSON-LD**: structured data embedded in the page.
2. **`<meta>` tags**: Open Graph / standard meta tags (`og:title`, `article:author`, etc.).
3. **LLM-read fallback**: read the fetched content directly and infer the value.

There is no CSS-selector extraction rung for Social. This skill has no DOM access for it (no headless browser). That's a future addition once a headless-browser capability exists in this environment, not something to fake with regex or guesswork today.
