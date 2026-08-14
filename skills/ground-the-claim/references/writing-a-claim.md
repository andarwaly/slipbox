# Writing a claim

See `qec-theory.md` first for what Question, Evidence, Warrant, and Conclusion each are,
and which of them ever reach the page (only Evidence and Conclusion do). This file covers
the note's structure, the Core Idea line, how to review a claim before committing it to
disk, and the formatting mechanics (quotes, Key Concepts wikilinks) that live inside a
claim entry once it's written.

## Structure

```markdown
# {{prefix}} [Source-oriented title]

[Core Idea — bare declarative sentence, no label]

## Key Claims

### [Conclusion, stated declaratively — this is the claim, and the heading]
[Evidence, condensed — no separate "Evidence:" label, just the prose itself]
```

`{{prefix}}` resolves from `.slipbox/config.json`'s `prefixes.literature` for the vault
in question — never hardcode a literal character.

**Core Idea** — one sentence stating the source's central argument, everything else in
the note in service of it. Positional, not labeled: it's always the line directly after
the title and before `## Key Claims`, the same way a Resource's own `description` field
sits bare under its title. Written once, when the note's first claim is written; never
touched on a second or later claim for the same note.

**The `###` heading is the Conclusion, verbatim.** No separate "Conclusion:" bullet
follows it — that would just duplicate the heading. Evidence is the only other thing
under the heading: condensed prose, no bullet marker, no hard length cap — governed by
the vault's own `.slipbox/style-profile.json` the same as any other note content.

## Review checklist

Run this against the assembled entry before writing it to disk. This checks the
*content* quality of the claim itself — not style, frontmatter, or humanize signals,
which is `/write-checks`'s job, run separately.

**Core Idea** (first claim in a note only)
- Does every claim in this session serve it? A claim that doesn't points to one of two
  things: it doesn't belong in this note, or the Core Idea was drawn too narrow — flag
  either read to the user rather than silently resolving it.

**Conclusion** (the heading)
- Delete-test: with the Evidence line gone, does the Conclusion still stand alone as a
  complete statement of the source's position?
- Is it the source's position — no drift into the user's own reaction or synthesis (per
  `/grounding`'s "never your own opinion" and the literature note's purity rule)?
- Warrant self-check (per `qec-theory.md`): can the "why" be stated in one sentence from
  the Evidence? If Conclusion and that one sentence would say the same thing, the
  Conclusion is still restating, not concluding — go back and sharpen it.

**Evidence**
- Does it report what the source said or showed — not already a step toward what it
  means?
- If quoted: does the exact wording earn its place (a definition, a phrase later
  discussion refers back to) — or would paraphrase lose nothing?
- Traceable to the source, nothing added that isn't there?

**The claim as a whole**
- Citability test (`CONTEXT.md`'s atomicity rule): if another note cited this Key
  Claim, is there exactly one clear thing being cited — not a bundle of several source
  points under one heading? (The shared-Warrant merge test in `qec-theory.md` should
  already have caught this at the Surface pass — this is the final check, not the first.)
- Everything this claim leans on present in Key Concepts, each with a correctly
  resolved wikilink (see Key Concepts wikilinks below)?

If any item fails, the claim isn't done — go back to `/grounding` and probe further
(Mechanism, Boundary, or Distinction probe, per `grounding/SKILL.md`) rather than
rewording at write time. A failed delete-test in particular means the interview closed
its Gate too early, not that the wording needs polish.

## Quotes

A direct quote earns its place in Evidence only when the exact wording carries
something paraphrase would lose — a definition, or a phrase later discussion refers
back to. Otherwise paraphrase.

When used, place it after the Evidence prose, still under the same `###` heading, never
folded into the Evidence line itself:

```markdown
> [the quoted text]
[[Author Name]] #quote
```

`[[Author Name]]` is a bare, intentionally-unresolved wikilink — no author-note entity
exists in this family.

## Key Concepts

Add or extend `## Key Concepts` with a wikilinked, 1-line gloss for anything this claim
introduces or leans on — a term, a named person, tool, framework, place, or anything
else. The test is always the same: is the claim's weight actually resting on it, or is
it just mentioned in passing? Niklas Luhmann, in a claim about the Zettelkasten method's
origins, passes this test; a place name mentioned once in an aside does not. This step
wikilinks liberally and does not decide what the target will become — Reference note,
Person, Location, Organization, or nothing — that classification happens entirely
downstream, in `find-connections`, once cross-note evidence exists (see
[[find-terms-find-connections-merge]]).

```markdown
- [[<note-filename>|Display Name]]: [what this source says about it, in one line]
```

This section is load-bearing — `find-connections` scans it for recurrence detection, so
everything the claim actually leans on must appear here.

**Resolving `<note-filename>` correctly** — this is not just casing. Three
`.slipbox/config.json` keys apply together, never assume any of them:

- `paths.reference` — which folder the note lives in (a vault may have no dedicated
  folder at all, e.g. everything under `Notes/`).
- `filenames.reference` — the casing convention (kebab-case, Title Case, snake_case,
  per vault).
- `prefixes.reference` — a title-prefix character (e.g. `※`), if the vault uses one.
  The note's actual filename on disk includes this prefix; a link built without it
  points at a file that doesn't exist.

**Correct**, vault using `※` prefix and Title Case: `[[※ Confirmation Bias|Confirmation
Bias]]` — prefix in the link target, clean name in the display alias.

**Incorrect**: `[[confirmation-bias|Confirmation Bias]]` — hardcoded kebab-case,
no `paths.reference` folder, no prefix. Points at nothing if the vault's actual
Reference notes live at `Notes/※ Confirmation Bias.md`.

A vault with no reference folder and no prefix links flat and unprefixed, e.g.
`[[Strong Opinions, Weakly Held]]` — read all three keys, don't assume any one of them
based on what another vault does.
