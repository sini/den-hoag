# den-hoag-4kh.53.72 — [DECISION 7] contentClass two arities — no gen mechanism carries a kind-level edge except gen-schema parent, and M2 dissolution may change the choice

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.72` |
| status at evacuation | open |
| priority | P1 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:16:03Z by Jason Bowman |
| last updated | 2026-07-29T00:16:03Z |
| description bytes | 1015 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None), `None` (None), `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

★ OWNER DECISION 7 -- `contentClass`'s TWO ARITIES. DOES A KIND-LEVEL `contentClass` LOWER
TO PER-INSTANCE EDGES, OR SURVIVE AS A KIND-LEVEL FACT?
★★ THE CONSTRAINT THAT MAKES THIS HARD: NEITHER GEN MECHANISM (refs, relations) CARRIES A
KIND-LEVEL EDGE. THE ONLY ONE IS GEN-SCHEMA'S `parent`, WHICH IS FIXED AND FRAMEWORK-OWNED.
⇒ Choosing "survive as a kind-level fact" means either extending a gen mechanism to carry
kind-level edges, or keeping a den-hoag-only representation for it.
★ PREREQUISITES IF LOWERING, all three stated by the audit:
1. FIX A8 (relation edge targets are unvalidated and the failure is UNCATCHABLE by tryEval)
2. THREAD THE REFS BINDINGS
3. DECIDE THE COMPAT STORY
★ AND M2 IS ENTANGLED: `metaWithClass` exists precisely because `contentClass` is a field
whose value is not knowable when the record is built. Its dissolution (pass the resolver as
an argument) may change what this decision is choosing between -- take M2's shape into
account rather than deciding around the current one.

## Comments (0)

(none)
