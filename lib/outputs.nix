# The output-families registry (`den.outputs.<family>`, spec §4.4) — the root-as-entity uniform-resolution
# reading (§4.6): a fleet's TOP-LEVEL output faces (nixosConfigurations, darwinConfigurations, a user's own
# target) are DATA, one row per family, resolved by the SAME machinery a nested receives row is. A family row
# NAMES how a class's built members surface at the flake root: its `at` placement (the paramPoint-first path,
# the built member's key under the target), the product it `consumes` (from which its MODE derives — F1's
# canonical machine form), the `render` that builds the artifact, the `params` axes the face is materialized
# over (today the `system` axis, whose values are `den.systems`), and the `requires` products it consults.
# The Bazel output-groups reading: a family is a named group of built artifacts a consumer addresses at the
# flake root; `consumes`/`requires` name the product faces flowing into it. This is the D7-promotion precedent
# once more (REFERENCE "Materialization registries"): the shipped `systemOutputs`/`faceOf` face-builder becomes
# a full validated registry row, superseding the render row's kept `output` field. See REFERENCE.md.
#
# NO EFFECT RUNTIME: `compile` is a `mapAttrs` + a validation fold — field defaults + product/render/axis
# checks, no algorithm (Law A1; the receivers/renders template). An `at` value is a FUNCTION: a registry holds
# functions freely — the fingerprint law (identity.nix) bans functions from EDGE DATA only, never from a
# registry entry.
{
  prelude,
  productsLib,
}:
let
  # The KNOWN AXIS registry (spec §4.4): a family's `params` names finite materialization axes, and today the
  # sole axis is `system` — the axis whose values are the fleet's `den.systems`. The registry is deliberately
  # minimal (one axis): a NEW axis (a per-family variant dimension a user invents) joins this set, and a
  # `params` entry outside it is a definition error. Generality is a registry extension, never a core literal.
  axes = [ "system" ];
  axisSet = prelude.genAttrs axes (_: true);

  # A family row's canonical fields (spec §4.4). THE §2.1 HOOK-SCOPING COROLLARY (the row contract, mirrored
  # from receivers.nix): `at` receives STRUCTURAL handles only (the paramPoint + the built member's structural
  # face) — never resolved graph state; the same singular-path / `[]`⇒flat convention the nest engine's `at`
  # obeys (nest.nix `nestAtPath`: a singular path list, `[ ]` places the member at the target root). `render`
  # names a registered render (the artifact the built member surfaces); `consumes` passes the products-table
  # gate; `params` names known axes; `requires` names registered products (shape-checked HERE; consumption is
  # a later task). `mode` is NOT a field — it is DERIVED from `consumes` (F1, a CHECKED law mirroring
  # receivers.nix): a user-declared `mode` is a definition error, rejected FIRST (never silently absorbed).
  rowOf =
    renders: products: family: raw:
    let
      # F1 AS A CHECKED LAW: mode derives from consumes; a user-declared `mode` field is forbidden.
      hasMode = raw ? mode;
      # `consumes` passes the products-table gate (unregistered / non-nestable / literal ArtifactRef all throw
      # THERE, named — the pure fn reused from the products registry, never re-implemented).
      consumes = if raw ? consumes then productsLib.checkConsumes products raw.consumes else null;
      mode = if consumes == null then null else productsLib.modeOf products consumes;
      render = raw.render or null;
      params = raw.params or [ ];
      requires = raw.requires or [ ];
      # each `params` entry names a KNOWN AXIS (today `system`); an unknown axis is a definition error.
      badParams = builtins.filter (p: !(axisSet ? ${p})) params;
      # each `requires` entry names a registered product (shape-check only — consumption is a later task).
      badRequires = builtins.filter (p: !(products ? ${p})) requires;
    in
    if hasMode then
      throw "den.outputs: family '${family}' derives mode from consumes — remove the mode field"
    else if !(raw ? at) then
      throw "den.outputs: family '${family}' declares no at — the placement `point: e: [ …path ]` is required"
    else if !(raw ? consumes) then
      throw "den.outputs: family '${family}' declares no consumes — the product face is required"
    else if render != null && !(renders ? ${render}) then
      throw "den.outputs: family '${family}' names unregistered render '${render}'"
    else if badParams != [ ] then
      throw "den.outputs: family '${family}' declares unknown param axis '${builtins.head badParams}' — one of ${builtins.toJSON axes}"
    else if badRequires != [ ] then
      throw "den.outputs: family '${family}' requires unregistered product '${builtins.head badRequires}' — register it in den.products"
    else
      {
        inherit (raw) at;
        inherit
          consumes
          mode
          render
          params
          requires
          ;
      };

  # `compile { registered; builtins ? { }; renders; products; systems }` → the validated compiled families
  # table (a `mapAttrs` + validation, Law A1 — the receivers/renders template). This task compiles USER rows
  # only; the framework seeding (the built-in nixosConfigurations/darwinConfigurations families) arrives as
  # the `builtins` compile arg in a later task, seeding beside the user rows exactly as renders' `builtinRows`
  # do — the arg seam is left open here (default `{ }`). `renders` is the COMPILED render table (§4.3, for the
  # `render` name check); `products` the COMPILED products table (§4.1, for the mode derivation + consumes
  # gate); `systems` the `den.systems` axis values (the `system` param's domain — carried for the later
  # per-system materialization, the axis NAMES are validated here). Invoked per-fleet (the render rows compile
  # inside the mkDen closure), following receivesTable's placement.
  compile =
    {
      registered ? { },
      builtins ? { },
      renders ? { },
      products ? { },
      systems ? [ ],
    }:
    let
      allRaw = builtins // registered;
    in
    prelude.mapAttrs (rowOf renders products) allRaw;
in
{
  inherit compile axes;
}
