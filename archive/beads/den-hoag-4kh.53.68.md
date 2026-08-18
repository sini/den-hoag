# den-hoag-4kh.53.68 — [DECISION 3] is the no-mutation rule absolute, or does it admit a cited bounded exception for gen-resolve incremental override tier?

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.68` |
| status at evacuation | open |
| priority | P2 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:16:01Z by Jason Bowman |
| last updated | 2026-07-29T00:16:01Z |
| description bytes | 1055 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

★ OWNER DECISION 3 -- IS THE NO-MUTATION RULE ABSOLUTE?
`gen-resolve/lib/override.nix` REWRITES NODE DECLS AFTER CONSTRUCTION -- but it DOCUMENTS
ITSELF as an INCREMENTAL-RECOMPUTE TIER with a CITED SOUNDNESS ARGUMENT (RTD 1983 §4.3, the
REVERSE CONE AS A SOUND OVER-APPROXIMATION), and ★ DEN-HOAG DOES NOT WIRE IT.
⇒ THE QUESTION IS WHETHER THE STANDING DIRECTIVE ("mutability is bad; returning results in
attrsets is fine, patching a built thing is not") ADMITS A CITED, BOUNDED EXCEPTION FOR AN
INCREMENTAL TIER, OR WHETHER IT IS ABSOLUTE.
★ THE ANSWER IS NOT ACADEMIC: it decides whether den-hoag may ever wire gen-resolve's
override tier, which is the only incremental-recompute path in the ecosystem.
★ USEFUL PRECEDENT FROM THE SAME AUDIT (M2): the model of CORRECT staging is the edge
override tier, which runs `applyOverrides` ON RAW INTENTS, BEFORE IDENTITY EXISTS -- the
record does not exist until after. That is mutation-shaped work done without mutation, and
it suggests the rule can stay absolute if the tier is staged rather than exempted.

## Comments (0)

(none)
