# flake-adapter — the GREENFIELD v2 flake-parts mount (spec §4.4/§4.6 output face, D8 flake-parts option
# targets). A pure mount: a built den fleet → a flake-parts module that hands the fleet's transposed family
# map to `config.flake`. The transposition already happened INSIDE `mkDen` (the family dispatch assembles
# `familyOutputs` = the root entity's product, with any hosted flake-parts render's output flat-merged at root
# via `at = _: _: [ ]`); `builtFleet.outputs` IS that map, so the whole mount is the one-line handoff.
#
# A v2 greenfield consumer calls `mkDen` DIRECTLY (the vocabulary is theirs), then
# `imports = [ (den.flakeAdapter (den.mkDen [ … ])) ]` surfaces the family map at the flake root — no manual
# threading. This is the ONE-WAY handoff: the self-knot (a hosted render reading sibling families) is tied
# INSIDE mkDen's `familyOutputs` let, not through `config.flake`, so mounting here opens no config.flake-level
# fixpoint.
#
# This is the v2 entry, distinct from the drop-in v1 `flakeModule` a migrating consumer imports: a consumer
# chooses ONE entry, and this adapter re-declares NO v1 option surface — it mounts an already-built fleet. The
# two are separate modules with zero shared splice, so the v1 face stays byte-untouched.
builtFleet: {
  config.flake = builtFleet.outputs;
}
