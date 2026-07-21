# The option-declaration PROJECTION (§ options-projection): re-key the den option-declaration tree
# (`den._options`, the `_type == "option"` leaves gen-merge's `evalModuleTree` exposes) into the exact
# shape a Nix LSP (nixd) walks — an attrset whose leaves carry `_type == "option"` with
# `type`/`description`/`default`, with gen-schema refinement metadata cleaned off each leaf's `.type`.
# Pure builtins (no prelude/schema dep) so `lib/**` stays nixpkgs-lib-free; the refinement strip mirrors
# gen-schema's module bridge (Cardelli 1997, bridge.nix) — a `__schema.refinements`-carrying type is
# replaced by its `.__schema.baseType`, so `__schema` never leaks into the projected type. The walk is
# structure-only + reads a leaf's static `.type`: it never forces resolved fleet `.config`.
{ }:
let
  # A gen-merge option leaf: an attrset tagged `_type == "option"`.
  isOptionDecl = v: builtins.isAttrs v && v ? _type && v._type == "option";
  # The refinement strip (gen-schema bridge.nix): a refined type (`__schema` carrying `refinements`) is
  # replaced by its base type; a plain type passes through untouched.
  stripRefinements = t: if t ? __schema && (t.__schema ? refinements) then t.__schema.baseType else t;
  # Project one leaf: keep every option field (`description`/`default`/…), cleaning refinement metadata
  # off `.type` (a typeless leaf projects `type = null`). A non-refined submodule/attrsOf type passes
  # through by identity, so its descent shape (`getSubOptions` / `nestedTypes.elemType`) is preserved.
  projectLeaf =
    opt:
    opt
    // {
      type = if opt ? type then stripRefinements opt.type else null;
    };
  # The tree walk: project at each option leaf, recurse through every other attrset, pass non-attrs
  # through — a leaf's own nested types ride inside its projected `.type`, never re-walked (no flatten).
  walk =
    node:
    if isOptionDecl node then
      projectLeaf node
    else if builtins.isAttrs node then
      builtins.mapAttrs (_: walk) node
    else
      node;
in
{
  optionsProjection = { options }: walk options;
}
