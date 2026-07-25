# Mode: literature

Invoked by `write-literature-note`. Produces a Claim only, grounded against the one source the candidate came from.

**Grounding direction:** the *user* must stay grounded to what the source actually claims. The *agent's* job is to flag drift into the user's own opinion — "that sounds like your own take, not what the author argued — is that what you meant, or is this the author's position?"

**Technique — stress-test:** when the paraphrase drifts from the source, push back: "are you sure that's what they're saying, and not X?" This technique exists solely to check paraphrase fidelity. It is never used to generate or shape the user's opinion — that's the personal-take path below, or evergreen's job entirely.

**No `idea.db` retrieval in this mode.** Ground only against the one resource the candidate came from — nothing else is pulled in.

**Gate:** the Claim is fixed.

**After the gate, actively ask** — this is an invitation, not passive noticing — "does this claim raise an open question?"

- If yes: the user's own typed answer becomes a new `seeds` row: `type: raw`, `target_type: literature` or `reference` depending on what the user's answer is actually about, `origin: 'discussion'`, `status: 'to-discuss'`.
- If the user has none: skip, without pressure. Never manufacture a question to fill this slot.

**Personal-take drift mid-conversation:** if the stress-test surfaces a personal take and the user confirms it's genuinely their own view (not the author's), log it the same way — a new `seeds` row, `origin: 'discussion'`, same field rules as above.

**Reference-note linking:** if a term with an existing reference note comes up, propose linking it with a one-line reason. The user accepts or rejects each proposed link individually. Never link silently.

**Write:** a literature note, Claim only. Filename derived from the confirmed claim text, no author prefix.

**Filename collision:** stop and ask the user to reword the claim, or confirm this is a genuine duplicate. Never auto-disambiguate the filename.

### Drift examples

These illustrate the boundary the stress-test technique above is checking — where a paraphrase stays anchored to the source versus where it has quietly become the user's own claim.

- **Grounded paraphrase:** "the author argues AI will restructure creative labor markets." This stays inside the source's claim — it restates scope and mechanism without adding a conclusion the author didn't draw.
  **Drifted version:** "I think AI will replace most writers within a decade." This swaps the author's structural claim for a specific, stronger prediction the user is now making on their own.
  **Stress-test question:** "that last part sounds like your own view, not the author's — is that what you meant, or is this what they argued?"

- **Grounded paraphrase:** "the author says spaced repetition outperforms rereading for long-term retention." A direct restatement of the source's comparison.
  **Drifted version:** "spaced repetition is basically the only study method worth using." The user has escalated a comparative finding into a sweeping personal endorsement the source never made.
  **Stress-test question:** "did they actually rule out other methods, or is that the conclusion you're drawing from it?"

- **Grounded paraphrase:** "the author claims open-plan offices reduce deep-focus time for engineers." Matches the source's specific population and effect.
  **Drifted version:** "open-plan offices are a management failure." The user has moved from the source's narrow empirical claim to a value judgment about intent that isn't in the text.
  **Stress-test question:** "that reads like a judgment on the people who designed it — is that the author's framing, or is it yours?"
