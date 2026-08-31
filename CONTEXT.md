# Slipbox — Domain Language

## Language

One frozen source-type plus five knowledge-management note types (Literature, Reference,
Evergreen — the family's actual subject) plus concrete named referents surfaced in
`Mentioned` (Person, Location, Organization, books/creative works, named tools, and
events) — never
conflate them:

**Resource** (`clip-resource`'s output):
Frozen clip, not a note. `type` frontmatter field holds the content-type directly (`article`/`news`/`social`/`video`) — no generic `"resource"` value; being a Resource is implied by folder location, not stated in frontmatter.

**Literature note** (bibliographic note, `make-literature-note`'s output — internally discussed via `grounding`, source-bound fidelity):
Source-oriented. Answers what the source chiefly communicates, whether through argument, explanation, reporting, or a mixture. Anchored to exactly one source and one clip; carries a Core Idea plus as many Source Points as that source supports. Each Source Point is independently interpretable and citable, preserving its local posture, attribution, evidential status, scope, and qualifications. Question/Evidence/Warrant is the agent's internal reasoning — never written to the note; only the Source Point and condensed Evidence land on disk. Source Points are written incrementally as each is confirmed and are not revisited afterward except the existing fidelity correction, Open Questions append, and session-close density-merge exemptions. The note contains no reader-owned stance, reaction, or synthesis.

**Open Questions** (a real, top-level section, sibling to `## Source Points` and `## Key Concepts`/`## Mentioned`): one bullet per question the source leaves unclear, ambiguous, or unanswered, plain declarative form, naming the gap — never nested inside a Source Point. User-flagged only: the agent never invents an open question unprompted, it's captured when the user notices the gap during grounding. A question may carry a nested `*Assumption*` bullet (the user's own guess, marked) and, once a different literature note grounds a Source Point that resolves it, a nested `*Answered*` bullet — a wikilink to that Source Point's heading, added only on explicit user request, never detected or added automatically. An `*Assumption*` bullet stays in place once an `*Answered*` bullet is added alongside it.

**Reference note** (`make-reference-note`'s output — renamed from Term note, and its scope
broadened; see [[reference-note-admission-contract]]):
Atomic, evergreen-shaped, but holds a stable fact or an established/reusable framework
rather than personal synthesis. Answers "what is X?" Not a one-shot write: accumulates
across however many resources touch that concept, extended on repeat runs rather than
finalized once — but only ever appends/extends, never overwrites what's already there
wholesale. Anchored to a concept, not to any single source — it may draw on several. Not
a personal idea (that's evergreen's job) and not primarily a citation record (the source
anchors the definition, it isn't the point of the note). Absorbs what earlier drafts of
this glossary considered splitting into separate "Tool," "Event," and "Mentioned" types,
plus named creative works (podcasts, shows, an author's own newsletter name) — none of
these get their own type; they fold into Reference note the same way Matuschak's own
"Proper Noun Note" spans person and business entities without distinction.

**Admission test: reusability, not origin.** A candidate concept qualifies for a
Reference note if it's self-contained enough to survive independent of the source(s)
that mention it — regardless of who coined it or how recently (a source's own
newly-introduced framework qualifies the same session it's introduced, provided it
passes the test below). Two checks, run together:

- **Deletion test** (Ahrens) — does the note survive if the source disappears?
- **Declarative-title test** (Matuschak) — can it compress into a subject+verb claim, no
  "According to X..."?

The same string can resolve to different types depending on how a given claim actually
uses it: "Ship30" as a writing method someone teaches passes the reusability test and
becomes a Reference note; "Ship30" as the brand/organization running that method is
surfacing-only, per the entity-check above. Which one applies is decided by the claim's
own usage, not by the string alone.

**Classification order: entity-check runs before the reusability test.** A candidate
wikilink is first checked for a concrete entity — person, place, or organization,
real or fictional. Only if that check is negative does it get evaluated against the
deletion/declarative-title test; that second pass covers reusable concepts and named
books/creative works, tools, or events. A person's name can technically pass the
deletion test too (e.g. a name survives independent of any one source), but that's a
coincidental technicality, not what the test is meant to check — "what kind of thing is
this" is prior to "is this a reusable concept."

**Scoping within a framework**: one Reference note per named framework, at the
framework's own level — not one note per internal sub-component. A framework with
functionally dependent internal steps (e.g. a four-question review method) gets a single
Reference note; its steps live as sections inside that one note, not as separately
wikilinked, separately-promoted targets.

**Mentioned referents** (surfacing only — no dedicated write skill):
Concrete named people, places, organizations, books/creative works, named tools, and
events, real or fictional alike. Abstract concepts, methods, and frameworks belong in
`Key Concepts`. `find-connections` detects, flags, and wikilinks these candidates exactly
like Reference candidates (same recurrence threshold, batch presentation, and
dedup/alias pass), but this family owns no write procedure for them. Many users already
have their own templates or tooling for these from elsewhere; the agent can still help
write one on request, as ad-hoc assistance, never as a mandated skill-procedure — there's
no author stance to hold to a citation-discipline interview for a stable fact like a
name or a place. A source's own author is the one standing exception: per
`make-literature-note`'s existing convention, an author gets a deliberately bare, unresolved
wikilink, never a Person note through this pipeline.

**Evergreen note** (Zettel / permanent note, `make-evergreen-note`'s output — internally discussed via `grounding`, notes-bound fidelity):
Idea-oriented. Answers "what do I think, as my own contribution?" Not bound to any one source or term. Holds exactly one atomic claim (the Take), synthesized from multiple existing notes (literature and/or evergreen) plus personal experience. Cites the notes that fed it; does not bundle or contain them, and never merely restates one of them un-transformed. **Can be revisited and evolve across separate sessions** (corrected 2026-07-23 — see Flagged ambiguities) — and unlike a Reference note's append-only accumulation, an evergreen note's update can be a full rewrite of its existing content, not just an addition alongside the old.

**Source Point**:
An independently interpretable, source-owned proposition selected because it answers the user's inquiry, supports the Core Idea, prevents material distortion, or preserves a distinct source idea worth retaining. It keeps local posture, attribution, evidential status, scope, and qualifications.

**Core Idea**:
What the source chiefly communicates through argument, explanation, reporting, or a mixture, stated as one declarative sentence. Every Source Point in the literature note serves it; it is written once, on the first Source Point.

**Reading context**:
The user's inquiry and the source passage or surrounding material that determine why a proposition is selected and how its scope is understood.

**Source posture**:
The source's mode and degree of commitment — argument, explanation, reporting, uncertainty, attribution, comparison, or qualification — preserved in a Source Point rather than silently strengthened.

**Source-owned proposition**:
A proposition attributable to the source and restated without material distortion; it may be selected as a Source Point.

**Reader-owned proposition**:
The user's interpretation, evaluation, synthesis, or personal stance. It does not belong in a Literature note and routes to an Evergreen note when appropriate.

**Take**:
The user's own position on an idea. Requires synthesis across sources/experience. Lives only in an evergreen note — never in a literature note, and not as a separate field alongside Claim.

**Open Question**:
A user-flagged bullet in a literature note's `## Open Questions` section naming something the source itself leaves unclear, ambiguous, or unanswered. Never invented by the agent unprompted. May carry a nested `*Assumption*` bullet (the user's own guess, marked) and, once a resolving claim exists elsewhere, a nested `*Answered*` bullet (a wikilink to that claim's heading, user-requested only, never auto-detected).

**Assumption** (the Open-Questions kind):
The user's own guess at an answer to an Open Question, written as a marked, nested bullet under it — the one narrow exception to the literature note's purity rule. Never a Claim, never elsewhere in the note.

**Atomicity**:
For evergreen notes, atomicity applies to the whole note — an evergreen note is atomic if it expresses exactly one independently referenceable claim. For literature notes, each Source Point is independently citable; a single-source note may hold several Source Points. Test either way: if another note wanted to cite this one, is there exactly one clear thing it would be citing (the whole evergreen note, or one specific Source Point)?

## Relationships

## Runtime contract

Migrated stateful workflows use `/using-slipbox` as the shared transaction
boundary. The specialist supplies the semantic artifact decision; the runtime assigns a
`work_id`, keeps transient work local under `.slipbox/work/`, checkpoints and
recovers by comparing fingerprints, and invokes `/write-checks` before
publication. The installed `.slipbox/bin/slipbox` owns schema validation, path
safety, atomic compare-and-swap publication, append-only link tombstones, source
map cache operations, and optional Git finalization. CLI syntax and failure
shapes are authoritative in the installed CLI's `--help` output and the runtime
CLI reference.

Work kinds are `resource`, `literature`, `reference`, `evergreen`, and
`migration`. Source-map cache identity is the Resource SHA-256, and cache
persistence (`local` or `tracked`) is independent of local work persistence.
Failed work is preserved for repair; a runtime failure never becomes a reported
success. Specialist workflow migration is a separate concern from this shared
runtime contract.

- A literature note is anchored to exactly one source and holds one or more Source Points, each independently citable.
- A Reference note is anchored to a concept, accumulates across multiple sources over separate runs, and holds a definition, not a stance.
- An evergreen note cites zero or more literature/Reference/evergreen notes as support; it does not contain them, and holds the Take.
- A Source Point lives in a literature note; a Take lives in an evergreen note. They never coexist in the same note.
- `make-literature-note` and `make-evergreen-note` both internally invoke the same skill, **`grounding`** (bare, fidelity-agnostic name, matching how `grill-with-docs` invokes `grilling`) — each states its own fidelity-direction inline (source-bound or notes-bound), rather than each having its own separate discussion skill. `grounding` is also user-invocable directly, unlike the old internal-only `discussion` skill it replaces.
- `make-reference-note` (renamed from `ground-term`, then from `write-reference`; see [[find-terms-find-connections-merge]]) produces/extends Reference notes, triggered by the user naming a concept directly, or by `find-connections --references` (absorbed `find-terms`; see below) reporting one that recurs across notes but has no Reference note yet — a derived, on-demand report, not a stored queue. Its own job is synthesis, not citation-discipline: by the time a candidate crosses the recurrence threshold, the `/grounding` interview already happened at the claim level, inside whichever literature notes' `## Key Concepts` wikilink to it, via `make-literature-note`'s own session. `make-reference-note` pulls those already-grounded characterizations out, reconciles them into one definition, presents for confirmation, writes — it never runs `/grounding` itself. Extending an *existing* Reference note with a source that hasn't been grounded yet routes through `make-literature-note` first, always — grounding stays at the claim level with no special case for this skill.
- `find-terms` and `find-connections` are merged into one skill, `find-connections`, taking an explicit mode flag: `--references` (the absorbed `find-terms` behavior — Reference and Mentioned-referent recurrence, dedup, batch-presented, never auto-written) or `--evergreen` (the original `find-connections` behavior — mechanical links and sparked ideas, which do write directly). No flag given stops and asks which mode. `--references` scans literature notes' `Key Concepts` and `Mentioned` sections, plus other mentions of the same or similar things elsewhere in notes' bodies, running semantic clustering *before* threshold-counting (recurrence is counted per cluster of variant labels referring to the same thing, not per exact string) — otherwise two single-occurrence variant labels for one idea would never individually reach the threshold that gates the dedup pass. It classifies each recurring cluster with the entity-check first, then the reusability test for non-entity candidates; people, places, and organizations remain surfacing-only, while reusable concepts and named works/tools/events are Reference candidates.
- Each of the three note types has its own template file (Obsidian core Templates plugin or Templater, whichever the user has), discovered or offered by `setup-slipbox` per type, not a single shared template.

## Flagged ambiguities

- Resolved 2026-07-23: whether "Take" belongs in the literature note. It doesn't — a take needs cross-source synthesis a single-source note can't provide. See `discussion/note-taking-skills/bibliographic-notes-vs-zettel.md` and `literature-note-field-justification.md` for the historical grounding (Luhmann's bibliographic notes vs. Zettel).
- Resolved 2026-07-23: whether a lighter "Reaction" field could stay in the literature note as a compromise. No — it was rejected as still adjacent to evergreen's synthesis territory. Literature note holds Claim only.
- Resolved 2026-07-23: literature note and term note are not the same thing (an earlier draft of this glossary conflated them under "bibliographic note"). Literature = per-source, one-shot. Term = per-term, cumulative.
- Resolved 2026-07-23: whether an evergreen note is one-shot like a literature note, or can be revisited. It can be revisited — closer to a term note's "accumulates across runs" nature than to literature's one-shot nature. But the update mechanism differs from term notes: term only appends/extends; evergreen can fully rewrite its own prior content.
- Resolved 2026-07-23: `discuss-idea`/`discuss-connection` are no longer the primary user-facing skill names — first repurposed as two separate internal discussion skills, then **superseded again**: consolidated into one internal skill, `discussion` (three modes: `literature`, `term`, `evergreen`), invoked by `write-literature-note`/`write-evergreen-note` respectively (mirroring how `grill-with-docs` invokes `grilling`). The two-separate-skills step left a real duplication gap (shared Socratic rules had no mechanism to avoid being restated in both files); consolidation removes that gap by construction. Also resolves the earlier "connection" naming collision — moot now, since neither old name survives as a skill identity.
- Resolved 2026-07-23: term notes join `idea.db` as a third `type` (alongside `raw`/`literature`), not a separate `reference-candidates.md` queue file. Recurrence detection (an untracked term appearing across resources) happens in `surface-ideas` at extraction time, not mid-discussion — `surface-ideas` has the cross-resource view needed to notice recurrence; the `discussion` skill (scoped to one candidate/session at a time) does not.
- Resolved 2026-08-08: literature notes hold several Key Claims per source, not one atomic Claim — the earlier one-Claim-only design conflated the permanent-note atomicity rule with the literature-note stage, where it doesn't historically apply (see `discussion/slipbox/decision.md`'s "Literature note holds several claims, not one" entry for the full grounding). `surface-ideas` and the `seeds` concept it fed are retired entirely — literature/term tracking is now derived on demand from existing notes' own frontmatter and wikilinks, replaced for the whole-corpus connection/recurrence work by two independent skills, `find-terms` and `find-connections`.
- Resolved 2026-08-13: "Term" and a separately-maintained, undefined "named entity" category collapse into one type, **Reference note**, plus three types kept genuinely separate — **Person, Location, Organization** — rather than either notion surviving as its own undefined floating category. The admission test changed from origin-based ("not a source's own argued organizing scheme") to reusability-based (deletion test + declarative-title test): the origin test broke on a source's own genuinely reusable framework, introduced in the same piece it's used in, which the old rule would have wrongly excluded. See [[reference-note-admission-contract]] for the full grounding, including the still-narrower entity-profile framing (extends to fiction, not just real-world entities) and the closed unified-theory/Ship30 edge cases.
- Resolved 2026-08-13/14: `find-terms` and `find-connections` merge into one skill, `find-connections`, mode-flagged (`--references` / `--evergreen`); `find-terms` is deleted outright, not deprecated with a stub. `ground-term` renames to **`write-reference`** (not `ground-reference` — it never runs `/grounding` itself, only synthesizes already-grounded characterizations). See [[find-terms-find-connections-merge]] for the full design, including the semantic-clustering-before-threshold-counting fix and why Person/Location/Organization detection needs no `paths.*` config (a vault-wide, folder-agnostic filename lookup already tells broken from already-noted, since this family never writes these three types).
- Resolved 2026-08-17: `write-reference` renames again, to **`make-reference-note`** — aligning it with the family's other two note-writing wrappers, `make-literature-note` and `make-evergreen-note`, which already use the `make-{{type}}-note` pattern. `write-reference` was the one skill in the family that didn't follow it. No behavior change; name only.
