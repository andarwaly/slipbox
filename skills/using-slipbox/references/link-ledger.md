# Link ledger

The link ledger is an append-only JSONL record of confirmed relationships. Add a link only after the specialist confirms exact source and target identities and a supported relation. Remove a link by appending a tombstone, retaining the prior record for auditability; never edit history in place.

Use the CLI's `links add`, `find`, and removal help for exact flags. JSON is the default output; table output is opt-in where supported.
