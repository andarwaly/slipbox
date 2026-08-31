---
name: make-reference-note
description: Synthesize an already-grounded Reference note from the literature
  notes that wikilink to it — pulls in each note's grounded characterization,
  reconciles them into one definition, presents for confirmation, writes.
disable-model-invocation: true
license: MIT
metadata:
  version: "1.9.0"
---

# Make-reference-note

Bold terms in this file are defined in `GLOSSARY.md`. This skill never runs
`/grounding` — that already happened upstream, at the claim level, inside the
literature notes whose `## Key Concepts` wikilink to this reference; this skill only
pulls those already-grounded characterizations back out, reconciles them, and writes.
At runtime, resolve that glossary from the installed vault path `.slipbox/GLOSSARY.md`;
the repository `CONTEXT.md` is authoring-only and is not runtime input.

## Prerequisite

- MUST: `.slipbox/AGENTS.md` exists — confirms `setup-slipbox` ran to completion.
- NEVER: proceed without it. Stop and tell the user to run `setup-slipbox` first.
- NEVER: call bare `slipbox` — always `.slipbox/bin/slipbox`, which isn't guaranteed to be on `PATH`.

## Take the candidate

Named directly, only — the user says which reference they want written, whether they
thought of it themselves or because `find-connections --references` surfaced it as a
recurrence candidate. There is no backlog this skill pulls from itself; recurrence is
derived on demand by `find-connections`, not surfaced into a queue this skill owns.

Use `.slipbox/bin/slipbox config get paths.reference` to locate the folder, checking for
a Reference note for this candidate there — not an assumed `reference/` folder —
before writing. Apply the `.slipbox/bin/slipbox config get filenames.reference` casing convention:

- **New reference** — no note exists. Proceed to gather characterizations.
- **Extending** — a note already exists. Read it in full now. Its accumulated text is
  the working synthesis of everything before it, not just a resource list to append
  to.

## Gather the grounded characterizations

Start or resume Reference work for the candidate `/using-slipbox`. The work
manifest's `kind` is `reference`, and its `activity` is one of `create`,
`recompose`, or `extend-provenance`. Keep the work local under
`.slipbox/work/<work_id>/`; a Reference work directory contains:

- `manifest.json` — target and contributing-source identities plus starting fingerprints;
- `synthesis-map.json` — the reconciled evidence map (see `references/synthesis-map.md`); and
- `draft.md` — the complete bounded Reference draft, including frontmatter.

Checkpoint the reconciled synthesis and bounded draft `/using-slipbox` after
the source-resolution/admission boundary and again after user confirmation.
There is no permanent synthesis cache: `synthesis-map.json` is transient work
state and is discarded with the work item after publication.

Find every final Literature note whose `## Key Concepts` wikilinks to this candidate (this
is what `find-connections --references` already surfaced recurrence over — re-derive
or reuse that same set here). For each one:

- Read the Literature note's own grounded treatment of the term — the characterization
  the user was already held to via `make-literature-note`'s `/grounding` session for that
  note. Do not re-interview the user about it; it's already settled at the claim
  level.
- Resolve that note's configured Literature `source` field to the original Resource.
  Verify the resolution against the Resource and source-map cache when available;
  report and exclude unresolved or mismatched sources until repaired.
- Deduplicate resolved Resource paths/links by canonical Resource identity. A Resource
  is recorded once even when several Literature notes point to it.
- Note where characterizations agree, add distinct facets, or conflict. Never write a
  source-by-source dossier.

If a source touching this candidate has not gone through `make-literature-note` (no
literature note with a grounded Key Concepts wikilink to it exists yet) — stop that
source here, do not synthesize from it, and tell the user it needs to go through
`make-literature-note` first. Continue synthesizing from whatever already-grounded sources
do exist; don't block the whole write on one ungrounded source unless it's the only
one.

## Route the evidence

Admission is a deterministic decision, separate from recurrence and from the user's
request to write a note. Apply the checks in the order defined in `.slipbox/GLOSSARY.md`:

- Exclude people, locations, and organizations first; they remain surfacing-only
  `Mentioned` referents.
- Require a stable lookup identity, source independence, bounded scope, and a natural
  unit. A coined label that is meaningful only inside one source has not passed source
  independence.
- Adapt the evidence threshold to the claim. One authoritative primary source may admit a
  settled standard. Otherwise, require two independently grounded sources whose support
  does not merely repeat one another. Duplicated, syndicated, or otherwise non-independent
  sources count as one support path, not two.
- Treat materially contested variants as unresolved until independent support covers the
  competing definitions, or the user resolves the conflict explicitly. Never silently pick
  the most convenient variant.

The result is either `admitted`, with the grounded inputs and the reason the evidence is
sufficient, or `unresolved`, naming the failed check and the support still needed. Never
create a provisional Reference artifact. If the result is unresolved, report the missing
support, leave the candidate's wikilink untouched, and do not create a `work_id` unless an
artifact operation has actually begun. A direct user invocation does not waive these gates.
Recurrence count is discovery evidence only; it is never itself a warrant for admission.

## Synthesize and confirm

Reconcile the gathered characterizations into one bounded lookup entry. Follow
`references/bounded-lookup.md`: clean H1, one concise definition, essential
characteristics/components, and optional disambiguation only when a common confusion
materially impairs lookup. The body adapts across concepts, frameworks, tools, events,
and creative works; it has no subtype-specific required headings.

Provenance is frontmatter only. Populate only the configured Reference fields
(`type`, `created`, `aliases`/`alt_names`, and `sources`); `sources` contains the
deduplicated original Resource links, never Literature-note links. Do not add body
`Sources`, mechanism, application, implications, or `Open Questions` sections.

Record every contributing Literature path, resolved Resource identity,
source-map fingerprint (when available), admission evidence, agreements,
conflicts, and proposed changes in `synthesis-map.json`. This map is the audit
trail for the current work, not a second note and not a source-by-source body.

- Where characterizations agree or add distinct facets, merge them into one coherent
  definition rather than listing each source's phrasing separately.
- Where characterizations conflict, surface the conflict to the user rather than
  silently picking one — resolve it the same way any other flagged tension in this
  family gets handled: if the user opts in to flagging it rather than resolving it now,
  insert it into the evergreen backlog before moving on to writing. The
  installed `.slipbox/AGENTS.md` is the canonical reference for backlog
  semantics and lifecycle; this skill retains the command it executes:

  ```bash
  .slipbox/bin/slipbox evergreen add --slug <draft-slug> --reason "<tension description>"
  ```

- Present the bounded synthesized definition and resolved Resource provenance to the
  user for confirmation before writing
  anything to disk. If extending an existing note, the user's confirmation must keep
  the result consistent with what's already recorded — not silently contradict it.

## Write — new reference

For a new candidate, use activity `create` and write fresh:

- Run a `/write-checks` session with `artifact-kind: note` and `note-type: reference`, passing the Reference field list (`type`,
  `created`, `sources`, and `alt_names`) — it resolves each field's mapping, formatting,
  zone placement, and title prefix, and checks the draft's style and humanize signals.
- Resolve `prefixes.reference` and the configured `alt_names` field before assembling
  frontmatter. When the Reference prefix is a string, add the clean concept display
  name (the concept before that generated prefix, preserving the user's casing) to the
  alternate-name values. When the prefix is `false`, use only explicit alternate names.
- Merge the inferred name before explicit alternate names, preserving first spelling and
  order while deduplicating by case-insensitive comparison. Write the resulting list to
  the mapped `alt_names`/`aliases` field. This alias rule applies only to Reference notes.
- Write into the folder from `.slipbox/bin/slipbox config get paths.reference`, filename per
  `.slipbox/bin/slipbox config get filenames.reference` casing convention.
- Re-read the target path from disk before assembling the complete temporary draft.
- Assemble the frontmatter from `/write-checks`' returned fields into the complete
  temporary draft.
- Validate the complete temporary draft with `/write-checks`, including the complete
  basename and exact H1. This pre-write validation is a hard gate: write only after it
  passes. Then write the validated draft, re-read the saved path, and run
  `.slipbox/bin/slipbox note validate --type reference --path <saved-path>
  --basename "<complete basename>.md" --title "<exact H1>"`; a failed post-write
  check blocks success.
- Filename collision → stop and ask, never auto-disambiguate.

The generated basename and link target use the exact configured Reference prefix;
the H1 remains the clean, unprefixed concept name. A per-link display alias is a
separate concern and must not be used as the frontmatter alias value.

## Stage and publish Reference work

Use these concrete `/using-slipbox` actions for every admitted operation:

- Start or resume Reference work for the candidate `/using-slipbox`, selecting
  `create`, `extend-provenance`, or `recompose` and recording the target's
  starting fingerprint in `manifest.json`.
- Checkpoint the reconciled synthesis and bounded draft `/using-slipbox`.
  Write the complete candidate note to `draft.md`; do not write the vault target.
- Stage `mutations.json` with one artifact mutation for the Reference target,
  whose `expected_fingerprint` is the manifest fingerprint (or `null` for a
  new target), and a replacement path inside the work directory. For every
  extension, include the Resource→Reference link mutation in that same list,
  targeting `links.jsonl` with its own expected fingerprint and one `extends`
  event replacement.
- Checkpoint the confirmed draft `/using-slipbox`, set the manifest to
  `ready-to-finalize`, then call `work finalize <work_id>` once. Publication is
  the single compare-and-swap transaction for the note and link mutations;
  never publish the note first and add the link afterward.
- If validation, preflight, or finalization fails, preserve the work and its
  diagnostics, inspect/resume it only after rechecking fingerprints, and report
  failure or repair-required status. Do not claim publication or discard work
  without the user's explicit confirmation.

## Write — extending an existing reference

**This is the collision-safe path. Follow it exactly.**

Use activity `extend-provenance` when the new grounded source only strengthens
the existing warrant. Use activity `recompose` when it changes the definition
boundary or any essential characteristic.

`sources` already has its resolved mapping and formatting from the reference's first
write — no field resolution needed here.

1. Run a `/write-checks` session with `artifact-kind: note` and `note-type: reference` in checks-only mode (no field list).
2. Re-read the file from disk immediately before assembling the new draft (state can
   have changed since the read in "Take the candidate").
3. Re-read the existing note and staged synthesis map. If the new source only strengthens warrant, keep existing body bytes stable and append the new resource(s) to the `sources` frontmatter array, formatted per the
   note's existing recorded `type` (list) and `wikilink` flag, to assemble the complete
   temporary draft. Never overwrite the file wholesale.
4. If the source materially changes the definition boundary or essential characteristics, preserve the prior synthesis in the map's `agreements`/`conflicts`, propose only required body changes, and stage a bounded replacement under activity `recompose`.
5. Validate the complete assembled draft with `/write-checks` before writing. This
   pre-write validation is a hard gate: write only after it passes. Then re-read the
   saved path and re-validate it with `slipbox note validate`. Repair only mechanical
   defects; semantic conflicts remain stop-and-ask cases.
6. Insert a `links` row recording the relationship — this reference's own note is the
   target, the resource being folded in is the source:

   ```bash
   .slipbox/bin/slipbox links add --source <this-resource-slug> --target <reference-note-slug> --rel extends
   ```

## Done

- New reference: the file on disk reflects the confirmed, synthesized definition.
- Extension: the file on disk reflects every source that has ever fed it, old and new;
  a `links` row (`rel_type: 'extends'`) connects the new resource to the reference
  note.
- Recomposition: only the bounded body fields required by the changed synthesis are
  replaced; unchanged aliases and provenance are preserved, and compare-and-swap
  publication blocks concurrent target edits.
- Any flagged tension is logged in the evergreen backlog.
- The user is told the file path.
