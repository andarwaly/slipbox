# Pending: Web Clipper reference outputs

`article-expected.md`, `news-expected.md`, `social-expected.md`, `video-expected.md` — not yet built. Each must be real output from Obsidian Web Clipper itself, run against the same test URL used in the matching `evals.json` case, using the matching template from `../vault-configured/.obsidian/templates/`. Not something to fabricate — no file goes here until it's actually produced by Web Clipper.

Kept outside `vault-configured/resources/` deliberately: a test run writes into that folder, so a reference file living there too would collide with or get diffed against itself.
