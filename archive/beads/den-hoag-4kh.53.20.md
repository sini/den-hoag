# den-hoag-4kh.53.20 — [S5] candidateKinds needs a fixture that does not exist — 25 test files declare the one shape that cannot catch the substitution

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.20` |
| status at evacuation | deferred |
| priority | P1 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:07:52Z by Jason Bowman |
| last updated | 2026-08-05T20:48:36Z |
| description bytes | 748 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

[S5] MEASURED, AND IT IS A PREREQUISITE, NOT A FOLLOW-UP.
`_leaves` ALONE OVER-APPROXIMATES `candidateKinds` by `_leaves` intersect `_roots` --
kinds both CHILDLESS and PARENTLESS.
★ 25 FILES UNDER ci/tests/ DECLARE EXACTLY THAT SHAPE (a single kind with `parent = null`).
⇒ THE EXISTING FIXTURES CANNOT CATCH A `_leaves`-ONLY SUBSTITUTION, BECAUSE THEY HAVE NO
CHAIN. A green suite would mean nothing for this change.
REQUIRED NEW FIXTURE: an ISOLATED KIND ALONGSIDE A REAL PARENT/CHILD CHAIN.
★ This is the same shape as the coarse-assertion class already tracked at den-hoag-9xo.79
-- a suite that cannot fail on the thing it appears to guard. Build the fixture, verify
it FAILS against a `_leaves`-only substitution, THEN make the substitution.

## Comments (0)

(none)
