# using-slipbox

`using-slipbox` is the shared runtime engine for the Slipbox skill family.

The responsibility split is:

specialist → `/using-slipbox` → `.slipbox/bin/slipbox`

Specialists make semantic decisions. The engine routes named actions, creates recoverable local work, invokes `/write-checks` before publication, and keeps Evergreen candidates, links, source maps, and Git finalization separate. The bundled CLI owns validation, path safety, atomic mutations, cache identity, tombstones, and isolated staging.

Work is always local and untracked. Source-map cache persistence is configured independently as local or tracked. Prefixes apply to filenames and exact link targets; H1s remain clean.

See the skill's [agent-facing instructions](../skills/using-slipbox/SKILL.md) and its progressive [references](../skills/using-slipbox/references/).
