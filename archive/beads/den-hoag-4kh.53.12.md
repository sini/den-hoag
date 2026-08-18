# den-hoag-4kh.53.12 — [N3] three node shapes, not two — every difference absorbed by or-defaulting at each reader, so the invariant is carried by discipline

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.12` |
| status at evacuation | open |
| priority | P2 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:07:03Z by Jason Bowman |
| last updated | 2026-07-29T00:07:03Z |
| description bytes | 767 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None), `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

[N3] MEASURED. THREE node shapes, and an in-tree comment claiming two.
root-as-minted, root-as-DECORATED, and cell. They differ in FIVE decls keys and one
count (a cell carries TWO kind-keyed entries, a root ONE).
★ EVERY DIFFERENCE IS ABSORBED BY `or`-DEFAULTING AT EACH CROSSING READER, so it NEVER
SURFACES AS AN ERROR -- the invariant is carried by DISCIPLINE.
`build-roots.nix` asserts "two -- and only two -- node constructors": TRUE of
CONSTRUCTORS, FALSE of SHAPES, because N2's decorator makes B != A.
⇒ Largely dissolves with N2 (which removes the decorated shape) plus N4/N5 (which give
gen-scope the constructors). Filed separately because the COMMENT is measured false and
must be corrected either way -- see X2, which lists it among five false comments.

## Comments (0)

(none)
