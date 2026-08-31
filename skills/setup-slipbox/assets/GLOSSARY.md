# Slipbox Glossary

Every jargon term used across the slipbox skill family, flat and alphabetical. Each entry states what the term IS, not how to use it.

**Admission sequence**
The ordered Reference-note lookup gate: entity exclusion; stable lookup identity; source independence; boundedness; adaptive evidence sufficiency; and natural-unit scope. A one-source authoritative standard may pass, while a source-specific term without independent support remains unresolved. No title-shape check is invoked.
_Avoid_: Origin test (the retired, superseded predecessor that gated on who coined the concept first; see its own entry, not this one).

**Assumption** (the Open Question kind)
A marked, nested bullet under an Open Question holding the user's own guess at an answer — the one narrow, explicit exception to the literature note's purity rule (no personal stance, no reaction field of any kind, otherwise unconditional). Scoped to this one bullet type, under this one section, never elsewhere in the note; never a Claim.
_Avoid_: `{"deferred": true}` (an unrelated, JSON-schema-level marker on a Field map entry recording that a field mapping hasn't been resolved yet — a config-resolution state, not a note-body content type; no collision despite the surface similarity).

**Atomicity**
The rule that a note expresses exactly one independently citable thing: for an evergreen note, the whole note; for a literature note, each Source Point individually, since one source clip can support several.
_Avoid_: One-topic rule (a coarser reading; atomicity is about one citable claim, not one broad subject).

**Backlog**
The persistent, CLI-tracked queue of pending evergreen candidates, read and written through `slipbox evergreen add/find/update`.
_Avoid_: Candidate (one item held in a Backlog, not the queue itself, see its own entry); Private backlog (a different, session-scoped, never-persisted list, see its own entry).

**Candidate**
One item held in a Backlog: a flagged tension, a sparked idea, or any other draft-stage entry waiting to become a Take.
_Avoid_: Backlog (the queue that holds Candidates, not a Candidate itself).

**Challenge**
The grounding technique that executes Compass's EAST direction: state the strongest form of an opposing case, then genuinely try to break the claim being synthesized, rather than listing minor downsides.
_Avoid_: Elenchus (also adversarial, but cross-examines a stated claim's own internal logic, not a competing position).

**Collector's Fallacy**
Mistaking restatement of a source for actual comprehension of it: paraphrasing what a source said without ever stating what that means, which leaves nothing for a Conclusion to add.
_Avoid_: Evidence (reporting what a source said is Evidence's legitimate job; the fallacy is stopping there and calling it a Conclusion).

**Compass**
The Idea Compass: a synthesis-orienting technique that places one idea at the center and asks what it comes from (NORTH), resembles (WEST, via Connect), leads to (SOUTH), and competes with (EAST, via Challenge). It decides what to ask about next, not how to respond to an answer.
_Avoid_: Grounding's answer-quality dispatch (decides how to respond to whatever comes back; a different layer than Compass, which decides what to ask about).

**Conclusion**
In Question/Evidence/Warrant reasoning, what the Evidence means, stated as the source's position. The one part of that internal trio that reaches the page, as a claim's declarative heading.
_Avoid_: Claim (the written, on-disk form of a Conclusion once it's confirmed and formatted, same content, different name for its internal-reasoning stage versus its written stage).

**Connect**
The grounding technique that executes Compass's WEST direction: surface a structural, not merely thematic, similarity between the idea in play and another note already in the session.
_Avoid_: Distil (combines Connect's and Challenge's findings into something new; Connect only surfaces one similarity on its own).

**Content type**
The four kinds of source clip-resource fetches and classifies: Article, News, Social/Forum thread, and Video, recorded directly as the `type` frontmatter field on a Resource.
_Avoid_: Resource type (no such field exists; the content type value fills `type` directly, and "resource" itself never appears as a value).

**Core Idea**
What the source chiefly communicates through argument, explanation, reporting, or a mixture, stated as one declarative sentence. Every Source Point in a literature note serves it.
_Avoid_: Source Point (one selected proposition serving the Core Idea); Core Thesis (ground-me's closing-card label for a confirmed take from a freeform interview).

**Reading context**
The user's inquiry and the source passage or surrounding material that determine why a proposition is selected and how its scope is understood.

**Reader-owned proposition**
The user's interpretation, evaluation, synthesis, or personal stance. It does not belong in a Literature note and routes to an Evergreen note when appropriate.

**Discovery walk**
The grounding technique for a blank answer with a source present, chosen by the user over trying to explain first: reveal one passage at a time, asking a prediction question before each next passage rather than after.
_Avoid_: Maieutic (drawing out a position with no source at all; Discovery walk is a composite that borrows Maieutic's drawing-out stance, but only when a source exists to walk through).

**Distil**
The grounding technique that runs only after Compass's Connect and Challenge have both produced something in the same session, combining the two findings into a new claim neither alone stated.
_Avoid_: Compass (the orienting layer that decides to reach WEST and EAST in the first place; Distil is a later, optional step that fires only once both already have).

**Elenchus**
The grounding technique reached only from inside Verification, on a genuine mismatch: cross-examine a stated position's own logic through six question moves (clarification, probing assumptions, probing reasons, alternatives, implications, questioning the question).
_Avoid_: Verification (checks a statement against the source text; Elenchus checks whether the statement, once granted, survives its own logical consequences, reached only after Verification finds a mismatch).

**Entity-check**
The first classification step run on a candidate crossing the recurrence threshold in find-connections: is this a person, place, or organization, checked via a vault-wide filename lookup before the remaining Admission sequence runs.
_Avoid_: admission gates (these run only if the entity-check comes back negative).

**Evergreen note**
The file a confirmed Take gets written into: idea-oriented, not bound to one source or term, synthesized from multiple existing notes plus personal experience. Unlike a literature or Reference note, can be revisited and fully rewritten across separate sessions.
_Avoid_: Literature note (source-bound, one-shot per claim, never rewritten); Reference note (concept-bound lookup artifact with transactional recomposition when its definition boundary changes).

**Evidence**
In Question/Evidence/Warrant reasoning, what the source said or showed, reported rather than interpreted. The raw material a Conclusion is built from, and the one part of that trio (besides Conclusion) written to disk, in condensed form.
_Avoid_: Conclusion (what the Evidence means, not what was said; collapsing the two into one is the Collector's Fallacy).

**Feynman**
The grounding technique for a hesitant, hedging answer: play the role of someone who's never heard the concept, name exactly where the user's plain-language explanation breaks down, then send the user back to the specific source passage that fills that gap.
_Avoid_: Self-explanation (for a confused, self-contradictory answer rather than a merely shaky one; Feynman needs a simplifiable idea to loop against, while a confused answer has no settled idea yet to simplify).

**Fidelity direction**
The parameter a caller supplies to a grounding session before it starts: whether to hold the user to the material present (the default) or to hold the agent itself to it instead.
_Avoid_: Gate (the confirmation mechanism a statement must pass regardless of which direction Fidelity points; Fidelity decides who's held to the material, Gate decides when a statement is fixed).

**Field map**
The `frontmatter.<type>` entry in `config.json` recording how one note-type field resolves to an actual vault property: its name, type, wikilink flag, and zone, or `{"deferred": true}` if not yet resolved.
_Avoid_: Zone (only one part of a field map entry, the placement of a newly created field, not the whole mapping).

**Gate**
The confirmation mechanism that fixes a grounding session's statement: requires at least one open probe-and-answer round before any draft is shown, and an explicit, unambiguous confirmation afterward. Never a pause, a topic change, or the conversation merely feeling settled.
_Avoid_: Purity check (an evergreen-specific test run before writing, on top of a Gate pass already having happened, not a substitute for it).

**Grounding**
The one-question-at-a-time interview that holds a statement to whatever material is present until it's explicitly confirmed through a Gate. The shared engine every note-writing skill in this family runs internally, and is also directly invocable on its own.
_Avoid_: Ground-me (a bare passthrough wrapper around a grounding session, not Grounding itself).

**Source Point**
An independently interpretable, source-owned proposition selected because it answers the user's inquiry, supports the Core Idea, prevents material distortion, or preserves a distinct source idea worth retaining. It keeps local posture, attribution, evidential status, scope, and qualifications.
_Avoid_: Key Claim (the retired literature-output label); Take (a reader-owned proposition synthesized for an Evergreen note).

**Source posture**
The source's mode and degree of commitment — argument, explanation, reporting, uncertainty, attribution, comparison, or qualification — preserved in a Source Point rather than silently strengthened.

**Source-owned proposition**
A proposition attributable to the source and restated without material distortion; it may be selected as a Source Point.

**Key Concepts**
The literature-note section wikilinking anything a Source Point's weight actually rests on that reads as an abstract concept, term, framework, or method — concrete named referents go to Mentioned instead. Accumulates during Source Point writes and receives a mandatory final batch pass; scanned by find-connections for recurrence detection.
_Avoid_: Reference note (what a Key Concepts wikilink target may eventually become, decided downstream in find-connections, never at the point Key Concepts is written); Mentioned (the sibling section for concrete named referents).

**Mentioned**
The literature-note section wikilinking concrete named referents a Source Point's weight actually rests on: people, places, organizations, books/creative works, named tools, and events (real or fictional). Uses flat, unprefixed links with no config lookup, accumulates during Source Point writes, and receives a mandatory final batch pass. Scanned by find-connections alongside Key Concepts; downstream classification checks people, places, and organizations as surfacing-only entities first, then applies the remaining Admission sequence to non-entities.
_Avoid_: Key Concepts (the sibling section for abstract concept/term/framework/method candidates, using the Reference-note prefixed format instead).

**Ladder**
The generic ordered-fallback-check pattern: try one method, and only on its failure move to the next, stopping at the first rung that yields a result.
_Avoid_: Extraction ladder (the same pattern, scoped to one specific sequence; say Ladder for the general pattern).

**Literature note**
The file a source's confirmed Source Points get written into: source-oriented, anchored to exactly one source clip, holding as many Source Points as that source supports. It preserves the source's reading context and posture, and is written incrementally with only the existing fidelity, Open Questions, and density-merge exemptions.
_Avoid_: Reference note (concept-anchored, accumulates across many sources instead of one); Evergreen note (idea-oriented, freely revisited and rewritten).

**Maieutic**
The grounding technique for a blank answer with no source at all: draw out a forming position through open questions aimed at memory or experience, then test whether what came out actually holds together.
_Avoid_: Discovery walk (the composite technique for a blank answer *with* a source present, which borrows Maieutic's drawing-out stance as one of three ingredients rather than running it alone).

**Open Question**
A user-flagged bullet in a literature note's `## Open Questions` section naming something the source itself leaves unclear, ambiguous, or unanswered. Never invented by the agent unprompted — captured only when the user notices the gap. May carry a nested *Assumption* bullet and, once a resolving claim exists elsewhere, a nested *Answered* bullet (a wikilink to that claim's heading, user-requested only, never auto-detected — no cross-note scanning).
_Avoid_: Tension (the agent's own prior-knowledge conflict noticed against the material, routed to the evergreen Backlog — a different thing than a gap the source itself leaves unanswered).

**Origin test**
Historical only: the retired admission check that gated a Reference-note candidate on who argued or coined it first. It was replaced because it wrongly excluded a source's own newly introduced, genuinely reusable framework.
_Avoid_: Origin test in current routing; use the Admission sequence.

**Mentioned referents**
The surfacing-only literature-note section for concrete named people, places, organizations, books/creative works, named tools, and events, real or fictional alike. `find-connections --references` scans it alongside `Key Concepts`; downstream classification runs entity exclusion first for people, places, and organizations, then the remaining Admission sequence for non-entity candidates. The first group remains surfacing-only; a reusable non-entity may become a Reference note.
_Avoid_: Key Concepts (abstract concepts, methods, and frameworks); Reference note (the downstream note type, never decided while the link is written).

**Prefix**
The optional per-note-type symbol (e.g. `§` for literature) prepended to a note's title and its filename, configured in `config.json`'s `prefixes` map. Resources are never prefixed.
_Avoid_: Field map (a different config concern: how a field maps to a property, not how a title is decorated).

**Principle of charity**
The instruction to reconstruct an emerging or opposing position in its strongest, most coherent form before responding to it, rather than the weakest or most convenient reading.
_Avoid_: Steelmanning (the practitioner move Challenge uses to apply this same principle against an opposing case specifically, before attempting to break it).

**Private backlog**
The ephemeral, session-scoped candidate list make-literature-note builds during its own Surface pass. Never shown to the user, never persisted past the session, named for that distinguishing property.
_Avoid_: Backlog (the persistent, CLI-tracked queue, the opposite of never-persisted); Candidate backlog (an earlier, rejected name for this same list; say Private backlog).

**Purity check**
The test make-evergreen-note runs on every sentence of a drafted Take before writing: is it attributable to a single cited note's claim, unchanged. A failing sentence means the conversation isn't finished, not that the wording needs polish.
_Avoid_: Gate (grounding's own confirmation mechanism, already passed by the time the Purity check runs; an additional, evergreen-specific test layered on top).

**Question**
In Question/Evidence/Warrant reasoning, the specific question one candidate passage actually answers, never a topic label. Used during the Surface pass to decide whether a passage is one claim, part of a bigger one, or not claim-worthy.
_Avoid_: Core Idea (what the whole source is *for*; a Question is scoped to one candidate passage, not the source's central argument).

**Reading state**
How a grounding session classifies what came back from its opening restatement question: Confident, Hesitant, Blank, or Confused, each routing to a different technique.
_Avoid_: Gate (the confirmation step reached once a statement is drafted; a reading state is read at the start of a turn, before any draft exists).

**Reference**
A named concept, method, tool, framework, or stable fact with a reusable label, independent of any one source. What a Reference note's content is about.
_Avoid_: Reference note (the file the Reference's definition accumulates into, not the concept itself).

**Reference note**
The file a Reference's bounded, reusable definition lives in. When a new source only
adds warrant, publication preserves the existing body and appends deduplicated Resource
provenance. When new evidence changes the definition boundary, the body may be
transactionally recomposed through compare-and-swap publication; this is not an
provenance-only append policy.
_Avoid_: Literature note (per-source, one-shot, holds Source Points rather than a definition); Evergreen note (idea-oriented and notes-bound rather than lookup-oriented).

**Resource**
The frozen clip clip-resource writes: `type` frontmatter holds the content type directly, and once written, no skill in this family reopens it to edit, append, or correct it. A needed fix means writing a fresh clip, never patching the old one.
_Avoid_: Literature note (what a Resource gets read into and grounded from, a separate file that isn't frozen the same way).

**Self-explanation**
The grounding technique for a confused, self-contradictory answer: name the specific discrepancy noticed in what was just said and let the user notice and repair it, rather than correcting it directly.
_Avoid_: Feynman (for a hesitant but internally consistent answer, not a self-contradictory one).

**Session**
One continuous grounding conversation, opened with a single stating line and closed once its Gate passes. The canonical unit of a grounding interview.
_Avoid_: Sitting (an earlier, inconsistently used synonym for the same thing; say Session).

**Sparked idea**
A connection noticed between two or more existing notes that produces something neither states alone. Generative, not mechanical, and routed to the evergreen Backlog rather than written directly.
_Avoid_: Link (a mechanical connection between two already-related notes, found and written directly by find-connections' `--evergreen` mode; a sparked idea needs full grounding before it becomes a Take).

**Steelmanning**
Stating the strongest possible version of an opposing case before attempting to break it, rather than a weak caricature. The practitioner form Challenge uses to keep Compass's EAST direction a genuine test.
_Avoid_: Principle of charity (the general instruction Steelmanning applies specifically to an opposing, competing case).

**Surface pass**
The private, ungrounded first read-through of a Resource that make-literature-note runs on its own, before any claim is grounded with the user: identifies every distinct claim the source supports and builds the Private backlog from them.
_Avoid_: Private backlog (the list this pass produces, not the pass itself); Grounding (the user-facing interview that follows, checking a statement against material — the Surface pass never involves the user).

**Take**
The user's own confirmed, synthesized position on an idea, requiring cross-source or cross-experience synthesis a single source can't provide. Lives only in an evergreen note; the lowercase "take" used mid-conversation before confirmation is the same concept, not a separate term.
_Avoid_: Claim (the source's position, lives only in a literature note; a Take and a Claim never coexist in the same note).

**Tension**
Something noticed in real conflict with the material during a grounding session: the agent's own prior knowledge, or anything else that doesn't belong in the statement itself. Surfaced at most once, after the Gate passes, and only if actually noticed.
_Avoid_: Sparked idea (a generative connection between existing notes, not a conflict noticed against material in play).

**Tombstone**
An append-only link-ledger removal event. It deactivates a previously recorded
edge without rewriting history; a later add can restore that edge, and
transaction compensation uses the same mechanism.
_Avoid_: Delete (rewriting or removing ledger history; link removal is recorded,
not erased).

**Verification**
The grounding technique for a confident answer: treat the restatement as a hypothesis about the source's meaning and check it against the actual source text, escalating to Elenchus only on a genuine mismatch.
_Avoid_: Elenchus (checks a claim's own internal logic once granted; Verification checks the claim against the source text itself).

**Work ID**
The sortable 26-character identifier assigned to one recoverable runtime
operation. It names the manifest under `.slipbox/work/` and is the identity used
by checkpoint, resume, finalize, discard, and optional Git commit actions.
_Avoid_: Slug (a note or evergreen-candidate filename identity, not a runtime
operation identity).

**Source-map cache**
Analysis state for a frozen Resource, keyed by that Resource's SHA-256 rather
than its path. It carries compatibility and provenance metadata and persists as
`local` or `tracked` independently of local recoverable work.
_Avoid_: Note (a cache entry is analysis metadata, never published note content).

**Warrant**
In Question/Evidence/Warrant reasoning, the source's own stated or implied reason why its Evidence supports its Conclusion. A report on the source's inferential move, never the note-writer's own judgment of whether that move holds.
_Avoid_: Conclusion (what the source claims as a result; Warrant answers why the source thinks its Evidence proves that Conclusion).

**Write-checks**
The shared pre-write session every note-writing skill runs before saving a draft: checks style and humanize signals, and, given a field list, resolves frontmatter field mappings, zone placement, and title prefix.
_Avoid_: Grounding (checks the content of a statement against material; Write-checks runs afterward, checking style, frontmatter, and mechanical fields, never content).

**Zone**
Where a newly created frontmatter field is placed in a note: `top`, right after the opening `---`, or `bottom`, right before the closing `---`. Never applies to a field mapped onto an already-existing property.
_Avoid_: Field map (the broader entry Zone is one attribute of, alongside a field's name, type, and wikilink flag).

**ZPD/scaffolding**
Vygotsky's zone of proximal development: the principle that support should track how someone is actually doing turn to turn, more after a miss, less after several correct answers in a row. Supplies Discovery walk's pacing.
_Avoid_: Discovery walk (the composite technique ZPD/scaffolding contributes pacing to, not the whole technique itself).
