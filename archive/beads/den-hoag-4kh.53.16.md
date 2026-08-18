# den-hoag-4kh.53.16 — [N7] the containment edge is declared and not built — schema topology and the scope graph disagree, and den.attach already mints it

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.16` |
| status at evacuation | open |
| priority | P1 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:07:04Z by Jason Bowman |
| last updated | 2026-07-29T00:07:04Z |
| description bytes | 580 |
| notes bytes | 0 |
| comments | 1 |
| dependencies | `None` (None), `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

[N7] MEASURED. THE CONTAINMENT EDGE IS DECLARED AND NOT BUILT.
With `host.parent = "env"` in the schema, `env` and `host` are BOTH scope roots IN
PARALLEL: {'env:env0':'«root»', 'host:host0':'«root»', ...}. `den.attach` already mints
the edge WHEN USED (roots 6 -> 2).
⇒ The schema's declared topology and the built scope graph disagree, and the mechanism to
make them agree exists and is opt-in.
★ DO NOT FIX THIS BEFORE D1. D8 measured that materialising exactly this edge sends
`envPolicy` 2 -> 18 under presence-gating. The descent is correct and currently makes
firing worse.

## Comments (1)

### 1 — 2026-07-29T02:44:25 · Jason Bowman

★★ THIS EDGE IS REAL AS RECORDED AND ITS PREMISE HAS EXPIRED — recorded as a distinct fact rather than inferred, because the two are easy to conflate and the conflation would unblock this bead for the wrong reason.
N7's stated reason for depending on D1 is D8's envPolicy 2 -> 18 'under presence-gating'. ★ THAT WAS MEASURED WHEN __firesAtKinds WAS POPULATED AT ZERO — i.e. selection absent and ctx-presence the only gate. Measured now: pEnv = 1 on a 17-node fleet with 4 hosts and 12 cells present.
AND THE MECHANISM IS CLOSED STRUCTURALLY, not just numerically: node type is minted at exactly TWO sites — lib/build-roots.nix type = kindName and lib/fleet.nix type = leafDim — NEITHER a function of the parent graph. So indexByKind, which reads only .type, is EDGE-INVARIANT. Materialising the containment edge cannot change which rules are offered at which kinds.
⇒ THE D8 BLOWUP IS CLOSED BY D1'S DEFECT HALF, WHICH IS ALREADY SHIPPED — not by D1's resolution, which is not delivered. The edge should be retired on THAT basis, not on 'D1 is done'. (ARGUED from measured facts; the edge was NOT re-materialised via den.attach, so this is a reasoned closure rather than an executed one.)
★ N7's OWN DEFECT PREMISE RE-VERIFIED AND STANDS, unaffected by any of the above: with host.parent = "env" DECLARED, env:prod and all four hosts carry parent = null — FIVE PARALLEL ROOTS. The edge is declared and not built. That is the live defect this bead tracks and it is untouched.
EDGE LEFT IN PLACE PENDING THE CONTAINMENT MIGRATION (den-hoag-5ae), which is where the declared-not-built edge actually gets built. Removing it now would leave N7 reading as ready when its real enabler has not landed.
