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
2. **Recoverable work and material** — starts or resumes one `create` or `revise`
   Evergreen work item with Start or resume work `/using-slipbox`. Its `manifest.json`, transient
   `synthesis-map.json`, and `draft.md` preserve the operation across interruption.
   Then takes named notes, a bare hunch to search around, or a pull from the
   evergreen backlog.
3. **Ground it** — a `/grounding` session where your own answers are free (personal
   experience, memory, anything unwritten), but your own questions and reflections must
   trace to what the retrieved notes actually establish, never to your own training.
   Orients with Compass (now living inside `grounding`, alongside its own Connect/
   Challenge/Distil supporting techniques) — reaches for whichever direction the
   conversation calls for. A Compass direction can spawn a fresh sub-idea; anything not
   pursued this sitting gets logged to the evergreen backlog for later. Before writing,
   every sentence in the draft gets a purity check: does it just restate one cited
   note's claim unchanged? If so, the conversation isn't done.
4. **Write and publish** — cites every note it draws on with a one-line reason;
   never links silently. The complete draft, citation events, and any backlog
   status/slug/note-path update are staged in one compensated work item and
   finalized together. A revisit is a full rewrite. Concurrent target changes or
   failed compensation leave recoverable diagnostics and are not reported as success.
5. **Sign-off** — checked against five criteria (complete-claim title,
   standalone-comprehensible, about one thing, every link has a reason, answers or
   spawns a "so what"), each grounded in Matuschak's evergreen-note practice and
   Ahrens' permanent-note rules — including a real tension between the two the skill
   deliberately sides on, spelled out in its own `references/sign-off-theory.md` —
   before the session finishes.

Once finalized, the note is on disk (or updated, if revisiting), every cited note is linked
with a reason, and any flagged tension is recorded. If
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
