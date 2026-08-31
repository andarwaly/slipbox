# Task 4 report

## Round 1

- Routed out-of-band fidelity corrections through staged `draft.md` and `/using-slipbox` CAS publication, with expected-fingerprint conflict handling.
- Replaced contradictory eval expectations for exhaustive source audits, private authoritative backlogs, and full-Gate incremental writes.
- Aligned Blank/not-started source reading with the read-alone versus collaborative choice; guided reading is used only for collaboration.
- Standardized final validation language around the staged artifact and transactional publication.
- Verification: `ruby -e 'require "json"; JSON.parse(File.read("tests/make-literature-note/evals.json"))'` and `git diff --check` pass.

## Round 2

- Made `<staged-draft>` the explicit pre-publication validation target while retaining `<saved-path>` for post-publication CLI validation.
- Added eval coverage for Blank/not-started read-alone versus collaborative dispatch and staged out-of-band correction CAS guarantees.
- Verification: JSON parsing and `git diff --check` pass.
