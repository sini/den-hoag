# den-hoag-4kh.53.26 — [S12] probe tree and build tree are different evals — a schema declaration conditional on an unset concern option sees absent in one and empty in the other

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.26` |
| status at evacuation | open |
| priority | P2 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:08:36Z by Jason Bowman |
| last updated | 2026-07-29T00:08:36Z |
| description bytes | 712 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None), `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

[S12] ARGUED, LATENT. PROBE TREE AND BUILD TREE ARE DIFFERENT EVALS.
The probe declares only `options.schema` under a freeform `den`; the build tree adds ~35
CONCERN OPTIONS *WITH DEFAULTS*. ⇒ A user module whose schema declaration is CONDITIONAL
ON AN UNSET CONCERN OPTION sees ABSENT in one and `{ }` in the other.
Corpus-unreachable today. NO GUARD FOUND.
★★ THIS IS NOT A REFACTOR -- IT IS A SEMANTIC CHANGE, AND THE AUDIT IS EXPLICIT THAT IT
MUST NOT RIDE IN THE SAME SPEC AS S3. Consolidating the evals (S11) CHANGES WHICH TREE A
CONDITIONAL DECLARATION SEES. Decide the semantics deliberately: either the probe gains
the concern defaults, or conditional-on-concern schema declarations are refused by name.

## Comments (0)

(none)
