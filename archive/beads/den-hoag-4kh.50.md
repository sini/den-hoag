# den-hoag-4kh.50 — [kernel] the policy probe is UNCONDITIONAL — a fully-declared policy is still fired against the sentinel ctx, and can be broken by it

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.50` |
| status at evacuation | closed |
| priority | P1 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh` |
| created | 2026-07-28T20:48:42Z by Jason Bowman |
| last updated | 2026-07-29T01:11:25Z |
| closed | 2026-07-29T01:11:25Z |
| close reason | EXPIRED — fixed by e6c8edc ('a policy declares what it emits, and the kernel checks it'), whose own message states 'the probe, its sentinel, the three-way expansion fan, strip, and four kernel options all dissolve'. Verified at HEAD 6f30460: lib/concern-policies.nix is 282 lines, so EVERY line this bead cites (:345 probeActs, :358 expanded, :340-357 mkRules metadata) is PAST EOF. grep -n 'probeActs|sentinel|deepSeq' lib/concern-policies.nix returns ONE hit, :214, reading verbatim 'ONE policy compiles to ONE rule. No probe, no sentinel, no fabricated context, no per-stratum fan'. The file now denies the construct by name. |
| description bytes | 1943 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

MEASURED — THE POLICY PROBE IS UNCONDITIONAL. A POLICY THAT FULLY DECLARES ITS METADATA IS STILL FIRED AGAINST
THE FABRICATED SENTINEL CTX.

`lib/concern-policies.nix`: `probeActs` binds at :345 and `expanded = probeActs == [ ]` FORCES at :358, BEFORE
every branch of `baseRules`. So declaring `__produces` — or `__firesAtKinds`, or any of the metadata `mkRules`
reads off the value at :340-357 — DOES NOT BUY YOU OUT OF THE PROBE. The execution happens regardless of the
declaration it was meant to substitute for.

★ WHY THAT IS WORSE THAN A WASTED EVALUATION: the probe's own header records its honest limit — "tryEval
cannot catch a non-recoverable eval error … a body that field-accesses or iterates a REQUIRED sentinel coord
bare still fails the probe HARD." So a fully-declared policy can still be BROKEN BY THE PROBE, on a ctx the
author never intended it to see, for information the author already supplied.
AND THE SWALLOW MAKES IT SILENT: a caught throw is "treated IDENTICALLY to an empty probe" (same header), so
`expanded` carries THREE meanings at :358 — value-conditional, threw-and-was-swallowed, genuinely-empty.

⇒ THIS IS THE SHAPE THE SURFACE AUDIT NAMED: MISSING INFORMATION RECOVERED BY EXECUTION WHERE IT SHOULD HAVE
BEEN CARRIED BY DECLARATION — and here the information is NOT missing. It was declared and then ignored.
★ NOTE THE CHEAP INTERIM: gating the probe on the absence of declared metadata is a strictly smaller change
than P1 and would remove the hard-failure risk for every already-declared policy. It does NOT fix the
three-meaning ambiguity for undeclared ones, and it must NOT be mistaken for P1 — under P1 the probe
disappears entirely rather than becoming conditional. Recorded as an option, not a recommendation.

PROVENANCE: structural surface audit, 2026-07-28, source-read. NOT execution-measured — no eval was run, and
the firing count for a fully-declared policy has not been observed directly.


## Comments (0)

(none)
