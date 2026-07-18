# The render registry (`den.renders.<name>`, spec §4.3) — the D7 promotion of the `{ evaluator; output }`
# instantiation record into a full registry row. A render NAMES how a class materializes: its `evaluator`
# (the ONE nixpkgs crossing, inert data), the artifact `face` it builds, the `produces`/`requires` product
# typing, the `params` axes, and the `provision` data. This registry HOLDS the built-in nixos/darwin rows
# directly (the framework's system-class defaults, seeded per-fleet below); a user registers a new system
# face beside them. The registry is the Bazel-provider reading again: a render is the rule that produces a
# typed artifact, and its `requires` names the products it consumes.
#
# PER-FLEET, NOT STATIC: unlike products/edges/disciplines (whose framework rows are static constants),
# the built-in render rows derive their EVALUATORS from the fleet's OWN `den.nixpkgs`/`den.darwin` inputs
# (null input ⇒ null evaluator ⇒ the nixpkgs-free `collect` fallback). So `compile` takes those inputs and
# is invoked INSIDE the mkDen closure after the input reads — this lib holds compile + validation and
# NEVER the evaluators themselves (lib/** stays nixpkgs-free; nixpkgs is inert config data a consumer
# supplies, forced only at the terminal crossing).
#
# NO EFFECT RUNTIME: `compile` is one built-in seed + a `mapAttrs` + a validation fold — field defaults +
# product-typing checks against the compiled products table, no algorithm (Law A1). An `evaluator` /
# `provision` / `adapt` value is a FUNCTION: a registry holds functions freely — the fingerprint law
# (identity.nix) bans functions from EDGE DATA only, never from a registry entry.
{
  prelude,
}:
let
  # A registry entry's canonical fields (spec §4.3). `evaluator` is the `{ modules, specialArgs } -> system`
  # crossing (inert data); `provision` is the per-render provisioning data (pkgs/system/specialArgs/…),
  # supplied as declared data rather than injected as a module; `adapt` binds only functionArgs-declared
  # args lazily; `face` builds the artifact from an eval; `produces` names the product this render emits;
  # `requires` names the products it consumes; `params` names the finite axes (materialized as a
  # params-keyed attrset); `extendsVia` is the extend-mode capability flag; `compatibleWith` is the
  # compatibility predicate. `output` is the D7 field KEPT on the row — the flake-parts target the built
  # systems mount at; a later families registry supersedes it (§4.4), so it stays here until that arrives.
  entryOf =
    products: name: raw:
    let
      # `provision`/`adapt`/`face`/`extendsVia`/`compatibleWith` are stored SHAPE-ONLY here — carried on the
      # row but not yet wired (the mode-execution / families work consumes them); only `produces`/`requires`/
      # `params` are validated below, and only `evaluator`/`output` are read by the read-through.
      e = {
        evaluator = raw.evaluator or null;
        provision = raw.provision or null;
        adapt = raw.adapt or null;
        face = raw.face or null;
        produces = raw.produces or null;
        requires = raw.requires or [ ];
        params = raw.params or [ ];
        extendsVia = raw.extendsVia or null;
        compatibleWith = raw.compatibleWith or null;
        output = raw.output or null;
        # `aggregate` (spec §4.7) TAGS the evaluator's ARITY: false (default) = the per-config crossing
        # `{ modules; specialArgs } -> system`; true = the AGGREGATE crossing `<memberName-map> -> HiveInfo`
        # (a collector render). The crossing stays the `evaluator` FIELD (swappable data — the gen-flake seam);
        # this flag only lets each mount site NAME a per-config/aggregate misuse instead of a bare shape crash.
        aggregate = raw.aggregate or false;
      };
      # `produces` (when stated) names a registered product; `requires` names registered products. The
      # definition-time CONSUMPTION of `requires` (the graft-site product-face checks) arrives with the
      # families work — here the shape is validated (each name resolves in the products table), no more.
      badProduces = e.produces != null && !(products ? ${e.produces});
      badRequires = builtins.filter (p: !(products ? ${p})) e.requires;
      # `params` axes are NAMES only in this step (the finite-domain axis validation arrives with the
      # families/root work); a non-string axis is a definition error.
      badParams = builtins.filter (p: !builtins.isString p) e.params;
    in
    if badProduces then
      throw "den.renders: render '${name}' declares produces = '${e.produces}', which is not a registered product"
    else if badRequires != [ ] then
      throw "den.renders: render '${name}' requires unregistered product '${builtins.head badRequires}' — register it in den.products"
    else if badParams != [ ] then
      throw "den.renders: render '${name}' declares a non-name params axis — axes are product-name strings in this step"
    else
      e;

  # The built-in nixos/darwin render rows (spec §4.3, the D7 promotion) — THE single source of the built-in
  # instantiation base (a system class declares HOW it crosses; these two are the framework's defaults).
  # DERIVED PER-FLEET: each evaluator comes from the supplied `npkgs`/`ndarwin` flake (null input ⇒ null
  # evaluator ⇒ the nixpkgs-free `collect` fallback, den-hoag's pure path). `produces = "SystemInfo"` (both
  # are artifact-mode faces, per the products table); `output` names the flake-parts target the built
  # systems mount at. These are DEFAULT rows (overridable): a `den.classes.<name>.instantiation` overlay
  # wins over the row at the read-through, and a class setting its own `instantiate` overrides everything
  # (the precedence law lives at the read-through).
  builtinRows = npkgs: ndarwin: {
    nixos = {
      evaluator = if npkgs == null then null else npkgs.lib.nixosSystem;
      produces = "SystemInfo";
      output = "nixosConfigurations";
    };
    darwin = {
      evaluator = if ndarwin == null then null else ndarwin.lib.darwinSystem;
      produces = "SystemInfo";
      output = "darwinConfigurations";
    };
  };

  # `compile { registered; npkgs; ndarwin; products }` → the validated compiled render table (the built-in
  # rows SEED it, a user registration merges beside them; a user `den.renders.<name>` may override a
  # built-in — the promotion is an extension point, not a reserved namespace). `products` is the COMPILED
  # products table (spec §4.1): the produces/requires typing is validated against it. Invoked INSIDE the
  # mkDen closure after the npkgs/ndarwin reads.
  compile =
    {
      registered ? { },
      npkgs ? null,
      ndarwin ? null,
      products ? { },
    }:
    let
      allRaw = builtinRows npkgs ndarwin // registered;
    in
    prelude.mapAttrs (entryOf products) allRaw;
in
{
  inherit compile;
}
