# den-hoag-4kh.35 — [kernel] the 'to' per-aspect consumer-addressed delivery seam — the ONE named net-new kernel binding seam in the WS-B design — exists in no tree, no bead, no tracker

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.35` |
| status at evacuation | deferred |
| priority | P1 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh` |
| created | 2026-07-28T05:36:43Z by Jason Bowman |
| last updated | 2026-08-05T20:48:32Z |
| description bytes | 2242 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

★ MEASURED — THE ONLY NAMED NET-NEW KERNEL BINDING SEAM IN THE AUTHORITATIVE WS-B DESIGN EXISTS NOWHERE:
NOT IN THE TREE, NOT IN BEADS, NOT IN ANY OF THE THREE LIVE PAPERS TRACKERS.

THE SEAM: `to` per-aspect CONSUMER-ADDRESSED DELIVERY.
`specs/2026-07-21-wsb-general-system-design.md` names it THREE times:
  :19  the seam itself, at `output-modules.nix:837-839`, mirroring v1's `applyPipeTargeting`
  :33  "the one genuine kernel binding seam"
  :43  the layer-2 build list
The same design also records what NOT to do and what must come first:
  :51 item 5 — a REJECTED alternative: producer-side `route{select}` at `pipe.nix:146`, "semantically wrong,
      do NOT thread". Anyone rebuilding this from scratch will find that shape first.
  :40, repeated :54 — an UNFILLED PRECONDITION: "consumer-indexed-delivery lit spike … NO catalog/dataflow
      anchor covers 'a channel value resolving differently per consumer' — ground before building the seam".

MEASURED at HEAD: `consumer-addressed|consumer-indexed|applyPipeTargeting|perAspectTo` =
  0 in `lib/` · 0 in beads · 0 in `STATUS/coverage-matrix.md`, `STATUS/compat-feature-register.md`,
  `STATUS/route-through-board.md`.
POSITIVE CONTROL on those same three tracker files, same run: `forward` = 87 / 16 / 5.
CITED SITE HAS DRIFTED: `lib/attributes/output-modules.nix:833-841` is now `edgesForRoot`.

★ WHY THIS IS THE MOST CONSEQUENTIAL ITEM OF THE RECONCILIATION: a design can lose its ONE net-new seam
without any tracker noticing, because trackers record work that STARTED. This never started, so nothing
recorded it. The design doc is the only witness, and design docs do not survive compaction — which is the
whole reason this graph exists.

GENUINELY OPEN, and both are real choices:
  (a) BUILD the seam, or DROP it — the productions-substrate redesign may have dissolved the need, and
      nothing has re-derived whether it did.
  (b) The LIT-SPIKE precondition is a separate prerequisite EITHER WAY: if built, it grounds the semantics;
      if dropped, the drop should be justified against the same gap. Do not treat (b) as satisfied by (a).

PROVENANCE: log-reconcile exhaustive pass over the 927-line historical log (archived at den-hoag-4kh.27),
2026-07-28, item C1.


## Comments (0)

(none)
