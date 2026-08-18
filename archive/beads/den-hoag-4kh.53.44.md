# den-hoag-4kh.53.44 — [E5] host and user are privileged as merge literals where v1 privileges nothing — and the coupling bites the planned native user registry in kernel code that never mentions user

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.44` |
| status at evacuation | deferred |
| priority | P1 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:11:20Z by Jason Bowman |
| last updated | 2026-08-05T20:48:38Z |
| description bytes | 1821 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

[E5] MEASURED. `host` AND `user` ARE PRIVILEGED AS MERGE LITERALS, AND v1 PRIVILEGES
NOTHING.
    withBuiltins = (if declared ? host then { } else { host.parent = null; })
                // (if declared ? user then { } else { user.parent = "host"; }) // declared;
★ THEY ARE THE MERGE'S IDENTITY ELEMENT, NOT ENTRIES IN IT -- NO DECLARATION A CONSUMER
CAN WRITE PRODUCES THEM. STRUCTURAL PRIVILEGE, NOT A NAMING COINCIDENCE.
★★ v1 DECLARES ALL FIVE OF ITS BUILTINS THROUGH THE ORDINARY CONSUMER SURFACE
(`modules/options.nix`: `config.den.schema.user.parent = "host";`), auto-imported,
PRIVILEGING NOTHING. So den-hoag privileges PRECISELY THE TWO KINDS v1 DOES NOT -- while
its OTHER FIVE builtins (flake, flake-system, flake-parts, fleet, hm-host) DO use the v1
mechanism. TWO BUILTIN MECHANISMS IN ONE LAYER, and the privileged one carries the two
kinds that matter.
THE TELL IT IS DELIBERATE: `// prelude.genAttrs customKinds (...)` appears FOUR TIMES --
the generic path is written to EXCLUDE the builtins rather than include them -- and
`k != "host" && k != "user"` appears VERBATIM IN THREE FILES, the last DIRECTLY BENEATH A
COMMENT CLAIMING "zero kind literals" (listed at X2).
★★ SCOPE NOTE, AND IT IS THE REASON THIS IS FILED RATHER THAN WAIVED: the owner ruled this
properly decoupled to the compat side, AND IT IS -- everything downstream of ingest is
kind-generic. BUT ONE COUPLING BITES THE PLANNED `host.users` -> NATIVE `user` REGISTRY
MIGRATION: `compile.nix` decides CELL-VERSUS-ROOT by a PROPERTY (`registryBacked` /
`isLeafDim`), which is honest -- but `user` SATISFIES IT ONLY BECAUSE INGEST DENIES `user`
A REGISTRY NAMESPACE BY LITERAL.
⇒ GIVE `user` A NATIVE REGISTRY AND IT STOPS BEING A CELL, IN KERNEL CODE THAT NEVER
MENTIONS `user`. DESIGN AGAINST THAT DELIBERATELY RATHER THAN DISCOVER IT.

## Comments (0)

(none)
