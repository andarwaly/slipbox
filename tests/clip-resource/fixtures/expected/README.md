# Pending: Web Clipper reference outputs

`article-expected.md`, `news-expected.md`, `video-expected.md` — not yet built. Each must be real output from Obsidian Web Clipper itself, run against the same test URL used in the matching `evals.json` case, using the matching template from `../vault-configured/.obsidian/templates/`. Not something to fabricate — no file goes here until it's actually produced by Web Clipper.

No `social-expected.md` — real Web Clipper has no concept matching `clip-resource`'s `continuation` (author's own reply-chain); only single-post text extraction, no schema.org on X/Twitter. No fair comparison possible, so Social is verified by mechanical assertions only (see `evals.json`).

Kept outside `vault-configured/resources/` deliberately: a test run writes into that folder, so a reference file living there too would collide with or get diffed against itself.
