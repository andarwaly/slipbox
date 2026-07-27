# Humanize Checklist

Fixed, skill-package-versioned. Copied verbatim into every vault by `setup-slipbox` — never edited per-vault, never register-matched to an individual user's corpus. This file only flags; it never auto-rewrites.

**Before applying**: read `.slipbox/style-profile.md` (or the `stated_style` fallback if no corpus exists) for this vault's own punctuation fingerprint, lexicon, and forbidden-vocabulary list. Signals below are generic; that file is what makes a flag specific to this user's actual voice.

**Rule**: require a cluster of 2 or more signals in the same passage before flagging it. A single hit is not enough.

## T1 — structural/durable tics

These don't decay — check every time, regardless of when this file was last updated.

- Negative parallelism ("not x, but y")
- Significance-inflation words ("crucial", "pivotal", "profound", "game-changing")
- Rule-of-three constructions used as a rhetorical crutch rather than because the content actually has three parts
- Vague attribution ("many believe", "some argue", "it is often said") with no traceable source
- Superficial "-ing" analysis clauses that restate the sentence's own claim instead of adding information
- Filler hedges ("it's worth noting that", "it's important to remember that")

## T2 — era-specific signals

- Em-dash density noticeably higher than this vault's own corpus baseline (see `style-profile.md`'s punctuation fingerprint)
- Passive voice used to obscure agency where the corpus's own writing is active
- AI-vocabulary words currently over-represented in generic AI writing: "delve", "leverage", "robust", "seamless", "tapestry", "testament", "underscore", "elevate", "unlock", "unpack", "navigate" (as a metaphor for handling a topic)

## T3 — decaying word lists

Versioned at the skill-package level — this list gets updated centrally as AI-vocabulary trends shift and ships with skill releases, never edited per-vault. `setup-slipbox` re-copies this file on every re-run, so a vault picks up package-level updates rather than staying frozen at first-setup content.

- Current version: v1 (2026-07-27)
- Watch list: "boils down to", "at the end of the day" (as a throwaway transition), "in today's fast-paced world", "it's not just about x, it's about y"
