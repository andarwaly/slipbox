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

The pipeline itself: clip a source, surface discussable ideas from it, ground one into a note.

```
clip-resource → surface-ideas → ground-claim / ground-term / ground-my-take
```

## Install

```bash
npx skills add andarwaly/slipbox
```

Run `/setup-slipbox` once per vault before anything else. It discovers your vault's conventions and writing style, and initializes `idea.db`.

## Skills

- **[setup-slipbox](./docs/setup-slipbox.md)**: one-time onboarding, vault conventions, writing style, `idea.db` init. Run once per vault.
- **[clip-resource](./docs/clip-resource.md)**: fetches a URL and freezes it as a Resource, for anyone without a clipper tool.
- **[surface-ideas](./docs/surface-ideas.md)**: pulls 5-10 discussion-worthy candidates and recurring terms out of a clipped Resource.
- **[grounding](./docs/grounding.md)**: the interview engine underneath every `ground-*` skill below.
- **[ground-me](./docs/ground-me.md)**: a bare grounding session, no note-type commitment, nothing gets written.
- **[ground-claim](./docs/ground-claim.md)**: grounds a candidate into a literature note, the source's own Claim, in your words.
- **[ground-term](./docs/ground-term.md)**: grounds a recurring term into a Term note that accumulates across sessions.
- **[ground-my-take](./docs/ground-my-take.md)**: grounds a synthesis across notes into an evergreen note, your own Take.
- **write-checks**: internal. Checks a note draft against vault style before any `ground-*` skill writes it. Runs automatically, not invoked directly.

For per-skill detail, see [docs/](./docs/README.md). For the domain vocabulary (Resource, Claim, Take, Atomicity, and the rest), see [CONTEXT.md](./CONTEXT.md).
