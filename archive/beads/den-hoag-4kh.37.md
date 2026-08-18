# den-hoag-4kh.37 — [kernel] settings blind // at output-modules.nix:992 — design doc calls it a latent correctness bug, in-tree comment denies it, nothing records which is right

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.37` |
| status at evacuation | deferred |
| priority | P1 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh` |
| created | 2026-07-28T05:36:44Z by Jason Bowman |
| last updated | 2026-08-05T20:48:33Z |
| description bytes | 1897 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

★ MEASURED — SETTINGS BLIND `//`: A DESIGN DOC NAMES IT A LATENT CORRECTNESS BUG, THE CODE IS INTACT AT HEAD,
NO TRACKER ANYWHERE CARRIES IT — AND AN IN-TREE COMMENT CONTRADICTS THE DESIGN DOC.

THE DESIGN DOC, `specs/2026-07-21-wsb-general-system-design.md:43`:
  "wire settings C8 -> `foldLayersTraced` (replaces blind `//` at `output-modules.nix:759` — LATENT
   CORRECTNESS BUG, append/recursive strategies silently wrong-merged)"

THE CODE AT HEAD — site moved, defect verbatim. `lib/attributes/output-modules.nix:992-996`:
  settingsBindingAt = id: prelude.foldl' (acc: a: acc // a.value) { }
    (builtins.attrValues (result.get id "resolved-settings"));
A blind `//` fold. Append and recursive merge strategies are silently flattened to last-writer-wins.

★ THE CONTRADICTION, AND IT IS THE REAL FINDING. The in-tree comment at `:990-991` says:
  "multi-aspect field COMPOSITION is the productions-substrate per-host union (P5b), not here."
That directly denies the design doc's claim that this site is where the bug lives. ONE OF THE TWO IS WRONG
AND NOTHING RECORDS WHICH. Either the composition genuinely moved to P5b and the design doc is stale, or the
comment is an assumption that was never discharged and the latent bug is live at this exact line.

MEASURED: `foldLayersTraced` = 0 in beads, 0 in all three papers trackers.
POSITIVE CONTROL, same run: `foldLayersTraced` IS live and greppable at `lib/concern-disciplines.nix:64,83`
— so the replacement primitive EXISTS and is simply not wired here.

⇒ FIRST STEP IS NOT A FIX, IT IS A DECISION OF FACT: does a settings field with an append or recursive
strategy survive this fold correctly at HEAD? A witness answers it. Do not wire `foldLayersTraced` before
that, or a green result will not distinguish "fixed" from "never broken here".

PROVENANCE: log-reconcile exhaustive pass, 2026-07-28, item C3. Untracked before this bead.


## Comments (0)

(none)
