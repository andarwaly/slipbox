# Write checks

Applies whenever a `ground-*` wrapper writes a note to disk. Two checks, both before the
file is written — not after:

- **Style.** Prose should read consistent with `.slipbox/style-profile.json` (or
  `.slipbox/stated_style.json` if no corpus exists) — voice, tone, punctuation
  fingerprint, lexicon, language/code-switching pattern — not a generic register.
- **Humanize.** After drafting, apply `humanize-checklist.json`'s `judgment` section
  directly and run its `mechanical` section via `idea-db humanize check <draft-path>`.
  If either flags a cluster, revise before writing the file — never write first and
  check after.
