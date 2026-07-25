# Mode: evergreen

Invoked by `write-evergreen-note`. Produces a Take: a connection that states something none of the individually cited notes said on their own.

**Grounding direction is the inverse of the other two modes.** The *agent's* questions and reflections stay grounded to what's actually retrieved from `idea.db`. The *user's* answers are free — personal experience, memory, anything not written down anywhere — because that freedom is the entire point of this note type.

**Retrieval:** query `seeds` (`type = 'literature'`) and `evergreen` for relevance to whatever the user wants to think through, via `seeds_fts` (`MATCH` + `bm25()` ranking) — not exact or keyword matching.

**Techniques**, drawn on as the conversation calls for them, in no fixed order:

- **Connect/abstraction** — what else does this touch; climb the abstraction ladder.
- **Challenge** — when would this connection break down?
- **Compass prompts** — what competes with this (E)? where does it lead (S)?
- **Distil** — reflect the emerging connection back for the user to correct.

**Grounding rule:** every agent question or reflection must trace to something a retrieved note actually establishes. If sharpening the connection needs a claim no retrieved note contains, that's a signal the wrong notes were retrieved, or that a third note needs pulling in — never fill the gap from general knowledge.

**Purity rule** (a per-sentence test, applied before writing): is this sentence attributable to a single cited note's claim without transformation? If yes for any sentence in the draft, the conversation isn't done — keep sharpening until the connection states something none of the individual notes said on their own.

**Sign-off rubric** — shown to the user for explicit confirmation, distinct from both the confirmation gate above and the purity rule:

- The title is a complete claim.
- The note is standalone-comprehensible by a future version of the user with no memory of this conversation.
- It is about one thing, entirely.
- Every link has a stated reason.
- The note answers, or spawns, a "so what / what's next."

### Technique examples

- **Connect/abstraction:** the user has a note on spaced repetition and a note on how compound interest rewards early, small, repeated contributions. The agent asks, "both of these are cases where a small repeated action compounds into an outsized result over a long enough window — is that the shape you're actually pointing at here, or is it more specific to learning?"
- **Challenge:** the user proposes that open-plan offices always hurt deep work. The agent asks, "would that hold for a team doing mostly quick synchronous coordination rather than long solo focus blocks — where would this connection actually break down?"
- **Compass prompts:** mid-conversation about a note on habit formation, the agent asks, "what competes with this — is there a note where friction *helps* rather than hurts, something that would push back on this claim (E)? And if this connection holds, where does it lead — does it say something about how you'd design a tool (S)?"
- **Distil:** after several exchanges about attention and tool design, the agent reflects back, "so what you're saying is: tools that remove friction from capturing a thought also remove the friction that would have forced you to clarify it first — is that close, or have I drifted from what you meant?"

**Placeholder row:** inserted into `evergreen` the moment the resume file would first be created (same "after the first substantive exchange" trigger as the shared resume-file rule) — a provisional draft-prefixed slug (e.g. `draft-tool-shapes-cognition-atomic-ideas`), `note_path: NULL`, `status: 'discussing'`.

**Gate:** the Take is fixed.

**On write:**

- The placeholder row's slug renames to its final claim-style form, prefix stripped.
- `note_path` is filled.
- `status` becomes `'discussed'`.
- `iteration` stays at its current value (`1` for a new note).
- `links` rows are inserted for every cited note (`rel_type: 'cites'`) only now, at write time — never earlier in the conversation.

**Revisiting an already-discussed evergreen note:** `status` moves back to `discussing` while the note is being reworked, then back to `discussed` once the rewrite lands; `iteration` increments. Unlike reference notes, which are append-only, an evergreen rewrite **can replace** the note's existing content wholesale, not just add to it.
