# Question / Evidence / Warrant — internal reasoning, never written to disk

Q/E/W is how the agent thinks about a source before and during grounding — it identifies
which passages are claim-worthy and checks a Conclusion before it's finalized. This
file's scope is per-claim reasoning; whole-source reasoning about motivation, tension,
and argument shape — the piece that feeds Core Idea formation — lives in
`source-architecture.md` instead, a different grain from what's covered here. None of
it becomes note content. The note holds only the Core Idea and each claim's declarative
Conclusion (plus condensed Evidence, kept for later verification — see
  `writing-a-source-point.md`). Question and Warrant never appear on the page.

## Question

What specific question does this candidate passage actually answer? Not a topic label
("what does this source cover?"), and not a question invented to give a claim a slot to
sit in — the question this specific claim resolves. Used during the Surface pass to
decide whether a passage is one claim, part of a bigger one, or not claim-worthy at all.

- **Good:** "What does Fei say is missing from standard Zettelkasten instructions?" —
  specific, answerable by one claim, traceable to something the source actually
  addresses.
- **Bad:** "What is the Zettelkasten Method?" — a topic label. Nothing this broad
  resolves into a single claim; it's an invitation to summarize the whole source under
  one heading, which breaks the atomicity a Key Claim needs (see `GLOSSARY.md`'s
  Atomicity entry).

## Evidence

What the source said or showed — reported, not yet interpreted. The raw material a
Conclusion is built from. Written to disk in condensed form (see `writing-a-source-point.md`),
so it's the one part of this trio that does surface on the page.

- **Good:** "Fei says the method came with no instructions beyond the slogan 'Think.
  Write. Connect.' She lists unanswered questions about what counts as an idea, which
  relationships to pursue, how to handle connections, and how to start with a new idea
  that has nothing to connect to." — reports what the source said, nothing more.
- **Bad:** "Fei argues the instructions are too vague to be useful." — already jumped to
  interpretation; doing the Conclusion's job inside Evidence, leaving nothing left for
  the Conclusion to add.

A quote can stand in for paraphrased Evidence, but only when it earns its place — see
`writing-a-source-point.md` for when and how.

## Warrant

The source's own stated or clearly implied reason *why* its Evidence is enough to
support its Conclusion — a report on the source's inferential move, never the
note-writer's judgment of whether that move holds up. Answers a third question distinct
from the other two: Evidence answers "what was said," Conclusion answers "what does the
source claim as a result," Warrant answers "why does the source think the first proves
the second."

Used two ways, both internal:

- **Merge/split test at the Surface pass** — two candidate claims that would share the
  same Warrant are usually one claim wearing two Questions, not two claims. Sharper than
  eyeballing topic overlap: "the instructions are underspecified" and "the difficulty of
  meaningful connections" both rest on the same inferential move (Fei treats the number
  and specificity of her unanswered questions as itself proof the guidance is vague) —
  one claim, not two.
- **Self-check before finalizing a Conclusion** — can the "why" be stated in one sentence
  from the Evidence? If not, the Conclusion is still restating Evidence, not concluding.
  This is the check that catches the collapse the bad example below shows.

Most sources never state their reasoning outright — that's normal, not a gap to fill by
inventing one. Write the Warrant as a factual observation of that absence ("the source
treats the number of open questions as self-evidently sufficient, without arguing the
inference further") rather than supplying reasoning the source didn't give — inventing
one crosses into the note-writer's own reasoning, which the literature-note boundary
forbids.

## Conclusion

What the Evidence means, stated as the source's position — not the user's own reaction,
agreement, or disagreement (a Claim is "an object of understanding, not agreement," per
`SKILL.md`'s own definition). Written to disk as the claim's declarative heading (see
`writing-a-source-point.md`) — the single sentence a reader's eye lands on.

- **Good:** "Standard Zettelkasten guidance is too vague to help writers decide what
  counts as an idea, which relationships to create, how to handle those connections, or
  how to begin when a new idea has nothing to connect to." — names the source's actual
  position, stands alone if the Evidence bullet is deleted.
- **Bad:** "Fei says the instructions are underspecified and lists several questions
  they leave open." — just reports the Evidence a second time in different words. Delete
  the Evidence bullet and this Conclusion collapses; it isn't adding the "what this
  means" step, it's restating "what was said." This is quote-dumping in paraphrase
  form — the Collector's Fallacy of mistaking restatement for comprehension, not genuine
  comprehension of the source's position. Warrant exists specifically to catch this: if
  Conclusion and Warrant would say the same thing, the Conclusion hasn't earned its
  place yet.

See `writing-a-source-point.md` for the note structure Evidence and Conclusion land in, and the
checklist that tests a finished claim against this theory.
