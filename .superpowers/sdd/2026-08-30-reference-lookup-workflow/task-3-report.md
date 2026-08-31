# Task 3 implementation report

## Round 1

- Added deterministic adaptive evidence routing to `make-reference-note`.
- Added matching admission guidance to `find-connections --references`: recurrence is
  discovery evidence, not warrant; duplicated sources count as one support path; contested
  variants remain unresolved.
- Added eval coverage for authoritative one-source standards, two independent grounded
  sources, duplicated/non-independent sources, contested variants, insufficient direct
  invocation, and recurrence that still fails admission.

## Verification

```text
python3 -m json.tool tests/make-reference-note/evals.json: PASS
python3 -m json.tool tests/find-connections/evals.json: PASS
git diff --check: PASS
```

## Round 2

- Clarified that `CONTEXT.md` is authoring-only and installed runtime vocabulary comes
  from `.slipbox/GLOSSARY.md`.
- Routed both affected skills explicitly to the installed glossary path.
- Strengthened the recurrence eval with explicit untouched-wikilink and no-work-id
  assertions.
- Replaced the brittle direct-invocation phrase assertion with assertions for the failed
  source-independence gate and required independent support.

## Round 3

- Replaced the remaining runtime admission-sequence references to authoring-only
  `CONTEXT.md` with the installed `.slipbox/GLOSSARY.md` path.
- Restored the direct-invocation eval's negative assertion that unresolved handling does
  not create a `work_id`.
