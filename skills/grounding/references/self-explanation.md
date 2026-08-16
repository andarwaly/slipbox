# Self-explanation

## What it is

From Chi et al.'s research on generative learning: learners explaining
material to themselves while engaging with it, generating inferences and
repairing their own mental model when they notice a discrepancy between new
material and what they already believed. Distinct from asking a targeted
"why" question (that's elaborative interrogation) — this is open-ended,
unprompted sense-making, and the repair happens because the discrepancy was
*noticed*, not because it was corrected for the person.

## Why this technique, for this job

A confused-but-not-blank answer is exactly a mental-model-repair situation —
something was said, it just doesn't hold together, meaning a discrepancy
exists somewhere between what was said and what the source (or the user's
own prior reasoning) actually supports. This technique's whole mechanism is
surfacing that discrepancy and letting the person notice and fix it
themselves, rather than the agent diagnosing and correcting it directly —
which matters here because correcting it outright would be exactly the
kind of "handing over the answer" the whole family exists to avoid.

**Use this when** the answer is confused — touched something, but garbled
or circular, distinct from Hesitant (uncertain but coherent) and Blank
(nothing substantive at all).

**Use `feynman.md` instead when** the answer is hesitant rather than
confused — shaky but not self-contradictory. Feynman's loop assumes a
simplifiable idea exists; this technique assumes a *specific internal
inconsistency* to surface, which a merely-hesitant answer may not have.

## Concept

Chi's own data shows the technique's benefit is highly contingent on how
well someone already self-explains — a "high self-explainer" and a "low
self-explainer" get very different results from the same open-ended
prompt, and the bare technique offers no built-in scaffolding for improving
a poor self-explainer's ability. That's exactly why this family's version
narrows the open-ended version down to something more targeted: rather than
"make sense of this however you can," surface the *specific* discrepancy
noticed in what was just said, pointed at directly, so even someone who
wouldn't self-explain well unprompted has something concrete to work from.

## Conversational adoption

- **Name the specific contradiction, not the general confusion.** "You said
  X, but a moment ago you said Y — how do those fit together?" is far more
  useful than "that doesn't quite make sense, try again."
- **Point at the discrepancy, don't resolve it.** The repair is the user's
  own — the agent's job stops at making the inconsistency visible.
- **Let genuine confusion sit for a moment.** Don't rush to rephrase the
  question if the first attempt to surface the discrepancy doesn't land
  immediately — repair takes a beat, especially for material that was
  genuinely garbled.
- **Distinguish "still confused" from "newly confused."** If naming the
  discrepancy produces a different confusion than the original one, that's
  actually progress (a smaller, sharper gap) — don't treat it as a failed
  attempt.

## Worked example

> **User:** So notes get better the more you write, because linking them
> makes them clearer, but also each note is supposed to stand alone without
> needing the others?
> **Agent:** Those two things you just said seem to be in tension — notes
> get clearer *through* their links, but also need to make sense *without*
> them. How do you square those?
> **User:** Hm. Maybe... the note itself has to be complete on its own, but
> the links are what make it *more* valuable, not what make it
> understandable in the first place?
> **Agent:** That's a real distinction — completeness versus value added.
> Does that resolve the tension, or is there still a piece that doesn't
> fit?

## Guardrail

There's a temptation to soften the discrepancy into something gentler than
it actually is — hedging the contradiction so it doesn't feel like a
callout. That defeats the mechanism: the discrepancy has to be named
clearly enough to actually notice, not smoothed into something so vague
it's easy to wave past without genuinely reconciling it.
