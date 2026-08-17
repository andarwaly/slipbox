# Discovery walk

## What it is

Not a single named academic technique — a composite, built for this family
specifically, of three: Maieutic's drawing-out stance, Feynman's
explain-then-patch loop, and ZPD/scaffolding's paced-support principle. The
source gets walked passage by passage, with a question asked before each
next passage is revealed rather than the passage being delivered and then
discussed afterward. Comprehension is built turn by turn, not handed over
and checked.

## Why this technique, for this job

Every other technique here assumes a restatement already exists, or at
least an attempt at one. Discovery walk is for the one case where nothing
does — the user hasn't engaged with the source at all yet, but a source
exists to walk through. Delivering the source and then asking about it
would be the exact didactic anti-pattern `grounding` exists to avoid;
walking it via questions, one passage at a time, keeps construction in the
user's hands even when there's nothing yet built to check.

**Use this when** the answer is blank, a source is present, and the user
chose "walk through this together" over "let me try explaining first."

**Don't use this when** a source isn't present — there's nothing to walk
through. See `maieutic.md` instead, aimed directly at memory or experience.

**Don't offer this before** a first plain attempt has genuinely failed —
it's a recovery path chosen by the user, never a default opener.

## Concept

The walk works because each turn's question is scoped to what's already
been shown, not what's coming — "what do you think this is building toward,
before I show you the next line?" forces a prediction against only the
material already available, the same way any single-passage question
would, just chained across the whole source rather than asked once at the
end.

ZPD's contribution is pacing, not question content: the amount of
scaffolding (how much of a hint accompanies each question) should track how
the user is actually doing turn to turn — more support after a missed
prediction, less once several land correctly in a row — support withdrawn
as competence shows itself, not held constant regardless of how the walk is
going.

## Conversational adoption

- **Reveal one passage at a time.** Never show more of the source than the
  current question needs — the next passage is the reward for engaging
  with the current one, not something to preview.
- **Ask before revealing, not after.** "What do you think happens next,
  based on what you've read so far?" comes before the next passage is
  shown, not as a recap question once it's already been read.
- **Calibrate support to how it's going.** A missed prediction earns a bit
  more scaffolding on the next question; several correct predictions in a
  row earns less — don't hold the difficulty flat regardless of signal.
- **Consolidate at the end, don't re-verify every turn.** Each turn already
  checks itself against the source locally; save the full Gate pass for the
  accumulated result once the walk concludes.

## Worked example

> **Agent:** Here's the opening: "A note gains meaning not when it's
> written, but..." — before I show you the rest of that sentence, what do
> you think comes next?
> **User:** Maybe... when someone reads it again?
> **Agent:** Close in spirit — here's the actual rest: "...but as it
> accumulates connections to other notes over time." Given that, what do
> you think the author is setting up to argue next?
> **User:** That the value of a note isn't really about what it says on its
> own, but what it ends up linked to?
> **Agent:** That's exactly the direction — let's keep going.

## Guardrail

The walk can quietly turn into delivery if the "before I show you the next
line" question gets skipped on a few turns because the pace feels slow —
once that happens even a couple of times, the session has become exactly
the didactic delivery this technique exists to avoid. Every passage
transition needs its question, no exceptions for pacing.
