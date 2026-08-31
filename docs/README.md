# Slipbox Docs

Human-facing documentation for the slipbox skill family.

Run `/setup-slipbox` once per vault before any peer operation; setup is self-contained and installs the CLI plus all local runtime directories and configuration. The shared runtime contract is documented in [using-slipbox](./using-slipbox.md).

`/using-slipbox` is mandatory for peer operations that create, revise, checkpoint, publish, link, cache, recover, or finalize work. Peer skills supply semantic decisions; the runtime owns recoverable state and transaction boundaries.
It owns recoverable work, transactional publication, source-map cache policy,
link tombstones, and optional Git finalization. Specialist pages describe their
domain decisions; they do not redefine this shared contract.

End-to-end coverage includes independent multi-URL Resource clips, Resource→Literature→Reference handoff, reader-owned Literature→Evergreen candidates, concise Reference concepts, named frameworks,
tools, events, creative works, insufficient coined terms, disputed definitions,
warrant-only extensions, recomposition, legacy-note recovery, and immediate
Literature handoff, alongside the existing Literature source-shape cases, cache persistence modes, Git policies, safe pre-dirty downgrades, commit recovery, and migration batches.

- [setup-slipbox](./setup-slipbox.md) — One-time onboarding: discovers vault conventions, analyzes writing style, installs the `slipbox` CLI
- [clip-resource](./clip-resource.md) — Fetch one or more URLs and write each as a frozen Resource, for users without a clipper tool
- [find-connections](./find-connections.md) — Scan existing notes for missing links, sparked ideas, and recurring Reference or Mentioned candidates — takes an explicit `--references` or `--evergreen` mode flag (absorbed the old `find-terms` skill entirely)
- [grounding](./grounding.md) — Socratic-discussion engine with named techniques (Feynman, Maieutic, Elenchus, and others) underlying the note-writing skills
- [ground-me](./ground-me.md) — Bare grounding session: no note-type commitment, nothing gets written
- [make-literature-note](./make-literature-note.md) — Ground a clipped source into a literature note, the source's own Claim, in your words
- [make-reference-note](./make-reference-note.md) — Synthesize a reference note from one or more sources, accumulating knowledge on a topic across sessions
- [make-evergreen-note](./make-evergreen-note.md) — Ground a synthesis across notes into an evergreen note, your own original Take
- [write-checks](./write-checks.md) — Internal: checks a note draft against vault style and the humanize checklist before any note-writing skill commits it
- [slipbox (CLI reference)](./slipbox-cli.md) — The command surface every skill above talks to `.slipbox/` state through
