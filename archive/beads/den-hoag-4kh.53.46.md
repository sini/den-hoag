# den-hoag-4kh.53.46 — [G12] den-hoag runs a SECOND content-delivery engine in parallel with gen-edge, and edges.nix makes it permanent — the highest-value single item in the inventory

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.46` |
| status at evacuation | deferred |
| priority | P1 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:12:11Z by Jason Bowman |
| last updated | 2026-08-05T20:48:39Z |
| description bytes | 1723 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

★★★ THE HIGHEST-VALUE SINGLE ITEM IN THE INVENTORY, and it is NOT a line-count argument.
ARGUED.
`edge.materialize` IS CALLED ONCE, in `outputFor` (`output-modules.nix`), whose only
consumers are A COMPAT VERB AND THE PARITY ORACLE. ★ WHAT BUILDS THE ARTIFACT IS
`terminalModulesAt = projectClass`, A HAND-ROLLED `concatMap`.
★ THE FILE CONTRADICTS ITSELF THREE TIMES: its header calls the materialize fold "the only
content path (A15)"; a later comment says projection "supersedes the emission model
entirely"; a third says the built content is "not this fold".
★★ SO DEN-HOAG RUNS A SECOND CONTENT-DELIVERY ENGINE (`projectClass` + `lib/nest.nix`,
~300 code lines) IN PARALLEL WITH GEN-EDGE'S -- and `edges.nix` MAKES IT PERMANENT by
declaring the two NOT EQUAL for module-list payloads.
⇒ THAT IS WORSE THAN DUPLICATION, BECAUSE IT IS AN INVARIANT SOMEONE MUST MAINTAIN BY HAND
FOREVER.
RELATED EXTEND -- NEST PLACEMENT: gen-edge's materialize WRAPS THE WHOLE VALUE ONCE;
den-hoag needs PER-CONTRIBUTION-ITEM placement, stated as an invariant at `edges.nix`.
★ THAT IS WHY `lib/nest.nix` (19.9K) EXISTS AS A SECOND MATERIALIZATION ENGINE.
RESOLUTION: `materialize`'s nest arm places PER ITEM (or `adapt` applies per item); then
ONE engine. Line accounting: ~60-80 of nest.nix's 162 code lines recoverable that way; the
rest is den mode semantics.
★★ AND THE DEEPER STATEMENT, which is A8's theory question: den-hoag runs A SECOND EDGE
VOCABULARY WITH NO SHARED IDENTITY DISCIPLINE. gen-edge renders "<kind>:<idHash>";
den-hoag's query records are "<kind>:<name>", and `output-modules.nix` `nameOf = id: id;`
OPTS OUT OF nameSpec RENDERING ENTIRELY. A8's `or` is a patch; UNIFYING THE VOCABULARIES IS
THE THEORY QUESTION.

## Comments (0)

(none)
