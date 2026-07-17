# The typed-product registry (`den.products.<name>`, spec §4.1) + the single-step conversion registry
# (`den.conversions."<from>-><to>"`, spec §4.1). A product NAMES a typed materialization payload and the
# MODE its receiver consumes it in — the Bazel-provider reading: a product is a typed carrier flowing
# from a producing rule to a consuming rule, and the mode is DERIVED from the product (a total function
# over the nestable products, F1's canonical machine form), never declared on the receiver. den-hoag
# pre-registers the framework faces; a user registers a new artifact face beside them. Conversions are
# single-step (produces, consumes) materializations — the MLIR dialect-conversion reading, but with the
# transitive pattern-application chain REJECTED for determinism: a needed composite is its own pair. The
# registry only DECLARES names + modes; the payload SCHEMAS (spec §4.1 "gen-schema-typed records") arrive
# with mode execution, not here. See REFERENCE.md.
#
# NO EFFECT RUNTIME: `compile` is one `mapAttrs` + a validation fold — field defaults + mode-set checks,
# no algorithm (Law A1; mirrors concern-classes / concern-disciplines / edges). A conversion's `via` is a
# FUNCTION: a registry holds functions freely — the fingerprint law (identity.nix) bans functions from
# EDGE DATA only, never from a registry entry.
{
  prelude,
}:
let
  # The closed set of materialization modes (spec §4.1). A product declares one of these; a name outside
  # the set is a definition error (there is no fallback mode). `content` = a module list joins the graft
  # site; `artifact` = an assembled built face; `extend` = an extendModules handle (legal only under a
  # render declaring `extendsVia`); `value` = the prebuilt arm (an ArtifactRef, injected verbatim, never
  # evaluated by den — it has no plain-row form, only the wrapper below).
  modes = [
    "content"
    "artifact"
    "extend"
    "value"
  ];
  modeSet = prelude.genAttrs modes (_: true);

  # The ArtifactRef WRAPPER prefix (spec §4.1). `ArtifactRef P` is value mode — the prebuilt arm of any row
  # consuming artifact-face P. It is NOT a table row: a production short-circuit stamps `ArtifactRef <face>`
  # as the product name of the prebuilt value, and a `consumes = P` row accepts it DEFINITIONALLY (no
  # conversion lookup). So the name is recognized STRUCTURALLY (by this prefix) rather than by table
  # membership, and it never appears literally in a `consumes` (that is a definition-time throw).
  artifactRefPrefix = "ArtifactRef ";
  isArtifactRef = name: prelude.hasPrefix artifactRefPrefix name;

  # The framework-pre-registered products (spec §4.1 table). Each row is `{ mode; nestable }`. The artifact
  # faces (SystemInfo … HiveInfo) are the assembled-output products (HiveInfo = a collector's built
  # aggregate). ArgsInfo is the arg-environment payload `adapt` consumes/produces — non-nestable, so it is
  # never a receiver's `consumes`. `ArtifactRef P` is NOT here: it is the structural wrapper (above), not a
  # row. A user re-registration of any of these names aborts NAMED (the reserved posture).
  frameworkProducts = {
    ModulesInfo = {
      mode = "content";
    };
    RawModulesInfo = {
      mode = "content";
    };
    SystemInfo = {
      mode = "artifact";
    };
    HmInfo = {
      mode = "artifact";
    };
    DroidInfo = {
      mode = "artifact";
    };
    NixidyEnvInfo = {
      mode = "artifact";
    };
    ShellInfo = {
      mode = "artifact";
    };
    TerranixInfo = {
      mode = "artifact";
    };
    HiveInfo = {
      mode = "artifact";
    };
    EvalHandleInfo = {
      mode = "extend";
    };
    # the non-nestable arg-environment payload — never a consumes (its content is `adapt`'s functionArgs).
    ArgsInfo = {
      mode = "content";
      nestable = false;
    };
  };
  reservedNames = builtins.attrNames frameworkProducts;
  reservedSet = prelude.genAttrs reservedNames (_: true);

  # A registry entry's canonical fields (spec §4.1). `mode` names the materialization mode (REQUIRED,
  # ∈ modes); `nestable` (default true) gates whether the product may appear in a receiver's `consumes` —
  # a non-nestable product (ArgsInfo, or a user payload) is a definition-time throw at a consumes position.
  entryOf =
    name: raw:
    let
      mode =
        raw.mode
          or (throw "den.products: product '${name}' declares no mode — one of ${builtins.toJSON modes} is required");
    in
    if !(modeSet ? ${mode}) then
      throw "den.products: product '${name}' declares unknown mode '${mode}' — one of ${builtins.toJSON modes}"
    else
      {
        inherit mode;
        nestable = raw.nestable or true;
      };

  # `compile { products }` → the validated compiled product table (a `mapAttrs` + validation fold,
  # mirroring concern-disciplines' / edges' compile shape). The framework faces SEED the table (their
  # reserved names are theirs to write); a USER registration merges beside them. Re-registering a
  # framework-reserved product name aborts NAMED before any entry is built; so does a name in the
  # `ArtifactRef ` prefix namespace — the value-mode wrapper is recognized structurally by that prefix, so
  # a table row wearing it would be silently misclassified (modeOf reads its prefix as value, checkConsumes
  # throws on it as the wrapper), never its declared mode. The prefix is reserved, not a legal product name.
  compile =
    {
      products ? { },
    }:
    let
      reservedOffenders = builtins.filter (n: reservedSet ? ${n}) (builtins.attrNames products);
      prefixOffenders = builtins.filter isArtifactRef (builtins.attrNames products);
      allRaw = frameworkProducts // products;
    in
    if reservedOffenders != [ ] then
      throw "den.products: product '${builtins.head reservedOffenders}' is framework-reserved"
    else if prefixOffenders != [ ] then
      throw "den.products: product names may not begin with the reserved 'ArtifactRef ' prefix (the value-mode wrapper namespace) — '${builtins.head prefixOffenders}' does"
    else
      prelude.mapAttrs entryOf allRaw;

  # `modeOf compiled name` — the product → mode derivation, TOTAL over the nestable products (spec §4.1).
  # An `ArtifactRef P` name resolves STRUCTURALLY to value mode (the prebuilt arm); every other name must
  # be a registered product (an unregistered name is a definition error — modeOf is total only over the
  # registered nestable products plus the value-mode wrapper).
  modeOf =
    compiled: name:
    if isArtifactRef name then
      "value"
    else if compiled ? ${name} then
      compiled.${name}.mode
    else
      throw "den.products: no mode for product '${name}' — it is not a registered product (modeOf is total over the registered nestable products and the ArtifactRef value-mode wrapper)";

  # `checkConsumes compiled name` — the definition-time gate a receiver's `consumes` passes through (spec
  # §4.1). Returns the name when it is a registered NESTABLE product; aborts NAMED when the name is
  # unregistered, non-nestable, or the literal `ArtifactRef` wrapper (which is a production short-circuit,
  # never a declared consumes — same rule as a non-nestable product). This is the pure fn receivers call.
  checkConsumes =
    compiled: name:
    if isArtifactRef name then
      throw "den.products: 'ArtifactRef' never appears literally in a consumes — it is the value-mode prebuilt arm of an artifact-consuming row (§4.1), injected at production, not a declared consumes"
    else if !(compiled ? ${name}) then
      throw "den.products: consumes names unregistered product '${name}' — register it in den.products or use a framework product"
    else if !compiled.${name}.nestable then
      throw "den.products: consumes names non-nestable product '${name}' — a non-nestable product (an arg-environment payload) is never a consumes (§4.1)"
    else
      name;

  # ── den.conversions: the single-step (from, to) materialization registry (spec §4.1) ──
  # A conversion is `den.conversions."<from>-><to>" = { via = fn; }` — the fn materializes a `from`-typed
  # product into a `to`-typed one when a (produces, consumes) mismatch arises. SINGLE-STEP: no transitive
  # chain search (the MLIR-style multi-hop materialization is REJECTED for determinism — a needed composite
  # is registered explicitly as its own pair). Uniqueness is GLOBAL per (from, to) pair BY CONSTRUCTION:
  # the registry is one attrset keyed by the pair string, so two registrations of the same pair ARE the
  # same key (kind-includes / receiver inheritance resolve in this global registry — they cannot
  # manufacture a shadowing duplicate). Within one module a same-key re-declaration collapses; a genuine
  # CROSS-MODULE same-pair collision surfaces as the module system's unique-merge conflict at
  # `den.conversions."<pair>".via` — the raw type never last-wins on non-equal records, so a real duplicate
  # throws `defined multiple times` at that key path, not a silent shadow. The compile gate then enforces
  # the KEY WELL-FORMEDNESS that keying relies on: each key splits on `->` into EXACTLY two non-empty faces,
  # and NEITHER face is an `ArtifactRef` (conversions never apply to the prebuilt arm — an ArtifactRef
  # endpoint is definitional acceptance or an unrealized-cast, never a conversion).
  # split a pair key on the literal `->` arrow: `builtins.split` interleaves the separator matches (as
  # sub-lists) with the string pieces, so keep only the string pieces. `-` and `>` are not regex
  # metacharacters, so the arrow is its own literal pattern (no anchor, no `.*` — linear over a short
  # product-name key, no backtracking).
  splitPair = key: builtins.filter builtins.isString (builtins.split "->" key);
  conversionEntryOf =
    key: raw:
    let
      faces = splitPair key;
      via =
        raw.via
          or (throw "den.conversions: pair '${key}' declares no via — the materialization function is required");
    in
    if builtins.length faces != 2 then
      throw "den.conversions: pair key '${key}' is malformed — it must name exactly two product faces as '<from>-><to>'"
    else if builtins.any (f: f == "") faces then
      throw "den.conversions: pair key '${key}' has an empty face — both '<from>' and '<to>' must be named"
    else if builtins.any isArtifactRef faces then
      throw "den.conversions: pair '${key}' names an ArtifactRef endpoint — conversions never apply to the prebuilt arm (§4.1)"
    else
      {
        from = builtins.head faces;
        to = builtins.elemAt faces 1;
        inherit via;
      };

  # `compileConversions { conversions }` → the validated conversion table (mapAttrs + validation, the
  # Law A1 shape). Each entry gains its split `from`/`to` faces beside the `via` fn; a malformed key or an
  # ArtifactRef endpoint aborts NAMED.
  compileConversions =
    {
      conversions ? { },
    }:
    prelude.mapAttrs conversionEntryOf conversions;
in
{
  inherit
    modes
    reservedNames
    compile
    compileConversions
    modeOf
    checkConsumes
    ;
}
