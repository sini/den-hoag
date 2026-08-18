# den-hoag-4kh.53.45 — [M2] metaWithClass leaves one record in two concurrent versions where authority depends on which field you ask for — it dissolves by passing the resolver as an argument

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.45` |
| status at evacuation | deferred |
| priority | P1 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:11:20Z by Jason Bowman |
| last updated | 2026-08-05T20:48:38Z |
| description bytes | 2304 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

[M2] MEASURED, with a positive control that independently rediscovered the known specimen
and found nothing else. Outside nodes, EXACTLY TWO mutation sites, and ONLY ONE IS REAL.
★ SITE 1 -- `metaWithClass`. STRICT PATCH. VERDICT: DISSOLVES.
The discriminator answers worst-case: `contentClass = null` at `entity.nix` is read by
NOBODY -- the only reader of that field receives the REWRITE. AND `ent.meta` is
simultaneously read UNPATCHED for `parent` AT FOUR SITES.
⇒ ONE RECORD EXISTS IN TWO VERSIONS CONCURRENTLY, AND WHICH IS AUTHORITATIVE DEPENDS ON
WHICH FIELD YOU ASK FOR. Not discoverable from either site.
The cycle is real (denMeta -> entity.build -> ent.config -> contentClass -> denMeta) but
THE PATCH IS NOT REQUIRED TO BREAK IT: pass the resolver as its own argument --
`entity.classOf { meta; contentClassOf; entityOfNode }` -- and BOTH the placeholder field
AND the rewrite disappear.
★ SITE 2 -- `addSelfIncludes`. Weak/append-only. VERDICT: UNCLEAR, LEANING NECESSARY.
Monotone, applied once, driven by a REAL architectural constraint (severable legacy), not
convenience. But the constraint is A CHOICE: expressed as a HOOK INPUT to `compile`
(defaulting to `_: [ ]`) rather than a wrapper, the patch disappears. NOT called DISSOLVES
because it is UNESTABLISHED whether the severability suite would still distinguish its
four wirings under that shape.
★★ SHARED ROOT CAUSE, AND THE GENERAL RULE FOR THE REDESIGN: A RECORD WAS GIVEN A FIELD
WHOSE VALUE IS NOT KNOWABLE WHEN THE RECORD IS BUILT. DO NOT PUT THE FIELD ON THE RECORD;
LET THE LATE FACT TRAVEL AS A FUNCTION OR AN INPUT.
★ THE DISCRIMINATOR, for anyone repeating this audit elsewhere: A PATCH IS ONLY MEANINGFUL
WHEN THE PRE-PATCH VALUE IS SEPARATELY REACHABLE. That separates `metaWithClass` (named,
exported, read unpatched at four sites) from the near-miss `schemaDecls` over `buildSchema`
-- structurally identical `mapAttrs (... decl // { ... })` but whose intermediate is
ANONYMOUS and whose producer has no external callers. WHERE THE PRE-PATCH VALUE IS
ANONYMOUS, `mapAttrs f (g x)` IS COMPOSITION, NOT MUTATION.
★ AND THE MODEL OF CORRECT STAGING, worth keeping as the counter-example: the edge override
tier runs `applyOverrides` on RAW INTENTS, BEFORE IDENTITY EXISTS -- the edge record does
not exist until after.

## Comments (0)

(none)
