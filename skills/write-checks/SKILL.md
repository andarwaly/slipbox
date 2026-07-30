---
name: write-checks
description: Check a note draft against the vault's own style profile and its humanize checklist before writing — use when another skill in the slipbox family is about to write a note to disk.
license: MIT
metadata:
  version: "1.0.0"
---

# Write-checks

## Prerequisite

Requires `.slipbox/style-profile.json` (or `.slipbox/stated_style.json`) and
`.slipbox/humanize-checklist.json` — both produced by `setup-slipbox`. If either is
missing, stop and say so.

## Style

Prose should read consistent with `.slipbox/style-profile.json` (or
`.slipbox/stated_style.json` if no corpus exists) — voice, tone, punctuation
fingerprint, lexicon, language/code-switching pattern — not a generic register.

## Humanize

After drafting, apply `humanize-checklist.json`'s `judgment` section directly — reading
comprehension, no tool needed — and run its `mechanical` section via
`idea-db humanize check <draft-path>`. If either surfaces a flagged cluster, revise
before writing the file — never write first and check after.

## Done

Hand back nothing but a pass/revise signal: either the draft reads clean against both
checks, or it doesn't yet and needs another pass before the calling skill writes it.
