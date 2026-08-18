# den-hoag-4kh.48 — [ci] boundary.nix's seam guard scans only denHoag.* references — it does NOT police kernel config.den.* options, which is the crossing pattern designs are told to use

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.48` |
| status at evacuation | open |
| priority | P2 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh` |
| created | 2026-07-28T19:12:59Z by Jason Bowman |
| last updated | 2026-07-28T19:12:59Z |
| description bytes | 2353 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

MEASURED — `ci/tests/boundary.nix`'s SEAM-ENUMERATION GUARD DOES NOT POLICE THE SEAM IT IS NAMED FOR. Found by
running the check against a proposed design rather than by reading it.

The boundary suite has three guards: (1) a token scan over kernel files, (2) import direction, (3) seam
enumeration. ★ GUARD (3) SCANS ONLY `denHoag.<ident>` AND `inherit (denHoag)` REFERENCES. IT DOES NOT POLICE
`config.den.*` OPTIONS AT ALL — and its own comment LISTS them and says in the same breath that they are
"NOT scanned".
⇒ A DESIGN THAT CROSSES THE KERNEL⟂COMPAT LINE BY ADDING A KERNEL OPTION CROSSES UNGUARDED. The precedent is
already in the tree: `den.excludeFamilyNames` (lib/default.nix:968-974, written by lib/compat/flake-module.nix:552)
is exactly this shape and is NOT in the enumerated set and NOT caught.

★ WHY THIS MATTERS MORE THAN A COVERAGE GAP: the option route is the ESTABLISHED, RECOMMENDED way to cross
the seam in this codebase — the kind-schema-excludes design cites `den.excludeFamilyNames` as its precedent,
and the policy-domain design proposes another. So the guard is blind to the crossing pattern designs are
actively told to use, while policing a pattern (`denHoag.<ident>`) that a design following house style would
not produce. THE GUARD IS STRONGEST WHERE THE RISK IS LOWEST.
AND THE CONSEQUENCE FOR REVIEW: "boundary.nix passes" has been quoted in this arc as evidence a design keeps
the seam clean. For an option-crossing design that sentence carries NO information. It should not be quoted
that way again until this is fixed.

ACCEPTANCE: guard (3) enumerates kernel `config.den.*` options as well as `denHoag.*` references, with the
existing crossings recorded as the baseline set — so a NEW option is what turns it red, not the existing ones.
★ AND THE BASELINE MUST BE CAPTURED AS A SET, NOT A COUNT: a count-based baseline passes when one crossing is
added and another removed, which is exactly the substitution a refactor makes.
NOTE the standing rule this serves: the kernel must be a pure graph representation, and `boundary.nix` guards
that line LEXICALLY ONLY — it cannot observe representation. This finding narrows what its lexical guarantee
actually covers.

PROVENANCE: policy-domain-selection investigation, 2026-07-28, while checking a proposed design against the
guard rather than assuming it would pass.


## Comments (0)

(none)
