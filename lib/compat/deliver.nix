# The `deliver` surface (and the permanent `route` / `provide` sugar) → a den-compat delivery
# DESCRIPTOR (Law C2: a declaration, NEVER a `genEdge.edge` call — the firing scope is unknowable at
# compile time). This file owns only the SURFACE normalization + the §2.3 error cases; the descriptor
# is turned into a den-hoag delivery declaration (the gen-edge `collected`/`synthesize` source + root
# target) inside `compile.nix`'s `translateDelivery`, at rule-fire time where the firing scope is known.
#
# The field mapping is frozen from v1 `nix/lib/policy-effects.nix` (`deliver`/`route`/`provide`) AND its
# edge classification (`edges/route.nix` `classifyRoute`, `edges/provides.nix` `providesEdges`): the
# deliver `mode` param collapses to {verbatim | not}, and the merge-vs-nest distinction is PATH-derived
# at the edge — so a compat trace edge byte-matches v1's. (v1's `route` value carries `path` +
# `reinstantiate`, never a `mode`; the classifier re-derives merge/nest from the path.)
#
# nixpkgs-lib-free: `prelude` + `errors` only, no gen-edge here (descriptor construction is inert data,
# gen-edge source records are built in `compile.nix` at fire time — see the C2 relaxation boundary).
{ prelude, errors }:
let
  # Validate the surface `mode` (merge | nest | verbatim); an invalid mode aborts named (§2.3
  # deliverMode). The RETURN value is the den-hoag mode a bare mode maps to (verbatim → nest-verbatim),
  # exported for callers that want the raw translation; the delivery descriptor's actual mode is the
  # PATH-derived `finalModeOf` below (v1 parity), not this — `modeOf` here is the validation gate.
  modeOf =
    m:
    if m == "merge" then
      "merge"
    else if m == "nest" then
      "nest"
    else if m == "verbatim" then
      "nest-verbatim"
    else
      errors.deliverMode m;

  # The edge mode v1 actually materializes (route.nix classifyRoute / provides.nix providesEdges):
  # verbatim → nest-verbatim; otherwise merge at the root (P = []) or nest at a path. The surface
  # merge/nest choice is DISCARDED for non-verbatim (v1's route value has no mode) — the path decides.
  finalModeOf =
    mode: at:
    if mode == "verbatim" then
      "nest-verbatim"
    else if at == [ ] then
      "merge"
    else
      "nest";

  # `deliver` → a delivery DESCRIPTOR (C2): `from` a class name (route case → a collected source at the
  # firing scope) or `{ module }` (provide case → a synthesize source — never a value source; the shim
  # never emits gen-edge's `value` arm, which v1's frozen sourceKey has no equivalent for). No
  # `reinstantiate`/`appendToParent` on this surface (strict pattern: both are shim-internal, reached
  # only through `route`) — passing either is an "unexpected argument" abort, the §2.3 surface guard.
  deliver =
    {
      from,
      to,
      at ? [ ],
      mode ? "merge",
      guard ? null,
      adaptArgs ? null,
    }:
    let
      isModule = builtins.isAttrs from && from ? module;
      # Force the mode validation FIRST (v1 order: invalid mode aborts before the module-verbatim
      # check), then reject verbatim on a module source (there is no collected wrapper to keep by ref).
      valid = modeOf mode;
    in
    builtins.seq valid (
      if isModule && mode == "verbatim" then
        errors.deliverVerbatimModule
      else
        {
          __delivery = true;
          sourceClass = if isModule then null else from; # a class name; resolved to a registration in compile (C6)
          moduleSource = if isModule then from.module else null;
          target = to; # a class name; resolved to a registration in compile (C6)
          path = at;
          mode = finalModeOf mode at;
          # Parent-targeting is shim-internal (v1 policy-effects.nix:60: "`appendToParent` is NOT
          # accepted here"): the `deliver` SURFACE never takes it (strict formals reject it), so the
          # descriptor field defaults false — only `route`'s `__extra` (the v1 route-internal mechanism
          # channel, policy-effects.nix:194) overlays it (#53c).
          appendToParent = false;
          inherit guard adaptArgs;
        }
    );

  # `route` — PERMANENT user-API sugar over `deliver`. `intoPath`/`path` → `at` (both present aborts
  # named, §2.3 routePathConflict); `reinstantiate = true` → `mode = "verbatim"` (the ONLY mode→flag
  # translation). `__extra` (route-internal mechanism fields — collectSubtree/adapterKey/appendToParent):
  # `appendToParent` is LIVE (#53c — v1 route.nix:364 reads it off the route value; the descriptor
  # carries it to `translateDelivery` → `deliveryTargetRootOf`, which resolves the containment-parent
  # target); the remaining fields (collectSubtree/adapterKey) ride through inert — their consumers are
  # the legacy `forwards` module (Task 5).
  route =
    {
      fromClass,
      intoClass,
      intoPath ? null,
      path ? null,
      reinstantiate ? false,
      guard ? null,
      adaptArgs ? null,
      __extra ? { },
    }:
    if intoPath != null && path != null then
      errors.routePathConflict
    else
      deliver {
        from = fromClass;
        to = intoClass;
        at = if intoPath != null then intoPath else (if path != null then path else [ ]);
        mode = if reinstantiate then "verbatim" else "merge";
        inherit guard adaptArgs;
      }
      // {
        appendToParent = __extra.appendToParent or false;
      };

  # `provide` — PERMANENT user-API sugar over a MODULE-source `deliver`: `class` → `to`, `module` →
  # `from.module`, `path` → `at`. P = [] degenerates to a merge contribution, P ≠ [] to a nest (the
  # nest∘merge decomposition). Module sources are synthesize-sourced (`deliver` above).
  provide =
    {
      class,
      module,
      path ? [ ],
    }:
    deliver {
      from = { inherit module; };
      to = class;
      at = path;
    };
in
{
  inherit
    deliver
    route
    provide
    modeOf
    finalModeOf
    ;
}
