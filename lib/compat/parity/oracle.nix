# The two-sided oracle — render BOTH arms into the frozen `T | P | S | M` trace (schema.nix), so the
# harness can diff them on the sort-key string alone.
#
#   traceHoag { denCompat } fixture   — the v2 arm: `denCompat.mkDen [ fixture.module ]`, class-share
#                                       ENABLED, gather `den.graph.edges` over `den.scopeRoots`, render
#                                       once via gen-edge `edgeSortKey`.
#   traceV1  { … } fixture            — the v1 arm: evaluate the fixture under the frozen den v1 pin
#                                       (replicating den v1's own denTest evalDen), resolve each root's
#                                       PRODUCTION `edgeTrace` via `resolveWithPaths` (oracle ≡ production
#                                       by construction), render via den v1's `edgeSortKey`.
#   traceV1Legacy { … } fixture       — the P7 NEGATIVE CONTROL: the SAME resolve, reading v1's
#                                       `legacyEdgeTrace` (the spawn-rewalk UNDERCOUNT) instead of the
#                                       production `edgeTrace`.
#
# TWO SCHEMA-ALIGNMENT FINDINGS drive the design (edge-schema.md + the C7 report — the plan's OQ4 /
# "schema-commitment finding" surface):
#
#   F1 (entity id_hash divergence). den v1 and gen-schema stamp DIFFERENT id_hashes for the same
#      (kind, name) — v1 `host:igloo` ≠ den-hoag `host:igloo`. So entity scopes CANNOT be diffed on raw
#      id_hash ("without translation" is empirically false). The harness name-normalizes entity scopes to
#      `<kind>:<name>` on BOTH arms before rendering — exactly what den v1's own `delivery-edges` suite
#      does (`normalizeTrace`, edge-trace.nix). Names are stable across both id_hash conventions.
#   F2 (non-entity scope naming, OQ4). den v1 names non-entity scopes by its `mkScopeId` string
#      (`""`→`"<root>"`, `system=…`); den-hoag by an opaque node string. `nonEntityNameMap` translates
#      the hoag arm's non-entity strings into v1's `mkScopeId` form; its completeness is only provable
#      against the first full-corpus run, so a residual mismatch surfaces as a first-corpus diff (ledger).
#
# nixpkgs-lib-free: `prelude` for the pure list/string work; `edgeCore` = gen-edge's frozen trace core
# (`edgeSortKey`/`renderName`), the v2 arm's renderer. The v1 arm's nixpkgs `lib` + `edgeSortKey` + the
# den v1 flake are INJECTED by the harness (`mkV1`), never imported here — the v1 eval genuinely needs
# them, and injecting keeps this file import-clean.
{ prelude, edgeCore }:
let
  # The tail segment after the LAST separator (`"host:igloo"` → `"igloo"`; a separator-free opaque string
  # → itself). `builtins.split` keeps regex-match sentinels between the string parts; filter to strings.
  lastSegment =
    sep: s:
    let
      segs = builtins.filter builtins.isString (builtins.split sep s);
    in
    if segs == [ ] then s else prelude.last segs;

  # ── the pinned non-entity scope name map (F2 / OQ4) ───────────────────────────────────────────────
  # hoag opaque non-entity string → the v1 `mkScopeId` string. Seeded minimal (the empty flake root);
  # completeness is a first-corpus finding (edge-schema.md). Applied on the hoag arm only.
  nonEntityNameMap = {
    "" = "<root>";
  };

  # ── shared: tag a NORMALIZED edge list into the frozen sorted trace ────────────────────────────────
  # `sortKey` is the ARM's own `edgeSortKey` (v1's and gen-edge's render byte-identical strings, but the
  # record SHAPES differ — v1 `synthesize = { forwardId; … }` vs gen-edge `synthesize.spec` — so each arm
  # must render with its own). Sorting mirrors gen-edge `trace`'s total order: the frozen key primary, a
  # canonical-JSON tie-break on the (arm-native) entry secondary, so equal topologies → equal traces.
  tagAndSort =
    { arm, sortKey }:
    normEdges:
    let
      tagged = map (e: {
        __sortKey = sortKey e;
        entry = e;
        inherit arm;
      }) normEdges;
      ord =
        a: b:
        if a.__sortKey != b.__sortKey then
          a.__sortKey < b.__sortKey
        else
          builtins.toJSON a.entry < builtins.toJSON b.entry;
    in
    prelude.sort ord tagged;

  # ══ the v2 (hoag) arm ═════════════════════════════════════════════════════════════════════════════
  # bare id_hash → "<kind>:<name>" over every den-hoag registry entry (F1 normalization source, this arm).
  hoagHashToName =
    den:
    prelude.foldl' (
      acc: kind:
      prelude.foldl' (
        acc': name:
        let
          e = den.registries.${kind}.${name};
        in
        acc' // { ${e.id_hash} = "${kind}:${name}"; }
      ) acc (builtins.attrNames den.registries.${kind})
    ) { } (builtins.attrNames den.registries);

  # An id_hash is exactly 64 lowercase hex (sha256). The entity-detection predicate requires BOTH the
  # shape AND registry membership, so a non-entity opaque string that merely CONTAINS a colon
  # (`system=x86_64-linux`, a flake-output path, …) can never be mis-mapped by a coincidental hex tail:
  # membership is the real guard (id_hashes are globally unique per (kind, name)); the shape is a cheap
  # pre-filter that also short-circuits the registry lookup for the common non-entity case.
  isIdHash = s: builtins.match "[0-9a-f]{64}" s != null;

  # Normalize one rendered scope string (gen-edge `renderName` output) → the cross-arm name:
  #   entity  "<kind>:<idHash>"  → "<kind>:<name>"   (F1 — the tail is a 64-hex id_hash IN the registry)
  #   non-ent  opaque string      → its v1 mkScopeId form (F2) else identity.
  hoagNormName =
    hashToName: rendered:
    let
      tail = lastSegment ":" rendered;
    in
    if isIdHash tail && hashToName ? ${tail} then
      hashToName.${tail}
    else
      nonEntityNameMap.${rendered} or rendered;

  # Rewrite an entity/opaque nameSpec to an opaque `<kind>:<name>` spec (so gen-edge `renderName` yields
  # the normalized name). Already-opaque non-entity specs pass through the name map.
  hoagNormSpec = hashToName: ns: { opaque = hoagNormName hashToName (edgeCore.renderName ns); };

  # Normalize a gen-edge edge record: rewrite the target root + the collected source scope (+ its rendered
  # members, for display parity) to names. rewalk/synthesize/value carry no entity SCOPE in their sort key
  # (aspect/forward ids are their own identity), so they pass through unchanged.
  hoagNormEdge =
    hashToName: e:
    e
    // {
      target =
        if e.target ? root then e.target // { root = hoagNormSpec hashToName e.target.root; } else e.target;
      source =
        if e.source ? collected then
          e.source
          // {
            collected = e.source.collected // {
              scope = hoagNormSpec hashToName e.source.collected.scope;
              members = map (hoagNormName hashToName) (e.source.collected.members or [ ]);
            };
          }
        else
          e.source;
    };

  traceHoag =
    { denCompat }:
    fixture:
    let
      built = denCompat.mkDen [ fixture.module ];
      den = built.den;
      hashToName = hoagHashToName den;
      roots = builtins.attrNames den.scopeRoots;
      rawEdges = prelude.concatMap (r: den.graph.edges r) roots;
      normEdges = map (hoagNormEdge hashToName) rawEdges;
    in
    tagAndSort {
      arm = "hoag";
      sortKey = edgeCore.edgeSortKey;
    } normEdges;

  # ══ the v1 (oracle) arm ═══════════════════════════════════════════════════════════════════════════
  mkV1 =
    {
      denV1Flake,
      denV1Edge,
      nixpkgsLib,
      nixpkgs,
    }:
    let
      lib = nixpkgsLib;

      # Replicate den v1's denTest `evalDen` (denTest.nix): a plain `evalModules` importing the v1
      # flakeModule, with the hand-emulated `withSystem` (self + nixpkgs only, no real flake-parts) and
      # the same test-harness defaults. `inputs.den`/`self` = the v1 flake itself (den v1 declares no
      # inputs — the consumer supplies them; here the harness does). `compute den` runs inside the eval
      # (where the `den` module arg is live) and its result is read back off a captured option.
      withSystem =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        cb:
        cb {
          inputs' = {
            nixpkgs.packages = pkgs;
            nixpkgs.legacyPackages = pkgs;
          };
          self'.packages = pkgs;
          self'.legacyPackages = pkgs;
        };
      inputs = {
        den = denV1Flake;
        self = denV1Flake;
        inherit nixpkgs;
      };
      defaults = {
        den.schema.user.classes = lib.mkDefault [ "homeManager" ];
        den.default.nixos.system.stateVersion = lib.mkDefault "25.11";
        den.default.homeManager.home.stateVersion = lib.mkDefault "25.11";
      };
      runV1 =
        { fixtureModule, compute }:
        let
          evaluated = lib.evalModules {
            specialArgs = { inherit inputs withSystem; };
            modules = [
              denV1Flake.flakeModule
              defaults
              fixtureModule
              { options.__parityOut = lib.mkOption { default = null; }; }
              (
                { den, ... }:
                {
                  config.__parityOut = compute den;
                }
              )
            ];
          };
        in
        evaluated.config.__parityOut;

      # hash → "<kind>:<name>" from a resolve result's scopeContexts (F1 source for this arm) — the
      # `normalizeTrace` construction (edge-trace.nix): every entity record in every scope's ctx, prefixed
      # ("<kind>:<idHash>" → "<kind>:<name>") for S/T scopes and bare ("<idHash>" → "<kind>:<name>") for
      # rewalk aspect ids.
      v1HashMaps =
        r:
        let
          sc = r.scopeContexts or { };
          prefixed = prelude.foldl' (
            acc: sid:
            let
              ctx = sc.${sid} or { };
              entityKeys = builtins.filter (k: builtins.isAttrs (ctx.${k} or null) && (ctx.${k} ? id_hash)) (
                builtins.attrNames ctx
              );
            in
            acc
            // prelude.listToAttrs (
              map (k: prelude.nameValuePair "${k}:${ctx.${k}.id_hash}" "${k}:${ctx.${k}.name or "?"}") entityKeys
            )
          ) { } (builtins.attrNames sc);
          bare = prelude.listToAttrs (
            prelude.mapAttrsToList (k: v: prelude.nameValuePair (lastSegment ":" k) v) prefixed
          );
        in
        {
          inherit prefixed bare;
        };

      # Normalize a v1 edge record (STRING scopes) using a resolve result's maps: target root + collected
      # scope via the prefixed map, rewalk aspect via the bare map. Non-entity strings fall through the
      # v1 side of F2 unchanged (v1 IS the reference mkScopeId naming).
      v1NormEdge =
        maps: e:
        let
          ren = s: maps.prefixed.${s} or s;
          renAspect = s: maps.bare.${s} or (maps.prefixed.${s} or s);
        in
        e
        // {
          target = if e.target ? root then e.target // { root = ren e.target.root; } else e.target;
          source =
            if e.source ? collected then
              e.source
              // {
                collected = e.source.collected // {
                  scope = ren e.source.collected.scope;
                };
              }
            else if e.source ? rewalk then
              e.source
              // {
                rewalk = e.source.rewalk // {
                  aspect = renAspect e.source.rewalk.aspect;
                };
              }
            else
              e.source;
        };

      # Enumerate the roots to trace. `hostRoots` (default true): every host in `den.hosts` at its class.
      # `flakeRoot` (default false): the flake root (spawn/instantiate topologies whose delivery is
      # flake-rooted — and the P7 negative control, a v1-only flake-root fixture). A fixture sets
      # `hostRoots = false; flakeRoot = true;` to trace the flake root ALONE.
      hostRootsOf =
        den:
        prelude.concatMap (
          sys:
          map (hn: {
            kind = "host";
            arg = {
              host = den.hosts.${sys}.${hn};
            };
            class = den.hosts.${sys}.${hn}.class or "nixos";
          }) (builtins.attrNames (den.hosts.${sys} or { }))
        ) (builtins.attrNames (den.hosts or { }));
      rootsOf =
        fixture: den:
        (if (fixture.hostRoots or true) then hostRootsOf den else [ ])
        ++ (
          if (fixture.flakeRoot or false) then
            [
              {
                kind = "flake";
                arg = { };
                class = "flake";
              }
            ]
          else
            [ ]
        );

      # The per-fixture v1 trace, reading `field` (`edgeTrace` production, or `legacyEdgeTrace` control)
      # off each root's resolve result, normalizing + concatenating + sorting.
      v1TraceField =
        field: fixture:
        runV1 {
          fixtureModule = fixture.module;
          compute =
            den:
            let
              roots = rootsOf fixture den;
              perRoot = map (
                root: den.lib.aspects.resolveWithPaths root.class (den.lib.resolveEntity root.kind root.arg)
              ) roots;
              allNorm = prelude.concatMap (r: map (v1NormEdge (v1HashMaps r)) (r.${field} or [ ])) perRoot;
            in
            tagAndSort {
              arm = "v1";
              sortKey = denV1Edge.edgeSortKey;
            } allNorm;
        };
    in
    {
      traceV1 = v1TraceField "edgeTrace";
      traceV1Legacy = v1TraceField "legacyEdgeTrace";
    };
in
{
  inherit
    traceHoag
    mkV1
    nonEntityNameMap
    tagAndSort
    # Exposed for the schema-guard suite: the entity-scope name normalizer (`hashToName -> rendered ->
    # name`) + its 64-hex id_hash predicate, so the mis-map guard is exercised directly (a colon-bearing
    # non-entity name passes through unmapped).
    hoagNormName
    isIdHash
    ;
}
