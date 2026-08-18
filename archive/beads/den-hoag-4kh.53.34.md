# den-hoag-4kh.53.34 — [A9] ingest repeats the A1 parent collapse, safe only by evaluation order, with nothing marking it order-sensitive

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.34` |
| status at evacuation | open |
| priority | P2 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:09:42Z by Jason Bowman |
| last updated | 2026-07-29T00:09:42Z |
| description bytes | 542 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None), `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

[A9] ARGUED. `ingest.nix` REPEATS THE A1 COLLAPSE AND IS SAFE ONLY BY EVALUATION ORDER.
`declared = builtins.mapAttrs (_: k: { parent = k.parent or null; }) v1Schema;`
-- harmless ONLY because `desugarLegacy` runs BEFORE it in `compileFull`.
★ NOTHING MARKS IT ORDER-SENSITIVE. A future reordering re-opens A1 at a second site with
no comment, no guard and no test.
⇒ Fix with A1 (same expression shape, same remedy: read the RAW DEFS, omit `parent` when
no def declares it) or, at minimum, state the ordering dependency where it can be seen.

## Comments (0)

(none)
