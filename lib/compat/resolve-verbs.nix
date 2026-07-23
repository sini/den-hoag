# den.lib.aspects.{resolve,resolveWithPaths,resolveImports} + den.lib.resolveEntity — a CONFIG-WIRED ADAPTER
# over den-hoag's ALREADY-NATIVE resolution output (#49 sub-rung C). v1 (den nix/lib/aspects/default.nix:
# 104-114, pin a2f4b60) ran a FRESH isolated fx pipeline per seed; den-hoag instead reads the memoized
# gen-edge fold over the ALREADY-INGESTED fleet graph (`built.den`), so this adapter closes over that built
# den and maps a seed → the node id its `output.outputFor`/`traceFor` key by. The field-map is
# THEORY-DETERMINED and oracle-proven the v1 twin (lib/compat/parity/oracle.nix:334-360,439-458,497 diffs
# `hoag traceFor == v1 edgeTrace` and `outputFor.<id>.<class> == v1 resolveWithPaths…imports`).
#
# CONFIG-WIRED (not the config-less migrationLib): it needs the built fleet, so it is bound at the bridge
# seam (bridge.nix `configWiredLib`) exactly as #49 sub-rung B bound `nh`/`schemaUtil`/`policyInspect`. The
# migrationLib carries NAMED config-wired stubs (throw on `inputs.den.lib`, real on the `den` module arg).
#
# ── LATENT ceilings (P5c-out-of-scope; ledgered so P5c is not ambushed) ────────────────────────────────
#  (a) ARBITRARY-NON-FLEET-ENTITY aspect tree. v1 `resolve`/`resolveImports` run over ANY seed (the
#      "extract homeManager modules from a host tree" nested-extraction, default.nix:113 doc). This adapter
#      resolves only a seed that maps to an INGESTED node (a built-fleet member); an off-fleet arbitrary
#      aspect tree would need Option B's per-call mini-ingest (deferred). LATENT until a nix-config corpus
#      policy is shown to call resolve on a non-fleet tree.
#  (b) SELF-REFERENCE. This adapter closes over `built.den`, which is the fold over the whole fleet; a
#      future corpus policy that calls `resolve <ownHost>` from WITHIN its own fleet self-references
#      (forcing `built.den` re-enters resolution). Option A (config-wired) is STATEFUL by construction, so
#      such a call is a latent cycle — no live consumer today (surface-totality; the witness resolves an
#      external fixture, never a self-call). LATENT/P5c.
#
# `resolveWithState` (v1 default.nix:114 → the raw `{ value; state; }` fx-trampoline result) has NO den-hoag
# native twin (fx retired) — it stays a NAMED stub on the migrationLib, never wired here.
{ den }:
let
  # resolveEntity kind seed → a node HANDLE. v1 nix/lib/resolve-entity.nix:17-76 built an entity SEED
  # aspect-tree carrying `__scopeHandlers = constantHandler augmentedCtx`; den-hoag DROPS it — `constantHandler`
  # is an fx primitive den-hoag retired, and native resolution reads ctx from the ingested node's
  # enriched-context (resolved-aspects.nix), never a seed field. The handle is the node id — a readable coord
  # path `"${kind}:${name}"` (lib/default.nix:1092, output-modules.nix:883), the key `outputFor`/`traceFor`
  # look up. v1's seed took `{ ${kind} = <entity record>; }`; the record's `.name` is the registry key.
  resolveEntity =
    kind: seed:
    let
      record = seed.${kind};
    in
    {
      __denNode = "${kind}:${record.name}";
    };

  nodeOf = handle: handle.__denNode;

  # imports = the per-class MATERIALIZED module list at the root = `outputFor.<id>.<class>` (the gen-edge
  # fold, Law A15; output-modules.nix:858). oracle.nix:442 reads exactly this as the v1 twin of v1
  # `resolveWithPaths class root → .imports`.
  importsAt =
    class: handle:
    let
      id = nodeOf handle;
    in
    (den.output.outputFor id).${id}.${class} or [ ];

  # resolve class handle → `{ imports }` (v1 default.nix:111 back-compat projection: imports only).
  resolve = class: handle: {
    imports = importsAt class handle;
  };

  # resolveWithPaths class handle → the FULL record (v1 resolve.nix:1027-1170).
  #  • edgeTrace = `traceFor id` (output-modules.nix:873); oracle-proven `hoag traceFor == v1 edgeTrace`
  #    (oracle.nix:334-360). `unifiedEdges` aliases it (v1 resolve.nix:1038).
  #  • pathSetByScope = the native `reach` closure keyed by id — v1's projected-hasAspect
  #    `{ scopeId → { pathKey → true } }` (pipeline.nix:138-142), reproduced from the native reach nodes'
  #    `.key`s (resolved-aspects.nix:333 `reach`). The native trace is ALREADY id-keyed, so v1's
  #    `scopeContexts`/`scopeEntityKind` (its scope-string→id_hash re-key inputs) are a v1-internal denorm —
  #    DROPPED. `legacyEdgeTrace`/`materializeEquiv` (v1 differential-suite internals, no consumer contract)
  #    DROPPED too.
  resolveWithPaths =
    class: handle:
    let
      id = nodeOf handle;
      trace = den.output.traceFor id;
    in
    {
      imports = importsAt class handle;
      edgeTrace = trace;
      unifiedEdges = trace;
      pathSetByScope = {
        ${id} = builtins.listToAttrs (
          map (n: {
            name = n.key;
            value = true;
          }) (den.structural.eval.get id "reach")
        );
      };
    };

  # resolveImports class handle → `{ imports }` (v1 default.nix:113 / resolve.nix:1183: phases 1-3 only,
  # SKIPS phase4 instantiate — "extract homeManager modules from a host tree"). den-hoag folds
  # materialization at `outputFor` and crosses the terminal (nixpkgs) SEPARATELY, so the v1 "phases-1-3 vs
  # phase4" split collapses: the materialized module list is the SAME one `resolve` reads (phase4 never
  # mutated the list).
  resolveImports = class: handle: {
    imports = importsAt class handle;
  };
in
{
  inherit
    resolve
    resolveWithPaths
    resolveImports
    resolveEntity
    ;
}
