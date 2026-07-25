---
name: discussion
description: Internal Socratic conversation engine for the slipbox family, three modes (literature/reference/evergreen). Invoked by write-literature-note, write-reference-note, and write-evergreen-note with their own framing; never invoked directly by name.
disable-model-invocation: true
license: MIT
metadata:
  version: "1.0.0"
---

# Discussion

This skill is never invoked by the user directly. `write-literature-note`, `write-reference-note`, and `write-evergreen-note` each call into it, naming their mode (`literature`, `reference`, or `evergreen`) and handing it whatever framing that mode needs (a source's claim, a term, a topic to think through). Everything in **Shared rules** applies to all three modes without exception. Each mode section below adds only what differs.

## Shared rules (all modes)

These hold regardless of which mode invoked this skill. Read this section once; it is not repeated per mode.

### One question at a time

Ask a single question, then wait for the user's answer before asking the next. Never dump two or more questions into one turn.

### INVARIANT #1: never draft the claim yourself

The agent never drafts the claim, definition, or connection. The whole assembly is built only from sentences the user actually typed. When the conversation calls for reflecting the emerging idea back ("distil" — see the evergreen section), that move quotes and lightly reshapes the user's own words for them to correct ("almost, actually…"). It never introduces phrasing of its own as if it were the content.

**Why this is a rule for an LLM specifically, not just good practice:** a human research assistant drafting on someone's behalf would still be putting the *user's* thinking into words, because the assistant has no other source of ideas to draw on. An LLM does — it can generate fluent, plausible-sounding claims from its training data that were never actually the user's thought, and the user may not notice the substitution because the phrasing reads as reasonable. The whole point of a slipbox is that every note traces back to the user's own thinking; a claim ghostwritten by the model breaks that traceability even when the words happen to be correct.

### Gate: explicit confirmation only

A claim, definition, or connection is fixed only when the user says something that explicitly confirms it — "yes, that's it," "fixed," or equivalent. Never infer the gate from a pause, a change of subject, or the conversation merely feeling settled.

**Why this needs stating explicitly:** an LLM has a strong prior toward treating a topic change or a lull as tacit agreement, because moving on is the conversationally smooth thing to do — a human assistant reads hesitation or silence far more skeptically by default. Left unstated, the model will round an ambiguous moment up to "confirmed" and write down something the user never actually signed off on.

### Anti-summary guard

If the user rubber-stamps a proposal without actually engaging with it, probe once more before treating the gate as passed. A claim, definition, or connection the user can't defend across one more exchange isn't fixed yet, no matter what they said.

### Mushy answers: keep grilling

A vague or hand-wavy answer is not raw material to polish into something coherent on the user's behalf. Flag the vagueness and ask again; don't fill it in.

### Resume-file discipline

**On start, before anything else:** list `.slipbox/discussions/` for files belonging to this mode and offer to resume one before offering to start new work.

**When to create the file:** only after the first substantive exchange — not after the first question is merely asked, but once the user has actually answered it. Write to `.slipbox/discussions/<slug>.md`:

```markdown
---
idea_slug: <slug>
mode: literature|reference|evergreen
phase: <mode-specific phase name>
resource: <resource slug(s), literature/reference modes only>
updated_at: <ISO8601>
---

## Draft (user's latest, verbatim)
...

## Open threads
- ...
```

`resource` carries whatever source(s) this session is grounding against (the one resource for literature mode, one or more for reference mode). It is what lets the calling skill resume a paused session without re-deriving that context from scratch — see each mode's own resume handling below. Evergreen mode omits it: the placeholder `evergreen` row it inserts already anchors the session by slug.

**Write it as an explicit step**, not an assumption: at each point this file needs creating or updating, actually do it — "write/update the resume file now." There is no default reason for an LLM to persist a file it wasn't told to persist; treat this as a required action in the flow, every time, not a background habit.

Bump `updated_at` at gate-relevant checkpoints (a phase fixed, a placeholder row inserted), not on every message.

**Lifecycle end:** the calling `write-*-note` skill deletes this file the moment it finishes writing the note and flips the corresponding row (`seeds` or `evergreen`). This skill never deletes it itself.

### Voice pass — three ordered sub-steps, run in this order, before any write

Run all three, in this order, immediately before writing the note (or the note section) to disk. None of these steps may introduce content beyond what the user confirmed.

1. **Fidelity** — re-read the user's confirmed sentences against the assembled note. Nothing may be added beyond what the user actually confirmed.
2. **Register** — load `.slipbox/style-profile.md` and sample 2-4 corpus notes of the same note type. Adjust connective tissue only (transitions, framing); confirmed claim/definition/Take sentences stay frozen, verbatim-first.
3. **Lint** — check the assembly's prose against `.slipbox/humanize-checklist.md`. Flag only a cluster of two or more signals together; never auto-rewrite — surface the flag and let the user decide. The user's own baseline habits, as recorded in the style profile, are never flagged even if they'd otherwise match a checklist signal.

## Mode reference files

Each mode's specific rules live in their own reference file — load only the one matching the mode this session was invoked with. For mode `literature`, load `references/mode-literature.md`. For mode `reference`, load `references/mode-reference.md`. For mode `evergreen`, load `references/mode-evergreen.md`.
