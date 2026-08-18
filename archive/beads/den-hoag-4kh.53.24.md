# den-hoag-4kh.53.24 — [S10] framework kinds cannot use the framework own registration path — the reserved-name guard protects a namespace the framework then evades with //

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.24` |
| status at evacuation | open |
| priority | P1 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:08:35Z by Jason Bowman |
| last updated | 2026-07-29T00:08:35Z |
| description bytes | 1106 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None), `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

[S10] ARGUED. FRAMEWORK KINDS CANNOT USE THE FRAMEWORK'S OWN REGISTRATION PATH.
`default.nix`, verbatim: "(NOT fed through discoverKinds, whose reserved-name guard would
throw on the framework kind)". ⇒ THE GUARD PROTECTS A NAMESPACE THE FRAMEWORK MUST THEN
EVADE WITH `//`.
★ RESOLUTION OPTIONS, OWNER LEANING: FRAMEWORK-NESS AS DECLARED DATA. Making framework
kinds ORDINARY DECLARATIONS -- v1's shape, which privileges nothing -- DELETES
`metaAugment`, the `collector` reserved-name branch AND the S9 keyset divergence TOGETHER.
★★ COSTS, AND THE SECOND ONE IS THE RISK: the reserved-name guard must be removed or
inverted; AND the collector's per-instance `contentClass` function needs
`effectiveClassEntries`/`effectiveClassNames`, WHICH ARE CURRENTLY COMPUTED OUTSIDE THE
MODULE TREE. THAT THREADING IS THE ONE THING THAT COULD TURN A DELETION INTO A REDESIGN.
Establish the threading cost BEFORE committing to the ruling.
Pairs with E5: den-hoag privileges `host` and `user` as MERGE LITERALS while v1 declares
all five of its builtins through the ordinary consumer surface. Same disease, two sites.

## Comments (0)

(none)
