# den-hoag-4kh.49 — [kernel] excludedType drops raw/deferredModule fields 'to keep them out of deepSeq'd resolution state' — no such deepSeq exists at HEAD; this is witness 5's mechanism and it gates P3

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.49` |
| status at evacuation | deferred |
| priority | P1 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh` |
| created | 2026-07-28T20:48:42Z by Jason Bowman |
| last updated | 2026-08-05T20:48:33Z |
| description bytes | 2948 |
| notes bytes | 0 |
| comments | 1 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

★★ THE CHARTERING PREMISE FOUND IN THE WILD — A v1-ERA CONSTRAINT RETAINED WITH ITS ORIGINAL RATIONALE, AND
THE RATIONALE IS NOT WITNESSED AT HEAD. THIS GATES P3 OF THE REFACTOR ORDER.

`excludedType` drops `raw` / `deferredModule` / `anything` fields from the entity record. Justified at FOUR
sites — lib/compat/registry.nix:226, :296 and lib/compat/ingest.nix:58, :418 — by:
    "must never enter deepSeq'd resolution state."
★ NO SUCH deepSeq EXISTS AT HEAD. The kernel's deepSeqs are exactly: the policy probe
(concern-policies.nix:185), a totality probe (query.nix:86), and two EAGER OUTPUT-TABLE validations
(default.nix:2607, :2618). The one deepSeq on the resolution path is gen-scope/lib/build-nodes.nix:66, under
`strict ? true` (:17) which den-hoag never overrides — AND IT COVERS ONLY `parentIndex`, A MAP OF NODE-ID
STRINGS, NOT decls AND NOT ENTITY VALUES.
POSITIVE CONTROL, same predicate same run: the identical `grep -rn "strict"` that returned no assignment in
`lib/` (excluding `compat/`) DOES return `strict ? true,` at build-nodes.nix:17 and `if strict then` at :66.
So the instrument finds the construct where it exists.

★ THIS IS WITNESS 5's MECHANISM. v1 declares `aspect` as `lib.types.raw` (denful/den @ 99cc0c5a,
nix/lib/entities/host.nix:70) — so `excludedType` is EXACTLY WHAT DROPS IT, and with it `environment` and
`microvm`. The missing-host-field class (den-hoag-9xo.49) is not three oversights; it is one exclusion rule
doing what it was written to do, for a reason that may no longer obtain.

★★ WHAT IS AND IS NOT ESTABLISHED — the auditor was explicit and I am preserving the distinction:
  ESTABLISHED: the STATED CAUSE is not witnessed at HEAD, and nobody has re-derived it.
  NOT ESTABLISHED: that the exclusion is unnecessary. It may STILL be load-bearing — for identity hashing, or
  for the terminal merge — by a mechanism nobody has written down.
⇒ THE OWNER-LEVEL QUESTION: RE-DERIVE WHETHER `excludedType` IS STILL REQUIRED, AND IF SO, FOR WHAT. P3
(entity record derives from the schema) CANNOT BE DESIGNED UNTIL THIS IS ANSWERED, because P3's whole content
is which fields reach the record.
★ AND IF IT IS NOT REQUIRED, DO NOT SIMPLY DELETE IT — the four sites carry the same sentence, so whatever
replaces it must be stated once and cited, or the next reader re-derives the same dead justification from the
same comment.

WHY THIS ENTRY MATTERS BEYOND ITS OWN FIX: den-hoag-4kh was chartered on the premise that "a v1-shaped state
accumulator wearing gen-native naming passes every guard", and that `ci/tests/boundary.nix` guards the line
LEXICALLY ONLY so it cannot observe representation. THIS IS THAT PREMISE INSTANTIATED: a constraint inherited
from an evaluation model den-hoag no longer has, justified by a comment nobody re-checked, silently deleting
user-declared fields, GREEN ON EVERY GUARD. It was found by reading the justification and looking for the
thing it names — not by any test.


## Comments (1)

### 1 — 2026-07-28T21:21:34 · Jason Bowman

★★ VERDICT: **NOT LOAD-BEARING** — and this bead's PREMISE WAS STALE, which changes what P3 is about.

★ `excludedType` DOES NOT DROP FIELDS FROM THE ENTITY RECORD. It stopped doing that at commit `77cb3c8`
("feat(compat): #70 — raw ctx-entity fields ride a lazy side channel", ledger row u20). At HEAD it PARTITIONS
FIELDS ACROSS TWO TRANSPORTS: `stampTreeOf` (registry.nix:292) → `_entityStamps`, `rawStampTreeOf` (:304) →
`_entityRawStamps` (bridge.nix:299,363), both overlaid onto the ctx entity at ingest.nix:435 / :441 / :722.
★★ AND `stampFieldNamesByKind` (ingest.nix:449-456) **UNIONS BOTH TREES' NAMES**, so THE KERNEL-DECLARED FIELD
SET IS IDENTICAL WITH OR WITHOUT THE EXCLUSION. `excludedType` selects WHICH CHANNEL A FIELD'S VALUE TRAVELS
ON — not which fields reach the record.
⇒ P3's STATED CONTENT — "which fields reach the record" — ALREADY HAS ITS ANSWER AT HEAD: **ALL DECLARED
REGISTRY FIELDS DO.** P3's real open content is whether the field set should keep coming from A PARALLEL
nixpkgs-lib EVAL OF THE REGISTRY at all, rather than from `den.schema` directly.
Also: `excludedType` occurs in `lib/compat/registry.nix` ONLY (:235,:243,:292,:304,:527). ingest.nix:58 and
:418 are the JUSTIFICATION COMMENT, not call sites. Positive control: the same grep returns the five registry
lines, so the instrument finds the symbol where it exists.

FALSIFIER, scratch clone, exit read adjacent: ci 1946/1946 EXIT 0 → **1940/1946 EXIT 1** widened (5 ❌ + 1 ☢️);
parity 71/71 EXIT 0 BOTH; ship gate `allEqual: true` EXIT 0 both, ★ with the SAME THREE STORE PATHS as
baseline — equal to baseline, not merely equal to each other.
ALL SIX FAILURES CLASSIFIED **(iii) — TESTS ASSERTING THE EXCLUSION ITSELF**, zero (i). One header literally
calls itself "THE ABSENCE PIN". ★ And the direct negative for the identity hypothesis: in
`compat-raw-field-stamp.test-safe-stamp-and-identity-unchanged`, only `noRawHasNoGuests` flipped —
`sameIdHash`, `sameName`, `sameRole` ALL HELD.

★★ THE DECISIVE MEASUREMENT, because the falsifier alone cannot settle it (widening empties the raw channel
too): a 2×2 placing a THROWING value in the safe stamp only / the raw stamp only / neither, run AT HEAD's
UNWIDENED predicate. RESULT — **SYMMETRIC**: neither channel is forced by resolution (`spine`) or by the
gather (`gathered`); BOTH abort identically under a full `deepSeq` of the output member (`fullMember`).
**THE PARTITION BUYS NOTHING.** Positive controls named inline: `clean.fullMember = true` proves the predicate
can return true; `rawOnly.live = false` and `safeOnly.live = false` prove the poison is live and reachable
through the ctx entity on both arms.
★ AND A SELF-CAUGHT INSTRUMENT ERROR, reported because it produced a false green on the first pass:
`deepUnionStamps` lets `b` win at a non-attrs leaf, so the clean raw overlay SILENTLY CLOBBERED the
safe-channel poison. Fixed by removing the clobbering entry. A sound predicate proving a different
proposition, caught by the author.

★ THE ONE REAL DEPENDENCE, AND IT IS NOT CORRECTNESS: `deepUnionStamps`' cheapness argument rests on THE TWO
TREES' LEAF SETS BEING DISJOINT, which `excludedType` guarantees BY CONSTRUCTION. So the predicate is
load-bearing FOR THE MECHANISM #70 BUILT AROUND IT, not for any property of the record. Delete the predicate
and the dual channel goes with it.

★★ Q3 — WHAT v1 DID, AND IT IS THIS EPIC'S CHARTERING PREMISE INSTANTIATED. v1 **HAD** the deepSeq the comment
names — `denful/den` @ 99cc0c5a `nix/lib/aspects/fx/pipeline.nix:99-106`: "Fields wrapped as thunks (`_: value`)
survive builtins.deepSeq — the trampoline deepSeqs state at each step, but deepSeq on a function forces the
closure, not its application", with `:171` `scopeContexts = _: { };`. ⇒ v1 SOLVED IT WITH A LAZINESS BARRIER,
AND ITS ENTITY RECORD IS COMPLETE — `raw` fields and all (`nix/lib/entities/host.nix:70` `aspect` = raw, `:81`
`instantiate` = raw).
★ SO THE COMMENT IS A **TRANSPOSED INHERITANCE**: v1's constraint was on the STATE ACCUMULATOR and was solved
by THUNKING; den-hoag re-expressed it as a constraint on the RECORD and solved it by DELETION. den-hoag has no
trampoline and no state accumulator, so THE CONSTRAINT HAS NO REFERENT. Same shape as the `__`-keys
state-hack: a v1 mechanism's rationale surviving into a system that does not have the mechanism.

CORRECTIONS TO THIS BEAD AND TO MY BRIEF: the sentence is at NINE source/test sites plus FOUR ledger rows, not
four — and `lib/compat/flake-module.nix:298-299` WRAPS A LINE, so single-line greps miss it. ★ AND THE AUDIT'S
deepSeq CENSUS WAS INCOMPLETE: `lib/compat/parity/oracle.nix:504` has a real `builtins.deepSeq` over
`denOn.output.systems.<cls>.<id>` in shipped `lib/` — a class-share parity oracle, not the resolution path, so
not the hazard the comment names, but the census as stated was not total.
REPLACEMENT JUSTIFICATION: ONE canonical block at the definition site (registry.nix:222-233), every other site
reduced to "see registry.nix `excludedType`". It must say (1) the predicate partitions TRANSPORT, not
membership; (2) the invariant it actually buys is DISJOINT LEAF SETS, which is what makes `deepUnionStamps` a
group-walk that never forces a leaf — name that as the load-bearing property; (3) ★ KILL THE deepSeq CLAIM AND
SAY WHY IT IS DEAD, citing v1's thunking answer, or the next reader re-derives it from the same comment.
★ AND IF THE EXCLUSION IS REMOVED, FOUR OF THE SIX PINS MUST BE REWRITTEN TO ASSERT DISJOINTNESS RATHER THAN
ABSENCE — otherwise the pins re-encode the dead reason.

WHAT THIS DOES NOT COVER, stated by the investigator: no drvPath on the real corpus (both arms die at an
unrelated `attribute 'id_hash' missing` at collections.nix:205:32, with 249-line traces BYTE-IDENTICAL modulo
the den narHash). ★ The ship gate is NEAR-VACUOUS here — its host declares NO `raw`-typed value at all, so
widening literally cannot change its stamp; its green is a spine result. ★ `deferredModule`/`anything` WERE
NEVER EXERCISED — all witnesses were `types.raw`/`listOf raw`, and an `anything`-typed value entering the safe
stamp CHANGES THE NIXPKGS MERGE (it deep-recurses to pick a merge function), a genuinely different failure
surface. If any part of this is still load-bearing, that is where to look.
