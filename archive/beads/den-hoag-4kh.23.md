# den-hoag-4kh.23 — [kernel] provision/adapt render-row fields are accepted and stored SHAPE-ONLY — declared, never consumed, no error

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.23` |
| status at evacuation | open |
| priority | P2 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh` |
| created | 2026-07-28T05:08:11Z by Jason Bowman |
| last updated | 2026-07-28T05:08:11Z |
| description bytes | 1546 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None), `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

MEASURED DEFECT — `provision` / `adapt` RENDER-ROW FIELDS ARE ACCEPTED AND STORED SHAPE-ONLY, NEVER CONSUMED.

SITES, verified at HEAD a40cc96:
  lib/renders.nix:35   "`provision`/`adapt`/`face`/`extendsVia`/`compatibleWith` are stored SHAPE-ONLY here"
  lib/renders.nix:40   `provision = raw.provision or null;`
  lib/nest.nix:181     "`renderRow.provision`/`adapt` stay SHAPE-ONLY here"

The declaration is taken, stored, and silently never honoured — the SILENT-NULL failure mode, distinct from
`deps`'s throw-on-read and 9xo.28's inertness. A user setting `provision` gets no error and no effect.

CONTEXT: the features memory (line 652) records "§R3's full provisioning record (pkgs/system/specialArgs/
charts) is a dedicated LATER arc". That later arc was never filed. Same shape as the epic's class-A queue:
DECLARED, ACCEPTED, UNCONSUMED.

★ BLOCKED ON THE POSTURE RULING (the decision node) — see the `deps` bead for why the three cannot be fixed
independently.

ACCEPTANCE, once the posture is ruled:
  under HONOUR — §R3 wired through the render evaluator with a witness that observes provisioning taking
  effect (not merely being stored);
  under NAMED-REJECT — the field rejected AT DEFINITION TIME with a named error, plus a REFERENCE row.
Note the field list at renders.nix:35 is FIVE fields, not two — `face`/`extendsVia`/`compatibleWith` are in
the same sentence and must be triaged with it rather than left behind as the next silent residue.

PROVENANCE: memory-reconcile audit 2026-07-28, item C3. Untracked before this bead.


## Comments (0)

(none)
