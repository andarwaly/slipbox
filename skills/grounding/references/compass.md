# Compass

## What it is

The Idea Compass, a thinking tool that places one idea (X) at the centre
and asks four different questions about it, one per compass direction.
Fei-Ling Tseng's own 2022 post coins it "the Compass of Zettelkasten
Thinking"; the shorter "Idea Compass" name comes from a later joint
presentation by Tseng and Vicky Zhao at a LYT (Nick Milo's "Linking Your
Thinking") conference — Sascha Fast (zettelkasten.de) adopted and
popularized that shorter name once he learned it predated his own writing
on the technique, and classifies it as a "closed creative technique": a
fixed set of questions that provides a direction of exploration from a
known starting point, as opposed to an open-ended technique like
mind-mapping.

## Why this technique, for this job

Compass operates at a different point in a session than the rest of
`grounding`'s techniques — it decides *what to ask about next*, not *how to
respond to whatever comes back*. A question Compass generates still gets a
confident, hesitant, blank, or confused answer, and that answer still
routes through `SKILL.md`'s own dispatch table exactly as any other
question's would. Compass is the layer that orients a synthesis session
toward something worth asking about; the rest of the family handles what
happens once it's asked.

**Use this when** a session is building toward a synthesized position (an
idea drawing on more than one source, or a hunch with nothing yet written
down) and needs a direction to explore next, rather than a response to
something already said.

**Don't use this** as a substitute for the answer-quality dispatch table —
Compass never decides how to handle a confused or hesitant answer; it only
decides what the next question is about.

## Layout

```
                    NORTH
                (where X comes from)
                        │
   WEST ─────────────── X ─────────────── EAST
(what's similar to X)          (what competes with X)
                        │
                    SOUTH
                (where X leads)
```

## Directions

- **NORTH — where does X come from?** Its origin, its parent category, what
  caused it. Not a question to ask fresh — the answer is already in hand:
  for a Take still being drafted, it's whichever notes were named,
  retrieved, or surfaced from the backlog to start this session; for an
  existing evergreen note being revisited, it's that note's own
  `derived-from` frontmatter field, read directly from the file. Never a
  database query either way.

- **WEST — what is similar to X?** What other disciplines already hold this
  idea, what other ways exist to say or do it. Executed via the **Connect**
  technique — see `references/connect.md`.

- **SOUTH — where can X lead? what does X contribute to?** Drilling into
  X's own downstream contribution — what it nurtures, what it could be the
  headline of — asked independently of whatever West or East turn up. A
  plain direct question, same treatment as North: no technique needed, just
  ask it and let the take develop.

- **EAST — what competes with X?** What is the opposite of X, what is it
  missing, its disadvantage. Executed via the **Challenge** technique — see
  `references/challenge.md`.

## Conversational adoption

- **Reach for whichever direction the conversation calls for**, never all
  four as a mandatory checklist — a direction turning up nothing is a
  complete result for that direction, not a gap to force-fill.
- **The four directions are independent of each other.** West's finding and
  East's finding don't get reconciled inside Compass itself — that
  reconciliation, when both have produced something, is Distil's job (see
  `references/distil.md`), never Compass's own.
- **Directions recurse — treat this as optional, not mandatory.** Any
  answer that comes out of a direction can become its own new center idea,
  with its own SOUTH/EAST/WEST branches. This is real and worth noticing,
  but never mandatory to chase within the current session: a spawned
  sub-idea that isn't pursued now is flagged for the evergreen backlog by the
  invoking skill, with `note-connection` and every participating actual path,
  or with `standalone` and no path when no notes were retrieved, for a later,
  separate session — the same way any other flagged tension
  gets carried forward, not lost. Compass itself performs no database write
  of any kind; that write, like every other one in this family, belongs to
  whichever skill invoked this one.

## Worked example

A user exploring "housing is a human right because it provides the
stability needed to function in society" reaches EAST and surfaces
"affordability crises make stable housing markets hard to guarantee." That
EAST answer is itself a candidate for a fresh Compass session later — its
own SOUTH might be "land-value taxation as one response," its own EAST
might be "does regulation actually worsen scarcity?" None of that gets
chased down in the current session unless the user wants to; if not, it's
flagged for whichever skill invoked this one to log to the backlog as its
own future starting point.

## Guardrail

Forcing every direction on every take produces a rote interview, not a
sharpened one — the compass is a portable thinking tool, not a required
pass. The same discipline applies to recursion: a sub-idea spawned by a
direction is optional to chase, never force-completed within the current
session, and never silently dropped either — it's flagged for the backlog,
via whichever skill invoked this one, if it isn't pursued now.
