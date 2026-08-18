# den-hoag-4kh.53.60 — [G23+G26+G27] toposort cited to Kahn ships cubic, gen-edge kind carries a permanent byte-compat tail at three sites, and factor.nix bare path silently loses validation

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.60` |
| status at evacuation | open |
| priority | P2 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:14:16Z by Jason Bowman |
| last updated | 2026-07-29T00:14:16Z |
| description bytes | 1833 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

[G23+G26+G27] ARGUED. THREE gen-side items with stated resolutions.
★ G23: `toposort` IS CITED TO KAHN 1962 AND SHIPS CUBIC. `gen-edge/lib/toposort.nix` cites
Kahn's algorithm -- O(V+E) via a DECREMENTING INDEGREE ARRAY and a READY QUEUE. What ships
REBUILDS THE ENTIRE INDEGREE VECTOR AND RE-SORTS THE ENTIRE READY SET ON EVERY PICK:
`filter` O(n) + `sort` O(n log n) + `genList` over n each doing an O(n) `elem` scan, PER
STEP, OVER n STEPS = O(n^3). ★ The only complexity note in the file is about `predsOf`
construction, NOT THE LOOP. MITIGATING: on den-hoag this sits on the ORACLE path, not the
build path (see G12) -- ★ BUT THAT IS AN ACCIDENT, and n grows with fleet demand-edge count.
RESOLUTION: keep `predsOf`, add a `succsOf`, carry a ready set and decrement only the pick's
successors -> O(V+E+n log n), tie-break intact, OUTPUT BYTE-IDENTICAL. Minor, same file: the
`!(state.done ? ...)` guard is DEAD, since `remaining'` already removes the pick.
★ G26: AN ADDITIVE FIELD CARRYING A PERMANENT BYTE-COMPAT TAIL. gen-edge's `kind` was added
later and THREE SITES NOW CARRY A CONDITIONAL FOREVER so un-labeled edges render as though
the field never existed; one states the reason: "so existing goldens stay byte-identical".
★ THE PATCH-AFTER-BUILD SHAPE WITH AN INVARIANT THREE SITES MUST MAINTAIN IN STEP.
RESOLUTION: REGENERATING THE GOLDENS ONCE RETIRES ALL THREE CONDITIONALS.
★ G27: `factor.nix`'s BARE-GRAPH PATH IS A WEAKER DEFAULT WITH NOTHING STEERING. It
discriminates on FIELD PRESENCE (`spec ? graph`); the bare path sets `key = id: id;
entryOf = id: id;` and the header ADMITS "not-a-node detection is vacuous on this path".
⇒ A CALLER WHO FORGETS THE WRAPPER SILENTLY LOSES `notANode` VALIDATION. THE D3 SHAPE AGAIN.
RESOLUTION: REQUIRE THE SPEC FORM; the bare form becomes an EXPLICIT `bareFactor` OPT-OUT.

## Comments (0)

(none)
