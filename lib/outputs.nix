# The output-families registry (`den.outputs.<family>`, spec §4.4) — the root-as-entity uniform-resolution
# reading (§4.6): a fleet's TOP-LEVEL output faces (nixosConfigurations, darwinConfigurations, a user's own
# target) are DATA, one row per family, resolved by the SAME machinery a nested receives row is. A family row
# NAMES how a class's built members surface at the flake root: its `at` placement (the paramPoint-first path,
# the built member's key under the target), the product it `consumes` (from which its MODE derives — F1's
# canonical machine form), the `render` that builds the artifact, the `params` axes the face is materialized
# over (today the `system` axis, whose values are `den.systems`), and the `requires` products it consults.
# The Bazel output-groups reading: a family is a named group of built artifacts a consumer addresses at the
# flake root; `consumes`/`requires` name the product faces flowing into it. This is the D7-promotion precedent
# once more (REFERENCE "Materialization registries"): the ad-hoc per-class declared-target face-builder became
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
      # `contentClass` (nullable) names the CONTENT CHANNEL an opted-in member's modules are sliced from
      # (`classSubtreeAt <entity-root-scope> contentClass`) to feed the render evaluator — the artifact-mode
      # opt-in mount's payload source. Built-ins declare none (null): they inject the prebuilt system VALUE-mode,
      # never re-sliced. A non-null non-string value is a definition error.
      contentClass = raw.contentClass or null;
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
    # `render` names the artifact evaluator the built member surfaces through — legal ONLY on an artifact-mode
    # family (mirroring receivers.nix; extend-mode families don't exist). A content/value family (the future
    # flake-parts transposition path) has no artifact to render, so a render there is a definition error.
    else if render != null && mode != "artifact" then
      throw "den.outputs: family '${family}' consumes '${consumes}' — a ${mode}-mode family has no artifact to render (render is the artifact eval, artifact-mode families only)"
    else if badParams != [ ] then
      throw "den.outputs: family '${family}' declares unknown param axis '${builtins.head badParams}' — one of ${builtins.toJSON axes}"
    else if badRequires != [ ] then
      throw "den.outputs: family '${family}' requires unregistered product '${builtins.head badRequires}' — register it in den.products"
    else if contentClass != null && !(builtins.isString contentClass) then
      throw "den.outputs: family '${family}' declares a non-string contentClass — the opt-in content channel is a class-name string (or null)"
    else
      {
        inherit (raw) at;
        inherit
          consumes
          mode
          render
          params
          requires
          contentClass
          ;
      };

  # THE ROOT KIND (spec §4.6, root-as-entity): the fleet's TOP-LEVEL output faces resolve through the SAME
  # slot ≻ class dispatch a nested receives row does — so a family IS a receives row on a framework `root`
  # kind. `toReceives registered` projects the raw `den.outputs` config into a raw `den.kinds` ENTRY
  # `{ root = { includes = [ ]; receives.<family> = <§4.2 receives row>; }; }`, merged into the receivers
  # compile's `rows`. Each family row carries the §4.2 receives contract ONLY — `at`/`consumes` (+ `render`
  # when present), plus the `arity = "many"` / `multiplicity = "error"` defaults; the family-specific
  # `params`/`requires` STAY on the family row (they are the §4.4 face-materialization fields, not §4.2 graft
  # data — the split keeps the receives row a clean §4.2 record the real `resolveReceiver` walks). The
  # RECEIVERS compile validates the projected rows (mode derivation via consumes, render/artifact pairing),
  # so this projection re-implements NONE of that — it selects the §4.2 fields and hands them over.
  toReceives =
    registered:
    let
      # `arity = "many"` / `multiplicity = "error"` are §4.4 INVARIANTS (a family always admits many members,
      # errors on a mount clash), NOT projected data — a family row never declares them, so they are set here.
      receivesRowOf =
        raw:
        {
          inherit (raw) at consumes;
          arity = "many";
          multiplicity = "error";
        }
        // prelude.optionalAttrs (raw ? render) { inherit (raw) render; };
    in
    {
      root = {
        includes = [ ];
        receives = prelude.mapAttrs (_family: receivesRowOf) registered;
      };
    };

  # THE BUILT-IN FAMILY SEEDING (spec §4.4, the D7 promotion of the declared-target face): the framework's
  # own output families — `nixosConfigurations`/`darwinConfigurations` and any user system class's declared
  # target — derived PER-FLEET from each class's INSTANTIATION `output` field. `builtinFamilies { classNames;
  # instantiationOf; hasRender }` reads, for each class, `(instantiationOf class).output` (via `instantiationOf`
  # so the `classes.<name>.instantiation` overlay is preserved, NOT raw rendersRows.output which would bypass
  # it); a non-null output STRING seeds a family keyed by that string, `consumes = "SystemInfo"` (the system
  # artifact face), `render` = the class name where a render row exists (`hasRender class`, null otherwise),
  # `at = _point: e: [ <family> e.name ]` (the placement producing the `[<family> <entityName>]` face path).
  # LAST-WINS on a shared output string: two classes declaring the same `output` collapse to the last one (the
  # fold's later write wins — the listToAttrs last-wins the declared-target face has; corpus-un-exercised,
  # reproduced for parity).
  # Returns `{ families; classOf; }` — `families` the raw rows (for `compile` + `toReceives` seeding),
  # `classOf.<family>` the winning class (the assembly reads `output.systems.<class>` + resolves that class).
  builtinFamilies =
    {
      classNames,
      instantiationOf,
      hasRender,
    }:
    let
      # one seed per class with a non-null output string, in effectiveClassNames order (so the fold's LAST
      # write for a shared output string wins — the listToAttrs last-wins parity).
      seeds = builtins.concatMap (
        class:
        let
          out = (instantiationOf class).output or null;
        in
        if out == null then
          [ ]
        else
          [
            {
              family = out;
              inherit class;
              row = {
                at = _point: e: [
                  out
                  e.name
                ];
                consumes = "SystemInfo";
                render = if hasRender class then class else null;
              };
            }
          ]
      ) classNames;
    in
    {
      families = builtins.listToAttrs (
        map (s: {
          name = s.family;
          value = s.row;
        }) seeds
      );
      classOf = builtins.listToAttrs (
        map (s: {
          name = s.family;
          value = s.class;
        }) seeds
      );
    };

  # ── REQUIRES CONSUMPTION (spec §4.4, the deferred definition-time check): a family's `requires` (∪ its
  # render's `requires`) names the products it CONSUMES; each must be SATISFIABLE at the graft site — present
  # in the `available` product set the fold can supply there. `checkRequires { family; requires; available }`
  # returns the required set unchanged when satisfied, else aborts NAMED (naming the family + the first missing
  # product) — the §4.4 sentence "Required fields are render-declared and definition-time-checked" realized.
  # An empty `requires` is vacuously satisfiable (the built-ins). This is the CONSUMPTION half of the shape
  # check the render/family compile already did — a registered product that is simply not producible HERE.
  checkRequires =
    {
      family,
      requires ? [ ],
      available ? [ ],
    }:
    let
      availableSet = prelude.genAttrs available (_: true);
      missing = builtins.filter (p: !(availableSet ? ${p})) requires;
    in
    if missing != [ ] then
      throw "den.outputs: family '${family}' requires product '${builtins.head missing}' but it is not satisfiable at the graft site — no producer supplies it there"
    else
      requires;

  # ── PARAMS FAN-OUT (spec §4.4): a family's `params` are the finite axes its face materializes over — today
  # the `system` axis, whose values are `den.systems`. `fanParams { family; params; systems }` produces the
  # declared CARTESIAN at the family level: one paramPoint per axis-value tuple. With `params = [ "system" ]`
  # the fan is one entry per system (the devShells shape, `{ system = <sys>; }` each); with `params = [ ]` the
  # fan is the DEGENERATE single face (`[ { } ]` — a system-agnostic family surfaces once). Today the sole
  # axis is `system`, so the fan is one-dimensional; a multi-axis cartesian is a later generality (one axis
  # registry entry per axis). DEDUP-PER-PARAMPOINT — the instanceId wiring that dedups a member materialized
  # at the same paramPoint twice rides the live-producer sub-plan; here the fan is the pure axis enumeration.
  fanParams =
    {
      family,
      params ? [ ],
      systems ? [ ],
    }:
    if params == [ ] then
      [ { } ]
    else if params == [ "system" ] then
      map (s: { system = s; }) systems
    else
      # unreachable while `system` is the sole axis (the family compile rejects an unknown axis); the named
      # throw guards a future axis reaching here before its fan is wired.
      throw
        "den.outputs: family '${family}' declares params ${builtins.toJSON params} — only the 'system' axis fans today";

  # ── THE ENTITY-LEVEL OPT-IN (spec §4.4/§7): an entity opts into a family via `den.<kind>.<name>.outputs.
  # <family> = { <field> = <value>; }`. The render-declared REQUIRED FIELDS an opt-in must supply are the
  # family's `params` (the axes the render fans over — the "render genuinely needs" set, e.g. a
  # homeConfigurations family requiring `system`). `checkOptIn { family; params; entity; optIn }` validates
  # the opt-in supplies a value for EACH param (missing → named throw quoting the field + family, NEVER
  # silent), and returns the elaboration RECORD `{ family; entity; data }` — the family + entity + the
  # structural opt-in data. A family naming no render and no params requires nothing, so an empty opt-in
  # `{ }` is valid. NO EDGE EMISSION: the family nest edge for an opted-in entity arrives with the
  # live-producer sub-plan; this produces the inert elaboration record only.
  checkOptIn =
    {
      family,
      params ? [ ],
      entity,
      optIn ? { },
    }:
    let
      missing = builtins.filter (p: !(optIn ? ${p})) params;
    in
    if missing != [ ] then
      throw "den.outputs: entity '${entity}' opts into family '${family}' but supplies no '${builtins.head missing}' — the render-declared required field (a family param) is missing (never silent)"
    else
      {
        inherit family entity;
        data = optIn;
      };

  # `compile { registered; builtins ? { }; renders; products; systems }` → the validated compiled families
  # table (a `mapAttrs` + validation, Law A1 — the receivers/renders template). The framework `builtins`
  # families (the built-in nixosConfigurations/darwinConfigurations seeded by `builtinFamilies`) seed the
  # table; a USER `den.outputs.<family>` merges beside them (a user re-declaration of a built-in family key
  # wins, the render/product extension posture). `renders` is the COMPILED render table (§4.3, for the
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
  inherit
    compile
    toReceives
    builtinFamilies
    checkRequires
    fanParams
    checkOptIn
    axes
    ;
}
