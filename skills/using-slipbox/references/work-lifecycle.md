# Work lifecycle

Work is local and untracked under `.slipbox/work/`, independent of source-map cache persistence. Use the installed `.slipbox/bin/slipbox` lifecycle commands; consult its `--help` output for exact flags. A work manifest records its ID, kind, activity, status, UTC timestamps, source/target identity and starting fingerprints, and affected paths.

The lifecycle is resumable: inspect before resume, verify fingerprints, checkpoint after meaningful boundaries, and preserve failed state for repair. Publication is transactional and must pass `/write-checks` before the CLI writes. Discard requires explicit confirmation and affects only the selected work directory.

CLI output is JSON by default. Table output is opt-in with `--format table` where supported. Every usage failure exits 2 and writes one JSON error object to stderr; runtime failures exit 1 with the same error shape, never a traceback.
