# Verification

## What it is

The scientific method, applied to a single restatement instead of a lab
experiment: treat what the user just said as a hypothesis about what the
source means, then check it against the actual source text as evidence. If
the hypothesis and the evidence agree, it's confirmed. If they disagree,
that's data too — a real mismatch worth surfacing, not something to smooth
over.

## Why this technique, for this job

Every other technique here checks internal logic — does the statement hold
together, does it survive scrutiny. Verification checks something different
and, for this job, more important: does the statement match what the source
*actually says*, which a perfectly coherent, confidently stated restatement
can still get wrong. A confident answer doesn't mean a correct one; this is
the one technique that anchors the check to the source text itself rather
than to how convincing the answer sounds.

**Use this when** the answer is confident — clear, complete, no hedging. It's
the cheap default for the common case, not a heavyweight check.

**Escalate to `elenchus.md` instead when** this check surfaces a genuine
mismatch between the statement and the source — not for a thin-but-accurate
answer, and never as the default opening move for a confident answer.

**Don't use this when** the answer is hesitant, blank, or confused — there's
no settled statement yet to check against anything. See `feynman.md`,
`guided-reading.md`, `maieutic.md`, or `self-explanation.md` depending on
which of those applies.

## Concept

The failure mode this targets is overconfidence in an unverified claim —
distinct from elenchus's target (a claim that's internally inconsistent). A
restatement can be perfectly well-reasoned, logically defensible, and still
simply wrong about what the source says. Checking internal logic alone would
miss this entirely; the only real check is against the external evidence,
the source itself.

This borrows the *shape* of hypothesis-testing, not its full apparatus —
there's no control condition, no formal falsifiability criterion, just the
core move: state a claim, check it against evidence, revise if they
disagree. Kept deliberately lightweight because it's meant to run by
default, every time, not as a special heavyweight procedure reserved for
important claims.

## Conversational adoption

- **State the check, don't hide it.** "Let's see if that holds up against
  what the source actually says" is a legitimate thing to say out loud —
  this isn't a trap, it's a stated, expected step.
- **Point to the specific passage.** The check is against actual text, not a
  vague sense of "does this feel right" — name where in the source the claim
  should be checkable.
- **A match closes the loop quickly.** If the restatement holds up, say so
  plainly and move to the Gate — don't manufacture doubt where the check
  passed clean, that would just be friction for its own sake.
- **A mismatch gets surfaced directly, not softened.** "The source actually
  says X, not Y — what do you make of that?" rather than easing into it
  obliquely.

## Worked example

> **Agent:** You said the author argues linking notes helps you "find things
> later." Let's check that against the text — look at the paragraph starting
> "a note gains meaning..." Does that match what it's actually claiming?
> **User:** Oh — no, it's saying something different, that the note's
> meaning itself changes over time as it gets linked to more things.
> **Agent:** Right — that's a stronger and different claim than "easier to
> find." Does the restatement need updating, or does this change anything
> else about what you said?

## Guardrail

The check can slide into rubber-stamping — accepting a restatement as
verified because it sounds plausible, without actually locating and
re-reading the specific passage it should match. If the exact sentence or
paragraph that would confirm or contradict the claim hasn't been pointed to
and read, the check hasn't actually happened yet, regardless of how
confident the exchange feels.
