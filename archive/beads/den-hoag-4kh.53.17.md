# den-hoag-4kh.53.17 — [S1] denMeta shadows a live surface with zero readers — owner ruled DELETE, with two feasibility constraints the design must state

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.17` |
| status at evacuation | deferred |
| priority | P1 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:07:51Z by Jason Bowman |
| last updated | 2026-08-05T20:48:35Z |
| description bytes | 1101 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

[S1] MEASURED. `denMeta` SHADOWS A LIVE SURFACE THAT HAS ZERO READERS.
`entity.nix` publishes `topology = tree.config.den.schema._topology` -- NO READERS
REPO-WIDE. Five sites read the HAND-COPY `ent.meta.<k>.parent` instead. `ent.roots` is
re-export-only. BLAST RADIUS: 12 internal sites, 2 test call sites, 1 public re-export.
★ OWNER RULED: DELETE THE SURFACE. Record -> list; `den.meta` removed from the public
re-export.
★★ TWO CONSTRAINTS FOUND BY FEASIBILITY CHECK, BOTH LOAD-BEARING:
1. `default.nix`'s early call site CANNOT read `ent` -- there is a CYCLE through
   denAspects -> aspectsDecl -> entity.build. It MUST read the probe. ⇒ THE KERNEL ENDS
   WITH TWO KIND-LIST SOURCES AND THE DESIGN MUST STATE THAT rather than discover it.
2. ★ THE KEYSET SUBSTITUTE IS NOT `sch._kindNames`. It is
   `sch._kindNames ++ prelude.optional hasCollectors "collector"`. THE BARE PROBE LIST
   SILENTLY STOPS MINTING COLLECTOR ROOT NODES AND REGISTRIES (`ent.registries.collector
   or { }` degrades to empty). This is recorded in the audit's own corrections ledger as
   a claim it made and refuted.

## Comments (0)

(none)
