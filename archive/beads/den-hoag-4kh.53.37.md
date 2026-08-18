# den-hoag-4kh.53.37 — [T6] flakeModules.strict registers two phantom kinds — inert, but a den-hoag-shipped demonstration of the pattern A1 punishes

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.37` |
| status at evacuation | open |
| priority | P3 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:10:25Z by Jason Bowman |
| last updated | 2026-07-29T00:10:25Z |
| description bytes | 619 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

[T6] MEASURED. `flakeModules.strict` REGISTERS TWO PHANTOM KINDS.
`flake-strict.nix` sets `den.schema.aspect.imports` and `den.schema.home.imports`; NEITHER
IS A DEN-HOAG KIND. Kind set 7 -> 9 with the import.
INERT (isolated arm: `nixosConfigurations` and the scope graph unchanged) -- COSMETIC, but
it goes away with the file.
★ RELEVANT BEYOND ITSELF: A1's trigger is "any consumer writing `den.schema.user.<x>`
without an explicit parent", and this file is a den-hoag-shipped example of writing
`den.schema.<k>.<x>` for a k that is not a kind. Retiring it removes a shipped
demonstration of the pattern A1 punishes.

## Comments (0)

(none)
