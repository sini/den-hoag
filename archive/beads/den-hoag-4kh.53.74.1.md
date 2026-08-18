# den-hoag-4kh.53.74.1 — [den-hoag] Closure-scoped settings law — priced design fork at 1,000-host scale (successor to 6s7k call 4)

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.74.1` |
| status at evacuation | deferred |
| priority | P3 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh.53.74` |
| created | 2026-08-03T01:19:50Z by Jason Bowman |
| last updated | 2026-08-07T21:37:57Z |
| description bytes | 1275 |
| notes bytes | 0 |
| comments | 1 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

Deferred design fork, ruled deferred 2026-08-03 (owner, 6s7k call 4): den-hoag KEEPS the fleet-wide settings law for parity NOW; this bead prices and decides the closure-scoped alternative at target scale, NOT as a parity blocker.

THE FORK. v1 law: every host settings record carries every fleet aspect options (fleet-wide). Measured: bitstream = 36 option leaves, 29 from aspects outside its closure, 7 own; den-hoag implements fleet-wide EXACTLY (36/36 vs v1 incl. the four throw-sentinels; settle-A cell 2). Closure-scoped arm: only the host own aspects options (7 leaves on bitstream).

THE QUESTION AT SCALE (4kh.53.74 bar, thousands of hosts): fleet-wide costs |fleet aspects| option decls per host record; and under fleet-wide, absent means a host silently carries machinery options it never runs — the absence-semantics concern at the type level (the lens).

INPUTS PENDING: Track 2 of the 2026-08-03 research program banks its priced keep-vs-scope table here (eval-cost shape, absence semantics per arm, migration shape, named v1-inequality surface if closure-scoped rules).

EXIT: an owner ruling with the price sheet in hand. Ruling closure-scoped costs a named v1 inequality on the settings surface — the register cell must be named and annotated at ruling time.

## Comments (1)

### 1 — 2026-08-03T01:46:27 · Jason Bowman

TRACK 2 DELIVERED (2026-08-03): pricing table banked at papers plans/2026-08-03-settings-pricing.md (md5 ad01dee44bc74b62c086abe69b62db53, papers commit 7d8ee83). Snapshot-only evals, three repos verified clean after. NOT yet Fable-validated.

VERDICT LINE: strict closure-scoping is the WRONG design to price further — it is inexpressible at the corpus construction site by construction, re-opens ledger u6, and buys at most 34%. The later ruling should weigh THREE arms: fleet-wide (status quo), the LOOSE rule (declaring-node-or-descendant in closure), and the already-built narrow accessor.

CELLS (one-liners):
- T2-1: fleet-wide materializes 36 value leaves/host INDEPENDENT of closure (39 declared); closure-scoped = 7-17 measured (mean 13.4 = 34% of declared; bitstream 19% value-basis). N=1000: 36,000 vs ~13,400 leaves.
- T2-2 ★ INEXPRESSIBLE: the construction site is the CORPUS's (_settings-type.nix:55-89, nodeModule takes the aspect tree and nothing else — no closure parameter); narrowing it = a declaration-stratum type depending on a resolution-stratum fact, a stratification inversion. den-hoag's NATIVE side needs no change (resolved-settings.nix:189-206 already batches over present).
- T2-3 ★ THIRD SHAPE ALREADY BUILT: mkNarrowAccessor (resolved-settings.nix:227-238) — fleet-wide KEYSPACE, closure-scoped VALUES, absence = named absentAspectSetting throw (errors.nix:448-450) + .present boolean. Neither silent-default nor missing-attribute.
- T2-4 absence semantics measured: silent-LINGER witness = uplink.nix:26 authors isHub=true on a node in 0/7 closures, accepted silently; 5 unforced-throw leaves fleet-wide with the throws = 5 - supplied rule confirmed per host; closure-scoping makes hard reads louder and leaves soft-or reads exactly as dangerous.
- T2-5 ★ PARITY: strict rule breaks 22 measured (host, read-site) pairs and RE-OPENS ledger u6 (the syncthing hub broadcast silently never fires — pipes.nix:147,157,166 swallow it); the value divergence is INVISIBLE to the structural oracle (sort-key string only), surfacing only at the P2 drv-hash gate. The LOOSE rule repairs exactly this case at +1 aspect/host.
- T2-6 eval cost: rebuilt-per-host measured (v1 94% per-host, marginal 46,186 values; den-hoag amortizes 78% but marginal = 427,232 values = 9.25x v1) — filed as its own perf-defect bead.
LIMITS carried: marginal-only comparability; 34% is an upper bound; primary-class closures only; user/cluster.settings reads unpriced (board #59 scope).

Bead stays OPEN awaiting the later owner ruling with this sheet in hand; status back to open (research input complete).
