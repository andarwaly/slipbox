---
name: surface-ideas
description: Surface 5-10 discussion-worthy candidate ideas from a clipped Resource, and detect recurring reference-worthy terms — explore, no structure committed yet. Does not write a literature or reference note itself; that's write-literature-note's or write-reference-note's job, run separately.
disable-model-invocation: true
license: MIT
metadata:
  version: "1.0.0"
---

# Surface Ideas

This skill takes a Resource file and surfaces candidate ideas from it, and separately flags any reference-worthy terms it names. It does not decide which candidate is worth writing up, and it does not write the literature note or reference note itself: that's `write-literature-note`'s or `write-reference-note`'s job, run separately, possibly in a different session.

## 0. Prerequisite: `.slipbox/config.json` must exist

Check first, before anything else. This skill writes rows to `.slipbox/idea.db`, which is only created by `setup-slipbox` alongside `config.json`.

If `.slipbox/config.json` is absent: stop. Do not proceed to any other step. Tell the user to run `setup-slipbox` first, then re-run this skill.

## 1. Take the Resource

Ask for the path to an already-captured Resource file: one written by `clip-resource`, or dropped in by an external tool such as Obsidian Web Clipper or Readwise. Either source is fine. Treat the file as frozen: read it, never edit it.

## 2. Surface pass

Read the Resource and surface 5-10 candidates. This is an explore pass, not an exploit pass: the goal is a spread of open questions worth discussing, not a shortlist of answers.

Each candidate is a question plus the motivation for asking it. Neither half is a conclusion. A candidate that already states what the idea means, or what follows from it, has skipped past exploration into the discussion that's supposed to happen later, in `discussion`. Watch for this shape and reject it:

> Reason: "Knowledge is most useful when broken into atomic, standalone ideas that can be freely recombined."

That's a finished claim, not a question. It reads like this instead:

> Question: What would it mean to treat a note as a single reusable idea rather than a container for everything related to a topic?
> Motivation: The source argues for atomic notes but never says what breaks when a note holds more than one idea, which is worth pressure-testing.

If a draft candidate reads like the first example, rewrite it as a question before it goes anywhere near `seeds`.

**Done when:** you have 5-10 candidates in question-plus-motivation form, none of them a conclusion. Fewer than 5 is fine if the Resource genuinely doesn't support more; don't pad the count with weak candidates.

## 3. Diversity lens: Idea Compass

Don't just ask what the source leaves unanswered — that's one direction among several. Use the Idea Compass to spread candidates across:

- **Origin** — what led the source to this idea? What is it responding to, building on, or reacting against?
- **Similar** — what else, inside or outside this source, resembles this idea, and is the resemblance real or superficial?
- **Competes** — what would someone who disagrees with this say instead? What's the strongest counter-framing?
- **Leads to** — what does this idea imply or make possible next, if taken seriously?

A set of candidates that all point in the same compass direction (five "what does this leave unanswered" questions) is not a diverse surface pass, even if each one individually is well-formed. Check the spread before finishing Step 2.

## 4. Specificity bar

A candidate is complete only when its `reason` passes this test: **could this exact reason be copy-pasted onto an unrelated resource and still make sense?** If yes, it's too generic — rewrite it before surfacing.

This is the actual bar for a "strong" candidate, not length or polish. A rough-but-specific candidate passes:

> Reason: This source claims atomic notes prevent "orphaned context," but never defines what counts as one idea versus two related ones — worth pressure-testing against a source that argues the opposite.

A smooth-but-generic one doesn't, even though it reads well:

> Reason: This is an interesting idea that connects to broader themes in the field and deserves further exploration.

The second could sit under any candidate from any resource unchanged. If a `reason` could survive that swap, it isn't done yet.

## 5. Reference-term recurrence detection

For each candidate, also check whether it names a **term that exists and could be looked up independent of this source** — a named concept, method, tool, or bias with a stable label (e.g. "confirmation bias," "CRDT," "the Zeigarnik effect") — versus **this source's own argued organizing scheme**, even one with labeled sub-parts that only make sense inside this source's argument.

If a candidate names an independently-existing term, query `seeds` for whether that term has already surfaced from a *different* resource:

```sql
SELECT slug, resource, status FROM seeds WHERE target_type = 'reference' AND reason LIKE '%<term>%';
```

- **Not found** — insert a new `seeds` row: `type: 'raw', target_type: 'reference', origin: 'surface'`.
- **Found** (an existing row/note for this term, from another resource) — still insert a new `seeds` row for *this* resource's mention. It needs its own row so it can later `links`-extend the existing reference note (`rel_type: 'extends'`) rather than being silently dropped.

This lookup is cross-resource by design — it's the only place in the whole skill family that queries across resources at surface time. Contrast with literature-destined candidates (Step 6), which are never deduped across resources.

## 6. No cross-resource dedup for literature candidates

This is intentional, not a gap: each literature-destined candidate is anchored to *its own* source's argument. Two similar-sounding questions surfaced from different resources each get their own `seeds` row — never merged, never deduped against each other. Noticing that two resources are actually talking about the same thing is `discussion` (evergreen mode)'s job, not this skill's. Don't reach across resources here except for the reference-term lookup in Step 5.

## 7. Repeat-run dedup, same-resource only

Before writing, check for a natural-key collision against existing rows *for this resource only* (`resource = '<slug>'`): same slug, or a fuzzy match on question text. A near-duplicate found this way is not auto-merged and not silently skipped — ask the user whether to surface it anyway or skip it. This check never looks at other resources; that would conflict with Step 6.

## 8. Dismiss at surface time

Some candidates that come up during the pass aren't worth keeping at all: too thin, too redundant with another candidate, or not really a question. Drop these before writing anything — no `seeds` row is written for them at all. That's different from a candidate dismissed later, during `discussion`'s pick step, which does get a row, with `status: 'dismissed'` and `reason` left exactly as it was written at surface time.

## 9. Write

Insert one `seeds` row per surviving candidate:

- `slug`: a fresh question-slug (renamed later at write time to a confirmed-claim-slug)
- `resource`: this resource's slug
- `type`: `'raw'`
- `target_type`: `'literature'` by default, or `'reference'` when Step 5's check applies
- `status`: `'to-discuss'`
- `origin`: `'surface'`
- `reason`: the question and motivation from Step 2 (or the term-focused reason from Step 5)
- `created_at` / `updated_at`: leave unset — the schema's `DEFAULT (datetime('now'))` fills them in

**Done when:** every surviving candidate is a `seeds` row, or, if none survived Step 8, zero rows were written. A null result is a complete run, not a failure; report the count either way.
