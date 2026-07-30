# slipbox

**Before anything else**: read [`.agents/dox-framework.md`](.agents/dox-framework.md) and [`.agents/index.md`](.agents/index.md) in full. If either file is missing, stop and flag it — do not proceed as if it simply doesn't apply.

## Purpose

Skills for a Zettelkasten-inspired, conversational note-taking pipeline: clip a source, surface discussable ideas from it, discuss one into a literature note, optionally spin off a reference note, optionally connect notes into an evergreen note.

Domain vocabulary (Resource, Literature note, Term note, Evergreen note, Claim, Take, Atomicity) is defined in [`CONTEXT.md`](CONTEXT.md) — read it before touching any skill's `SKILL.md`, and don't restate its definitions here.

## Structure

```
slipbox/                    ← repo root, this file's location
├── AGENTS.md                ← this file
├── CLAUDE.md                 ← symlink to AGENTS.md
├── CONTEXT.md                ← domain glossary — the four note/resource types, Claim vs. Take
├── .agents/
│   ├── dox-framework.md     ← doc-maintenance rules (read first)
│   └── index.md              ← index of every AGENTS.md in this repo
├── docs/                     ← human-facing doc per skill (README.md + one per skill)
├── skills/
│   ├── setup-slipbox/       ← one-time onboarding: vault conventions, idea.db init
│   ├── clip-resource/        ← fetches a URL, writes a frozen Resource
│   ├── surface-ideas/        ← surfaces discussion-worthy candidates + recurring terms
│   ├── grounding/            ← lean interview engine; user-invocable, like grilling
│   ├── ground-me/             ← bare passthrough wrapper, no note-writing
│   ├── ground-claim/          ← literature-note wrapper (was write-literature-note)
│   ├── ground-term/           ← term-note wrapper (was write-reference-note)
│   └── ground-my-take/        ← evergreen-note wrapper (was write-evergreen-note)
└── tests/
    └── {{skill-name}}/
        ├── evals.json         ← test cases: prompt, expected_output, assertions
        └── {{skill-name}}-workspace/   ← run outputs, one subfolder per iteration
```

`tests/` sits at repo root, sibling to `skills/` — never nested inside a skill's own folder. This keeps it out of every `npx skills add` per-skill install (same mechanism that keeps `CONTEXT.md` out of individual installs) while still shipping with a full clone of the repo.

## Workflow

- **Skill format**: follow the [agentskills.io](https://agentskills.io) spec — a directory with `SKILL.md` (`name`, `description` frontmatter; optional `license`, `metadata`, and `scripts/`/`references/`/`assets/` subdirs). Frontmatter extensions (e.g. `disable-model-invocation`) are fine anywhere; an unrecognized key degrades gracefully. Heading/prose style (no numbered step-headings, etc.) is governed workspace-wide by the root `AGENTS.md`'s "Skill-writing conventions" section — not restated here.
- **Docs**: every skill gets a human-facing page at `docs/{{skill-name}}.md`.
- **Distribution**: published to a public GitHub repo. Users install with `npx skills add andarwaly/slipbox` (or a specific skill within it).
- **Writing a skill or a change to one**: two phases, don't skip the second.
  - *Write*: draft grounded in the skill's own domain rules (`CONTEXT.md`) and this repo's format conventions above.
  - *Review*: is this skill stateless (pure input → output, no filesystem writes) or stateful (saves to the filesystem, improves across sessions)? Confirm the choice was deliberate. Then audit completion criteria, leading words, information hierarchy (what's inline in `SKILL.md` vs. pushed to `references/`).
- **Evals**: every skill carries `tests/{{skill-name}}/evals.json` — `prompt`, `expected_output`, optional `files`, and objective `assertions` (reserve subjective quality judgments for human review, not an assertion). Start with 2-3 varied prompts including one edge case; add assertions after seeing a first run's output. Run with the skill and without (or against the previous version) in a clean context each time. Track the with/without delta — pass rate, time, tokens.

## Guardrails

- A folder gets its own `AGENTS.md` only when it has a rule not already covered by inheriting this doc (the delta test — see `.agents/dox-framework.md`). Individual `skills/{{skill-name}}/` folders do not get their own `AGENTS.md` under this test.
- A Resource file, once written by `clip-resource`, is frozen — no skill in this family reopens it to edit, append, or correct it.
