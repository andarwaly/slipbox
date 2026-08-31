# Task 1 implementation report

Implemented the Literature source-point contract.

- Added regression assertions requiring `Source Points` and rejecting live `Key Claims` and the universal author-argument question.
- Reworked `CONTEXT.md` and the shipped glossary with Core Idea, Source Point, reading context, source posture, and source-owned/reader-owned proposition boundaries.
- Renamed `writing-a-claim.md` to `writing-a-source-point.md` and added independent-interpretability, attribution, and certainty checks.
- Updated live skill, documentation, fixture, and cross-reference terminology; historical planning material remains unchanged.

Verification:

- `jq empty tests/make-literature-note/evals.json`
- Confirmed the old reference file is absent and the new reference file exists.
- `git diff --check`
