# Writing a claim

See `qew-theory.md` first for what Question, Evidence, Warrant, and Conclusion each are,
and which of them ever reach the page (only Evidence and Conclusion do). This file covers
the note's structure, the Core Idea line, how to review a claim before committing it to
disk, and the formatting mechanics (quotes, Key Concepts wikilinks) that live inside a
claim entry once it's written.

## Structure

```markdown
# {{prefix}} [Exact Resource/source title]

[Core Idea — bare declarative sentence, no label]

## Key Claims

### [Conclusion, stated declaratively — this is the claim, and the heading]
[Evidence, condensed — no separate "Evidence:" label, just the prose itself]

## Open Questions

- [plain declarative question naming a gap in the source]
  - *Assumption*: [the user's own guess, marked, never a Claim]
  - *Answered*: [[§ Other Literature Note#the-claim-that-answers-it|Other Literature Note]]
```

The H1 preserves the Resource/source title exactly. Construct the filename separately with
`.slipbox/bin/slipbox filename format --type literature --title "<exact source title>"`;
do not independently case, sanitize, or prepend its prefix. `{{prefix}}` resolves from
`prefixes.literature` — see Resolving a note-type prefix
below, never hardcode a literal character.

**Core Idea** — one sentence stating the source's central argument, everything else in
the note in service of it. Positional, not labeled: it's always the line directly after
the title and before `## Key Claims`, the same way a Resource's own `description` field
sits bare under its title. Written once, when the note's first claim is written; never
touched on a second or later claim for the same note.

**The `###` heading is the Conclusion, verbatim.** No separate "Conclusion:" bullet
follows it — that would just duplicate the heading. Evidence is the only other thing
under the heading: condensed prose, no bullet marker, no hard length cap — governed by
the vault's own `.slipbox/style-profile.json` the same as any other note content.

## Resolving a note-type prefix

Building a wikilink to a note of type `<type>` (`literature`, `reference`, or any
future note type this family adds) is not just casing. Three invocations resolve
together, never assume any of them:

- `.slipbox/bin/slipbox config get paths.<type>` — which folder the note lives in (a
  vault may have no dedicated folder at all, e.g. everything under `Notes/`).
- `.slipbox/bin/slipbox config get filenames.<type>` — the casing convention
  (kebab-case, Title Case, snake_case, per vault).
- `.slipbox/bin/slipbox config get prefixes.<type>` — a title-prefix character (e.g.
  `※` for Reference notes, `§` for literature notes), if the vault uses one. The
  note's actual filename on disk includes this prefix; a link built without it points
  at a file that doesn't exist. If this returns `false`, the link stays unprefixed
  instead.

Prefix in the link target, clean name in the display alias.

**Correct**, vault using `※` prefix and Title Case for Reference notes: `[[※
Confirmation Bias|Confirmation Bias]]`.

**Incorrect**: `[[confirmation-bias|Confirmation Bias]]` — hardcoded kebab-case, no
`paths.reference` folder, no prefix. Points at nothing if the vault's actual Reference
notes live at `Notes/※ Confirmation Bias.md`.

A vault with no reference folder and no prefix links flat and unprefixed, e.g. `[[Strong
Opinions, Weakly Held]]` — read all three keys, don't assume any one of them based on
what another vault does. (This can look identical to the Person/Location/Organization
format below for a vault with no reference prefix — the distinction is still meaningful
once the vault does configure one.)

This same resolution governs the note's own title prefix (`{{prefix}}` in Structure
above, from `prefixes.literature`) and any cross-note link this file builds — an
`*Answered*` Open Questions bullet pointing at another literature note, or a Key
Concepts wikilink pointing at a Reference-note candidate.

## Open Questions

A top-level section, sibling to `## Key Claims` and `## Key Concepts`/`## Mentioned` —
never nested inside a claim. One bullet per question, plain declarative form, naming
something the source itself leaves unclear, ambiguous, or unanswered:

```markdown
## Open Questions

- [plain declarative question naming a gap in the source]
  - *Assumption*: [the user's own guess, marked, never a Claim]
  - *Answered*: [[§ Other Literature Note#the-claim-that-answers-it|Other Literature Note]]
```

See `SKILL.md`'s "Ground the source" section for the policy this format serves — when
an `## Open Questions` entry gets recorded, and the `*Assumption*`/`*Answered*` bullet
mechanics (user-flagged only, the purity-rule exception, no auto-detection). What's
specific to this file: the template above, and that an `*Answered*` wikilink resolves a
note-type prefix the same way any other cross-note link does — see Resolving a
note-type prefix above, treating `literature` as the `<type>`.

This section also carries the append-only exemption from the literature note's
otherwise frozen-once-written rule — see `SKILL.md`'s "Checking the shape" section for
the full list of exemptions.

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
- Warrant self-check (per `qew-theory.md`): can the "why" be stated in one sentence from
  the Evidence? If Conclusion and that one sentence would say the same thing, the
  Conclusion is still restating, not concluding — go back and sharpen it.
- Does it stay in the source's own terms, or has a metaphor/framing crept in that the
  source itself never used? A Conclusion that compresses cleanly into the agent's own
  imagery rather than the source's is drift, not synthesis. Example: a source describing
  a process as "layers building on each other" and the Conclusion rendering it as "a
  ratchet that only turns one way" — the ratchet is the agent's image, not the source's.
- Fidelity Signals check (per `source-architecture.md`'s Fidelity Signals group): does
  the Conclusion upgrade the source's own hedged or comparative language into something
  stronger than stated? Example: the source calls a window "most sensitive" to a signal
  — a comparative claim about degree — and the Conclusion states it as "most effective,"
  a claim about outcome the source never made. Same failure shape as epistemic-stance
  drift (firming up a hedge), but distinct from the metaphor-drift check above: this one
  is about smuggling in a stronger *claim*, not a foreign *image*.

**Evidence**
- Does it report what the source said or showed — not already a step toward what it
  means?
- If quoted: does the exact wording earn its place (a definition, a phrase later
  discussion refers back to) — or would paraphrase lose nothing?
- Traceable to the source, nothing added that isn't there?

**The claim as a whole**
- Citability test (`GLOSSARY.md`'s atomicity rule): if another note cited this Key
  Claim, is there exactly one clear thing being cited — not a bundle of several source
  points under one heading? (The shared-Warrant merge test in `qew-theory.md` should
  already have caught this at the Surface pass — this is the final check, not the first.)
- List-as-one-claim rule: when several claims on the table trace back to one
  source-authored list (a bulleted or enumerated set the source itself presented as a
  unit), default to one claim citing the list as a whole rather than one claim per item
  — the items fold into Evidence instead of each spawning its own Key Claim heading. A
  source's numbered list of five recommendations becomes one Conclusion ("the source
  recommends five practices for X") with the five items condensed into the Evidence
  line beneath it, not five separate Key Claims.
- Everything this claim leans on present in Key Concepts, each with a correctly
  resolved wikilink (see Key Concepts wikilinks below)?

If any item fails, the claim isn't done — go back to `/grounding` and probe further
(whichever technique its answer-quality dispatch picks, per `/grounding`'s SKILL.md)
rather than rewording at write time. A failed delete-test in particular means the
interview closed its Gate too early, not that the wording needs polish.

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

## Key Concepts and Mentioned

Add or extend `## Key Concepts` (abstract concept/term/framework/method candidates) or
`## Mentioned` (concrete named referents: person, place, organization, book or
creative work, named tool, or event) with a
wikilinked, 1-line gloss for anything this claim introduces or leans on. The test is
always the same, for either section: is the claim's weight actually resting on it, or
is it just mentioned in passing? Niklas Luhmann, in a claim about the Zettelkasten
method's origins, passes this test and lands in `## Mentioned`; a place name mentioned
once in an aside does not. Neither section decides what the target will become —
the eventual note type — that classification happens entirely downstream, in
`find-connections`, once cross-note evidence exists (see [[find-terms-find-connections-merge]]).
The downstream map is fixed: the entity-check tests people, places, and organizations
first and keeps those surfacing-only; the reusability test then handles abstract
Key-Concept candidates and non-entity named works, tools, and events as possible
Reference notes.

```markdown
- [[<note-filename>|Display Name]]: [what this source says about it, in one line]
```

For a `## Mentioned` entry specifically, front-load the source's attribution rather than
burying it mid-sentence: "Tseng identifies X as the person who popularized Y," not "the
person Tseng identifies as having popularized Y" — the source's own claim should read as
the subject of the sentence, not a clause nested inside a description of the entity.

Both sections are load-bearing and incremental — update the applicable section
for every confirmed claim before continuing. A mandatory final batch pass runs
after claims, density, and Core Idea stabilize; it catches load-bearing entries
that were not surfaced during individual writes. `find-connections` scans `## Key Concepts` **and**
`## Mentioned` for recurrence detection, so everything the claim actually leans on must
appear in one or the other.

**Which section is a link-*format* decision, not a note-*type* decision.** The
candidate's eventual type is decided downstream, in `find-connections` — never here.
At write time, put every concrete named referent (person, place, organization, book or
creative work, named tool, or event) in `## Mentioned`, flat and unprefixed. Put every
abstract concept, term, method, or framework in `## Key Concepts` using the
Reference-note format below. Downstream, the entity-check keeps people, places, and
organizations surfacing-only; the reusability test decides whether a non-entity
candidate becomes a Reference note. Get this guess wrong and the link still just sits
broken like any other unresolved candidate — nothing is lost, and the "spot terms and
entities" batch confirmation is exactly where the user can catch and correct a misread
before it's written.

**Mentioned format** — flat, unprefixed, no config lookup needed:
`[[Niklas Luhmann]]`, `[[Wano]]`, `[[Ship30]]` (as a brand/organization — see
`GLOSSARY.md`'s Admission test entry for when the same string reads as a method
instead), `[[The Lord of the Rings]]`, `[[Obsidian]]`, or `[[Oktoberfest]]`.

**Reference-note format** — resolving `<note-filename>` correctly here is not just
casing; see Resolving a note-type prefix above, treating `reference` as the `<type>`.
