# den-hoag-4kh.53.13 — [N4] [gen-scope] EXTEND: buildNodes specifies the @-suffix multi-parent convention and implements neither half — den-hoag supplies both

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.13` |
| status at evacuation | open |
| priority | P1 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:07:04Z by Jason Bowman |
| last updated | 2026-07-29T00:07:04Z |
| description bytes | 1065 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

[N4] MEASURED. gen-scope SPECIFIES the multi-attachment convention AND IMPLEMENTS NEITHER
HALF. `build-nodes.nix` throws: "node '${from}' has N parent edges (P must be a partial
function, Neron §2.2). If this node should exist under multiple parents, use distinct IDs
(e.g., '${from}@parent1', '${from}@parent2')."
den-hoag implements EXACTLY THAT (`build-roots.nix` `mintedRootId`) and needs the INVERSE
(`parseParent`) at THREE call sites. And `gen-scope/lib/eval.nix` takes `parseParent ? null`
AS A CALLER-SUPPLIED PARAMETER -- so the library asks the consumer for the half of its own
convention it declined to implement.
★ RESOLUTION -- EXTEND gen-scope: `buildNodes` accepts a MULTI-PARENT `parentGraph`, mints
the `@`-suffixed ids, and exports the matching `parseParent` and id constructor.
★ THIS ALSO RETIRES `decls.__root`, which exists ONLY because `@` in ids broke the id-shape
test that distinguished constructors.
Pairs with G5: gen-scope prescribes-but-does-not-implement TWICE in one library (this, and
the `__` decls namespace G2 attributes to it).

## Comments (0)

(none)
