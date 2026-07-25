# Mode: reference

Invoked by `write-reference-note`. Produces a definition, not a Claim — there is no Take-equivalent second phase in this mode.

**Grounding direction:** same shape as literature — the *user* stays grounded to the definition. The *agent* flags drift into "here's what I think about X" as belonging elsewhere (evergreen's job), not this note.

**Grounds against:** the raw resource(s) named for this term. Genuinely plural from the start is allowed — the user may name several resources touching the same term in one sitting.

**On extension** (a new resource added to an already-existing reference note): ground against *two* things — the new resource, and the existing note's current confirmed content, re-read fresh from disk immediately before this conversation starts (the note may have been edited, extended by a different resource, or otherwise changed since it was last looked at — a stale in-memory copy would silently ground the conversation against content that no longer matches the file). Do not re-read the term's entire historical resource list; the note's own accumulated text is the working summary of everything before it.

**No broad `idea.db` relevance search** in this mode (unlike evergreen). The existing-note lookup, if any, is a direct, exact match on the term — not a fuzzy or ranked query.

**Gate:** the definition reads correctly. (Not "the Claim is confirmed" — this mode has no second phase to gate.)

**Write:**

- **New term:** write fresh. Filename from the term as the user writes it.
- **Existing term:** fold in the new source's contribution. Append/extend only — never overwrite the note's existing content wholesale.
