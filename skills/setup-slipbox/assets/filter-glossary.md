# clip-resource filter glossary

_Mirrored from `clip-resource/references/filter-glossary.md`, bundled here so `setup-slipbox` can draft resource templates without a cross-skill path. `clip-resource` is the canonical, authoring-time source — keep both in sync by hand when the vocabulary changes._

Filters transform an already-resolved variable's value — applied after the variable (bare or quoted) has its value, chained with `|`. Mirrors Obsidian Web Clipper's own filter vocabulary, limited to the subset that's usable without DOM/selector access (`clip-resource` has none — see `variable-glossary.md`'s "Not supported" section).

Chain them left to right: `{{author|wikilink}}`, `{{published|date:"YYYY-MM-DD"}}`.

| Filter | Effect | When to use |
|---|---|---|
| `wikilink` | Wraps the value as an Obsidian wikilink: `[[value]]`. | Linking `{{author}}` or other entity-like values to their own note. |
| `date:"FORMAT"` | Reformats a date/timestamp string to the given format (e.g. `"YYYY-MM-DD"`). | Normalizing `{{published}}`/`{{clipped_date}}` to a consistent frontmatter format. |
| `slice:N,M` | Truncates to characters `N` through `M`. | Capping a long `{{description}}` or similar for frontmatter, or bounding what a quoted instruction reads. |
| `trim` | Strips leading/trailing whitespace. | Cleaning up a value pulled from inconsistent source formatting. |
| `join` | Joins a list value into a single string (default separator, or specify one). | Combining a multi-value field (e.g. multiple tags) into one frontmatter string. |
| `split` | Splits a string into a list on a separator. | Breaking apart a compound value (e.g. `"Author, Site"`) before further filtering. |
| `first` | Takes the first item from a list value. | When only one of several possible matches is wanted. |
| `last` | Takes the last item from a list value. | Same as `first`, from the other end. |
| `round` | Rounds a numeric value. | Cleaning up a computed number before writing to frontmatter. |
| `calc:"EXPR"` | Applies a simple arithmetic expression to a numeric value. | Deriving a value (e.g. estimated reading time from a word count) that isn't directly available as its own variable. |

## Not supported (yet)

DOM-dependent filters from Web Clipper's own vocabulary — `markdown`, `strip_tags`, `strip_attr`, `remove_html`, `image` — require operating on raw HTML, which `clip-resource` never has (no headless browser). Deferred to the same future version planned for `{{selector:...}}` support.
