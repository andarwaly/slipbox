<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://shieldcn.dev/header/grid.svg?title=%2Fslipbox&amp;subtitle=Ground+yourself+to+the+source&amp;logo=lu%3AArchive&amp;align=left&amp;mode=dark">
  <source media="(prefers-color-scheme: light)" srcset="https://shieldcn.dev/header/grid.svg?title=%2Fslipbox&amp;subtitle=Ground+yourself+to+the+source&amp;logo=lu%3AArchive&amp;align=left&amp;mode=light">
  <img alt="/slipbox" src="https://shieldcn.dev/header/grid.svg?title=%2Fslipbox&amp;subtitle=Ground+yourself+to+the+source&amp;logo=lu%3AArchive&amp;align=left&amp;mode=light">
</picture>

[![npx skills add andarwaly/slipbox](https://shieldcn.dev/badge/npx-skills%20add%20andarwaly%2Fslipbox-000000.svg?variant=secondary)](https://github.com/andarwaly/slipbox)
[![License: MIT](https://shieldcn.dev/github/license/andarwaly/slipbox.svg?variant=secondary)](./LICENSE)

Note-making is thinking. Read, write, connect, re-read, synthesize, think, write again, that's the actual pipeline, and I keep skipping most of it. I read constantly and almost never write any of it down. Too lazy for the process, honestly.

Handing that whole job to an agent doesn't fix the laziness, it just hides it. Notes get dumped and filed, and it feels like understanding happened, but the thinking never did. That part, working out what a source actually means and where it argues with something I already believe, can't be outsourced. It can only be helped along.

This is heavily inspired by Matt Pocock's grilling skill. I saw it and thought, hey, maybe I could build one focused specifically on holding the user to the source instead of holding them to a plan. Built first for myself, so it has to actually help me learn something, not just produce a nicer-looking note.

So this isn't an agent that writes notes for me. It's the opposite. It grounds every claim back to the source instead of paraphrasing it away, asks me questions instead of handing me summaries, and drags my old notes back into the conversation so they can argue with the new one.

The pipeline itself: clip a source, ground discussable ideas from it into notes, or run whole-corpus passes to find patterns.

```
clip-resource → make-literature-note / make-reference-note / make-evergreen-note
find-connections (whole-corpus pass, run separately)
```

## Install

```bash
npx skills add andarwaly/slipbox
```

Run `/setup-slipbox` once per vault before any peer operation. Setup is self-contained: it checks prerequisites, discovers the vault's conventions and writing style, installs the `slipbox` CLI, and creates the runtime state used by every other skill.

`/using-slipbox` is the mandatory shared runtime for peer operations. Skills that create, revise, checkpoint, publish, link, cache, recover, or finalize work must use it rather than writing vault artifacts or invoking the CLI directly.

Migrated stateful workflows use the shared `/using-slipbox` runtime. It gives
each migrated operation a recoverable `work_id`, checkpoints interrupted work under
`.slipbox/work/`, runs `/write-checks` before publication, and delegates atomic
filesystem changes, cache handling, link tombstones, and optional Git commits to
the installed `.slipbox/bin/slipbox` CLI. Work is always local; source-map cache
persistence is independently `local` or `tracked`. The runtime supports
`resource`, `literature`, `reference`, `evergreen`, and `migration` work kinds.
Specialist workflow migration to this contract is shipped separately; this
runtime documentation describes the shared interface only.

The Resource, Literature, Reference, and Evergreen workflows are regression-tested end to end across
concise concepts, named frameworks, tools, events, creative works, insufficient
coined terms, disputed definitions, warrant-only extensions, bounded
recomposition, legacy-note recovery, and immediate Literature handoff. These
cases preserve source posture and uncertainty while exercising the shared
recoverable-work and publication contract.

## Skills

- **[setup-slipbox](./docs/setup-slipbox.md)**: one-time onboarding, vault conventions, writing style, `slipbox` CLI install. Run once per vault.
- **[clip-resource](./docs/clip-resource.md)**: fetches a URL and freezes it as a Resource, for anyone without a clipper tool.
- **[find-connections](./docs/find-connections.md)**: scans literature notes for candidate links, sparked ideas, and Reference/Person/Location/Organization recurrence across your notes.
- **[grounding](./docs/grounding.md)**: the Socratic-discussion engine underlying the note-writing skills.
- **[using-slipbox](./docs/using-slipbox.md)**: shared recoverable work, publication, cache, link-ledger, and Git runtime actions.
- **[ground-me](./docs/ground-me.md)**: a bare grounding session, no note-type commitment, nothing gets written.
- **[make-literature-note](./docs/make-literature-note.md)**: grounds a clipped source into a literature note, the source's own Claim, in your words.
- **[make-reference-note](./docs/make-reference-note.md)**: synthesizes a reference note from one or more sources, accumulating knowledge on a single topic across sessions.
- **[make-evergreen-note](./docs/make-evergreen-note.md)**: grounds a synthesis across notes into an evergreen note, your own original Take.
- **write-checks**: internal. Checks a note draft against vault style before any note-writing skill commits it. Runs automatically, not invoked directly.

For per-skill detail, see [docs/](./docs/README.md). For the domain vocabulary (Resource, Claim, Take, Atomicity, and the rest), see [CONTEXT.md](./CONTEXT.md).
