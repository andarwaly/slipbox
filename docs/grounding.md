# grounding

A relentless one-question-at-a-time interview that holds a statement to whatever
material is present — a source, retrieved notes, or nothing at all — until the user
explicitly confirms it.

## When to use

You won't usually invoke this directly. `ground-me`, `make-literature-note`, and
`make-evergreen-note` each call `/grounding` internally, framing the session with
whatever material they've already gathered. Invoke it directly only if you want the
raw interview loop without any of those wrappers' note-writing.

## How it works

1. **Fidelity** — whichever material is present decides who gets held to it: a source
   present means the user is held to it; retrieved notes present means the agent is
   held to them; neither present means an ungrounded hunch is accepted as a valid,
   complete outcome — and a source and retrieved notes can both apply at once, not just
   one at a time. A self-contradicting source gets both readings surfaced, not silently
   picked; notes that disagree with the source lose to it. The source itself is never
   quoted before the user answers a question about it. If the user restates their own
   opinion a second time after one push-back, the offer shifts to routing it to the
   evergreen backlog instead of pushing back again. A caller can frame which direction
   to hold before a session starts.
2. **Never your own opinion** — the agent never introduces its own training or memory
   as if it belonged to the material, even when it privately disagrees with a source.
3. **Never finish it for them** — the completion, the candidate, the connection, or the
   counter-argument is always the user's own to supply, never the agent's to hand over;
   a probing question never pre-decomposes the source's own structure into
   sub-questions the user hasn't identified themselves yet.
4. **Reading the answer** — the caller supplies the inquiry, passage, and reading state
   when available; a direct invocation opens with a plain-context question. What comes
   back is read as confident, hesitant, blank, confused, not-started, or partial. If
   intent to read is unclear, offer the independent path and collaborative path. A user
   who wants to finish reading first is acknowledged without being forced into a route.
   Anything read as hesitant, blank, confused, or partial gets one short, varied
   acknowledgment before the next question — never a fixed stock phrase.
5. **Choosing a technique** — the answer's reading picks the technique: confident routes
   to a source-anchored verification check (escalating to a fuller elenchus pass only on
   a real mismatch), hesitant routes to a Feynman-style explain-and-patch loop,
   not-started or partial source reading with collaboration routes to adaptive guided
   reading, a blank answer with no source routes to a maieutic drawing-out session, and
   a confused answer routes to surfacing the specific discrepancy and letting the user
   reconcile it. Ten named
   techniques live in `references/`, including four (Compass and its Connect/Challenge/
   Distil supporting techniques) reached when a caller orients a session toward
   synthesizing a position rather than probing a single source.
6. **Gate** — the statement only fixes on an explicit, unambiguous confirmation, and
   getting there is hardened two ways: a finished draft is never shown until at least one
   open probe-and-answer round has produced real content, and the confirmation question
   itself always stays open ("what's missing or wrong?") rather than inviting a binary
   yes/no rubber-stamp. A compound claim gets built from the user's own already-stated
   parts incrementally, never compressed into one agent-authored sentence at Gate time. A
   guided-reading session passes through this same Gate once, over the whole accumulated
   result at the end of the collaboration — not per move.
7. **Noticing a tension** — if something in real tension with the material comes up
   mid-session, it's never acted on or leaked into the statement. Once the gate passes,
   the agent asks once whether to flag it for later — surfacing at most one tension even
   if several came up, the rest dropped silently.

A session hands back at most two things when it finishes: the confirmed statement
verbatim, and — only if the user opted in above — a short description of the flagged
tension. No filename, no format, no note-type label, no database write of any kind;
that's the calling skill's job. A `## References` table in the skill's own source lists
all ten technique files, what each does, and when it's reached.

A session opens with one plain line naming the source or topic, or with a plain-context
question when invoked directly, then stays silent about being "in a grounding session"
for the rest of the exchange — no repeated marker on every question.

## Usage

> Let's ground this: [whatever you're working through]

## Installation

```bash
npx skills add andarwaly/slipbox
```

See the [skill source](../skills/grounding/) for the full agent-facing
instructions.
