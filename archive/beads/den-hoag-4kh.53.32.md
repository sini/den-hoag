# den-hoag-4kh.53.32 — [A7] an undeclared per-instance key is silently dropped — and the mechanism doing it is an invariant E3 wants kept, so they are one design question

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.32` |
| status at evacuation | open |
| priority | P2 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:09:41Z by Jason Bowman |
| last updated | 2026-07-29T00:09:41Z |
| description bytes | 1108 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None), `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

[A7] ARGUED. AN UNDECLARED PER-INSTANCE KEY IS SILENTLY DROPPED.
`den.hosts.x86_64-linux.igloo.typo = "x"` produces NO ERROR from ANY of the four
entity-construction paths. The nixpkgs registry absorbs it via freeformType; THE STAMP
PROJECTION WALKS THE DECLARED OPTION SURFACE ONLY (`registry.nix`, leaf branch gated on
`isOption v`), so it NEVER ENTERS `entityFields` -> `instanceConfig` -> the kernel.
★ Per-instance keys sit OUTSIDE compile's surface-totality gate, which is top-level
`den.<key>` ONLY.
★★ SAME MECHANISM AS E3, WHICH IS AN INVARIANT WE WANT: the option-gating is what keeps
freeform-absorbed keys from crossing to the kernel. ⇒ FIXING A7 AND KEEPING E3 ARE THE
SAME DESIGN QUESTION -- the projection must distinguish "absorbed and deliberately not
crossed" from "absorbed because the user misspelled it". Do not fix one by deleting the
other.
Interacts with the always-on strict ruling (§6): under strict, an undeclared per-instance
key should arguably be REJECTED rather than absorbed -- which would close this by
construction. Establish whether strict reaches per-instance keys at all.

## Comments (0)

(none)
