# den-hoag-4kh.53.29 — [A4] a typo-d aspect reference is a silent no-op on three paths, and the typo vanishes beside a good ref — the guard needs a routing decision, not a union

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.29` |
| status at evacuation | open |
| priority | P1 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:09:40Z by Jason Bowman |
| last updated | 2026-07-29T00:09:40Z |
| description bytes | 1435 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None), `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

[A4] LIVE, MEASURED. A TYPO'D ASPECT REFERENCE IS A SILENT NO-OP ON THREE PATHS.
`compile.nix` `aspectRec = name: (aspects.${name} or { }) // ing.aspectEntry name;` --
`aspectEntry` is PURE IDENTITY, so "declared aspect with no content" and "NO SUCH ASPECT"
become THE SAME RECORD.
MEASURED: known 4, unknown 3 (IDENTICAL to no include at all), known+unknown 4 --
★ THE TYPO VANISHES BESIDE A GOOD REF, WHICH IS THE WORST CASE.
`resolved-aspects.nix` takes `a.aspect` VERBATIM and never sees a name, so NOTHING
DOWNSTREAM CAN VALIDATE. `compile.nix` claims R9 aborts an unresolvable ref; THE STRING
ARM RESOLVES UNCONDITIONALLY, so R9 only ever catches an `int` (listed at X2 as a comment
measured false).
★★ RESOLUTION HAS A CAVEAT THAT MAKES IT A DESIGN QUESTION, NOT A GUARD:
`aspects` alone -> 4 FALSE REJECTIONS. `aspects union policies` -> 1946/1946 with the typo
still caught -- BUT THE UNION SILENCES THE ERROR WITHOUT FIXING THE BEHAVIOUR: a policy
named in a kind-include string STILL RESOLVES TO AN EMPTY STUB and contributes nothing.
It only appears to work because the policy ALSO fires fleet-wide, and
`ci/tests/compat-expose-gather.nix` IS EXACTLY THIS AND IS LOAD-BEARING IN DEN-HOAG'S OWN
FIXTURES.
⇒ THE REAL QUESTION IS WHAT A KIND-INCLUDE STRING MAY NAME, and whether it gets ROUTED
accordingly. That is §12 decision 4. `compile.nix` already guards a SIBLING ARM with
`registry ? ${ref.key}`, so the pattern exists.

## Comments (0)

(none)
