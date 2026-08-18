# den-hoag-4kh.53.6 — [D6] functionArgs carries no locus intent, so D1 lowering CANNOT be mechanical — every policy needs a per-policy decision and a wrong one silently relocates firing

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.6` |
| status at evacuation | closed |
| priority | P1 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:06:12Z by Jason Bowman |
| last updated | 2026-08-01T19:58:09Z |
| closed | 2026-08-01T19:58:09Z |
| close reason | DISCHARGED BY CONSTRUCTION, witnessed at 693919f: the un-lowered population is ZERO — selects is a REQUIRED field read BARE at dispatch (indexBySelection, concern-policies.nix:676/:680, no or-default) and a rule without one is refused at registration by name (:524), so no policy can reach dispatch with locus intent left to functionArgs. functionArgs remains only the PRESENCE gate (gateOf :118), which was never the locus carrier. The per-policy-decision hazard this bead predicted was real and is RESOLVED the other way: compat lowers the whole v1 population mechanically via selectsOfFormals, licensed and guarded (compile.nix :1318 'DECLARATION BEATS DERIVATION, and the absence is the thing being decided'; both call sites guarded if ref ? selects), and the wrong-relocation hazard for the one genuinely positional corpus rule was measured UNEXPRESSIBLE-and-unnecessary (§6.1's answer, 53.3 record). MIGRATION.md's selects silence is the owed remainder, tracked on 53.3. |
| description bytes | 887 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None), `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

[D6] MEASURED, and the document calls it "the real cost of the switch."
`{ host, ... }` is AMBIGUOUS between "at hosts" (10 fires) and "at hosts and their cells"
(210). BOTH ARE EXPRESSIBLE and the formals are SILENT about which is meant.
`concern-policies` conditionOf: `if isRecord v then v.__condition else builtins.functionArgs v`.
⇒ EVERY EXISTING POLICY NEEDS A PER-POLICY INTENT DECISION, and a wrong one SILENTLY
RELOCATES WHERE IT FIRES. This is MIGRATION WORK, NOT A GEN GAP.
★ It is also the work the redesign actually buys: the intent becomes STATED instead of
INFERRED. Do not scope D1's lowering as mechanical -- the audit is explicit that it
cannot be.
BLOCKED BY the reconcile bead: the record surface's `selects` may already carry the
intent for migrated policies, which would change the size of this set. Establish the
remaining un-lowered population before estimating.

## Comments (0)

(none)
