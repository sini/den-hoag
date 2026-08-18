# den-hoag-4kh.53.11 — [N2] the scopeRoots decorator is den-hoag only node mutation and it dissolves into buildNodes decls — but its ordering is load-bearing for ABW condition 2

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.11` |
| status at evacuation | open |
| priority | P1 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:07:03Z by Jason Bowman |
| last updated | 2026-07-29T00:07:03Z |
| description bytes | 1224 |
| notes bytes | 0 |
| comments | 1 |
| dependencies | `None` (None), `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

[N2] MEASURED + ARGUED. The scopeRoots decorator is den-hoag's ONLY node mutation, and
it DISSOLVES.
    decls = node.decls // (prePass.containmentBindings.${id} or { }) // systemView
            // optionalAttrs (prePass.suppressions ? ${id}) { suppressedPolicies = ...; };
Three `//` layers, TWO CONDITIONAL, and TWO CONTRIBUTING ARBITRARY USER-CHOSEN KEY
NAMES. The node gains fields NOT ENUMERABLE FROM THE MINTING SITE.
★ RESOLUTION -- DISSOLVES. The layers are PAYLOAD belonging in `buildNodes`' `decls`
argument. The decorator exists ONLY because `buildRoots` runs before the pre-pass that
produces those bindings. A STAGING ARTEFACT, NOT A DESIGN CHOICE.
⇒ Retiring it removes den-hoag's only node mutation (see M1), so it discharges part of
the standing "mutability is bad" directive as a side effect of N1 rather than as its own
refactor.
★ CAUTION, from tonight's separate measurement: `suppressedPolicies` is load-bearing for
ABW condition 2 -- the pre-pass ctx is fixed BEFORE suppressions exist, which is the only
thing making the negated read in `gateSuppression` sound (den-hoag-4kh.51 / 4kh.18).
MOVING WHEN IT IS COMPUTED IS NOT A FREE REORDERING. Preserve the ordering property or
replace it deliberately.

## Comments (1)

### 1 — 2026-07-29T02:44:24 · Jason Bowman

★ DIRECT D1 EDGE REMOVED, 2026-07-29 — it was redundant and unargued. N2 is decls layering plus ABW-condition-2 ordering; NOTHING in it reads selects or dispatch selection, and the bead states no reason for the dependency. It IS genuinely blocked by N1, and N1 by D1, so THE TRANSITIVE PATH ALREADY COVERS IT. A direct edge that duplicates a transitive one is not free: it makes a bead look blocked by something it does not depend on, and it survives the removal of the real reason. Verified by reading N2 in full rather than inheriting the edge.
