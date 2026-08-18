# den-hoag-4kh.52 — [kernel] negates and from are unchecked annotations while emits is a checked contract — and concern-derived uses strict < for POSITIVE reads where ABW condition 1 permits <=, opposite to gen-resolve

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.52` |
| status at evacuation | open |
| priority | P2 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh` |
| created | 2026-07-28T22:20:43Z by Jason Bowman |
| last updated | 2026-07-28T22:20:43Z |
| description bytes | 2936 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

MEASURED 2026-07-28 while auditing ABW condition 2. Two defects in the same guard
layer, both about the gap between what a field DECLARES and what the engine CHECKS.

★ (1) `negates` AND `from` ARE UNCHECKED ANNOTATIONS, WHILE `emits` IS NOW A
CHECKED CONTRACT. Same shape, opposite treatment, in the same tree.
· lib/concern-derived.nix -- `negates` defaults to [ ] and BOTH negation guards
  SKIP when it is empty. A derive body that reads a relation and branches on its
  emptiness WITHOUT listing it in `negates` is invisible to the gate.
· lib/concern-productions.nix says it verbatim of `from`: "it DRIVES the L2 gate +
  documents the contract, IT IS NOT EXECUTED."
· Meanwhile the policy record's `emits` became a CHECKED contract -- conformingProduce
  verifies every emission against the declaration and aborts emitsUndeclared.
⇒ The soundness of every negation guard rests on the author having DECLARED the
negation. This is exactly the hazard the emits contract was built to remove, left
standing one file over. And it is the permissive-default failure mode
(feedback_absence_is_a_decision): absent `negates` means "negates nothing", so the
guard fails OPEN and the omission lives in code that does not mention the field.
NOT A REMEDY, but note the asymmetry to weigh: `emits` could be checked because
emissions are observable at the funnel they pass through. A negated READ is not
obviously observable the same way -- establish whether it is before assuming the
emits treatment transfers.

★ (2) THE TWO LAYERS TAKE OPPOSITE POSITIONS ON ABW CONDITION 1, AND ONE OF THEM
IS OVER-RESTRICTIVE.
· lib/concern-derived.nix uses STRICT `<` for the POSITIVE `over` read:
  notLater = any (s: !(strataLt strataOrder s stratum)) overStrata
  ABW Definition 3 condition 1 permits `<=` for positive occurrences -- same
  stratum is legal, and that is how intra-stratum positive recursion works.
· gen-resolve lib/schedule.nix gets it right: the violation predicate is `pb > pa`
  ONLY, with its own comment "a rule may read predicates at strata <= its own
  (positive dep); reading a STRICTLY-LATER stratum is the violation."
· den-hoag's own circular attributes RELY on the permissive reading:
  `resolved-aspects` and `reach` are self-reading circular attrs.
This is SOUND (strictly-stratified is a subset of stratified) but the layer CANNOT
EXPRESS intra-stratum positive recursion, so a legitimate den.derived that needed
it would be refused with a stratum complaint rather than a real one.
★ AND THE BINDING IS NAMED FOR THE BEHAVIOUR IT DOES NOT HAVE: `notLater`
describes `<=`; the code does `<`. A reader checking this layer against the paper
would read the name and move on.

WHY BOTH ARE FILED TOGETHER: they are the same layer's two halves -- what the
guard is TOLD (1) and what the guard DOES with it (2). Fixing either alone leaves
a guard whose faithfulness to Definition 3 is still unestablished in the other
direction.

## Comments (0)

(none)
