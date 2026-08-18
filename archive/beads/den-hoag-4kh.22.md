# den-hoag-4kh.22 — [kernel] deps is a throw-on-read placeholder passed into user derive functions — §5 value-composition has no consumer

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.22` |
| status at evacuation | open |
| priority | P1 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh` |
| created | 2026-07-28T05:08:10Z by Jason Bowman |
| last updated | 2026-07-28T05:08:10Z |
| description bytes | 1555 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None), `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

MEASURED DEFECT — `deps` IS A THROW-ON-READ PLACEHOLDER IN A SHIPPED USER SURFACE.

SITES, verified at HEAD a40cc96:
  lib/concern-derived.nix:88-90   `depsPlaceholderMessage`
  lib/concern-derived.nix:156     `deps = throw depsPlaceholderMessage;`
  lib/concern-derived.nix:158     `spec.derive node deps`   <- the placeholder is PASSED to user code

So a user's `derive` function receives an argument that aborts the evaluation if it is ever read. The surface
accepts the declaration; the engine cannot serve it.

WHY IT IS OPEN: spec §5's requires/provides VALUE-COMPOSITION is declared and HAS NO CONSUMER. Deferred once
at WS-DERIVED, deferred again at WS-ACL, and never tracked — it survived two workstreams by being invisible
to the tracker. Recorded in the features memory (line 760) as "deps STILL deferred … no witness composes
deriveds", which is where it stayed.

★ BLOCKED ON THE POSTURE RULING (the decision node). Do not fix in isolation — `provision`/`adapt` and
den-hoag-9xo.28 are the same defect class with different failure modes, and fixing this one alone commits the
kernel to throw-on-read by accident.

ACCEPTANCE, once the posture is ruled:
  under HONOUR — a witness composing TWO deriveds through requires/provides, red before and green after;
  under NAMED-REJECT — a REFERENCE row declaring `deps` out of the facet AND removal of the parameter from
  the derive signature, so the field cannot be read at all rather than throwing when it is.

PROVENANCE: memory-reconcile audit 2026-07-28, item C2. Untracked before this bead.


## Comments (0)

(none)
