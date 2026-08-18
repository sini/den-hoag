# den-hoag-4kh.53.58 — [G15+G25] gen-demand surface stops short and demand.adapters is permanently empty, failing with a bare attribute-missing and no library name

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.58` |
| status at evacuation | closed |
| priority | P2 |
| type | bug |
| labels | (none) |
| parent | (none) |
| created | 2026-07-29T00:14:15Z by Jason Bowman |
| last updated | 2026-08-14T02:13:08Z |
| closed | 2026-08-14T02:13:08Z |
| close reason | Discharged by RETIREMENT at the W8 landing (gen-demand off the roster, orphaned per ADR-0031 F3; gen-scope carries the re-expressed surface with zero gen-select and zero adapters — both measured with firing controls). The recorded tombstone resolution is SUPERSEDED with its reason banked in-body: no surface survives to tombstone; the discipline stays valid where a surface survives with a dead member (sel.entityKind unchanged). |
| description bytes | 2484 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

[G15+G25] ARGUED/MEASURED. gen-demand's SURFACE STOPS SHORT, AND ITS ADAPTER FAILS SILENTLY.
★ G15: `wiringFor` / `spliceWiring` ARE UNREACHED, so a consumer reading
`config.<idHash>.wiring` gets RAW PER-KIND LISTS WITH NO GLOBAL SCHEDULE ORDER AND NO
SPLICE. And `demand.folds` (FIVE STOCK FOLDS) IS NOT RE-EXPORTED ON THE DEN SURFACE, so a
user writing `den.demandKinds.<k>.fold` HAND-WRITES WHAT GEN-DEMAND SHIPS.
★ BOTH ARE NON-USE, NOT HAND-ROLL -- the cascade discipline GENUINELY LIVES IN THE LIBRARY.
Do not file this as a duplication finding.
★★ G25, MEASURED: `demand.adapters` IS PERMANENTLY EMPTY AND FAILS SILENTLY.
`gen-demand/lib/default.nix` returns `{ }` when `select == null`, and `gen-demand/flake.nix`
declares ONLY gen-prelude and gen-graph -- ★ NO GEN-SELECT. The hub passes the flake lib
through unchanged, so `demand.adapters == { }` FOR EVERY CONSUMER, PERMANENTLY. Calling
`demand.adapters.select.filterDemands` yields a BARE `attribute 'select' missing` WITH NO
LIBRARY NAME.
★ COMPARE gen-edge GETTING THIS RIGHT FOR THE SAME SITUATION: a NAMED THROW identifying the
missing input.
RESOLUTION: `adapters.select` PRESENT-BUT-THROWING when uninjected -- the TOMBSTONE
DISCIPLINE `sel.entityKind` ALREADY USES. Same D3 shape: a weaker path with nothing
steering.

════ ★★ THE RECORDED RESOLUTION IS SUPERSEDED, WITH ITS REASON (2026-08-14, W8 landing — recorded
so the tombstone is not re-proposed) ════
The resolution above (adapters.select PRESENT-BUT-THROWING when uninjected — the sel.entityKind
tombstone discipline) was written for a world where the demand surface SURVIVED with an empty
adapters slot. R§2.4 of the re-expression spec retired the surface instead: gen-scope declares NO
gen-select input (measured: 0 in flake.nix AND flake.lock, live controls 6 and 1 on gen-demand's
own), and `adapters` exports 0 in gen-scope's lib (control: gen-demand's lib fires 4) — so there is
NO SURFACE LEFT TO TOMBSTONE, and both of this bead's halves (stops-short; fails with no library
name) die with the export rather than being repaired at it. A tombstone on a retired surface would
be a repair where the construction removed the shape (C7's own direction). The replacement
capability is reachable on gen-scope's published surface (wiringFor, spliceWiring, folds — all
verified through the hub at the W8 bump). The tombstone discipline itself remains valid where a
surface SURVIVES with a dead member — sel.entityKind stands unchanged as its live exemplar.


## Comments (0)

(none)
