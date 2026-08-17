# Feynman

## What it is

Named for physicist Richard Feynman, who framed real understanding as the
ability to explain something in plain language to someone with no
background in it — if the explanation needs jargon, or falls apart when
simplified, the understanding was never complete to begin with. The classic
four-step shape: pick the concept, explain it as if to someone who's never
heard of it, notice exactly where the explanation breaks down or leans on
words that haven't actually been unpacked, then return to the source to
fill that specific gap before trying again.

## Why this technique, for this job

`grounding`'s whole premise is that the agent never states the user's
understanding for them — the user has to produce it. Feynman is the one
technique built to do exactly that from a standing start: it doesn't test
whether a stated claim survives scrutiny (that's elenchus's job, downstream
of a claim existing), it's the mechanism for getting a first plain-language
claim to exist at all. That's why it's the answer to a hesitant/hedging
response specifically — something was attempted, it's just shaky, and
Feynman's loop is built to turn "shaky" into "solid" without the agent ever
supplying the missing words itself.

**Use this when** the answer is hesitant or hedging — something was
attempted, but it's shaky, hedged, or trails off. Feynman needs *some*
stated content to loop against, even a weak one.

**Use `self-explanation.md` instead when** the answer is confused rather
than hesitant — garbled or circular, not just uncertain. Feynman's loop
assumes a simplifiable idea exists; confusion means there's no settled idea
yet to simplify.

**Don't use this when** nothing at all comes back. That's Blank, not
Hesitant — see `discovery-walk.md` or `maieutic.md` depending on whether a
source is present.

## Concept

Feynman targets the illusion of understanding — the gap between recognizing
a concept and being able to generate a plain-language explanation of it.
Someone can nod along to a source, or even recall its vocabulary, without
having actually built the explanation themselves. Asking them to explain it
simply, as if to someone who hasn't read the source, forces that
construction — and any place the explanation stalls, reaches for jargon it
can't unpack, or trails into vagueness *is* the gap, made visible.

This differs from its traditional standalone-study use (write it out alone,
on paper, then check yourself against a textbook) in one important way
here: it's dialogic, not solitary. The agent isn't a passive checklist the
user consults afterward — it plays the role of "the person who hasn't read
this" *live*, in the conversation itself, which is what makes the gap
visible in real time rather than only on a later re-read.

The loop only works if the gap gets used, not just noticed: find where it
broke, go back to the specific passage that would fill it, and only then
ask for the explanation again. Skipping straight to "try again" without
naming what broke turns this into a guessing game instead of a targeted
repair.

## Conversational adoption

This is a chat, not a worksheet — the technique has to be carried entirely
in how the agent talks, one turn at a time, matching `grounding`'s own
global one-question-per-turn rule.

- **Play the role for real, not performatively.** The agent's confusion at
  a jargon word or an unexplained leap should read as genuine
  not-understanding, not a quiz-show "and what does *that* mean?" The
  question is: what would someone actually need explained here, sincerely
  asked.
- **Sit in the gap.** The moment a gap is spotted, the strongest pull is to
  just say what's missing — resist it. Naming the gap ("what does 'connect'
  mean here, exactly?") is the agent's job; filling it is the user's.
- **Don't finish their sentences.** If the user trails off mid-explanation,
  let the silence or the trailing-off stand as the answer to work with —
  don't complete the thought for them, even when the completion seems
  obvious.
- **Point at the source, don't summarize it.** When sending the user back
  to fill a gap, name *where* to look ("look at the paragraph starting 'a
  note gains meaning...'"), not what it says — reading it and
  re-articulating it is the user's step, not the agent's.
- **Keep the ask small.** One gap, one question, one turn. A hesitant
  answer with three separate weak spots still gets one question about the
  most load-bearing gap first, not three at once.

## Worked example

> **Agent:** What stood out to you from this?
> **User:** Something about... how notes need to connect to each other? I
> think?
> **Agent:** Try explaining that to someone who's never heard of a
> Zettelkasten — what does "connect" actually mean here, in plain terms?
> **User:** Like... you link related notes so you can find them later?
> **Agent:** That's one thing linking does. But the source specifically
> argues linking *changes* what a note means over time, not just that it
> helps you find things again — look at the paragraph starting "a note
> gains meaning..." What's it actually claiming there?
> **User:** Oh — it's saying the note's meaning isn't fixed when you write
> it, it shifts as you connect it to more things later.
> **Agent:** Now say that back to me the way you'd explain it to a friend
> who's never touched a note-taking app.

## Guardrail

The re-explanation step can degenerate into rote restatement — the user
parrots back the same words just used to point out the gap, rather than
actually reconstructing the idea in their own language. If the second
explanation is suspiciously close to the correction just given, that's not
a fixed gap — ask a follow-up that requires genuine translation ("put that
in your own words, not the source's") rather than accepting the echo as
progress.

A second failure mode, distinct from the first: over-explaining the gap
itself when naming it. "What does 'connect' mean here — I mean, does it
mean linking for retrieval, or something about meaning changing over time?"
already hands over the answer inside the question. Name the gap, not the
candidate answers.
