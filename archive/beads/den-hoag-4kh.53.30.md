# den-hoag-4kh.53.30 — [A5] den.attach keys are unvalidated strings — a typo-d row is stated intent landing in the branch written for absence, with the validator present twice in the same file

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.30` |
| status at evacuation | open |
| priority | P2 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:09:41Z by Jason Bowman |
| last updated | 2026-07-29T00:09:41Z |
| description bytes | 546 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

[A5] ARGUED. `den.attach` KEYS ARE UNVALIDATED STRINGS. Typed `attrsOf (submodule ...)`;
THE ATTR NAME IS NEVER CHECKED AGAINST DECLARED KINDS. A typo yields `parentKind == null`
-> `[ ]` -> NOTHING, NO ERROR.
★ The declaration's OWN COMMENT says "ABSENCE OF A ROW MEANS THE KIND DOES NOT NATIVELY
ATTACH" -- so A TYPO'D ROW IS STATED INTENT LANDING IN THE BRANCH WRITTEN FOR ABSENCE.
That is the §4 class in one sentence.
POSITIVE CONTROL: kind-name validation EXISTS TWICE IN THE SAME FILE. The primitive is
present; this site does not call it.

## Comments (0)

(none)
