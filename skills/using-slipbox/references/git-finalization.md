# Git finalization

Git finalization is opt-in according to the vault's configured `git` policy. Invoke `slipbox work commit <work-id> --yes` (or `--leave-uncommitted`) only after publication succeeds. Repository detection is runtime-only; manifests record per-path baseline status, blob identity, and worktree fingerprint.

Commit staging uses a temporary `GIT_INDEX_FILE` seeded from `HEAD`, then adds only successfully published allowlisted paths. The user's real index remains untouched, unrelated staged and unstaged changes are preserved, and normal Git hooks run. Pre-dirty affected paths are excluded and recorded as a safety downgrade. Subjects follow configured detected/fallback style and enabled activity/work-ID trailers.

Modes are `off`, `ask`, and `auto`. A hook or commit failure preserves validated files and marks the work `commit-failed` for retry.

Use the CLI and repository Git help for exact flags. Never stage `.slipbox/work/`; cache staging follows its independent persistence policy.
