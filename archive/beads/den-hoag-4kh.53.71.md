# den-hoag-4kh.53.71 — [DECISION 6] framework kinds as ordinary declarations vs framework-ness as declared data — establish the effectiveClassEntries threading cost first

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.71` |
| status at evacuation | open |
| priority | P1 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:16:02Z by Jason Bowman |
| last updated | 2026-07-29T00:16:02Z |
| description bytes | 1113 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None), `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

★ OWNER DECISION 6 -- FRAMEWORK KINDS: ORDINARY DECLARATIONS (v1's SHAPE) VERSUS
FRAMEWORK-NESS AS DECLARED DATA. ★ OWNER LEANING: DECLARED DATA.
Making framework kinds ORDINARY DECLARATIONS deletes `metaAugment`, the `collector`
reserved-name branch AND the S9 keyset divergence TOGETHER -- v1's shape, which privileges
nothing.
★★ THE COST THAT COULD TURN A DELETION INTO A REDESIGN, and it must be established BEFORE
the ruling: the collector's per-instance `contentClass` function needs
`effectiveClassEntries`/`effectiveClassNames`, WHICH ARE CURRENTLY COMPUTED OUTSIDE THE
MODULE TREE. THAT THREADING IS THE RISK. The reserved-name guard must also be removed or
inverted.
★ NOTE: the reserved-names half MAY NOT NEED A HOME AT ALL if decision 5's derivation lands
-- so decisions 5 and 6 should be taken together, not separately.
★ AND E5 IS THE SAME DISEASE AT A SECOND SITE: den-hoag privileges `host` and `user` as
MERGE LITERALS while v1 declares all five of ITS builtins through the ordinary consumer
surface. A ruling for "framework-ness is declared data" should say whether it also governs
those two.

## Comments (0)

(none)
