# vault-unconfigured

Deliberately empty — no `.slipbox/config.json` anywhere in this fixture. Covers the collapsed "config absent" case (no vault, vault with no setup, or vault mid-setup — `clip-resource` can't distinguish any of these, since it only ever checks for `.slipbox/config.json`'s presence).

This file exists only so the empty directory survives git; it is not itself part of the fixture.
