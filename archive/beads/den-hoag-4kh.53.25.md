# den-hoag-4kh.53.25 — [S11] discovery is four evaluations of the user module set — three byte-identical probes, one already copy-pasted into another file

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.25` |
| status at evacuation | open |
| priority | P2 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:08:35Z by Jason Bowman |
| last updated | 2026-07-29T00:08:35Z |
| description bytes | 991 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

[S11] MEASURED. DISCOVERY IS FOUR EVALUATIONS OF THE USER MODULE SET.
`entity.nix` at three points plus `concern-collectors.nix` -- THREE BYTE-IDENTICAL PROBES
differing ONLY in the final `attrNames` read, plus the build tree.
★ THE TELL THAT IT IS NOT A PRIMITIVE: the pattern has ALREADY BEEN COPY-PASTED OUT OF
`entity.nix` INTO ANOTHER FILE.
RESOLUTION -- DEN-HOAG CONSOLIDATION, NO LIBRARY CHANGE. The probes differ only in whether
`options.schema` is mounted, AND MOUNTING IT IS STRICTLY ADDITIVE. ONE `evalModuleTree`,
`let`-bound once, serves all four lists.
★ gen-merge's `warmFrom` path is PUBLIC BUT KEYED ON THE WRONG AXIS (an appended module
tail, not a varying decl tree) -- so this is not a gen gap and should not be filed as one.
CONSTRAINT FROM S1: one call site CANNOT read `ent` (cycle through denAspects ->
aspectsDecl -> entity.build) and must read a probe. The consolidation must preserve that,
so "one eval" means one PROBE eval plus the build tree, not literally one.

## Comments (0)

(none)
