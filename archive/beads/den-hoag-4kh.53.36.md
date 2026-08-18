# den-hoag-4kh.53.36 — [T5] the always-on strict ruling must state three things — relaxed mode is a tested public API, the deletions are not independent, and constructor D is out of reach

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.36` |
| status at evacuation | open |
| priority | P1 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:10:25Z by Jason Bowman |
| last updated | 2026-07-29T00:10:25Z |
| description bytes | 1563 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None), `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

[T5] ARGUED. OWNER RULING (always-on strict, relaxed returns later as an explicit opt-in
flag) NEEDS THREE THINGS STATED EXPLICITLY, or it reads as cleanup when it is a semantic
retirement.
(a) ★ RELAXED MODE IS A TESTED PUBLIC API. `templates/ci/modules/public-api/strict.nix`
    ASSERTS AN ABSORBED VALUE READS BACK, and v1 OPTS OUT EXPLICITLY, passing
    `strict = false` PER KIND. ⇒ THIS IS A DELIBERATE v1 SEMANTIC BEING RETIRED, NOT DRIFT
    BEING CLEANED. Say so.
(b) The three deletions are NOT INDEPENDENT (see T1).
(c) ★★ CONSTRUCTOR D IS OUT OF REACH: a corpus writing `mkInstanceRegistry ... { strict =
    false; }` IN ITS OWN EVAL KEEPS RELAXED ENTITIES REGARDLESS. ⇒ THE SPEC MUST SAY
    WHETHER PARTIAL COVERAGE IS ACCEPTABLE or whether the belt should REJECT a consumer's
    `strict = false`. This is not a detail -- it decides whether "always-on" is true.
SUPPORTING, MEASURED ACROSS 21 FLEETS (T4): NO CAPABILITY LOSS. Every key authored onto a
host or user entry across nix-config, 19 external configs and the den templates is
DECLARED -- five classes, all with declaration sites. Sharpest case: `hasAspect`, a functor
with sub-methods read off entities, IS A DECLARED OPTION on `den.schema.conf`. POSITIVE
CONTROL: the extraction DOES find undeclared keys where they exist (the two strict test
files, authored to exercise the freeform).
★ AND `registry.nix`'s COMMENT CLAIMING "aspect content" ABSORBS ON ENTITIES IS NOT
CORROBORATED -- zero hits across all three corpora; class content is authored on
`den.aspects.<name>`. Listed at X2.

## Comments (0)

(none)
