# den-hoag-4kh.43 — [gen] design hand-rolls transpose/reachability that gen-graph already provides and den-hoag already calls — and default.nix:2067's comment forbids exactly this

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.43` |
| status at evacuation | closed |
| priority | P1 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh` |
| created | 2026-07-28T06:24:59Z by Jason Bowman |
| last updated | 2026-07-28T15:12:31Z |
| closed | 2026-07-28T15:12:31Z |
| close reason | Closed |
| description bytes | 2871 |
| notes bytes | 0 |
| comments | 2 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

★ MEASURED — FOURTH BUILD-WHAT-EXISTS INSTANCE, AND THE FIRST WHERE AN IN-TREE COMMENT PROHIBITS THE
CONSTRUCTION BY NAME AT A SITE ALREADY DOING THE SAME JOB.

THE DESIGN (specs/2026-07-28-bucket-to-edge-design.md §9) asserts "Substrate: none" and its §11 R1 argues zero
gen-substrate blast radius. NO REUSE SCAN WAS PERFORMED AT ANY GRANULARITY.

MEASURED AT HEAD:
  gen-graph IS ALREADY A den-hoag INPUT — flake.nix:11 `gen-graph.url = "github:sini/gen-graph";`,
  bound at lib/default.nix:42 `graph = inputs.gen-graph.lib;`.
  It ships EXACTLY the primitives the design's E2/E3/E7 hand-roll (gen-graph/README.md:117-124, 250-262):
  `reachableFrom` (C-level BFS via builtins.genericClosure), `canReach`, `selfReachable`, `cycles`,
  `transpose`, `condensation` ({ reps; bottomUp; members; sccs; sccOf; condEdges } — the SCC semantics
  den-hoag-4kh.12 reasoned in).
★ AND den-hoag ALREADY CALLS `transpose` FOR PRECISELY THE PREIMAGE JOB, at lib/default.nix:2067, whose own
comment reads:
    "THE INVERSE EDGES via gen-graph.transpose (§9) … a per-kind genGraphLib.transpose (Mokhov 2017 §4.3),
     NOT A HAND-ROLLED FROM/TO SWAP."
  THE DESIGN'S E3 IS A HAND-ROLLED FROM/TO SWAP.

⇒ THE TREE CONTAINS A COMMENT FORBIDDING THE EXACT CONSTRUCTION THE DESIGN PROPOSES, AT A SITE PERFORMING
THE SAME OPERATION, AND THE DESIGN NEITHER CITES NOR CONTRADICTS IT.

★ THIS IS NOT MERELY DUPLICATION — IT IS THE DESIGN'S PERFORMANCE DEFECT. The gate measured the hand-rolled
closure at Θ(K²·b^h·R), understated by 10-13× against the design's own bound, and established that the
exponential lives ENTIRELY in unmemoised `nf` re-exploration rather than in content replication. gen-graph's
`reachableFrom` and `condensation` MEMOISE THE CLOSURE. So routing through the existing library discharges
the performance defect BY CONSTRUCTION, where the design's own remedy (obligation O4) was measured to have
ZERO EFFECT — 884→884, 11360→11360.

WHY THE PREVENTIVE INSTRUMENT DID NOT FIRE: the reuse-scan discipline points at the capability map
(reference_gen_lib_capability_map). That map was separately measured WRONG — it called gen-product's
`latticeGraph` "genuinely absent" on the very day it was committed. A scan against it would not have been
trusted anyway. THE CHEAPER AND SOUNDER CHECK IS THE ONE THAT WAS SKIPPED: read `flake.nix`'s inputs and grep
the tree for existing calls. den-hoag's own `flake.nix` names gen-graph, and `lib/default.nix` already binds
and uses it.
⇒ STANDING RULE THIS EARNS: BEFORE HAND-ROLLING A GRAPH, SET OR FOLD PRIMITIVE, GREP THE REPO FOR AN EXISTING
CALL TO THE SAME OPERATION. The inputs list is authoritative and local; a capability map is neither.

PROVENANCE: bucket-to-seed-query gate, 2026-07-28. Verified by reading flake.nix, lib/default.nix:2067,
gen-graph/README.md, and by measuring the hand-rolled closure's invocation count.


## Comments (2)

### 1 — 2026-07-28T07:04:58 · Jason Bowman

★ CORRECTION TO THIS BEAD'S BODY — A CITATION OF MINE IS WRONG AND WOULD PROPAGATE.
I wrote 'bound at lib/default.nix:42 `graph = inputs.gen-graph.lib;`'. THAT IS `flake.nix:42`. `lib/default.nix` RECEIVES `graph` as a FUNCTION ARGUMENT (its arg set, lines 1-21) and does not bind the input at all. Verified by the bucket-r2 agent reading at an explicit rev.
The bead's SUBSTANCE is unaffected — gen-graph IS an input, IS bound, and IS already called for the preimage job at lib/default.nix:2067 under the comment forbidding a hand-rolled from/to swap. Only the binding site is misattributed.

★★ AND THE FIX IS NOT THE MECHANICAL SWAP THIS BEAD IMPLIES. Two defects that 'just use gen-graph' WOULD HAVE INTRODUCED SILENTLY, both found by reading gen-graph's SOURCE at the pinned rev 231b319 rather than its README:

(A) THE ACYCLICITY GUARD STOPS BEING AUTOMATIC. The hand-rolled formulation threaded `seen`, which made the cycle abort SELF-ENFORCING — the recursion could not step past a cycle. gen-graph's rest-position formulation HAS NO RECURSION and ANSWERS A CYCLIC RELATION SILENTLY. MEASURED: on `A->B, B->A` over Ch=[A B C Z] it returns ["C"] for C where the current code THROWS. ⇒ Adopting gen-graph REQUIRES adding an explicit forced guard that the hand-rolled version got for free. Had the swap been done mechanically, THE CYCLE ABORT WOULD HAVE QUIETLY DISAPPEARED — a silent loss of a safety property, in a change whose whole justification is correctness.
(B) `condensation` IS NOT TOTAL ON THIS DOMAIN. It is the primitive den-hoag-4kh.12's SCC theory points at and that I named in the brief. With `nodes = Ch` plus an act naming an UNREGISTERED channel it fails `attribute 'X' missing` at gen-graph lib/global.nix:165 — ★ AND THAT ERROR ESCAPES `builtins.tryEval`, so it cannot even be contained. `transpose`/`cycles`/`reachableFrom` all answer on the same input byte-identically to the retired formulation; only `condensation` is partial. Recorded in the spec so the SCC option is not re-proposed as free.

★ THIS IS THE C7-a FAILURE MODE IN ITS OTHER DIRECTION, and worth stating as a standing lesson: 'the library already exists' establishes that you should NOT hand-roll; it does NOT establish that the library's surface has your semantics. RIGHT LIBRARY, WRONG SURFACE IS INVISIBLE TO REVIEW. `reachableFrom` EXCLUDES startId (`filter (id: id != startId)`) — irreflexive — so the rest-position formulation must add `d == c` back explicitly; assuming reflexivity would have silently dropped every rest position's own content.
VERIFIED PROPERLY, three layers: source read at the pinned rev (which the agent confirmed the local clone actually IS, not a drifted one); the irreflexivity trap found by reading; and an EXECUTED equivalence probe over 9 relation shapes (empty/chain/diamond/multicast/forest/deep/branchy/converge/partial-depth) with a POSITIVE CONTROL — a variant dropping the rest-position guard DISAGREES on 8 of 9, agreeing only on `empty` where the guard is vacuous, so the equality is not vacuous.

ORDER IS LOAD-BEARING: E1's identity-drop MUST precede graph construction — `cycles` reports [] after the filter and ["A"] before.

### 2 — 2026-07-28T15:12:30 · Jason Bowman

★ DISCHARGED IN THE DESIGN — closing. The bucket-to-seed-query spec (abac0e0) now BINDS gen-graph rather than hand-rolling: 23 references to `reachableFrom`/`graph.transpose`/`graph.cycles` in the executable core and its prose, and §9.1/§11 R6 name this defect explicitly and cite this bead. The surviving 'hand-rolled' mentions are the HISTORICAL RECORD — the rejected first-revision E3, and the `lib/default.nix:2067` comment that forbade it — kept deliberately so the rejected construction leaves a trace.
POSITIVE CONTROL on the predicate: `gen-graph` matches 18 times in the same run, so the instrument finds the term and the 23 primitive hits are real.

★ AND THE ADOPTION WAS NOT THE MECHANICAL SWAP THIS BEAD IMPLIED — that finding survives the close and is the more valuable half. Verified against gen-graph's SOURCE at the pinned rev: `reachableFrom` EXCLUDES the start node, so the caller must re-add it or every rest position silently loses its own content; the library's rest-position formulation HAS NO RECURSION, so the cycle abort the hand-rolled `seen`-thread enforced FOR FREE would have vanished silently — measured, it returns an answer where the old code throws; and `condensation` is PARTIAL on this domain, failing with an error that ESCAPES `tryEval`. All three are recorded in the spec so the SCC option is not re-proposed as free.
⇒ STANDING LESSON, recorded in memory as reuse-scan rule 8: 'the library exists' establishes you should NOT hand-roll; it does NOT establish that the library's surface has your semantics. RIGHT LIBRARY, WRONG SURFACE IS INVISIBLE TO REVIEW — the diff reads as a simplification and the wrong answer is silent.

WHAT IS NOT CLOSED BY THIS: the design is UNIMPLEMENTED. This bead was about the DESIGN hand-rolling primitives, and that is fixed. The tree's `applyInjectReroute` is the construct being RETIRED and is tracked by den-hoag-4kh.16 itself. Removing the block so 4kh.16's critical path is not held by a satisfied blocker.
