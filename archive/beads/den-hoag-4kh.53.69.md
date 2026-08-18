# den-hoag-4kh.53.69 — [DECISION 4] what may a kind-include string name? One answer makes a load-bearing den-hoag fixture wrong, and it blocks A4 guard

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.69` |
| status at evacuation | deferred |
| priority | P1 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:16:02Z by Jason Bowman |
| last updated | 2026-08-05T20:48:40Z |
| description bytes | 905 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

★ OWNER DECISION 4 -- WHAT MAY A KIND-INCLUDE STRING NAME?
A4's union guard (`aspects union policies`) MAKES THE SUITE PASS WITHOUT MAKING THE POLICY
WORK -- a policy named in a kind-include string STILL RESOLVES TO AN EMPTY STUB and
contributes nothing. It only APPEARS to work because the policy ALSO fires fleet-wide.
★★ AND `ci/tests/compat-expose-gather.nix` IS EXACTLY THIS SHAPE AND IS LOAD-BEARING IN
DEN-HOAG'S OWN FIXTURES. So the decision is not hypothetical -- one answer makes a shipped
fixture wrong.
⇒ EITHER such a string MAY name a policy AND IS ROUTED AS ONE, OR IT MAY NOT AND DEN-HOAG'S
OWN FIXTURES ARE WRONG. There is no third option that leaves both standing.
★ The pattern for the guard already exists: `compile.nix` guards a SIBLING ARM with
`registry ? ${ref.key}`.
BLOCKS A4 -- do not add the guard before this is answered, or it silences the error without
fixing the behaviour.

## Comments (0)

(none)
