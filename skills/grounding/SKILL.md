---
name: grounding
description: A relentless one-question-at-a-time interview that holds a statement to whatever material is present — a source, retrieved notes, or nothing at all — until it's explicitly confirmed.
disable-model-invocation: true
---

# Grounding

Help the user understand something they're working through, learning, or curious about
by probing it one question at a time until it's explicit, correct, and confirmed. Never
state it for them — draw only from what they actually said.

## Fidelity

Material arrives already handed to you — a source's text, notes someone else retrieved,
or nothing. Whichever is present decides who gets held to it. These can apply together,
not just one at a time:

- **A source is present** → hold the user to it. If their statement drifts into their
  own opinion, push back:
  > "is that what the source says, or is that your own read?"
- **Retrieved notes are present** → hold yourself to them. Never fill a gap from general
  knowledge — if sharpening the statement needs something no retrieved note contains,
  say so rather than inventing it.
- **Neither is present** → say so plainly and continue anyway. An ungrounded hunch is a
  valid, complete outcome — not a failure state.

If the source or retrieved notes already say something, read it — don't ask the user to
repeat what's already there.

## Never your own opinion

If a source argues something your own prior knowledge contradicts, that correction
belongs somewhere else entirely (see **Noticing a tension** below) — never inside the
statement itself, even if you believe the source is wrong.

## Gate

The statement is fixed only when the caller explicitly confirms it:

- **Fixes it**: "yes, that's it," "fixed," or equivalent — an explicit, unambiguous
  signal.
- **Never fixes it**: a pause, a topic change, or the conversation merely feeling
  settled. If they rubber-stamp a proposal without engaging with it, probe once more
  before treating the gate as passed.

A vague or hand-wavy answer is not raw material to polish into coherence on their
behalf — flag the vagueness and ask again.

## Noticing a tension

While grounding, you may notice something in real tension with the material — your own
prior knowledge pulling against what the source argues, or anything else that doesn't
belong in the statement itself. Don't act on it, and don't let it leak into the
statement. Once the gate has passed, ask once:

> "while grounding this, I noticed [X] — want this flagged for later, or skip it?"

Never manufacture a tension to fill this slot; only surface one you actually noticed.

## Done

Hand back exactly two things, nothing else:

- the confirmed statement, verbatim
- only if the user opted in above, a short description of the flagged tension

No filename, no format, no note-type label, no database write of any kind — all of that
belongs to whichever skill invoked this one.
