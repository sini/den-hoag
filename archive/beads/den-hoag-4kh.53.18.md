# den-hoag-4kh.53.18 — [S2] sidecar dim is a third spelling of its own key with zero readers — and a same-named gen-product field nearby that IS read

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.18` |
| status at evacuation | open |
| priority | P3 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:07:51Z by Jason Bowman |
| last updated | 2026-07-29T00:07:51Z |
| description bytes | 423 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None), `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

[S2] MEASURED. `dim` is a THIRD SPELLING OF ITS OWN KEY. Zero readers repo-wide, positive
control passed (`.parent` fired, `.dim` did not). Both writers assign the LOOP VARIABLE
THAT *IS* THE KEY.
★ TRAP, MEASURED AND STATED: `fleet.nix`'s `dim` is an UNRELATED gen-product factor field,
GENUINELY READ by `gen-product/lib/product.nix`. REMOVING THE SIDECAR `dim` DOES NOT TOUCH
IT. Anyone grepping the name will find both.

## Comments (0)

(none)
