# den-hoag-4kh.53.21 — [S7] kinds is defined by a hardcoded blacklist while the positive list sits eleven lines above — three spellings of one contract

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.21` |
| status at evacuation | open |
| priority | P2 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:07:52Z by Jason Bowman |
| last updated | 2026-07-29T00:07:52Z |
| description bytes | 689 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None), `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

[S7] ARGUED. `kinds` is defined BY BLACKLIST while the POSITIVE LIST SITS ELEVEN LINES
ABOVE. `entity.nix` does `removeAttrs tree.config.den.schema [ "_kindNames" "_topology"
"_refEdges" "_edges" "_roots" "_leaves" ]` while `sch._kindNames` is used in the same file.
★ It RE-IMPLEMENTS THE `_`-PREFIX FILTER GEN-SCHEMA ALREADY RAN, as a HARDCODED SIX-NAME
LIST -- and `compat/schema-util.nix` re-implements it A THIRD TIME as a substring test.
⇒ Three spellings of one contract, two of them in den-hoag. Fix depends on G9 (gen-schema
publishes no list of its own introspection keys, so consumers hardcode them) -- once the
library publishes the set, all three sites collapse to reading it.

## Comments (0)

(none)
