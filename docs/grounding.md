# grounding

A relentless one-question-at-a-time interview that holds a statement to whatever
material is present — a source, retrieved notes, or nothing at all — until you've
explicitly confirmed it.

## When to use

You won't usually invoke this directly. `ground-me`, `ground-the-claim`, `ground-term`, and
`ground-my-take` each call `/grounding` internally, framing the session with whatever
material they've already gathered. Invoke it directly only if you want the raw interview
loop without any of those wrappers' note-writing.

## How it works

1. **Fidelity** — whichever material is present decides who gets held to it: a source
   present means the user is held to it; retrieved notes present means the agent is
   held to them; neither present means an ungrounded hunch is accepted as a valid,
   complete outcome.
2. **Never your own opinion** — the agent never introduces its own training or memory
   as if it belonged to the material, even when it privately disagrees with a source.
3. **Probing** — when a statement has more than one gap, the agent names the gap before
   picking a question, using one of three patterns: a mechanism probe (what causes this
   claim?), a boundary probe (where would this stop holding?), or a distinction probe
   (how does this differ from a similar term?). Whichever gap the statement actually has
   picks the pattern, not habit.
4. **Gate** — the statement only fixes on an explicit, unambiguous confirmation, and
   getting there is hardened two ways: a finished draft is never shown until at least one
   open probe-and-answer round has produced real content, and the confirmation question
   itself always stays open ("what's missing or wrong?") rather than inviting a binary
   yes/no rubber-stamp. A pause, a topic change, or a rubber-stamped proposal doesn't
   count; a rubber-stamp gets probed once more before the gate can pass.
5. **Noticing a tension** — if something in real tension with the material comes up
   mid-session, it's never acted on or leaked into the statement. Once the gate passes,
   the agent asks once whether to flag it for later.

## Usage

> Let's ground this: [whatever you're working through]

## Installation

```bash
npx skills add andarwaly/slipbox
```

See the [skill source](../../skills/slipbox/grounding/) for the full agent-facing
instructions.
