# den-hoag-4kh.53.48 — [G21] [gen-prelude] groupBy is a quadratic shadow of builtins.groupBy — which gen-graph and gen-scope already call directly

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.48` |
| status at evacuation | closed |
| priority | P1 |
| type | bug |
| labels | (none) |
| parent | (none) |
| created | 2026-07-29T00:12:11Z by Jason Bowman |
| last updated | 2026-08-12T04:41:39Z |
| closed | 2026-08-12T04:41:39Z |
| close reason | Asked resolution already delivered: gen-prelude beab47b (2026-07-30) re-exports builtins.groupBy in the inherit-builtins block (lib/default.nix:26 and :177 at e1794e2), with the in-file comment documenting the retired quadratic fold (acc // + bucket ++ copies) and the unchanged key domain. Verified at e1794e2 this session; surfaced by the 34zp spec's C10 reconciliation (R§6.4/R§7.5 of wt/spec-34zp), independently confirmed by orchestrator before close. Fixed-by-beab47b — finding was true when filed (2026-07-27 era). |
| description bytes | 525 |
| notes bytes | 869 |
| comments | 0 |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

★ ARGUED. `gen-prelude.groupBy` IS A QUADRATIC SHADOW OF A NIX BUILTIN.
It folds with `acc // { ... }` (COPIES THE WHOLE ACCUMULATOR PER ELEMENT) and `++ [ x ]`
(copies the bucket per element). ★ `builtins.groupBy` EXISTS AND IS LINEAR.
★ POSITIVE CONTROL THAT THE ECOSYSTEM ALREADY KNOWS: gen-graph calls the BUILTIN five times
and gen-scope twice. So the libraries that get this right sit beside the one that does not.
RESOLUTION: `groupBy = builtins.groupBy;` in THE BUILTINS RE-EXPORT BLOCK THAT ALREADY
EXISTS. One line.

## Notes



★★ CONFIRMED BY MEASUREMENT, 2026-07-29, AND IT IS THE ONE OF THE THREE WORTH DOING.
    prelude.groupBy   nrOpUpdateValuesCopied  723 -> 2,599 -> 10,199 -> 40,399   (4x per doubling: QUADRATIC)
    builtins.groupBy  nrOpUpdateValuesCopied    0 ->     0 ->      0 ->      0   (FULLY LINEAR)
The `//`-per-element copy IS exactly the quadratic, and `builtins.groupBy` is a CLEAN
DROP-IN. Instrument: NIX_SHOW_STATS operation counts on a plain file (sidesteps the 345 ms
flake floor; cpuTime stayed flat at ~0.007 s across every N, so wall-clock proves nothing
and the counters are the signal). Positive control: a genuinely linear dedup measured
exactly 2x per doubling on the same instrument.
⇒ READY TO SPEC. Cheapest of the three, confirmed linear replacement, no consumer-shape
caveat -- unlike G20, whose named fix measured 272x WORSE and is now closed as refuted.

## Comments (0)

(none)
