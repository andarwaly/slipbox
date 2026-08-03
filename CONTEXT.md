# Slipbox — Domain Language

## Language

One frozen source-type plus three note types, produced by four different skills — never conflate them:

**Resource** (`clip-resource`'s output):
Frozen clip, not a note. `type` frontmatter field holds the content-type directly (`article`/`news`/`social`/`video`) — no generic `"resource"` value; being a Resource is implied by folder location, not stated in frontmatter.

**Literature note** (bibliographic note, `ground-claim`'s output — internally discussed via `grounding`, source-bound fidelity):
Source-oriented. Answers "what did this author argue?" Contains only the Claim — the author's position restated in the user's own words. Anchored to exactly one source, one clip, one discussion, written once, never revisited afterward — except out-of-band manual fidelity corrections (fixing a misreading, a transcription error, or wording that misrepresents the source); the correction must move the note closer to the source, and the slug stays final. Contains no personal stance and no reaction/reflection field of any kind — even a lightweight spontaneous reaction edges into personal synthesis, which this note type never holds. A stance requires weighing multiple sources, which a single-source note structurally cannot do.

**Term note** (`ground-term`'s output):
Term-oriented. Answers "what is X?" Not a one-shot write: accumulates across however many resources touch that term, extended on repeat runs rather than finalized once — but only ever appends/extends, never overwrites what's already there wholesale. Anchored to a term, not to any single source — it may draw on several. Not a personal idea (that's evergreen's job) and not primarily a citation record (the source anchors the definition, it isn't the point of the note).

**Evergreen note** (Zettel / permanent note, `ground-my-take`'s output — internally discussed via `grounding`, notes-bound fidelity):
Idea-oriented. Answers "what do I think, as my own contribution?" Not bound to any one source or term. Holds exactly one atomic claim (the Take), synthesized from multiple existing notes (literature and/or evergreen) plus personal experience. Cites the notes that fed it; does not bundle or contain them, and never merely restates one of them un-transformed. **Can be revisited and evolve across separate sessions** (corrected 2026-07-23 — see Flagged ambiguities) — and unlike a term note's append-only accumulation, an evergreen note's update can be a full rewrite of its existing content, not just an addition alongside the old.

**Claim**:
The author's position on an idea, restated in the user's own words. Lives only in a literature note. Object of understanding, not agreement.

**Take**:
The user's own position on an idea. Requires synthesis across sources/experience. Lives only in an evergreen note — never in a literature note, and not as a separate field alongside Claim.

**Atomicity** (for evergreen notes):
An evergreen note is atomic if it expresses exactly one independently referenceable claim — not one topic, not one paragraph. Test: if another note wanted to cite this one, is there exactly one clear thing it would be citing?

## Relationships

- A literature note is anchored to exactly one source and holds only a Claim.
- A term note is anchored to a term, accumulates across multiple sources over separate runs, and holds a definition, not a stance.
- An evergreen note cites zero or more literature/term/evergreen notes as support; it does not contain them, and holds the Take.
- A Claim lives in a literature note; a Take lives in an evergreen note. They never coexist in the same note.
- `ground-claim` and `ground-my-take` both internally invoke the same skill, **`grounding`** (bare, fidelity-agnostic name, matching how `grill-with-docs` invokes `grilling`) — each states its own fidelity-direction inline (source-bound or notes-bound), rather than each having its own separate discussion skill. `grounding` is also user-invocable directly, unlike the old internal-only `discussion` skill it replaces.
- `ground-term` produces/extends term notes, triggered by the user naming a term directly, or by a recurring-term row `surface-ideas` surfaces into `idea.db` (`type: raw, target_type: term`). Routes its interview through `grounding` (source-bound fidelity, same as literature notes — the term note traces to whichever source(s) back it) too, same as the other two — not left inline.
- Each of the three note types has its own template file (Obsidian core Templates plugin or Templater, whichever the user has), discovered or offered by `setup-slipbox` per type, not a single shared template.

## Flagged ambiguities

- Resolved 2026-07-23: whether "Take" belongs in the literature note. It doesn't — a take needs cross-source synthesis a single-source note can't provide. See `discussion/note-taking-skills/bibliographic-notes-vs-zettel.md` and `literature-note-field-justification.md` for the historical grounding (Luhmann's bibliographic notes vs. Zettel).
- Resolved 2026-07-23: whether a lighter "Reaction" field could stay in the literature note as a compromise. No — it was rejected as still adjacent to evergreen's synthesis territory. Literature note holds Claim only.
- Resolved 2026-07-23: literature note and term note are not the same thing (an earlier draft of this glossary conflated them under "bibliographic note"). Literature = per-source, one-shot. Term = per-term, cumulative.
- Resolved 2026-07-23: whether an evergreen note is one-shot like a literature note, or can be revisited. It can be revisited — closer to a term note's "accumulates across runs" nature than to literature's one-shot nature. But the update mechanism differs from term notes: term only appends/extends; evergreen can fully rewrite its own prior content.
- Resolved 2026-07-23: `discuss-idea`/`discuss-connection` are no longer the primary user-facing skill names — first repurposed as two separate internal discussion skills, then **superseded again**: consolidated into one internal skill, `discussion` (three modes: `literature`, `term`, `evergreen`), invoked by `write-literature-note`/`write-evergreen-note` respectively (mirroring how `grill-with-docs` invokes `grilling`). The two-separate-skills step left a real duplication gap (shared Socratic rules had no mechanism to avoid being restated in both files); consolidation removes that gap by construction. Also resolves the earlier "connection" naming collision — moot now, since neither old name survives as a skill identity.
- Resolved 2026-07-23: term notes join `idea.db` as a third `type` (alongside `raw`/`literature`), not a separate `reference-candidates.md` queue file. Recurrence detection (an untracked term appearing across resources) happens in `surface-ideas` at extraction time, not mid-discussion — `surface-ideas` has the cross-resource view needed to notice recurrence; the `discussion` skill (scoped to one candidate/session at a time) does not.
