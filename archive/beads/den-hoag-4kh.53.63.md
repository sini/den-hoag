# den-hoag-4kh.53.63 — [M3+M4] the __ census — zero state carriers on nodes, ~23 carriers on rules/declarations unaudited, and the one staging-dependent field carries no __ prefix

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.63` |
| status at evacuation | open |
| priority | P2 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:15:00Z by Jason Bowman |
| last updated | 2026-07-29T00:15:00Z |
| description bytes | 1626 |
| notes bytes | 0 |
| comments | 1 |
| dependencies | `None` (None), `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

[M3+M4] MEASURED. THE `__` CENSUS: 31 distinct names, 219 occurrences, 20 non-compat kernel
files.
★ OF THE EIGHT THAT LIVE ON A NODE OR NODE CONTENT: FOUR ARE INERT TAGS, ZERO ARE STATE
CARRIERS. Two are markers for declarations NEVER MADE (`__contentless`, and `__forward` --
★ WRITTEN BY COMPAT THEN *REFUSED* BY COMPAT). `__edges` is written NOWHERE REACHABLE (N6).
`__coords` PROVES ITS OWN INERTNESS: its reader FALLS BACK TO `coordDims node`, WHICH
RECOMPUTES IT.
⇒ ★ THE AUDIT'S OWN CORRECTIONS LEDGER RECORDS THIS AS A REFUTATION: "the `__` surface is
criterion-2 (state carriers) at scale" is REFUTED FOR THE NODE-CARRIED SUBSET. Do not
re-litigate that; the v1 `__`-keys-are-state-hack framing does NOT transfer to den-hoag's
node surface.
DISPOSITION: NOT DEN-HOAG'S -- `__entry` (★ but see G2: this is INVERTED from what it looks
like) and `__edges` (gen-scope's convention, ★ which has no reader either).
DEN-HOAG'S -- `__root` (RETIRES UNDER N4/N5), `__coords`/`__containment` (PAYLOAD, KEEP),
`__firesAtKinds` (★ DELETE -- IT IS `sel.kind`; see D1), and ★★ ~23 MORE ON RULES,
DECLARATIONS AND THUNKS, **UNAUDITED AS A CLASS**.
★★ M4 -- AND THE CONVENTION DOES NOT MARK THE THING IT WOULD NEED TO. `suppressedPolicies`
is the ONLY FIELD WHOSE *PRESENCE* DEPENDS ON HOW FAR EVALUATION HAS PROGRESSED -- AND IT
CARRIES NO `__` PREFIX. ⇒ ANY FUTURE AUDIT KEYED ON `__` INHERITS THAT BLIND SPOT.
(It is also the field N2's dissolution moves, and it is load-bearing for ABW condition 2 --
see 4kh.51. The one staging-dependent field is the one the convention does not mark and the
one whose staging is load-bearing.)

## Comments (1)

### 1 — 2026-08-04T19:55:35 · Jason Bowman

★★ PREDICATE HAZARD FOR THIS BEAD'S OWN CENSUS, measured 2026-08-04 at ffaafb8, orchestrator-reproduced.
NOT a finding against the bead — a warning to whoever runs its count.

`git grep -n "__firesAtKinds" ffaafb8 -- lib/ ci/` → 9 lines, ALL in lib/compat/compile.nix, and EVERY ONE IS
A COMMENT LINE (:636, :1608, :1611, :1631, :1703, :1927, :1930, :2197, :2374 — each begins `#`).
Consistent with e6c8edc, whose own message records deleting "the three hand-written `!(r ? __firesAtKinds) ||`
copies": THE GUARD COPIES WENT, THE PROSE STAYED.
⇒ A CENSUS PREDICATE GREPPING `__firesAtKinds` COUNTS A LIVE CARRIER WHERE ONLY DOCUMENTATION REMAINS.
This is the general shape of law 51 (a bare-word grep cannot distinguish the construct from prose ABOUT the
construct) landing on a `__`-prefixed identifier, where one would least expect prose contamination.

★ CONSEQUENCE FOR THE "~23 CARRIERS" FIGURE IN THIS BODY: it is a pinned count with NO RECORDED COMMAND, and
it was deliberately NOT re-measured, because CARRIER-VERSUS-MENTION IS EXACTLY THE DISTINCTION THAT HAS TO BE
DEFINED BEFORE THE COUNT MEANS ANYTHING. Whoever runs this census states the predicate first — an
attribute-shaped one (`(^|[^A-Za-z_.-])__name\s*=`) rather than a bare word — and records it beside the
figure. Deriving a new number under an undefined predicate would replace one unreproducible count with
another, which is worse than the original because it carries the authority of a fresh measurement.

★ THE BEAD'S ANCHORS ARE OTHERWISE INTACT — zero drift. All nine cited identifiers present at ffaafb8:
`__containment` 5, `__contentless` 4, `__coords` 7, `__edges` 4, `__entry` 30, `__firesAtKinds` 4 (see above),
`__forward` 9, `__root` 1, `suppressedPolicies` 9 — file counts, command
`for s in ...; do git grep -c $s ffaafb8 -- lib/ ci/ | wc -l; done`. Its question is landing-independent.
