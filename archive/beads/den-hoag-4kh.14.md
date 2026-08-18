# den-hoag-4kh.14 — [kernel] a throwing enrich value is swallowed and its key silently dropped from the context

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.14` |
| status at evacuation | closed |
| priority | P1 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh` |
| created | 2026-07-28T04:01:05Z by Jason Bowman |
| last updated | 2026-07-29T19:50:32Z |
| closed | 2026-07-29T19:50:32Z |
| close reason | FIXED and merged (a9ca187, 18592fc). Suite 1946 -> 1960, red set byte-identical both directions, verified independently on main with a cross-leak control; +14 is exactly the new silent-deletion suite. ★ 4kh.15 REFUTED THE ORCHESTRATOR'S RULING BY MEASUREMENT: 'empty declaration is an error' was implemented first and moved 92 checks red, 102 of 104 errors from one deliberately-inert v1 built-in (host-to-users = _ctx: [ ]), so an empty consequence set is a live legitimate shape. The taken reading makes the deletion UNREPRESENTABLE rather than refused and needs no new maintained invariant. 4kh.14's swallow was already discharged by 4kh.13's remedy landing, as this bead predicted; what remained was attribution, fixed with addErrorContext because tryEval cannot recover a caught throw's text. |
| description bytes | 3320 |
| notes bytes | 0 |
| comments | 1 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

MEASURED DEFECT IN SHIPPED CODE. A policy whose enrichment VALUE throws has its key SILENTLY DROPPED from the
enriched context. No abort, no warning, no trace — the key simply is not there.

SITE: lib/concern-policies.nix:343-345 (the enrich feed).
MEASURED with a control (scratchpad force.nix, by the agent that designed the den-hoag-4kh.13 remedy):
  · a policy whose enrich value THROWS at the real context  -> its key is ABSENT from the published context,
    silently. The evaluation continues.
  · its NON-THROWING twin, same fleet, same policy shape    -> key present. Control fires, so the fixture is
    not vacuous and the absence is caused by the throw.

WHY IT IS SEPARATE FROM den-hoag-4kh.13, and why it was NOT folded in: 4kh.13 is a NEGATIVE-EDGE CYCLE
publishing a fact whose premise vanished. This is a THROWN VALUE being swallowed on the same feed. Same file,
different mechanism, different remedy space. The agent that found it declined to fold it into its own design
and returned it as a review candidate rather than widening its scope — the correct call, and the reason it is
its own bead.

★ IT INTERACTS WITH 4kh.13's REMEDY AND THE INTERACTION IS THE INTERESTING PART.
The 4kh.13 proposal (`published == converged`, value-level) FORCES enrichment values. Measured: a value that
is fine at the stratum probe but throws at the real context lands SILENTLY UNFORCED today and ABORTS under
that proposal. So 4kh.13's remedy would CONVERT THIS SILENT DROP INTO A LOUD FAILURE as a side effect.
BOUNDED, and this is what keeps the blast radius small: the shipped probe ALREADY forces every enrich value,
so the class of values that reach the new comparison unforced is narrow — those fine at the probe context and
throwing at the real one.
⇒ WHOEVER LANDS 4kh.13 MUST DECIDE WHETHER THAT CONVERSION IS INTENDED. It is a behaviour change on a live
path arriving as a side effect of a different fix, which is exactly the shape that should not land
unremarked. If it IS intended, this bead is discharged by that landing and should say so. If it is NOT, the
4kh.13 remedy needs to distinguish the two cases.

WHY IT IS A DEFECT ON ITS OWN TERMS: a throw is the author's own diagnostic. Swallowing it and continuing
with the key absent means a downstream consumer destructuring that key gets an attribute-missing error at a
site with no relation to the policy that failed — or, worse, a consumer with an `or` default silently takes
the default and the fleet builds wrong. Compare den-hoag-4kh.13's own finding: the enriched context reaches
MATERIALIZED NixOS OPTIONS, so a silently-absent key is not confined to policy dispatch.

ACCEPTANCE: a fixture whose enrich value throws, pinning that the failure is NAMED and attributable to the
producing policy. Against the current tree it will show the key silently absent; that is the point. Under the
three-state CI ruling it lands as a known-fail with a tracked id.

NOT MEASURED: whether any corpus config has a policy whose enrich value can throw at a real context. Not
searched. Do not upgrade the claim past "reachable and measured on a synthetic fixture".

PROVENANCE: surfaced while measuring the honest cost of the den-hoag-4kh.13 remedy — the agent was
establishing what its own proposal would force, and found the current behaviour on the same feed.


## Comments (1)

### 1 — 2026-07-29T19:50:31 · Jason Bowman

★ FIXED — a9ca187, merged. AND HALF OF THIS BEAD WAS ALREADY DISCHARGED, EXACTLY AS IT PREDICTED.
Measured at HEAD BEFORE changing anything: a throwing enrich value ALREADY ABORTS — it does not silently drop the
key. This bead predicted it ('4kh.13's remedy would CONVERT THIS SILENT DROP INTO A LOUD FAILURE') and 4kh.13's
remedy has landed (errors.unsupportedEnrichment, agree/project).
WHAT REMAINED IS THIS BEAD'S ACTUAL ACCEPTANCE — 'the failure is NAMED and attributable to the producing policy' —
AND IT WAS NOT MET: the trace was a bare 'error: <author's throw>' with no mention of the policy.
★★ AND IT CORRECTLY REJECTED MY tryEval NOTE: neither mechanism I flagged was in play — the swallow was the
retired probe. Two reasons tryEval is the WRONG instrument, now written in-file: it would have to CATCH in order
to name, and NIX CANNOT RECOVER A CAUGHT THROW'S TEXT, so it trades one half of the diagnosis for the other; and
it cannot catch the non-recoverable class at all, which is exactly what a body reading an absent ctx field raises.
FIX: builtins.addErrorContext, attached at the binding in delta where the fact AND its deriving rule are both in
scope. It DECORATES rather than catches — original error verbatim, frame added, total over error classes, and an
unforced application so laziness and abort ordering are untouched.
A/B ON THE SHIPPED CODE with one identical uncaught-abort probe: without -> 'evaluating enrichments on node:h' ->
'error: MUTATION-PROBE-BOOM'; with -> 'while forcing the enrichment fact t, derived by policy the-writer (B1
enrichment; the error below is the policy's own)' -> 'error: MUTATION-PROBE-BOOM'. Named policy, named key,
author's diagnostic preserved verbatim. Restored md5 46aa587ff89dfca523bdce64b8745b3b, verified.
★★ COVERAGE LIMIT STATED IN THE FIXTURE HEADER RATHER THAN LEFT IMPLIED: THE ATTRIBUTION FRAME IS NOT
SUITE-ASSERTABLE — mutating it away leaves the suite GREEN. test-throwing-enrich-value-is-loud pins the LOUDNESS
(a regression to the swallow would break it), NOT the naming; the proof is the trace. ★ And the frame's extent is
ONE FORCE TO WHNF: a throw nested deeper inside an already-WHNF enrich value raises after the frame returns and is
undecorated. Closing that means deepSeq-ing every fact at its binding — A STRICTNESS CHANGE ON A LAZY CONTRACT, a
worse defect than the one it diagnoses. Stated in lib/errors.nix.
★ BOTH BEADS WERE STALE AGAINST HEAD and were re-derived by measurement first: they cite concern-policies.nix
:343-345 / :305-319 / :267 / :357 and the producesByName table, NONE OF WHICH EXIST AT HEAD — e6c8edc retired
producesByName for a declared emits field and deleted the fire-and-classify probe. producesByName survives only as
a compat name->kinds table at lib/compat/produces-by-name.nix.
