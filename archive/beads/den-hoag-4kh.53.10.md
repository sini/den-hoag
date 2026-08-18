# den-hoag-4kh.53.10 — [N1] buildRoots/fleet.nix re-implement gen-scope.buildNodes byte-for-byte — and buildNodes additionally validates P is a partial function

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.10` |
| status at evacuation | open |
| priority | P1 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:07:03Z by Jason Bowman |
| last updated | 2026-07-29T00:07:03Z |
| description bytes | 906 |
| notes bytes | 0 |
| comments | 1 |
| dependencies | `None` (None), `None` (None), `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

[N1] MEASURED. `buildRoots` / `fleet.nix` RE-IMPLEMENT `gen-scope.buildNodes`.
Called `buildNodes` with an env<-host parent graph and den-hoag-shaped decls: IDENTICAL
record shape, `decls.<kindName>` and `decls.__entry` ride through untouched, and it
builds the env->host P edge. `build-nodes.nix`'s stated output shape -- "{ id = { id,
type, parent, decls }; }" -- is BYTE-FOR-BYTE what `build-roots.nix` assembles by hand.
★ `buildNodes` ADDITIONALLY VALIDATES P IS A PARTIAL FUNCTION, which `buildRoots` does
not. So the swap is not neutral -- it gains a guard.
gen-scope's own examples/nix-config-acl/graph.nix does this AT FLEET SCALE with a
synthetic "root" vertex as the flake anchor, so the pattern is demonstrated.
RESOLUTION -- USE: `buildNodes { parentGraph = overlays <containment edges>; decls; types; }`.
BLOCKED BY D1 (see D8: building the descent before fixing dispatch makes firing worse).

## Comments (1)

### 1 — 2026-07-29T02:44:25 · Jason Bowman

★ THIS EDGE IS REAL ONLY VIA A BUNDLED CHANGE — re-scope rather than inherit. N1's own resolution is buildNodes { parentGraph = overlays <containment edges>; ... }, which BUNDLES the containment edge that is N7. Node replacement ALONE is fire-neutral — this bead itself claims byte-identical output plus a guard. ⇒ SCOPED EDGE-NEUTRALLY, THE D1 DEPENDENCY DISSOLVES; scoped as written, it is real because of the bundled edge, not because of node replacement.
⇒ SPLIT THE SCOPE BEFORE ACTING ON IT: the node-replacement half is independent and can proceed; the containment-edge half belongs with den-hoag-5ae, which specifies that producer properly (and which established that fleet.nix's containmentPairs CANNOT be adopted as-is — it emits an edge to a node that does not exist and omits one that does).
