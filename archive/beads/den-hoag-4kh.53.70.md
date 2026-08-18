# den-hoag-4kh.53.70 — [DECISION 5] do the concern-name collisions fold into the redesign or stand alone? 39 by enumeration now, or 40 by construction later

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.70` |
| status at evacuation | deferred |
| priority | P1 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:16:02Z by Jason Bowman |
| last updated | 2026-08-05T20:48:41Z |
| description bytes | 1054 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

★ OWNER DECISION 5 -- DO THE CONCERN-NAME COLLISIONS FOLD INTO THE REDESIGN OR STAND ALONE?
The measured defect is at den-hoag-4kh.53.27 (24 of 40 framework concern names build
silently; a kind named `policies` corrupts the scope graph WITH NO INSTANCE AUTHORED).
★ THE ARGUMENT FOR STANDING ALONE: the resolution -- derive the reserved set from den-hoag's
own declared concern-option names -- is MECHANICALLY ENUMERABLE, CLOSES 39 NAMES, and NEEDS
NO GEN CHANGE. It is cheap and it is a live corruption.
★ THE ARGUMENT FOR FOLDING: the audit locates the ROOT CAUSE in the §0 thesis -- THE
REGISTRATION PATH CANNOT DISTINGUISH A NAMESPACE HOLDING ENTITIES FROM ONE HOLDING FRAMEWORK
DECLARATIONS, because kinds mount at `options.den.<kindName>` WITH NO RESERVATION. A
redesign that separates those namespaces closes all 40 BY CONSTRUCTION rather than 39 by
enumeration.
⇒ THE DECISION IS WHETHER TO PAY FOR THE ENUMERATED FIX NOW KNOWING THE CONSTRUCTION MAY
RETIRE IT. Note decision 6 leans the same way and may subsume the reserved-names half
entirely.

## Comments (0)

(none)
