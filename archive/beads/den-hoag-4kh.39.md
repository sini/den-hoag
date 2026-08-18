# den-hoag-4kh.39 — [kernel] 'THE RED WINDOW' block at output-modules.nix:767-775 asserts corpus facts falsified by 6.2a/6.2b — and its self-quoting marker manufactures its own corroboration

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.39` |
| status at evacuation | closed |
| priority | P2 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh` |
| created | 2026-07-28T05:37:50Z by Jason Bowman |
| last updated | 2026-07-31T00:40:49Z |
| closed | 2026-07-31T00:40:49Z |
| close reason | FIXED at 2930c9c. Both asserted facts FALSE at HEAD, re-verified: the reach-edge producer EXISTS (compile.nix:1096-1115, the v1 policy.spawn { classes } arm lowering one declare.reach-edge per class) and the corpus OPTS IN (users/sini.nix:4 includes batteries.host-aspects) — producers fire on the real fleet. BUT the correcting writer measured the two producers the bead did NOT: reach-suppress is a declared kind (declarations.nix:59) with NO producer, and default-edge is not a declaration kind at all — the block's precondition was false for one third of its claim and still true for two thirds; deletion would have been wrong. Rewritten to the measured split, keeping the synthetic-validation rationale; the self-quoting marker is GONE not reworded (0 tracked-source occurrences after; the mechanism, not the string). TRAP HIT AND RESOLVED (logged 4kh.20): naming the shim in a kernel comment tripped boundary's core token scan — reworded into the guard's permitted v1 vocabulary; all three edited core files re-scanned against the full token list with a positive control. Sibling residue: EIGHT sites carry the same premise non-uniformly — per-site read done, scoped follow-up bead filed (the three projection.* sites are the priority). Suite identical. |
| description bytes | 1604 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

★ MEASURED — A STALE BLOCK IN THE KERNEL'S MOST-READ FILE ASSERTS A PRECONDITION THAT SHIPPED WEEKS AGO.

`lib/attributes/output-modules.nix:767-775`, "THE RED WINDOW", asserts:
  - "the corpus has NO reach-edge / reach-suppress / default-edge PRODUCERS until Phase 5"
  - the fleet golden suites are "MARKED PENDING (`# Phase 5: needs corpus edge producers`)"

MEASURED AT HEAD — BOTH FALSE:
  6.2a/6.2b SHIPPED. `lib/compat/compile.nix:987-998` emits `declare.reach-edge` PER NAMED CLASS. So corpus
  producers exist.
  The cited pending-marker string has ONE occurrence tree-wide — and it is THIS COMMENT QUOTING ITSELF.
  ZERO real markers in `ci/`. POSITIVE CONTROL, same run: `RED WINDOW` = 1 occurrence.

★ WHY A COMMENT COUNTS AS A DEFECT HERE, not a nit: this block does not describe code, it asserts a FACT
ABOUT THE CORPUS and uses that fact to justify why something is safe. A reader who trusts it will conclude a
whole class of edge producers cannot occur, and will not test for them. And the self-quoting marker means a
grep for the pending marker FINDS A HIT — so the comment manufactures its own corroboration.

This is the documented-invariant-that-nothing-enforces pattern, inverted: an invariant that nothing
establishes, asserted as established.

REMEDY IS NOT OBVIOUS AND SHOULD NOT BE ASSUMED: deleting the block is only right if the reasoning it
supported is also stale. If that reasoning is still load-bearing, it needs a CURRENT justification, not a
deletion. Read what the block is protecting before touching it.

PROVENANCE: log-reconcile exhaustive pass, 2026-07-28, item D4.


## Comments (0)

(none)
