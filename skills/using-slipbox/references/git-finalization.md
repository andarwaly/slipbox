# Git finalization

Git finalization is opt-in according to the vault's configured `git` policy. Confirm the work is ready, stage only the isolated artifact and required index paths, and preserve the work manifest until the commit result is known. A failed commit becomes recoverable `commit-failed` work; do not report publication as finalized. Commit style detection and activity trailers come from configuration, not ad hoc inference in this engine.

Use the CLI and repository Git help for exact flags. Never stage `.slipbox/work/`; cache staging follows its independent persistence policy.
