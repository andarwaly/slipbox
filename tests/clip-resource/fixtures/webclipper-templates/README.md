# Pending: Web Clipper's own JSON templates

`article.json`, `news.json`, `social.json`, `video.json` — not yet built. Web Clipper's own template-export format (distinct from Obsidian's native Templater-style templates in `../vault-configured/.obsidian/templates/`). Imported into Web Clipper itself to produce `../expected/*-expected.md`.

Must request identical variables/fields, per content type, as the corresponding `.md` template — hand-written independently for now, not derived from one shared source (see `discussion/slipbox/decision.md`, point 10 of the TDD-verification section, for the accepted drift risk).
