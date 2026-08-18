# den-hoag-4kh.53.4 — [D2] NARROWED: matchIdWith is NOT unwired — it is driven at lib/default.nix matchIdStructural and was at the audit's own baseline; the surviving claim is that it is unwired into the THREE POLICY-DISPATCH SITES

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.4` |
| status at evacuation | closed |
| priority | P2 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:06:12Z by Jason Bowman |
| last updated | 2026-08-01T19:58:09Z |
| closed | 2026-08-01T19:58:09Z |
| close reason | RESIDUE DISCHARGED, witnessed at 693919f (closure scout, commands in the 53.3-thread report): matchIdWith reaches the policy-dispatch path — matchAt (lib/attributes/default.nix:54, scopeAdapter.matchIdWith { eval = self; } { } r.selects) is CONSUMED at both structural dispatch sites (policiesIndex.enrich/policy (matchAt self), structural.nix:192/:374, the D1 landing-2 mechanism). The third site (staged-resolution.nix:253) is excluded BY DESIGN, not unwired: a constant named throw with the in-file reason (a matcher carrying the resolve eval cannot be built before the eval exists) and unreachability secured at registration by firstUnstable — the D1 spec's IC-4/IC-11 ruling. Suites selects-position-dependent 4/4 + selects-lowering 18/18 exit 0 same session. The bead's surviving claim (unwired into the three policy-dispatch sites) is false at HEAD in the two ways that matter and answered-by-design in the third. |
| description bytes | 635 |
| notes bytes | 0 |
| comments | 1 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

[D2] MEASURED. den-hoag WROTE the scope adapter and never called it. `lib/scope-adapter.nix`
`matchIdWith` builds the gen-select scope context; its header says "A thin wrapper, no
algorithm of its own." ★ `matchId` HAS ZERO CALLERS -- one grep hit repo-wide, a comment.
It is the correct entry point for D1's resolution (see D3's navigational note: the
gen-side `mkMatch` forwards the wrong context object), so this is not dead code to
delete -- it is BUILT-AND-UNWIRED, and D1's fix is what wires it.
⇒ Scope with D1 rather than separately. Filed distinctly because "we already have the
adapter" changes D1's cost estimate materially.

## Comments (1)

### 1 — 2026-07-29T01:53:08 · Jason Bowman

★★ THE HEADLINE CLAIM IS REFUTED AT THIS BEAD'S OWN BASELINE, NOT MERELY EXPIRED. Retitled to the surviving claim rather than closed, because the narrower version is real and closing would discard it.

CLAIMED, and labelled MEASURED: 'matchIdWith has zero callers' and 'matchId has one grep hit, a comment'.
MEASURED NOW: lib/default.nix:1975 IS CODE —
    matchIdStructural = scopeAdapter.matchIdWith structural { classOf = classNameOf; };
★ AND IT EXISTED AT c42df53, THE AUDIT'S OWN BASELINE, as lib/default.nix:2029, IDENTICAL EXPRESSION. matchId additionally has TWO live callers at ci/tests/entity-fleet.nix:165,169, also present at c42df53.
⇒ THIS IS NOT STALENESS. A single grep at the commit the audit itself named would have refuted it on the day it was written. That is a different and worse failure than a claim overtaken by later work: staleness is the record decaying, this is the record never having been right.

SURVIVING CLAIM, and it is worth keeping: matchIdWith is unwired INTO THE THREE POLICY-DISPATCH SITES. That is a real gap and it is what this bead should now be read as tracking. Anyone scoping from the old title would have gone looking for a dead binding and found live code, then either concluded the bead was fixed or re-implemented something that exists.

★ METHOD CONSEQUENCE FOR THE WHOLE INVENTORY (den-hoag-4kh.53): a 'MEASURED' label is a claim about a PROCEDURE, and the procedure can be wrong. Two of the thirteen deep-verified children were refuted at their own baseline. The other sixty children of that inventory received only an identifier-existence sweep, which CANNOT detect this failure mode — it confirms a symbol exists, not that the claim about it holds.
