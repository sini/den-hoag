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
  # The generic source-position layer (§ options-projection): `positions.positionsOf { fields } raw` maps a
  # raw attrset to its fields' declaration sites (`unsafeGetAttrPos` over the un-merged AST). Reused here to
  # attach `declarationPositions` to option leaves; standalone-reusable by later graph/nav consumers.
  positions = import ./positions.nix { };
  # The fields a MERGED option leaf carries whose source position IS its declaration site (its `mkOption`
  # block): `type` first (a real option always declares it), `default`/`description` as fallbacks for a
  # leaf whose `type` position is reconstructed. First hit → the declaration anchor (positions.nix).
  optionLeafFields = [
    "type"
    "default"
    "description"
  ];

  # A gen-merge option leaf: an attrset tagged `_type == "option"`.
  isOptionDecl = v: builtins.isAttrs v && v ? _type && v._type == "option";
  # The refinement strip (gen-schema bridge.nix): a refined type (`__schema` carrying `refinements`) is
  # replaced by its base type; a plain type passes through untouched.
  stripRefinements = t: if t ? __schema && (t.__schema ? refinements) then t.__schema.baseType else t;
  # Project one leaf: keep every option field (`description`/`default`/…), cleaning refinement metadata
  # off `.type` (a typeless leaf projects `type = null`). A non-refined submodule/attrsOf type passes
  # through by identity, so its descent shape (`getSubOptions` / `nestedTypes.elemType`) is preserved.
  # `declarationPositions` is read from the ORIGINAL `opt` (the un-merged leaf), NOT the `opt // { … }`
  # result — `unsafeGetAttrPos` on the rebuilt attrset would locate this file's `//`, not the source decl.
  projectLeaf =
    opt:
    opt
    // {
      type = if opt ? type then stripRefinements opt.type else null;
      declarationPositions = positions.positionsOf { fields = optionLeafFields; } opt;
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

  # The aspect-registry projection (§ options-projection): synthesize one nixd-walkable SUBMODULE option
  # node per DECLARED aspect instance so an LSP completes aspect names as submodules and each aspect's
  # settings (§2.6 schema) as sub-options. Its input is `den.aspects` (= `config.den.aspects`, keyed by
  # aspect name) — the ONE projection that reads resolved config, but only the aspect DECLARATION merge:
  # a field-spec's `{ default; merge ? }` record (§2.6 source 1, concern-aspects settingsModule) is static
  # data forced without entering the resolution fixpoint or materialization, so the walk stays fx-free.
  #
  # A settings field VALUE is a `{ default; merge ? "replace"; }` RECORD, NOT a `mkOption` decl — the leaf
  # is SYNTHESIZED from it (leaf `default = record.default`; `type = raw` since settings are lazyAttrsOf raw).
  synthSetting = fieldVal: {
    _type = "option";
    default = fieldVal.default or null;
    description = "";
    type = {
      name = "raw";
    };
  };
  # One aspect → a submodule option node. `getSubOptions` yields the synthesized settings leaves (a nixd
  # submodule descends through it); `description` falls back to the built-in `"Aspect ${name}"` default.
  aspectNode = name: a: {
    _type = "option";
    description = a.description or "Aspect ${name}";
    type = {
      name = "submodule";
      getSubOptions = _: builtins.mapAttrs (_: synthSetting) (a.settings or { });
    };
  };

  # The gen-lib API-surface projection (§ options-projection): project the 19 gen substrate libraries as an
  # option-tree of members so an LSP completes/hovers a gen-lib member. THIN BY DESIGN (den-map finding: the
  # gen libs are FLAT function attrsets carrying no type/signature metadata) — this projects member NAMES +
  # `functionArgs` PARTIAL formals, NEVER typed signatures. The `internal` input MIXES the 19 libs with ~30
  # den helper closures (buildRoots/runResolve/structural/compilePolicies/…, lib/default.nix internal block),
  # so membership is an EXPLICIT allowlist — never `attrNames internal`. The walk reads only `attrNames` +
  # `functionArgs` (config-free): it never enters the fx pipeline, so no fleet `.config` is forced.
  genLibNames = [
    "prelude"
    "dispatch"
    "resolve"
    "scope"
    "select"
    "product"
    "aspects"
    "pipe"
    "settings"
    "algebra"
    "demand"
    "edge"
    "bind"
    "class"
    "merge"
    "flake"
    "schema"
    "identity"
    "genGraph"
  ];
  # The allowlist as an attrset (any value): `intersectAttrs allow internal` keeps only the 19 lib keys,
  # dropping every den helper — the filter that makes the projection lib-only.
  genLibAllow = builtins.listToAttrs (
    map (n: {
      name = n;
      value = null;
    }) genLibNames
  );
  # DEFERRED ENRICHMENT (doc citations): the plan wants per-lib doc text (README / gen-specs REFERENCE.md) as
  # a member's hover `description`, but no doc source is reachable from a lib's pure function VALUE — the libs
  # are flake inputs (READMEs live in input store paths, absent from the `.lib` attrset) and gen-specs live in
  # a separate papers repo, not den-hoag. So `docFor` stubs to "" (empty description, never an error); wiring
  # real docs needs the lib-source paths threaded, out of this projection's pure `{ internal }` scope.
  docFor = _libName: _member: "";
  # One member → an option leaf: names + doc (deferred) + `functionArgs` formals when the member is a lambda
  # (a non-function member — a nested sub-namespace like `flake.terminals` — projects a bare leaf, no formals).
  projectGenLibMember =
    libName: member: fn:
    {
      _type = "option";
      description = docFor libName member;
    }
    // (if builtins.isFunction fn then { formals = builtins.functionArgs fn; } else { });
  # One lib → an attrset of its projected members. A lib carried as a bare function (none today; the guard is
  # defensive) projects an empty member set rather than tripping `mapAttrs`.
  projectGenLib =
    libName: lib:
    if builtins.isAttrs lib then builtins.mapAttrs (projectGenLibMember libName) lib else { };

  optionsProjection = { options }: walk options;

  # KNOWN LIMIT: this projects DECLARED aspect instances (`attrNames aspects`), not a fixed catalog (den
  # has none) — an empty/new fleet (`aspects == { }`) projects nothing. Correct + sufficient for listing +
  # completing already-declared aspects and their settings; it does NOT discover undeclared aspects.
  aspectsProjection = { aspects }: builtins.mapAttrs aspectNode aspects;

  # KNOWN LIMIT (thin by design): this projects member NAMES + `functionArgs` formals, NOT typed signatures —
  # the gen libs carry no type metadata (den-map). Doc citations are a deferred enrichment (see `docFor`): a
  # member's `description` is empty until lib-source paths are threaded. The allowlist keeps the projection
  # lib-only against `internal`'s mixed helper+lib content.
  genLibProjection =
    { internal }: builtins.mapAttrs projectGenLib (builtins.intersectAttrs genLibAllow internal);

  # The consumer entry (§ options-projection): given a BUILT den (`mkDen … .den`, carrying `_options` +
  # `aspects`) and the gen-lib `internal` bundle (`den.lib.internal` — it rides the LIBRARY, not the built
  # den value), return the three projections keyed exactly as a nixd option-provider config names them:
  # `nixd.settings.options.den.expr` → the option-declaration tree, `.den-aspects.expr` → the aspect
  # registry, `.gen.expr` → the gen-lib API surface. Each value is what a nixd worker evaluates ONCE (E0,
  # cache-once) and walks for completion/hover/goto — so all three are declaration-only (the laziness
  # guarantee, ci/tests/lsp-laziness.nix): none forces the fleet's resolved output / materialization.
  forNixd =
    { den, internal }:
    {
      den = optionsProjection { options = den._options; };
      "den-aspects" = aspectsProjection { aspects = den.aspects; };
      gen = genLibProjection { inherit internal; };
    };
in
{
  # The generic source-position layer, exposed on `den.lib.lsp.positions` for a later graph/nav consumer
  # to reuse independently of options (`positions.positionsOf { fields } raw` → nixd goto records).
  inherit
    positions
    optionsProjection
    aspectsProjection
    genLibProjection
    forNixd
    ;
}
