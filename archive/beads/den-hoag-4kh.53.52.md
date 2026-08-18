# den-hoag-4kh.53.52 — [G2+G3+G5] gen-select bakes den-hoag private __entry into a library default and inverts who owns the convention — plus a live __coords collision and gen-scope prescribing twice

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.52` |
| status at evacuation | open |
| priority | P2 |
| type | bug |
| labels | (none) |
| parent | (none) |
| created | 2026-07-29T00:13:09Z by Jason Bowman |
| last updated | 2026-07-29T00:13:09Z |
| description bytes | 1532 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

[G2+G3+G5] ARGUED/MEASURED. gen-select's DEFAULT HARD-CODES DEN-HOAG'S PRIVATE KEY, and
the natural reading is INVERTED.
`gen-select/lib/adapters/scope.nix`: `entryFor ? (id: (node id).decls.__entry or null),`
with a comment naming den-hoag and asserting that gen-scope reserves the `__` namespace.
★ `__entry` IS MINTED BY DEN-HOAG (`build-roots.nix`, `fleet.nix`); GEN-SCOPE WRITES ONLY
`__edges`. ⇒ A LIBRARY DEFAULT ENCODES A CONSUMER'S CONVENTION, NAMES THAT CONSUMER IN A
COMMENT, AND ASSERTS A NAMESPACE RESERVATION THAT LIVES IN THE WRONG LIBRARY AND IS
ENFORCED IN NEITHER.
★★ `__entry` IS NOT A GEN CONTRACT DEN-HOAG MUST HONOUR; IT IS DEN-HOAG'S CONVENTION THAT
GEN-SELECT BAKED INTO A DEFAULT. (Recorded in the audit's corrections ledger as a claim it
made and inverted.)
RESOLUTION: `entryFor` has NO DEFAULT, or defaults to `id: node id` with the caller
projecting. If the convention is to exist, IT BELONGS IN GEN-SCOPE AS A WRITTEN KEY WITH A
READER -- the same EXTEND as N4.
★ G3 -- A LIVE `__coords` COLLISION: gen-select's product adapter WRITES `__coords` and
THROWS ON ITS ABSENCE; den-hoag INDEPENDENTLY writes `decls.__coords` on cells AND STRIPS
IT IN FOUR PLACES. SAME SPELLING, TWO PRODUCERS, ONE OF WHICH REMOVES IT. ★ WHETHER THEY
ARE THE SAME CONCEPT WAS NOT ESTABLISHED -- establish that before either is touched.
★ G5 -- gen-scope SPECIFIES CONVENTIONS IT DOES NOT IMPLEMENT, TWICE IN ONE LIBRARY: the
`@parent` multi-attachment convention (N4) and this `__` decls namespace. One shape, two
instances.

## Comments (0)

(none)
