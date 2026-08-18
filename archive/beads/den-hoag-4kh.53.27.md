# den-hoag-4kh.53.27 — [C1-C3] 24 of 40 framework concern names build silently and take over the namespace — a kind named policies corrupts the scope graph with no instance authored

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.27` |
| status at evacuation | open |
| priority | P0 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:08:36Z by Jason Bowman |
| last updated | 2026-07-29T00:08:36Z |
| description bytes | 2185 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None), `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

★★ MEASURED, 40 evals plus controls. 24 OF 40 FRAMEWORK CONCERN NAMES BUILD SILENTLY AND
TAKE OVER THE NAMESPACE when a user declares a kind with that name.
· 1 throws NAMED: `kinds`
· 15 throw INCIDENTALLY -- leaf/group collisions, "expected a set but found a list", one
  "infinite recursion" (`schema`). NONE NAMES THE ACTUAL PROBLEM.
· ★ 24 BUILD SILENTLY: aspects attach axes classes collectors contentClass conversions
  demandContext demandKinds derived disciplines edges interpret outputs policies
  probeSentinelFields producesByName productions products quirks relations renders
  resolutionProducts systemViews
Each appears in BOTH `registries` and `meta`; the kind registry claims `options.den.<name>`.

★ C2 -- THE GUARD COVERS ONE OF THE FORTY AND MISSES THE PLURAL OF A NAME IT LISTS.
`entity.nix` names `kinds`, `root`, `collector` -- but only `kinds` is one of the 40.
`root` and `collector` are not `options.den.*` concerns at all. THE REAL CONCERN OPTION IS
`collectors`, PLURAL -- UNGUARDED AND SILENT.

★★ C3 -- A POLICY DECLARATION IS DOUBLY INTERPRETED. With a kind named `policies` declared
and NO INSTANCE AUTHORED: the policy STILL FIRES, *AND* `den.policies.p1` is ingested as a
kind instance MINTING SCOPE NODE `policies:p1`. ⇒ SCOPE GRAPH CORRUPTION ARRIVES WITHOUT
THE INSTANCE, which is the case a real fleet hits. Authoring an instance as well gives an
UNCATCHABLE "attempt to call something which is not a function but a set" in gen-dispatch.

RESOLUTION: DERIVE THE RESERVED SET FROM DEN-HOAG'S OWN DECLARED CONCERN-OPTION NAMES --
mechanically enumerable, closes 39 names, NO GEN CHANGE.
★ CAVEATS THE SPEC MUST CARRY: `root` is a key INSIDE `den.kinds`, not a concern option;
`collector` is a SEED-VERSUS-USER collision (the framework declares that kind itself), so
a derived set does NOT subsume either. And `lib/reserved-registry.nix`'s
`mkReservedRegistry` DOES NOT FIT -- `reserved // table` would INJECT PHANTOM KIND ROWS.

ROOT CAUSE, connecting to the §0 thesis: the registration path CANNOT DISTINGUISH A
NAMESPACE HOLDING ENTITIES FROM ONE HOLDING FRAMEWORK DECLARATIONS, because kinds mount at
`options.den.<kindName>` with no reservation.

## Comments (0)

(none)
