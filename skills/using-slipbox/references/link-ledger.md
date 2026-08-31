# Link ledger

The link ledger is an append-only JSONL record of confirmed relationships. Add a link only after the specialist confirms exact source and target identities and a supported relation. Remove a link by appending a tombstone, retaining the prior record for auditability; never edit history in place.

Use `links add --source S --target T --rel cites|extends` to append an add event and `links remove --source S --target T --rel cites|extends` to append a removal tombstone. Removal is idempotent: removing an inactive edge succeeds with a warning. `links find` folds legacy rows (implicit adds), explicit add events, and tombstones in file order; a later add restores an edge. JSON is the default output; table output is opt-in where supported.
