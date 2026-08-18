# den-hoag-4kh.53.33 — [A8] relation edge targets are unvalidated and the failure is uncatchable by tryEval — gen-edge has the total primitive but a different edge vocabulary

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.33` |
| status at evacuation | open |
| priority | P1 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:09:42Z by Jason Bowman |
| last updated | 2026-07-29T00:09:42Z |
| description bytes | 879 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None), `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

[A8] ARGUED. RELATION EDGE TARGETS ARE UNVALIDATED AND THE FAILURE IS UNCATCHABLE.
`default.nix`: `to = "${entityKindOf target}:${target.name}";` with
`entityKindOf = entry: index.${entry.id_hash}` -- ★ NO `or`.
⇒ A target outside the index is an ATTRIBUTE-MISSING ERROR: UNCATCHABLE BY `tryEval`,
NAMING NO RELATION, NO ENTITY, AND NO FIELD. The relation NAME is validated; the TARGET
is not.
★ gen-edge HAS THE PRIMITIVE -- `core.nix` `toNameSpec` is TOTAL and THROWS NAMED -- BUT
IT IS NOT A DROP-IN, because these are a DIFFERENT EDGE VOCABULARY (G12): gen-edge renders
"<kind>:<idHash>" while den-hoag's query records are "<kind>:<name>", and
`output-modules.nix` `nameOf = id: id;` OPTS OUT of nameSpec rendering entirely.
⇒ Adding an `or` here is a PATCH. UNIFYING THE VOCABULARIES IS THE THEORY QUESTION, and it
is G12. File the patch only as an interim with that stated.

## Comments (0)

(none)
