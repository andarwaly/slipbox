# make-evergreen-note

Ground a hunch into a Take — your own synthesized position, checked against existing
notes it connects — then write it as an evergreen note.

## When to use

Bring specific existing notes you want connected, or just a hunch with nothing named
yet — this skill searches for anything related before starting either way. Unlike a
Claim, a Take can be revisited: a later session may rewrite the note's content wholesale
rather than only appending to it.

## How it works

1. **Prerequisite** — requires `.slipbox/AGENTS.md` to exist, confirming
   `setup-slipbox` has run; every `slipbox` CLI call throughout this skill goes
   through `.slipbox/bin/slipbox`, never bare `slipbox`.
2. **Take the material** — named notes, a bare hunch to search around, or a pull from
   the evergreen backlog.
3. **Ground it** — a `/grounding` session where your own answers are free (personal
   experience, memory, anything unwritten), but your own questions and reflections must
   trace to what the retrieved notes actually establish, never to your own training.
   Orients with Compass (now living inside `grounding`, alongside its own Connect/
   Challenge/Distil supporting techniques) — reaches for whichever direction the
   conversation calls for. A Compass direction can spawn a fresh sub-idea; anything not
   pursued this sitting gets logged to the evergreen backlog for later. Before writing,
   every sentence in the draft gets a purity check: does it just restate one cited
   note's claim unchanged? If so, the conversation isn't done.
4. **Write** — cites every note it draws on with a one-line reason; never links
   silently. Can be a full rewrite if revisiting an existing evergreen note.
5. **Sign-off** — checked against five criteria (complete-claim title,
   standalone-comprehensible, about one thing, every link has a reason, answers or
   spawns a "so what"), each grounded in Matuschak's evergreen-note practice and
   Ahrens' permanent-note rules — including a real tension between the two the skill
   deliberately sides on, spelled out in its own `references/sign-off-theory.md` —
   before the session finishes.

Once done, the note is on disk (or updated, if revisiting), every cited note is linked
with a reason, and any flagged tension is logged as its own evergreen-backlog entry. If
this session's material came from the backlog itself, that row gets closed out —
renamed to the note's own slug on a first write, or its `--iteration` bumped on a
revisit — and the user is told the file path.

## Usage

> Let's think through how [note A] connects to [note B] — or just: make-evergreen-note

## Installation

```bash
npx skills add andarwaly/slipbox
```

See the [skill source](../skills/make-evergreen-note/) for the full
agent-facing instructions.
# Make evergreen note

Provenance uses `origin_kind: evergreen-note` and records notes-in-play in `origin_paths`, or a standalone origin when no notes are involved.
