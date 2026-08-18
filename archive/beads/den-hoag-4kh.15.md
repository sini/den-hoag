# den-hoag-4kh.15 — [kernel] an empty producesByName entry compiles the policy away entirely — total silent deletion

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.15` |
| status at evacuation | closed |
| priority | P1 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh` |
| created | 2026-07-28T04:10:38Z by Jason Bowman |
| last updated | 2026-07-29T19:50:32Z |
| closed | 2026-07-29T19:50:32Z |
| close reason | FIXED and merged (a9ca187, 18592fc). Suite 1946 -> 1960, red set byte-identical both directions, verified independently on main with a cross-leak control; +14 is exactly the new silent-deletion suite. ★ 4kh.15 REFUTED THE ORCHESTRATOR'S RULING BY MEASUREMENT: 'empty declaration is an error' was implemented first and moved 92 checks red, 102 of 104 errors from one deliberately-inert v1 built-in (host-to-users = _ctx: [ ]), so an empty consequence set is a live legitimate shape. The taken reading makes the deletion UNREPRESENTABLE rather than refused and needs no new maintained invariant. 4kh.14's swallow was already discharged by 4kh.13's remedy landing, as this bead predicted; what remained was attribution, fixed with addErrorContext because tryEval cannot recover a caught throw's text. |
| description bytes | 2590 |
| notes bytes | 0 |
| comments | 1 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

MEASURED DEFECT IN SHIPPED CODE, WORSE IN KIND THAN THE ONE IT WAS FOUND BESIDE.

`producesByName.<name> = [ ]` classifies to NO STRATUM, so `mkDeclaredSlices` maps over an EMPTY GROUP LIST
and builds ZERO RULES. The policy is COMPILED AWAY ENTIRELY and its body never fires at any node. Silently.

TOTAL DELETION, NOT PARTIAL LOSS. The adjacent defect (den-hoag-4kh.6 Candidate A) drops emissions OUTSIDE
the declared family — a policy still runs and still produces something. This one removes the policy from the
compiled rule set altogether: no acts, no error, no trace, nothing reddens.

REACHABLE BY THE SAME DATA PATH: `producesByName` is a name-keyed external table installed for every compat
consumer with no check that any entry corresponds to a real body. An empty list is a well-formed entry.
UNTESTED: the three `__produces` fixtures (ci/tests/compat-policy-expansion.nix:421,451,498) all declare
non-empty families that match their bodies, so the empty case is exercised nowhere.

SITES: lib/concern-policies.nix:305-319 (`mkDeclaredSlices`), :267 (`mkSlice`'s per-stratum filter), :357
(the `declaredKinds` read). `lib/concern-policies.nix` is KERNEL — confirmed against ci/tests/boundary.nix:37
`coreFiles` — so this is a kernel defect, not a compat one.

PROVENANCE: surfaced while designing the remedy for the name-keyed-trust defect
(specs/2026-07-28-produces-declaration-trust-design.md). The author was enumerating the totality matrix for
its own proposal and found the empty-declaration row produces total deletion on the CURRENT tree. It was NOT
folded into that design's scope beyond being aborted by the proposed core; it is recorded here so the DEFECT
survives independently of that remedy's fate.

RELATIONSHIP TO THE REMEDY: the proposed core aborts this case NAMED (matrix row D7). If that design lands,
this bead is discharged by it and should say so. If the design is rejected or reshaped, THIS DEFECT REMAINS
and needs its own answer — which is the reason it is filed separately rather than living inside a spec.

ACCEPTANCE: a fixture declaring `producesByName.<name> = [ ]` for a policy with a non-empty body, pinning
that the policy still compiles to rules — or that the empty declaration aborts named. Against the current
tree the policy vanishes; that is the point. Under the three-state CI ruling it lands as a known-fail with a
tracked id.

NOT MEASURED: whether any corpus config supplies an empty produces entry. The five shipped table keys all
carry non-empty families. Do not upgrade the claim past "reachable and measured on a synthetic fixture".


## Comments (1)

### 1 — 2026-07-29T19:50:30 · Jason Bowman

★★★ FIXED — 18592fc, merged. AND THE ORCHESTRATOR'S RULING WAS REFUTED BY MEASUREMENT, WHICH IS THE BEST AVAILABLE OUTCOME.
My dispatch leaned toward 'empty declaration is an ERROR'. THE IMPLEMENTER BUILT THAT FIRST. ★ IT MOVED 92 CHECKS
RED, and 102 of the 104 new ☢️ traced to ONE POLICY: host-to-users at lib/compat/builtins.nix:428, literally
'_ctx: [ ]' — a v1 built-in that MUST exist as an attribute so den.schema.host.excludes = [ den.policies.host-to-users ]
resolves, AND MUST NEVER EMIT. ★ ORCHESTRATOR VERIFIED INDEPENDENTLY: the line is at :428, positive control 3 hits
for host-to-users in that file.
⇒ A RULE WITH A GENUINELY EMPTY CONSEQUENCE SET IS A LIVE, LEGITIMATE, SHIPPED SHAPE. 'An emitter of nothing is
not a rule' IS FALSE ABOUT THIS PROGRAM.

THE RULING TAKEN, this bead's FIRST acceptance arm: emits = [ ] IS AN EMPTY HEAD, NOT AN ABSENT RULE. The three
readings, decided by representation rather than preference:
· EVERYTHING — UNREPRESENTABLE, and refused by a law already present: the stratum is DERIVED from the codomain,
  and an all-kinds codomain SPANS STRATA, which policyMessage already rejects.
· NOTHING (delete) — REFUSED. It reads an under-specified declaration as a DELETION ORDER, and takes selects,
  gate and fleet-wide ops with the body, since every feed is a filter over the compiled rules. It also conflates
  'I deliberately produce nothing' with 'my codomain could not be determined'.
· AN EMPTY CONSEQUENCE SET — TAKEN. A clause with no head is an ordinary clause form: it is in P, T_P maps over
  it, it contributes nothing to the model, and DROPPING IT FROM P YIELDS A DIFFERENT PROGRAM.
★★ AND IT BEATS THE ERROR READING ON MY OWN STATED CRITERIA: IT MAKES THE DELETION UNREPRESENTABLE RATHER THAN
REFUSED. compileOne is now TOTAL onto exactly one rule per declared policy with no arm yielding none — no value of
emits can remove a policy from the compiled set; a policy disappears only by not being written. The honest reading
is enforced by the contract every other policy already runs (a body emitting under an empty head aborts named at
the emitting site via conformingProduce -> errors.emitsUndeclared). ⇒ NO NEW INVARIANT FOR ANYONE TO MAINTAIN,
which the error reading WOULD have required — a named compat exclusion list for host-to-users.
★ SUB-DECISION DECIDED, NOT DEFAULTED — the empty head's STRATUM: ABW Def 3 p.96 constrains a clause's level
THROUGH THE RELATIONS IN ITS HEAD; an empty head imposes NO LOWER BOUND, so the bottom stratum is canonical, and
it is also the most restrictive A9 ctx capability and the earliest firing. ★ PINNED AGAINST declare.strata RATHER
THAN SPELLED, so inserting a stratum cannot leave the test asserting a stale name.
MUTATION PROOF: restoring the 'if emits == [ ] then [ ]' arm reds 7 of 14 by name. No 4kh.14 check moved, so the
two fixes are INDEPENDENT. Restored md5 4589d268de916b3c866177f3cef742d4, verified.
