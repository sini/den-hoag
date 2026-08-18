# den-hoag-4kh.53.40 — [E1] four entity constructors and two derivations — two views of one entity joined by NAME and never by hash, and the name-join is forced

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.40` |
| status at evacuation | deferred |
| priority | P1 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:11:19Z by Jason Bowman |
| last updated | 2026-08-05T20:48:37Z |
| description bytes | 952 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

[E1] ARGUED. FOUR ENTITY CONSTRUCTORS AND TWO DERIVATIONS, NOT ONE PATH:
(A) kernel gen-schema registry (`entity.nix`)
(B) shim gen-schema registry (`ingest.nix`) -- ★ BYTE-IDENTICAL CALL TEXT TO A, DIFFERENT
    EVAL
(C) hand-rolled nixpkgs registry (`registry.nix`) -- ★ CARRIES NO `id_hash`
(D) ★ THE CORPUS'S OWN `mkInstanceRegistry`, AT THE CORPUS'S OWN GEN-SCHEMA PIN --
    den-hoag CONSTRUCTS ITS INPUT AND READS ITS OUTPUT BUT NEVER CALLS IT
(E) synthetic `{ name; }` membership targets (`ingest.nix`)
(F) compile's identity overlay -- RE-DERIVES `id_hash` AND BYPASSES `mkIdentityModule`
★★ THEY ARE TWO VIEWS OF ONE ENTITY, JOINED BY NAME, NEVER BY HASH -- AND THAT IS FORCED,
because C carries NO IDENTITY and D computes ITS identity UNDER A DIFFERENT OPTION SET.
⇒ The name-join is not a shortcut someone took; it is the only join available given C and
D. Any consolidation must decide what to do about D, which is outside den-hoag's eval.

## Comments (0)

(none)
