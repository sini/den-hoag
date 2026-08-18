# den-hoag-4kh.53.65 — [X1+X2+X3] five in-tree comments measured false, a stale bead description whose subject gained a new obligation, and 5,474 lines of kernel prose as a maintenance surface

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.65` |
| status at evacuation | open |
| priority | P2 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:15:00Z by Jason Bowman |
| last updated | 2026-07-29T00:15:00Z |
| description bytes | 2220 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

[X1+X2+X3] DOCUMENTATION AND TRACKER DEFECTS.
★ X1 -- ARGUED: bead den-hoag-4kh.18 CALLS THE TWO-STAGE SCHEDULE A LIVE EFFECT-RUNTIME
HOLDOVER, and that code no longer exists -- `staged-resolution.nix` describes a
`groupBy`/transpose keyed by TARGET NODE ID, ORDER-INDEPENDENT, and states "no schedule is
derived". `circular` CANNOT replace it (per-node fixpoint vs cross-root transpose --
different shapes).
★★ BUT DO NOT SIMPLY CLOSE IT. A measurement recorded on 4kh.18 the SAME DAY established
the staged pre-pass is LOAD-BEARING FOR ABW CONDITION 2 -- its ctx is fixed BEFORE
suppressions exist, which is the only thing making the negated read in `gateSuppression`
sound (den-hoag-4kh.51, with a live witness). ⇒ ITS DESCRIPTION IS STALE; ITS SUBJECT
ACQUIRED A NEW OBLIGATION. RE-SCOPE.
★ RELATED, worth its own attention: `gen-resolve/lib/schedule.nix` has
`defaultStrataOrder = [ "structural" "resolution" ]` -- ★ DEN-HOAG'S OWN TWO STRATA,
VERBATIM -- and den-hoag DOES NOT CALL `buildSchedule`. `staged-resolution.nix` names it as
THE ESCAPE HATCH FOR THE GENERAL CASE.
★ X2 -- MEASURED: FIVE IN-TREE COMMENTS MEASURED FALSE.
· `registry.nix` -- "unknown authored keys (aspect content, ...)": ZERO corroboration across
  21 fleets (see T5/T4)
· `build-roots.nix` -- "two -- and only two -- node constructors": THREE SHAPES (N3)
· `bridge.nix` -- "zero kind literals": THE LINE BENEATH CONTAINS TWO (E5)
· `compile.nix` -- claims R9 aborts an unresolvable ref: THE STRING ARM NEVER REACHES R9 (A4)
· `staged-resolution.nix` -- "the same `__`-key strip as attr 1": THE LISTS DIFFER (N6)
★ X3 -- MEASURED: COMMENT DENSITY IS ~3x THE ECOSYSTEM NORM. den-hoag kernel 40%, compat
42%; EVERY gen library 13-19%; the demos 7-17%. ⇒ 5,474 LINES OF PROSE IN THE KERNEL THAT
MUST STAY TRUE, AND X2 SHOWS IT IS ALREADY DRIFTING.
★★ NOT "WRITE FEWER COMMENTS" -- the audit is explicit that THE COMMENTS WERE REPEATEDLY THE
BEST EVIDENCE AVAILABLE, and SEVERAL FINDINGS CAME FROM A FILE CONTRADICTING ITSELF. But it
is A MAINTENANCE SURFACE AND SHOULD BE COUNTED AS ONE.
(X4 was a naming correction only: `edge.derive` is not an export name -- the module is
`derive.nix` and its export is `edgesFor`, which HAS a call site.)

## Comments (0)

(none)
