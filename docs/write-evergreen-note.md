# write-evergreen-note

Turn a connective aha or an open-ended "let's think this through" into a new, purely original evergreen note — via a Socratic discussion grounded in what's actually in your vault. Notes can be revisited and evolved across sessions.

## When to use

Use this when you want to explore a connection between multiple notes, or work through a hunch, or think out loud. The result is an evergreen note — a statement that says something none of your individual cited notes said on their own. No fixed trigger: bring a rough question, a named note, or just "I keep coming back to this idea." The skill grounds the conversation in what you've already written, not in speculation.

## How it works

1. **No fixed trigger** — starts whenever you want to think something through. Bring one or more note names, a question, or just a hunch. No special format required.
2. **Resume check** — before starting new work, checks `.slipbox/discussions/` for any in-progress evergreen-note sessions. Offers to resume one if any exist.
3. **Placeholder row** — after you've answered the first substantive question, inserts a placeholder row in `idea.db` with a draft slug (e.g., `draft-tool-shapes-cognition`) while the discussion is still provisional.
4. **Discuss** — runs a Socratic conversation grounded in your vault's related notes (retrieved via full-text search). Retrieval, grounding, the purity rule (no mere restatement of cited notes), and the final rubric are all handled by the discussion skill.
5. **Write the note** — once the Take is confirmed, writes the finished evergreen note with frontmatter (`type: evergreen`, `created`, `derived-from: [...]`) and cites each related note with a stated reason in the body.
6. **Link the connections** — records which notes this one cites in `idea.db`, and updates the placeholder row with the final slug and path.
7. **Revisiting an existing note** — you can bring an already-discussed evergreen note back for fresh thinking at any later time. The skill re-reads the note from disk, runs discussion again, and can rewrite the note's content wholesale (unlike reference notes, which only append). On completion, `iteration` increments and `status` returns to `discussed`.

## Usage

Invoke it by name to start exploring a connection:

> Let's think through how these ideas connect.

Or bring specific notes:

> Can we connect note A and note B?

Or just think out loud:

> I keep coming back to the shape of how tools shape thinking.

## Installation

This skill ships as part of the `andarwaly/skills` collection:

```bash
npx skills add andarwaly/skills
```

See the [skill source](../../skills/slipbox/write-evergreen-note/) for the full agent-facing instructions.
