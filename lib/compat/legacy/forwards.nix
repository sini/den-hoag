# den-compat LEGACY surface: `forwards` (self-contained, tagged — the severance surface, §2.1).
#
# The v1 forward system as a self-contained tagged module. A forward is `deliver from a class INTO
# another class[.path]`, split by v1 into two tiers (frozen pin denful/den@11866c16):
#
#   TIER-1 (static) — a directly-importable forward: static `intoClass`, static `intoPath`, no adapter
#     machinery (compile-forward.nix `isSimpleSpec = canDirectImport ∧ ¬needsAdapter ∧ ¬evalConfig`).
#     Desugars to a plain `deliver` (a collected source → reroute-shaped edge), IDENTICAL to v1's own
#     tier-1 classification — the shim just calls the public `deliver` surface (Task 2), the same path
#     the corpus takes, so severing this module never touches `deliver`.
#
#   COMPLEX (adapter-bearing) — a forward that threads args/modules through an adapter (`adaptArgs`,
#     `adapterModule`, a function-valued `intoPath`, a `mapModule`, `evalConfig`, or a `guard`; v1
#     forward.nix `needsAdapter`). Desugars to an INERT gen-edge `synthesize` SOURCE RECORD (Law C2's
#     ONE relaxation — the shim CONSTRUCTS the record, it never evaluates it, reads the scope graph, or
#     reads resolved state). Its identity triple is `(forwardId, fromClass, intoClass)`, matching the
#     frozen v1 schema (gen-edge core.nix `sourceKey`: `synthesize:${forwardId}/${fromClass}>${intoClass}`).
#     The record is INERT: gen-edge's `trace` renders only that identity and never forces the carried
#     module — so the edge "records identity, never resolved content" (v1's `sourceVia = "unresolved"`
#     edge annotation is the same property, added when the synthesize edge is assembled). The adapter
#     composition itself is this module's `interpret.synthesize`, which den-hoag RUNS later, inside its
#     single `materialize` fold, threaded via the shipped `den.interpret` raw seam (item 7).
#
# den-hoag constructs NO synthesize record and defines NO interpreter (item 7): both are the legacy
# module's, threaded in as data + a closure. With this module absent, any use of `den.classes.<c>.forwardTo`
# is a definition-time error (Law C5, sentinels.nix). (Tier-2 derived-children NTA: NOT implemented —
# the corpus census found zero consumers; PIN.md §Open-Question-2.)
{
  prelude,
  schema,
  edge,
  errors,
  ...
}:
let
  inherit (prelude) concatStringsSep isFunction optional;
  id = x: x;

  # tier-1 reuses the shim's public `deliver` surface (Task 2) — a static forward IS a plain route with
  # no adapter. Imported (not passed) so the legacy module depends on the shim core exactly as the corpus
  # does, through the public surface: severing `forwards` leaves `deliver` and its consumers untouched.
  deliverLib = import ../deliver.nix { inherit prelude errors; };

  # ── the forward tier classification ────────────────────────────────────────────────────────────────
  # ADAPTER-BEARING (⇒ complex ⇒ synthesize) when the forward threads args or modules through an adapter.
  # Frozen from v1 forward.nix `needsAdapter = guard≠null ∨ adaptArgs≠null ∨ adapterModule≠null ∨
  # isFunction intoPath` PLUS compile-forward.nix's `¬(evalConfig)` gate and `mapModule` (a non-identity
  # module transform is an adapter too). Everything else — a static intoClass + static intoPath, directly
  # importable — is TIER-1. A `guard` alone forces v1's adapter arm (guardFn threading), so it counts.
  isComplex =
    spec:
    (spec.adaptArgs or null) != null
    || (spec.adapterModule or null) != null
    || (spec.mapModule or null) != null
    || (spec.guard or null) != null
    || (spec.evalConfig or false)
    || isFunction (spec.intoPath or null);

  # The static (function-free) intoPath — v1 `staticIntoPath` (forward.nix): a function-valued intoPath
  # is dynamic (resolved per firing scope), so its STATIC part is `[ ]`. tier-1 delivers at it; the
  # complex forwardId keys on it.
  staticIntoPathOf =
    spec:
    let
      p = spec.intoPath or spec.path or [ ];
    in
    if isFunction p then [ ] else p;

  # forwardId — the synthesize identity's first field. v1 routeEdges: `spec.adapterKey or
  # "${fromClass}>${intoClass}@${sourceScopeId}/${path}"`. The `adapterKey` (forward.nix:
  # `concatStringsSep "/" ([fromClass intoClass] ++ staticIntoPath)`) is the SCOPE-FREE identity v1
  # prefers whenever present. The shim uses it — the firing `sourceScopeId` is unknowable at compile time
  # (Law C2), and a spec that carries `adapterKey` byte-matches v1's forwardId, which reads it first. A
  # spec without one falls back to the same `adapterKey` FORMULA (scope-free), never the scope-bearing arm.
  forwardId =
    spec:
    spec.adapterKey or (concatStringsSep "/" (
      [
        spec.fromClass
        spec.intoClass
      ]
      ++ staticIntoPathOf spec
    ));

  # ── tier-1: a static forward → a plain `deliver` (collected source, reroute-shaped) ─────────────────
  tier1 =
    spec:
    deliverLib.deliver {
      from = spec.fromClass;
      to = spec.intoClass;
      at = staticIntoPathOf spec;
    };

  # ── complex: an INERT gen-edge `synthesize` SOURCE RECORD (Law C2 relaxation — record construction,
  #    no evaluation). Identity triple `(forwardId, fromClass, intoClass)` matches the frozen v1 schema;
  #    the adapter machinery + source module ride on `module` (opaque payload) for interpret.synthesize.
  #    A synthesize forward is a pure producer (its content is built from its own source module, not
  #    from accumulator cells; v1 buildForwardAspect reads no fold state) — so `reads` is left at
  #    gen-edge's default `[ ]` rather than passed explicitly. ─────────────────────────────────────────
  synthRecord =
    spec:
    edge.sources.synthesize {
      spec = {
        forwardId = forwardId spec;
        inherit (spec) fromClass intoClass;
      };
      module = {
        forwardSpec = spec;
        sourceModule = spec.sourceModule or { };
      };
    };

  # The per-spec desugar: tier-1 → a `deliver` declaration; complex → an inert synthesize source record.
  forward = spec: if isComplex spec then synthRecord spec else tier1 spec;

  # ── interpret.synthesize — the adapter composition, RUN by den-hoag inside `materialize` (item 7),
  #    NOT by the shim. gen-edge calls `interpret.synthesize edge pi reads` and folds the returned
  #    content into the target class bucket, ordered by the edge toposort. Packages v1
  #    forward.nix/handlers/forward.nix's `buildForwardAspect` composition: the freeform module +
  #    adapterModule + mapModule(sourceModule) + adaptArgs/guard threading. The submoduleWith `__functor`
  #    fidelity (v1 handlers/forward.nix `mkAdapterAspect`) is the C8 CONTENT-oracle's byte concern; here
  #    the composition RUNS and yields the intoClass module (a real, forceable value). ──────────────────
  #
  # freeform module — v1 forward.nix `freeformMod`. den-hoag's terminal ALSO freeform-absorbs
  # (output-modules.nix `freeformAbsorber`), so this is belt-and-suspenders parity with v1's evalModules
  # path; `schema.types.lazyAttrsOf schema.types.raw` is the den-hoag-native `lib.types.lazyAttrsOf
  # lib.types.unspecified`.
  freeformMod = {
    config._module.freeformType = schema.types.lazyAttrsOf schema.types.raw;
  };
  interpretSynthesize =
    edgeRec: _pi: _reads:
    let
      payload = edgeRec.source.synthesize.module;
      spec = payload.forwardSpec;
      mapModule = spec.mapModule or id;
      adapterModule = spec.adapterModule or null;
      adaptArgs = spec.adaptArgs or null;
      # v1 forward.nix: the mapped source module + freeform + (optional) adapterModule.
      mapped = mapModule payload.sourceModule;
      mods = [ freeformMod ] ++ optional (adapterModule != null) adapterModule ++ [ mapped ];
    in
    # No adapter-args threading ⇒ a plain module set (v1 mkDirectAspect's imports). adaptArgs ⇒ a FUNCTION
    # module that adapts the cell's args before the source sees them (v1 route.nix `adaptModule` /
    # handlers `extraArgsFor`, threaded through den-hoag's terminal module args). The GUARD's config gate
    # (v1 forward.nix `guardFn`) is a C8 content-fidelity item — carried on the spec, applied faithfully
    # there; here the guard-bearing forward still yields its content (guard forces only the adapter arm).
    if adaptArgs == null then
      { imports = mods; }
    else
      args: {
        imports = mods;
        _module.args = adaptArgs args;
      };
in
{
  _denCompat.legacy = "forwards";

  # The forward machinery (the desugar primitives), for the harness + a future forward-using corpus.
  inherit
    isComplex
    forwardId
    tier1
    synthRecord
    forward
    ;

  # interpret — the gen-edge source interpreters, threaded into den-hoag's single `materialize` via the
  # shipped `den.interpret` raw seam (flake-module.nix `mkDen`; output-modules.nix `interpret ? { }`),
  # WITHOUT editing output-modules.nix. `rewalk` is unset — no corpus spawn-legacy forward exercises it.
  interpret = {
    synthesize = interpretSynthesize;
  };

  # desugar — the surface consumer wired by flake-module.nix's `desugarLegacy` (or-identity severance,
  # the C4 template). Strips `den.classes.<c>.forwardTo`: it is INERT default metadata (v1 forward.nix
  # reads it as the fallback intoClass/intoPath for a `forward` FROM that class), and the corpus has no
  # forward USING it (PIN.md census) — so stripping is semantically complete. The sentinel mechanism:
  # this desugar removes `forwardTo` BEFORE compile sees it, so translateClass's sentinel finds nothing
  # when the module is present; severed (or compile called directly), the residual `forwardTo` survives
  # to compile and trips `errors.legacyForwardsAbsent` (Law C5). Everything else passes through.
  desugar =
    v1:
    v1
    // prelude.optionalAttrs (v1 ? classes) {
      classes = builtins.mapAttrs (
        _: cls: if builtins.isAttrs cls then builtins.removeAttrs cls [ "forwardTo" ] else cls
      ) v1.classes;
    };
}
