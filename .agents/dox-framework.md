# DOX framework

Doc-maintenance rules for this repo's `AGENTS.md`/`CLAUDE.md` hierarchy. This file is purely about *how to maintain the docs* — what this project actually is, its structure, and its workflow live in the root `AGENTS.md`, not here.

Adapted from [agent0ai/dox](https://github.com/agent0ai/dox).

## Core Contract

- `AGENTS.md` files are binding work contracts for their subtrees.
- Work products, source materials, instructions, records, assets, and durable docs must stay understandable from the nearest applicable `AGENTS.md` plus every parent `AGENTS.md` above it.
- `CLAUDE.md` is a symlink to `AGENTS.md` at every level that has one — there is exactly one file to read or edit, never two copies to keep in sync.

## Hierarchy

- Root `AGENTS.md` is the project-wide doc: purpose, structure, workflow, guardrails.
- Child `AGENTS.md` files (where they exist) own domain-specific rules for their own subtree.
- The closer a doc is to the work, the more specific and practical it must be. If a closer doc and a parent doc conflict, the closer doc controls local work details, but no child doc may weaken this framework itself.
- There is no per-file "Child DOX Index" repeated at the bottom of every `AGENTS.md`. A single global index lives at `.agents/index.md` instead — see below.

## Read Before Editing

1. Read the root `AGENTS.md` (you should already be here, per its own mandatory pointer).
2. Check `.agents/index.md` for the full map of which `AGENTS.md` exists where, and what each one governs.
3. Identify every file or folder you expect to touch, and read the nearest governing `AGENTS.md` for each — walking from the repo root down, not skipping levels.
4. Use the nearest `AGENTS.md` as the local contract; parent docs still apply for anything the local doc doesn't cover.

Do not rely on memory. Re-read the applicable chain in the current session before editing.

## The delta test — when a folder gets its own `AGENTS.md`

A folder gets its own `AGENTS.md` **only when it has at least one rule, constraint, or workflow that isn't already fully covered by inheriting its parent's doc.** Not because the folder "feels" important, and not merely because it's a durable boundary — a durable boundary with no rules of its own beyond what its parent already states does not qualify.

When creating one:
- **Update `.agents/index.md`** with the new file's path and a one-line annotation of what it governs. This is the only index-maintenance step required — there is no per-file Child DOX Index to also update.
- Add the child doc's own one-line pointer back to `.agents/dox-framework.md` and `.agents/index.md`, for sessions that start scoped inside that folder rather than at the repo root.
- Leave "Work Guidance" / "Verification" sections empty if no specific standard or check exists yet — do not invent one to fill space.

## Style

- Keep docs concise, current, and operational.
- Document stable contracts, not diary entries — history belongs in a `decision.md` log, not in `AGENTS.md`.
- Put broad rules in parent docs, concrete details in child docs.
- Prefer direct bullets with explicit names.
- Do not duplicate rules across files unless each scope genuinely needs a local variant.
- Delete stale notes instead of explaining history.
- Trim obvious statements, repeated rules, misplaced detail, and warnings for risks that no longer exist.

## Update After Editing

Every meaningful change requires a pass over the affected docs before the task is done. Update the closest owning `AGENTS.md` when a change affects:

- purpose, scope, ownership, or responsibilities
- durable structure, contracts, workflows, or operating rules
- required inputs, outputs, permissions, constraints, side effects, or artifacts
- user preferences about behavior, communication, process, organization, or quality
- `AGENTS.md` creation, deletion, move, or rename (also update `.agents/index.md`)

Update parent docs when parent-level structure, ownership, or workflow changes. Update child docs when a parent change alters local rules. Remove stale or contradictory text immediately. Small edits that don't change behavior or contracts may leave docs unchanged, but this pass still must happen.

## Missing-file safeguard

If any file this framework or an `AGENTS.md` points to is missing — `.agents/dox-framework.md`, `.agents/index.md`, a cross-referenced doc, anything — **stop and flag it**. Do not silently continue as though the pointer didn't exist. A missing file is either a real gap (something wasn't created yet) or a broken reference (a rename, a typo) — both need a human's attention, and both look identical to a silent skip.

## Closeout

1. Re-check changed paths against this framework.
2. Update nearest owning docs and any affected parents or children.
3. Refresh `.agents/index.md` if any doc was created, deleted, moved, or renamed.
4. Remove stale or contradictory text.
5. Run existing verification when relevant.
6. Report any docs intentionally left unchanged, and why.
