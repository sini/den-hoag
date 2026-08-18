# den-hoag-4kh.53.38 — [T7] the test guarding strict cannot distinguish a strict throw from a conflicting-option-types throw — an instance of the coarse-assertion class

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.38` |
| status at evacuation | open |
| priority | P2 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:10:25Z by Jason Bowman |
| last updated | 2026-07-29T00:10:25Z |
| description bytes | 810 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None), `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

[T7] ARGUED. THE TEST GUARDING STRICT CANNOT DISTINGUISH WHAT IT TESTS.
`ci/tests/flake-strict.nix` asserts `!(tryEval ...).success`. ★ A CONFLICTING-OPTION-TYPES
THROW SATISFIES THAT IDENTICALLY TO A STRICT-MODE THROW; THE MESSAGE IS NOT PINNED.
The arm that ACTUALLY DISCRIMINATES is the DECLARED one, and the comment DOES NOT CREDIT
IT.
★★ THIS IS AN INSTANCE OF THE CLASS ALREADY TRACKED AT den-hoag-9xo.79 (assertions coarser
than their claim), and it should be fixed by that sweep's rule rather than ad hoc:
value-returning guard -> assert the message text; THROWING guard -> paired arms with a
negative control in the same run, because Nix CANNOT recover a throw's text.
The same document also flags the five exclude-family fixtures as a sibling case -- those
were fixed on 2026-07-28; this one was not.

## Comments (0)

(none)
