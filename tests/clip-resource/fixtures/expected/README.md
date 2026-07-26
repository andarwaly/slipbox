# Web Clipper reference outputs

Real output from Obsidian Web Clipper, kept under the actual filenames Web Clipper derived from each title — not a generic `{{type}}-expected.md` name. Filename derivation is itself part of what `evals.json`'s `filename_equals` assertion checks, so flattening these to generic names would erase the thing being tested.

| File | Test URL | Content type |
|---|---|---|
| `Claude Code for Designers A Practical Guide.md` | `nervegna.substack.com/p/claude-code-for-designers-a-practical` | Article |
| `Israeli settlers set fire to mosques, cars and farm land in West Bank, Palestinians say.md` | `www.bbc.com/news/articles/cjrv77gl4deo` | News |
| `How Anthropic, Every, & Ramp design with AI.md` | `youtube.com/watch?v=V-jd3v9P-Ps` | Video |

**Set aside, not used**: `Xbox 360 games may be coming to PC soon.md` (Polygon) — Polygon mixes articles/guides and game news; the Substack piece was chosen for the Article slot instead. Left in place rather than deleted, in case it's useful later.

No Social file — see the parent `evals.json`'s note on why Social is excluded from the Web Clipper diff entirely (no fair comparison possible).

Kept outside `vault-configured/resources/` deliberately: a test run writes into that folder, so a reference file living there too would collide with or get diffed against itself.
