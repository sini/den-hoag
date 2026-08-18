# den-hoag-4kh.7 — SPIKE (user-guided): sequencing — park y53/8rf behind kernel purity, or land the live defect first?

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.7` |
| status at evacuation | closed |
| priority | P1 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh` |
| created | 2026-07-27T20:24:58Z by Jason Bowman |
| last updated | 2026-07-28T01:38:37Z |
| closed | 2026-07-28T01:38:37Z |
| close reason | RESOLVED BY OWNER RULING (full text in comments): 00g proceeds; y53 and 8rf park until the kernel registry/identity representation is settled; m0a stays open as the defect record independent of any remedy. Theory: compat is a thin Van Wyk map onto the kernel representation, so hardening a compat seam before the codomain is fixed builds a morphism against a moving target. 00g is a soundness violation in gen-merge algebra, independent of den-hoag representation, so no kernel-shape risk attaches. |
| description bytes | 1347 |
| notes bytes | 0 |
| comments | 1 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

NEEDS A USER-GUIDED DESIGN DECISION. Do not resolve autonomously.

THE CONFLICT: den-hoag-y53 (registry descriptor) and den-hoag-8rf (composite registries) are compat-layer and registry-shape work. The owner directive puts a pure-graph KERNEL before materializing the full compat layer. Hardening a compat seam now risks cementing a shape the kernel audit may change.

AGAINST PARKING: y53 is small, has been adversarially reviewed TWICE, and fixes a live silent-data-loss defect (den-hoag-m0a). The corpus is mis-keying registries TODAY — a declared registry that resolves to no kind reaches the fleet EMPTY and nothing reddens. That is the .8 failure mode, live.

THE TRADE: a real current defect versus possible rework. Both are legitimate readings of best-architecture-first.

MATERIAL FOR THE DECISION: y53 rev 3 is written and twice-reviewed; its scope has already shrunk to a single seam (the bridge arm feeds _registryKinds at lib/compat/ingest.nix:528, which already has the bridge-wins shape; nothing is deleted). It is blocked on den-hoag-00g regardless, because gen-merge silently right-biases a redeclared option where nixpkgs aborts, and the descriptor would be sole authority on that path.

So a third option exists: let 00g proceed (it is a gen-merge soundness defect independent of den-hoag's kernel shape) while y53 itself parks.

## Comments (1)

### 1 — 2026-07-28T01:38:15 · Jason Bowman

★★★ OWNER RULING (2026-07-27) — SEQUENCING. THIS SPIKE IS RESOLVED.

RULED: den-hoag-00g PROCEEDS. den-hoag-y53 and den-hoag-8rf PARK. den-hoag-m0a STAYS OPEN as the defect
record, independent of any remedy.

THEORY — WHY y53 PARKS, and it is not caution:
compat is a THIN VAN WYK MAP ONTO THE KERNEL'S REPRESENTATION. A map onto an unsettled denotation is built
against a moving target. Hardening a compat seam before the kernel's representation is fixed is not "safer
sequencing" — it is constructing a morphism whose CODOMAIN IS STILL CHANGING. y53's scope is a compat seam
(the bridge arm feeding _registryKinds at lib/compat/ingest.nix:528); 8rf is registry-shape work. Both are
maps. The kernel-purity arc is precisely the work of fixing the codomain.
THAT KILLS "LAND y53 NOW" ON THEORY, NOT ON RISK APPETITE.

THEORY — WHY 00g PROCEEDS ANYWAY, and it is a different kind of thing:
gen-merge's mergeOptionDecls SILENTLY RIGHT-BIASES a redeclared option WHERE NIXPKGS ABORTS. That is a
SOUNDNESS VIOLATION IN THE ALGEBRA ITSELF — a merge that is not the merge it claims to be. It is independent
of den-hoag's representation entirely, so NO KERNEL-SHAPE RISK ATTACHES TO FIXING IT. A law violation in a
gen library is not sequenced behind a consumer's representation question.
(y53 was blocked on 00g regardless, because the descriptor would be sole authority on that path. So this
ordering costs nothing even on the parked branch.)

★ THE CORRECTION THAT MATTERS — SEPARATE THE DEFECT FROM THE REMEDY.
Both "park" and "land" as originally framed would have left m0a's silent data loss tracked only through the
fate of a proposed fix. That is the error. A DECLARED REGISTRY RESOLVING TO NO KIND, REACHING THE FLEET
EMPTY WITH NOTHING REDDENING, IS MEASURED FACT. It belongs in the graph on its own, now, regardless of which
remedy is eventually chosen or whether the chosen remedy changes shape.
den-hoag-m0a already exists as a P1 bug and STAYS OPEN in exactly that role. y53's SHAPE is unvalidated
design and parks with it.
THE GENERAL RULE THIS INSTANTIATES: beads hold VALIDATED work — a MEASURED DEFECT qualifies; a PROPOSED FIX
does not. Same treatment as den-hoag-4kh.12, where the reroute fold's measured defects entered the graph
while the confluence design that would remove them went to the review gate.

UNPARK CONDITION: y53 and 8rf resume when the kernel's registry/identity representation is settled — i.e.
when the kernel-purity arc has ruled on the representation those seams map onto. Not on a date, on that
event.
