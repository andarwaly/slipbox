# clip-resource variable glossary

Two variable forms, matching Obsidian Web Clipper's own convention (no new syntax invented):

- **Bare `{{variable}}`** — a raw, mechanically-extracted value. No agent judgment involved in producing it.
- **Quoted `{{"instruction"}}`** — a freeform natural-language instruction, executed inline by the agent running this skill (no separate Interpreter service, no API key, since the skill itself is the LLM). The agent's answer to that literal prompt becomes the value.

This file only describes *what each variable is and when to use it*. How a bare variable's value actually gets resolved (extraction ladder, or the `{{transcript}}` exception) is a workflow detail owned by `SKILL.md` §3 — not restated here.

## Bare variables

| Variable | Applies to | Description | When to use |
|---|---|---|---|
| `{{title}}` | All | The page or content title. Never includes `{{content}}`'s scope. | Frontmatter title, or referencing the source's own heading. |
| `{{url}}` | All | The source URL as given. | Frontmatter `link`. |
| `{{clipped_date}}` | All | The date this skill ran, not the source's publish date. | Frontmatter clip timestamp. |
| `{{domain}}` | All | The source URL's domain. | Tagging or grouping by site. |
| `{{content}}` | All | The raw body — headings and body text, everything inside the content area. Excludes title. Verbatim; never agent-rewritten. | Social/Video: this *is* the final body. Article/News: raw material a template's own quoted instruction can reference — not the final body itself. |
| `{{author}}` | Article, News, Social, Video | The byline (Article/News), display name falling back to handle (Social), or channel name (Video). | Frontmatter `author`. |
| `{{published}}` | Article, News, Social, Video | The source's own publish date. | Frontmatter `published`, usually paired with a `date` filter (see `filter-glossary.md`). |
| `{{description}}` | Article, News | A short summary or meta description, as given by the source. | Frontmatter `description`, or as raw material for a quoted instruction. |
| `{{publisher}}` | News | The outlet/publication name. | News-only frontmatter field. |
| `{{root_post}}` | Social | The thread's opening post. | Body content for Social — the thread-as-a-single-post case. |
| `{{continuation}}` | Social | The original author's own reply chain continuing the thread. Never other participants' replies. | Appended to `{{root_post}}` for the full thread body. |
| `{{transcript}}` | Video | The video's transcript. | Body content for Video. |
| `{{video_id}}` | Video (YouTube only) | The YouTube video identifier from the active transcript path. | Build a canonical URL, use as a lookup key, or construct `https://i.ytimg.com/vi/{{video_id}}/maxresdefault.jpg` for a deterministic `cover:` property. |

## Quoted instructions

Freeform, no fixed vocabulary. Example: `{{"rewrite the transcript, as an article"}}`. A template author writing an Article or News body that should be a cleaned rewrite or a compressed summary — rather than raw `{{content}}` — writes the instruction directly, e.g. `{{"cleaned rewrite of the source article"}}` or `{{"summarized, compressed treatment of the source"}}`.

Output from a quoted instruction goes through `/write-checks` with `artifact-kind: resource`, run from `SKILL.md`'s Write step, because the agent synthesized or rewrote it. Resource mode runs Style and Humanize only; bare-variable output never does, since there is nothing synthesized to check.

## Filters

See `filter-glossary.md` for the filter vocabulary (`wikilink`, `date`, `slice`, `trim`, `join`, `split`, `first`, `last`, `round`, `calc`) applied to any bare or quoted variable's resolved value.

## Not supported (yet)

CSS-selector-style variables (`{{selector:...}}`, `{{selectorHtml:...}}`) — no DOM access without a headless browser. Planned for a future version alongside a headless-browser install script. See `filter-glossary.md` for the filter vocabulary's own "Not supported (yet)" section, which covers the matching DOM-dependent filters. Template logic (`{% if %}`, `{% for %}`) is also unsupported — the agent has judgment already; a rules-engine layer here would be redundant.
