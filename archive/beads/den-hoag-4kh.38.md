# den-hoag-4kh.38 — [kernel] REFERENCE.md delegates the claim-accessor's disjointness obligation to a 'shared registration pass' that does not exist; + the demand-order residual

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.38` |
| status at evacuation | open |
| priority | P2 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh` |
| created | 2026-07-28T05:37:49Z by Jason Bowman |
| last updated | 2026-07-28T05:37:49Z |
| description bytes | 2045 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

★ MEASURED — TWO P5b RESIDUALS ARE PRINTED IN THE SHIPPED PUBLIC `REFERENCE.md` AND TRACKED NOWHERE. ONE OF
THEM DELEGATES ITS CORRECTNESS OBLIGATION TO A PASS THAT DOES NOT EXIST.

(a) DEMAND-ORDER RESIDUAL. `REFERENCE.md:995-999` and `:1012`: "the gather -> spawn ordering is
    DEMAND-guaranteed (the spawn …) … demand-order is a real, documented residual". The log names the static
    fix at :876-877: "deferred `resolve.nta` accepting stratum + readsAttrs".

★ (b) THE CLAIM-ACCESSOR'S UNDISCHARGED ASSUMPTION. `REFERENCE.md:1014-1016` states the claim-accessor's
    stratum-scoping ASSUMES leaf-claim names are DISJOINT from `den.relations` edge-kinds, and delegates that
    obligation to "the FRAMEWORK-WIDE name-uniqueness invariant"; `lib/attributes/claim-accessor.nix:50` says
    it is "owned by the shared registration pass".
    MEASURED: THERE IS NO SUCH PASS. `name-uniqueness|nameUnique|uniqueness` in `lib/` = 8 hits, ALL
    per-concern LOCALITY comments — `concern-quirks.nix:6` (channel-name E4b), `products.nix:153` (per-pair
    keying), `default.nix:665`, `:1440`, `:2199`. None is a global registration pass.
    ⇒ A shipped public document tells users an invariant holds, and names an owner for it that does not
    exist. This is the documented-but-unenforced pattern the kernel-purity criteria name explicitly, in its
    worst form: the assumption is not merely unenforced, its stated ENFORCER is fictional.

NOT den-hoag-ahl: that bead is in the SAME FILE but is a different defect (the undocumented `queryEdges`
variant). 0 beads on either residual here.

GENUINELY OPEN for (b): build the global uniqueness pass, OR narrow the accessor so it does not need the
assumption, OR document the collision as a real limitation with its failure mode. The third is legitimate and
cheapest, and is the honest option if the collision is unreachable in practice — but "unreachable" would then
need the measurement the kernel rules require, not an assertion.

PROVENANCE: log-reconcile exhaustive pass, 2026-07-28, item C6.


## Comments (0)

(none)
