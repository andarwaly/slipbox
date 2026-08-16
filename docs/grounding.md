# grounding

A relentless one-question-at-a-time interview that holds a statement to whatever
material is present — a source, retrieved notes, or nothing at all — until you've
explicitly confirmed it.

## When to use

You won't usually invoke this directly. `ground-me`, `make-literature-note`, and
`make-evergreen-note` each call `/grounding` internally, framing the session with
whatever material they've already gathered. Invoke it directly only if you want the
raw interview loop without any of those wrappers' note-writing.

## How it works

1. **Fidelity** — whichever material is present decides who gets held to it: a source
   present means the user is held to it; retrieved notes present means the agent is
   held to them; neither present means an ungrounded hunch is accepted as a valid,
   complete outcome. A caller can frame which direction to hold before a session starts.
2. **Never your own opinion** — the agent never introduces its own training or memory
   as if it belonged to the material, even when it privately disagrees with a source.
3. **Reading the answer** — every session opens with a plain restatement request, and
   what comes back gets read as confident, hesitant, blank, or confused. A blank answer
   only ever gets a reactive offer (walk through it together, or try explaining first)
   after a first attempt has genuinely failed — never a stated reading-state question
   upfront.
4. **Choosing a technique** — the answer's reading picks the technique: confident routes
   to a source-anchored verification check (escalating to a fuller elenchus pass only on
   a real mismatch), hesitant routes to a Feynman-style explain-and-patch loop, a blank
   answer with a source routes to a passage-by-passage discovery walk, a blank answer
   with no source routes to a maieutic drawing-out session, and a confused answer routes
   to surfacing the specific discrepancy and letting the user reconcile it. Ten named
   techniques live in `references/`, including four (Compass and its Connect/Challenge/
   Distil supporting techniques) reached when a caller orients a session toward
   synthesizing a position rather than probing a single source.
5. **Gate** — the statement only fixes on an explicit, unambiguous confirmation, and
   getting there is hardened two ways: a finished draft is never shown until at least one
   open probe-and-answer round has produced real content, and the confirmation question
   itself always stays open ("what's missing or wrong?") rather than inviting a binary
   yes/no rubber-stamp.
6. **Noticing a tension** — if something in real tension with the material comes up
   mid-session, it's never acted on or leaked into the statement. Once the gate passes,
   the agent asks once whether to flag it for later.

A session opens with one plain line naming the source or topic, then stays silent about
being "in a grounding session" for the rest of the exchange — no repeated marker on
every question.

## Usage

> Let's ground this: [whatever you're working through]

## Installation

```bash
npx skills add andarwaly/slipbox
```

See the [skill source](../../skills/slipbox/grounding/) for the full agent-facing
instructions.
