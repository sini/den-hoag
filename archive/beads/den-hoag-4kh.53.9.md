# den-hoag-4kh.53.9 — [D8] building the containment tree makes firing WORSE under presence-gating — args-gating and downward inheritance are incompatible, so dispatch must be fixed first

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.9` |
| status at evacuation | closed |
| priority | P1 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:06:13Z by Jason Bowman |
| last updated | 2026-08-01T19:58:09Z |
| closed | 2026-08-01T19:58:09Z |
| close reason | SEQUENCING CONSTRAINT SATISFIED, executed witness at 693919f (closure scout): dispatch is fixed FIRST, as this bead demanded — the locus is an independent declared axis applied BEFORE dispatch (selection-indexed feeds), so containment-tree growth no longer moves a kind-scoped rule's fire set. Executed: selects-position-dependent 4/4 exit 0 — a kind-scoped rule fires at the 2 hosts and NOT the 3 users attached beneath them on real P edges; in-run controls span both extremes (sel.star → 5, sel.any [] → 0). This INVERTS the bead's measurement (a locus-less policy whose fire set grew with the tree because inheritAll satisfied more presence-guards downward): inheritAll and the functionArgs gate remain, but args-gating and downward inheritance are no longer in conflict because selection is not derived from args. A sel.star rule firing everywhere is now a stated choice with a stated meaning, not a defect. |
| description bytes | 847 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

[D8] MEASURED, and it is the SEQUENCING CONSTRAINT for the whole graph rework.
Adding `den.attach.host = { ref = "environment"; }` materialises the env->host edge
(scope roots 6 -> 2, parents exactly as expected) -- AND `envPolicy` GOES 2 -> 18, once
per node in the tree, because `inheritAll` propagates `env` DOWNWARD and more
presence-guards become satisfied.
★★ BUILDING THE CONTAINMENT TREE MAKES FIRING *WORSE* UNDER PRESENCE-GATING.
LOAD-BEARING CONSEQUENCE: args-gating and downward-inherited context are INCOMPATIBLE.
Either context stays LOCAL (as in both gen examples, which stub parent/children/
ancestors) or the gate carries an EXPLICIT SCOPE. den-hoag has inheritance AND
presence-gating, which is the worst pair.
⇒ FIX DISPATCH BEFORE BUILDING THE DESCENT, NOT AFTER. This is why D1 sequences first
and N1/N2/N4/N5/N7 depend on it.

## Comments (0)

(none)
