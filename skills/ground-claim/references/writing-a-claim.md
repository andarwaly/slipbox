# Writing a claim

See `qec-theory.md` first for what Question, Evidence, and Conclusion each are. This
file covers the structure a confirmed claim gets assembled into, how to review it before
committing it to disk, and the formatting mechanics (quotes, Key Concepts wikilinks)
that live inside a claim entry once it's written.

## Structure

Assemble the claim as its own `###`-headed entry under `## Key Claims`:

```markdown
### [short name for this claim]
- **Question:** [the question this claim answers]
- **Evidence:** [paraphrased evidence, or a quote — see Quotes below]
- **Conclusion:** [the confirmed Claim, in the user's own words]
```

## Review checklist

Run this against the assembled entry before writing it to disk. This checks the
*content* quality of the claim itself — not style, frontmatter, or humanize signals,
which is `/write-checks`'s job, run separately.

**Question**
- Is it a question the source actually answers, not one invented to give the claim a
  slot to sit in?
- Is it specific enough that a Conclusion could resolve it — not a topic label
  ("What does X cover?") standing in for a real question?

**Evidence**
- Does it report what the source said or showed — not already a step toward what it
  means?
- If quoted: does the exact wording earn its place (a definition, a phrase later
  discussion refers back to) — or would paraphrase lose nothing?
- Traceable to the source, nothing added that isn't there?

**Conclusion**
- Delete-test: with the Evidence bullet gone, does the Conclusion still stand alone as
  a complete statement of the source's position?
- Is it the source's position — no drift into the user's own reaction or synthesis (per
  `/grounding`'s "never your own opinion" and the literature note's purity rule)?
- Stated as a claim, not a rewording of Evidence?

**The claim as a whole**
- Citability test (`CONTEXT.md`'s atomicity rule): if another note cited this Key
  Claim, is there exactly one clear thing being cited — not a bundle of several source
  points under one heading?
- Every term the claim leans on present in Key Concepts, each with a correctly
  resolved wikilink (see Key Concepts wikilinks below)?

If any item fails, the claim isn't done — go back to `/grounding` and probe further
(Mechanism, Boundary, or Distinction probe, per `grounding/SKILL.md`) rather than
rewording at write time. A failed delete-test in particular means the interview closed
its Gate too early, not that the wording needs polish.

## Quotes

A direct quote earns its place in Evidence only when the exact wording carries
something paraphrase would lose — a definition, or a phrase later discussion refers
back to. Otherwise paraphrase.

When used, place it after the bullet list, still under the same `###` heading, never
nested inside the Evidence bullet:

```markdown
> [the quoted text]
[[Author Name]] #quote
```

`[[Author Name]]` is a bare, intentionally-unresolved wikilink — no author-note entity
exists in this family.

## Key Concepts wikilinks

Add or extend `## Key Concepts` with a wikilinked, 1-line gloss for any term this claim
introduces or leans on:

```markdown
- [[<term-note-filename>|Term Name]]: [what this source says about it, in one line]
```

This section is load-bearing — `find-terms` scans it for term-recurrence detection, so
every term the claim actually uses must appear here.

**Resolving `<term-note-filename>` correctly** — this is not just casing. Three
`.slipbox/config.json` keys apply together, never assume any of them:

- `paths.term` — which folder the term note lives in (a vault may have no dedicated
  term folder at all, e.g. everything under `Notes/`).
- `filenames.term` — the casing convention (kebab-case, Title Case, snake_case, per
  vault).
- `prefixes.term` — a title-prefix character (e.g. `※`), if the vault uses one. The
  term note's actual filename on disk includes this prefix; a link built without it
  points at a file that doesn't exist.

**Correct**, vault using `※` prefix and Title Case: `[[※ Confirmation Bias|Confirmation
Bias]]` — prefix in the link target, clean name in the display alias.

**Incorrect**: `[[confirmation-bias|Confirmation Bias]]` — hardcoded kebab-case,
no `paths.term` folder, no prefix. Points at nothing if the vault's actual term notes
live at `Notes/※ Confirmation Bias.md`.

A vault with no term folder and no prefix links flat and unprefixed, e.g.
`[[Strong Opinions, Weakly Held]]` — read all three keys, don't assume any one of them
based on what another vault does.
