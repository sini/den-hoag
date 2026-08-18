# den-hoag-4kh.53.67 — [DECISION 2] the excludes posture — partially overtaken: 4kh.21 already removed excludes from that node and 9xo.28 measured it subtree-scoped

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.67` |
| status at evacuation | deferred |
| priority | P1 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:16:01Z by Jason Bowman |
| last updated | 2026-08-05T20:48:39Z |
| description bytes | 1173 |
| notes bytes | 1413 |
| comments | 0 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

★ OWNER DECISION 2 -- THE `excludes` POSTURE, AND PER den-hoag-4kh.21 IT MUST COVER `deps`
AND `provision` IN ONE POSTURE: IMPLEMENT / REFUSE LOUDLY / DELETE THE SURFACE.
★ PARTIALLY OVERTAKEN -- read before deciding: 4kh.21's owner ruling of 2026-07-28 already
set the posture for `deps` and `provision` as NAMED-REJECT AT DEFINITION TIME, and
explicitly REMOVED `excludes` FROM THAT NODE on the grounds that it is a PARITY DEFECT WITH
LIVE CONSUMERS -- den v1 CONSUMES it and the corpus USES it with stated intent, so
named-rejecting it would reject a construct v1 honours.
★ AND THE SEMANTICS ARE NOW MEASURED (den-hoag-9xo.28, amended 2026-07-28):
`den.schema.<K>.excludes` IS SUBTREE-SCOPED in v1 -- `includes` fires ONLY at K-nodes,
`excludes` reaches K AND ALL DESCENDANTS -- so ★ A FLAT PER-KIND LIST CANNOT REPRESENT IT,
and the "excludes is includes' DUAL" justification was WITHDRAWN as the wrong reason for a
right answer.
⇒ WHAT REMAINS FOR THE OWNER: whether the SUBTREE representation gets built now or the
same-kind case (which is EVERY declaration that exists anywhere -- full census in 9xo.58)
stays with a NAMED ABORT on the descendant case. See also A3.

## Notes



★★ THE QUESTION IS NARROWER THAN THE AUDIT'S, AND MUST BE RESTATED. Measured at e6c8edc
(den-hoag-4kh.53.1, closed): the landed code ALREADY IMPLEMENTS the settled semantics.
· SAME-KIND exclude: HONOURED. Measured -- `selects` [ "host" ] -> [ ], marker gone from
  materialized resolved-aspects.
· DESCENDANT-KIND exclude: ABORTS BY NAME. Measured, and the message states the extent
  mismatch and says refusing beats silently over-applying.
· ★ ingest.nix:238-242 ALREADY ENCODES THE 9xo.28 AMENDMENT IN SOURCE: an `includes`
  entry fires at K-NODES ONLY, an `excludes` entry reaches K AND ITS WHOLE SUBTREE, and
  "excludes is includes with a minus sign" is named as the wrong model. The withdrawn DUAL
  justification is already retired where it lived.
⇒ SO DO NOT ASK "what should excludes mean" -- THAT IS SETTLED AND SHIPPED. ASK:
★ DOES DEN-HOAG'S PER-KIND SELECTION REPRESENTATION NEED TO BECOME PER-INSTANCE (SUBTREE)
SELECTION, OR IS REFUSING THE DESCENDANT CASE THE ACCEPTED PERMANENT POSTURE?
Inputs to that: every schema-tier exclude declaration in existence is SAME-KIND (full
census at den-hoag-9xo.58), so the descendant case has NO corpus witness -- which by
feedback_den_surface_not_config does NOT discharge it, since the bar is den-surface
expressibility. And the refusal is currently LOUD, which is the standing posture for a
declared surface the engine does not honour (den-hoag-4kh.21).

## Comments (0)

(none)
