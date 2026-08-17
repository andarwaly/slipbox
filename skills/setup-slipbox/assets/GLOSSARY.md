# Slipbox Glossary

Every jargon term used across the slipbox skill family, flat and alphabetical. Each entry states what the term IS, not how to use it.

**Admission test**
The reusability check a candidate concept must pass to qualify for a Reference note: does the note survive if its source disappears (deletion test), and can it compress into a declarative, subject-plus-verb title (declarative-title test). Also called the reusability test. The same string can resolve to different types depending on how a given claim uses it — e.g. "Ship30" as a writing method passes this test and becomes a Reference note, while "Ship30" as the brand/organization running that method is surfacing-only, decided by the entity-check that runs first, not by the string alone.
_Avoid_: Origin test (the retired, superseded predecessor that gated on who coined the concept first; see its own entry, not this one).

**Atomicity**
The rule that a note expresses exactly one independently citable thing: for an evergreen note, the whole note; for a literature note, each Key Claim individually, since one source clip can support several.
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

**Claim**
The source's own position on one question it answers, restated in the user's own words and checked for fidelity, written as a declarative sentence. Lives only in a literature note, as an object of understanding rather than agreement.
_Avoid_: Take (the user's own synthesized position, lives only in an evergreen note; the two never coexist in one note); Conclusion (the internal-reasoning term for the same content before it's written to disk, see its own entry).

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
The source's central argument, one declarative sentence, every Claim in a literature note in service of it. Written once, on the note's first Claim.
_Avoid_: Claim (one thing the source argues; the Core Idea is what the source is *for*, not one of the things it argues); Core Thesis (ground-me's own closing-card label for a confirmed take from a freeform interview — a different context, not a synonym for a source's central argument).

**Declarative-title test**
Half of the Admission test: can the candidate concept compress into a subject-plus-verb claim with no "According to X..." framing.
_Avoid_: Deletion test (the Admission test's other half, checking survival independent of the source rather than title shape).

**Deletion test**
Half of the Admission test: does the candidate concept survive as meaningful if the source that mentions it disappears.
_Avoid_: Declarative-title test (the Admission test's other half, checking title shape rather than source-independence).

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
The first classification step run on a candidate crossing the recurrence threshold in find-connections: is this a person, place, or organization, checked via a vault-wide filename lookup before the Admission test ever runs.
_Avoid_: Admission test (run second, only if the entity-check comes back negative).

**Evergreen note**
The file a confirmed Take gets written into: idea-oriented, not bound to one source or term, synthesized from multiple existing notes plus personal experience. Unlike a literature or Reference note, can be revisited and fully rewritten across separate sessions.
_Avoid_: Literature note (source-bound, one-shot per claim, never rewritten); Reference note (concept-bound, only ever appended to, never rewritten wholesale).

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

**Key Claim**
One `###`-headed entry inside a literature note's `## Key Claims` section: a Conclusion as its declarative heading, condensed Evidence beneath it, independently citable from every other Key Claim in the same note.
_Avoid_: Core Idea (the note's single central argument, written once; a Key Claim is one of potentially several claims serving that Core Idea).

**Key Concepts**
The literature-note section wikilinking anything a Key Claim's weight actually rests on that reads as a concept, term, framework, or method — a person, place, or organization goes to Mentioned instead. Scanned by find-connections for recurrence detection.
_Avoid_: Reference note (what a Key Concepts wikilink target may eventually become, decided downstream in find-connections, never at the point Key Concepts is written); Mentioned (the sibling section for person/place/organization candidates).

**Mentioned**
The literature-note section wikilinking anything a Key Claim's weight actually rests on that reads as a person, place, or organization (real or fictional) — flat, unprefixed link format, no config lookup. Scanned by find-connections for recurrence detection alongside Key Concepts.
_Avoid_: Key Concepts (the sibling section for concept/term/framework/method candidates, using the Reference-note prefixed format instead).

**Ladder**
The generic ordered-fallback-check pattern: try one method, and only on its failure move to the next, stopping at the first rung that yields a result.
_Avoid_: Extraction ladder (the same pattern, scoped to one specific sequence; say Ladder for the general pattern).

**Literature note**
The file a source's confirmed Claims get written into: source-oriented, anchored to exactly one source clip, holding as many Key Claims as that source supports. Written incrementally and never revisited afterward except an out-of-band fidelity correction.
_Avoid_: Reference note (concept-anchored, accumulates across many sources instead of one); Evergreen note (idea-oriented, freely revisited and rewritten).

**Maieutic**
The grounding technique for a blank answer with no source at all: draw out a forming position through open questions aimed at memory or experience, then test whether what came out actually holds together.
_Avoid_: Discovery walk (the composite technique for a blank answer *with* a source present, which borrows Maieutic's drawing-out stance as one of three ingredients rather than running it alone).

**Origin test**
The retired, superseded admission check that gated a Reference-note candidate on who argued or coined it first, replaced because it wrongly excluded a source's own newly introduced, genuinely reusable framework.
_Avoid_: Admission test (the current, reusability-based replacement; say Admission test, not Origin test).

**Person, Location, Organization**
The three surfacing-only entity types find-connections detects and wikilinks like Reference candidates, real or fictional alike, but never writes. Entity-profile territory this family owns no write procedure for.
_Avoid_: Reference note (knowledge-synthesis territory this family does write; the entity-check runs before the Admission test specifically to keep the two separate).

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
The cumulative file a Reference's definition lives in: evergreen-shaped but holding a stable, reusable fact rather than personal synthesis, extended across however many sources touch it, appending or extending but never overwriting what's already there.
_Avoid_: Literature note (per-source, one-shot, holds Claims rather than a definition); Evergreen note (can be wholesale rewritten; a Reference note only ever appends).

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

**Verification**
The grounding technique for a confident answer: treat the restatement as a hypothesis about the source's meaning and check it against the actual source text, escalating to Elenchus only on a genuine mismatch.
_Avoid_: Elenchus (checks a claim's own internal logic once granted; Verification checks the claim against the source text itself).

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
