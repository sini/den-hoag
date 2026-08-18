# den-hoag-4kh.9 — Re-run W1/W2 with Nix-aware codebase-memory when it lands (owner-signalled)

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.9` |
| status at evacuation | open |
| priority | P2 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh` |
| created | 2026-07-27T20:35:40Z by Jason Bowman |
| last updated | 2026-07-27T20:35:40Z |
| description bytes | 2320 |
| notes bytes | 0 |
| comments | 2 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

TRIGGERED BY OWNER SIGNAL: a major codebase-memory improvement lands proper NIX SEARCH. Do not start before
the signal.

WHY THIS IS AN UPGRADE PASS, NOT A RESTART. W1's highest-value output is the SHIPPED-RENAMED-ONLY bucket —
"is the accumulator/trampoline/bucket actually gone, or present under a gen-native name?" That is a STRUCTURAL
question and grep is the wrong instrument. Same for W2 criteria 1 (state accumulation instead of query), 4
(bounded-depth traversal), and 5 (effect-runtime holdovers) — all shape questions currently approximated by
text search. Symbol, call-graph and data-flow queries answer them directly.

SCOPE WHEN TRIGGERED:
  1. Re-run den-hoag-4kh.1 (W1) and den-hoag-4kh.2 (W2) with graph-backed queries. Treat the text-search
     results as a PRIOR to be confirmed or refuted, not as a baseline to match — a disagreement between the
     two instruments is itself a finding, and the graph result wins only where it can show its work.
  2. Index the relevant repos first (index_repository) and CONFIRM Nix coverage with get_architecture before
     trusting any query — a language absent from the extracted list yields zero for every real identifier,
     which is indistinguishable from a clean result.

TWO ARTIFACTS GO STALE THE MOMENT IT LANDS, and both currently INSTRUCT AGENTS TO AVOID THE NEW CAPABILITY:
  - Memory `reference_codebase_memory_no_nix` — records ZERO Nix symbols for den-hoag/gen-*/nix-config and
    says to use Read+Grep and skip search_graph. Must be rewritten, not deleted: the correct replacement
    states what IS covered and how to verify coverage.
  - The SessionStart hook's Code Discovery Protocol (installed in nix-config, corrected there at 2ff20571)
    says "NIX IS NOT COVERED ... do not spend turns on search_graph or trace_path". That text ships to every
    session in every repo and will actively steer agents away from the new capability.
  Both must be updated as part of this task, or the improvement will be invisible to future sessions.

ALSO NOTE: subagents are SESSION-SCOPED and do not survive a session exit/resume. Relaunch is cheap by design
because bead bodies are self-contained specifications — but any partial findings held by a running agent are
lost on exit, so results are recorded to beads as they land rather than at the end.

## Comments (2)

### 1 — 2026-07-27T20:48:41 · Jason Bowman

FIRST TARGET WHEN TRIGGERED: the A1 runPrePass verdict. W1 (den-hoag-4kh.1) went unresponsive without delivering it, and it is the single most load-bearing result outstanding — it decides whether den-hoag-9xo's 'No effect-runtime duplication remains' or den-hoag-4kh's use of that same accumulator as a known-positive violation is the false statement. The question is 'is the accumulator GONE, or present under a gen-native name?', which is exactly the structural query grep cannot settle. Route-through-board records the rung SHIPPED at 6bef742. Salvaged context: all three gates (ci, parity, ship-gate allEqual) are GREEN at HEAD and settle nothing here — den-hoag-9xo.27 established the gates cannot fail on this class of change.

### 2 — 2026-07-27T21:33:58 · Jason Bowman

INSTRUMENT VERIFIED AND CALIBRATED (2026-07-27, session resumed with Nix-aware codebase-memory). Read this
BEFORE any agent uses the graph, and treat the two limitations as load-bearing.

VERIFICATION: den-hoag indexed at 3094 nodes / 9279 edges, 2213 Function nodes, edge types incl. CALLS 1461,
USAGE 4182, DEFINES 2730. Positive control PASSED: search_graph "runPrePass" resolves to
lib/staged-resolution.nix:131-446 as a Function. Nix symbols ARE extracted.

★ TRAP 1 — get_architecture's `languages` FIELD DOES NOT LIST NIX. It reports only YAML (3 files) and
Python (1). An agent following the standing instruction "confirm coverage via get_architecture before
trusting a query" would read that field, conclude Nix is uncovered, and fall back to grep — discarding the
whole capability. COVERAGE MUST BE CONFIRMED BY A KNOWN-POSITIVE SYMBOL QUERY, not by the languages list.

★★ TRAP 2 — CALLS EDGES MISS ATTRSET-MEDIATED CALLS, WHICH IS NIX'S DOMINANT IDIOM. Measured:
  trace_path runPrePass inbound  -> ZERO callers
  grep runPrePass                -> lib/default.nix:1097  `prePass = stagedResolution.runPrePass { ... }`
The call is real; the graph does not see it, because the callee is reached through an imported attrset
(module imported as a value, member called off it) rather than by a bare identifier.
POSITIVE CONTROL PROVING THE DIRECTION WORKS AT ALL: trace_path fail inbound -> 23 callers. So caller-tracing
is functional; it is specifically the attrset-mediated cross-module call that is invisible.
⇒ "ZERO CALLERS" FROM THIS GRAPH IS NOT EVIDENCE OF DEAD CODE. Every zero-caller result must be cross-checked
with grep before any conclusion, and especially before any deletion. Within-file CALLS appear reliable;
cross-module CALLS through an attrset are incomplete.

CONSEQUENCE FOR THE RELAUNCH: the graph is a genuine upgrade for STRUCTURE questions (what exists, what a
function calls, clustering, fan-in ranking) and must NOT be trusted alone for REACHABILITY or
liveness/deadness. The text-search prior from the previous session is not superseded — the two instruments
are complementary, and a disagreement between them is a finding to investigate, not a tie to break by
preferring the newer tool.

SUBSTANTIVE LEAD FOR THE A1 QUESTION, established while calibrating (NOT a verdict):
  - runPrePass is LIVE: lib/staged-resolution.nix:131-446 (315 lines), called at lib/default.nix:1097.
  - Its own header comment, lib/staged-resolution.nix:104, calls it "the transpose carrier. Returns
    { tuples; containmentBindings; containmentAncestors; ... }" — language consistent with the claimed
    dissolution ("runPrePass state-accumulator DISSOLVED -> prelude.groupBy per-target carrier + demand-read").
  - Direct callees per the graph: kindParent, mintedRootId, rootNodeIndex, baseCtxOf, fireFeedAt,
    isContainment, attachmentsOf, foldBindings, ownedBy, deliverCtxOf.
  - Graph clustering puts it in one cluster with mkDen, buildRoots, mintedRootId, ancNodeId (cohesion 1.0).
  ⇒ THE FUNCTION SURVIVED THE RENAME. Whether the ACCUMULATOR SHAPE survived — i.e. SHIPPED-REAL vs
    SHIPPED-RENAMED-ONLY — is exactly the open question and is NOT answered by any of the above. 315 lines is
    a large "carrier". This is the W2 question; do not infer the verdict from the name or the comment.
