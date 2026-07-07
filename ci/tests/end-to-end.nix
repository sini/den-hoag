# Task 11 (A11) — the end-to-end acceptance fleet: the whole four-concern assembly composed through one
# `mkDen` over the full r2 fleet (`_fixtures/fleet.nix` `acceptance`), all 18 laws holding together, and
# `nixosConfigurations` crossing to REAL NixOS systems. This is the integration capstone: every earlier
# suite pins ONE law over a minimal fixture; this one pins them TOGETHER over a fleet that exercises
# aspect radiation, the projects facet, a settings policy slot, two fleet-wide quirk channels, a `link`
# cluster, and a `database` demand cascade — and asserts the mkDen output shape a consumer sees.
#
# It also closes the two A9 stagings and pins the three owner-directive tripwires:
#   • demand-edge folding — the fleet's gen-demand resolution (provider + consumer gen-edge records) joins
#     each root's edge set and materializes into config(root) (providers under `outputs.demands.*`,
#     consumers under `<subjectHash>.wiring`).
#   • the real nixpkgs crossing — `nixosConfigurations.<host>` evaluates its `networking.hostName`.
#   • no-effect-runtime tripwires (a) per-root demand-laziness, (b) inert declarations, (c) fixpoint census.
{
  denHoag,
  nixpkgsLib,
  nixpkgs,
  denHoagSrc,
  ...
}:
let
  lib = nixpkgsLib;
  fx = import ./_fixtures/fleet.nix;
  sort = builtins.sort (a: b: a < b);

  # ── the full acceptance fleet, crossed through real nixpkgs ──────────────────────────────────────
  fleetModules = fx.acceptance { inherit denHoag nixpkgs; };
  result = denHoag.mkDen fleetModules;
  den = result.den;

  # the same fleet with the UNRELATED policy modules permuted (link/demand/configure reordered) — the
  # channel order + trace must be invariant under it (order is pinned by producer identity, never policy
  # declaration order).
  resultPerm = denHoag.mkDen (
    fx.acceptance {
      inherit denHoag nixpkgs;
      permute = true;
    }
  );
  denPerm = resultPerm.den;

  iglooId = "host:igloo";
  web1Id = "host:web-1";
  clusterId = "cluster:k3s";
  tuxIglooCell = "user:tux@host:igloo";
  eval = den.structural.eval;

  keysOf = id: map (n: n.key) (eval.get id "resolved-aspects");
  hasAspectAt = id: k: builtins.elem k (keysOf id);

  # ── settings resolution at the igloo cell (projects facet + host override + policy slot) ─────────
  rs = eval.get tuxIglooCell "resolved-settings";

  # ── quirk gathers ────────────────────────────────────────────────────────────────────────────────
  # ssh-peers gathered fleet-wide AT the cluster: the cluster's `link` imports both hosts, so its neron
  # cone receives each host's ssh-peers contribution — cross-member channel consumption via the link.
  sshAtCluster = sort (
    map (c: builtins.head c.value) ((den.receivedOutputs.at clusterId).ssh-peers.contributions or [ ])
  );
  # http-backends order at igloo (two same-position producers, pinned by producer identity).
  httpOrderAt =
    d:
    map (c: c.producer.aspect.name or null) (
      (d.structural.eval.get iglooId "received-collections").http-backends.contributions or [ ]
    );

  # ── output / trace (demand edges folded in) ──────────────────────────────────────────────────────
  outIgloo = den.output.outputFor iglooId;
  iglooHash = den.registries.host.igloo.id_hash;
  traceIgloo = den.graph.trace iglooId;
  edge = denHoag.internal.edge;

  # ── deferred (config-demanding) channel through the REAL terminal (PR #623 parity) ──────────────────
  # `deferredProbe` emits a `probe` value that reads the PRODUCING class's config and consumes it in its
  # nixos content. The consumer keeps an unbound `config` arg so gen-bind resolves the config-thunk (a
  # fully-bound module skips resolution — gen-bind wrap.nix `allMatched`). Its own den instance (not the
  # base fleet): a deferred channel is an E6 poison thunk in the FOLD — resolvable only at the terminal —
  # so folding it into the base would poison the laziness probe's deepSeq of igloo's OWN output.
  deferredMod =
    { config, ... }:
    {
      config.den.quirks.probe = { };
      config.den.aspects.deferredProbe = {
        probe =
          { config, ... }:
          [ "host-is-${config.networking.hostName}" ];
        nixos =
          { config, probe, ... }:
          {
            networking.domain = builtins.head probe;
          };
      };
      config.den.include = [
        {
          at = config.den.host.igloo;
          aspects = [ config.den.aspects.deferredProbe ];
        }
      ];
    };
  resultDeferred = denHoag.mkDen (fleetModules ++ [ deferredMod ]);

  # provider edges → output-arm sinks (`outputs.demands.<kind>.<key>`); consumer edges → the subject's
  # `wiring` root bucket. Both materialize into config(igloo).
  demandArms = builtins.attrNames (outIgloo.outputs or { });
  dbArm = lib.head (builtins.filter (k: lib.hasPrefix "demands.database." k) demandArms);
  traceHasProviderEdge = builtins.any (
    e: e.target.arm == "output" && builtins.head e.target.output == "demands"
  ) traceIgloo;
  traceHasConsumerEdge = builtins.any (
    e: e.target.arm == "root" && e.target.class == "wiring"
  ) traceIgloo;

  # ── tripwire (a): per-root demand-laziness ───────────────────────────────────────────────────────
  # A sibling root (web-1) whose OWN channel content throws when forced does NOT prevent forcing the
  # other root's (igloo's) output-modules. This is the correct per-root probe for the output path: a
  # PRODUCE-level throw would be forced by every node's channel-presence spine (gen-edge's `universe`
  # scans all bucket-bearing positions), so the load-bearing throw must be a deeply-lazy channel VALUE —
  # siblings' presence is forced, their content values are not. web-1 is an isolated sibling root, so its
  # throwing http-backends value is NOT in igloo's subtree fold; forcing igloo's config succeeds, forcing
  # web-1's config genuinely throws (non-vacuous).
  saboteurMod =
    { config, ... }:
    {
      config.den.aspects.saboteur.http-backends = [ (builtins.throw "web-1 sibling content boom") ];
      config.den.include = [
        {
          at = config.den.host.web-1;
          aspects = [ config.den.aspects.saboteur ];
        }
      ];
    };
  denLazy = (denHoag.mkDen (fleetModules ++ [ saboteurMod ])).den;
  lazyIglooForces =
    (builtins.tryEval (builtins.deepSeq (denLazy.output.outputFor iglooId) true)).success;
  lazyWeb1Throws =
    !(builtins.tryEval (builtins.deepSeq (denLazy.output.outputFor web1Id) true)).success;

  # ── tripwire (b): inert declarations ─────────────────────────────────────────────────────────────
  # Every declaration the fixture's policies construct is DATA: no field is a lambda. (Policy declarations
  # carry no guard slots — guards live on aspects, not on policy declarations — so the check is
  # unconditional here. The entry-typed fields `of`/`subject`/`target` are attrsets, `typeOf` = "set".)
  allNodeIds = builtins.attrNames eval.allNodes;
  strata = [
    "structural"
    "resolution"
    "collection"
    "demand"
  ];
  policyDeclsAt = id: builtins.concatMap (s: (eval.get id "declarations").actions.${s} or [ ]) strata;
  allPolicyDecls = builtins.concatMap policyDeclsAt allNodeIds;
  lambdaFields = builtins.concatMap (
    d: builtins.filter (v: builtins.typeOf v == "lambda") (builtins.attrValues d)
  ) allPolicyDecls;

  # ── tripwire (c): fixpoint census (zero-machinery style) ─────────────────────────────────────────
  # Source scan over EVERY lib file (comment lines stripped, so only call sites count): the ONLY loop
  # primitives in lib/** are the two declared fixpoints — B1 enrichment (`scope.circular` in
  # attributes/structural.nix) and B4 presence (`scope.circular` in attributes/resolved-aspects.nix) —
  # and ZERO `dispatchStep` anywhere (the enrichment accumulator was retired to the re-dispatch form,
  # decision #25). Collections use gen-pipe folds, not a circular. Any NEW `scope.circular` in another
  # file, any extra call in these two, or any `dispatchStep` fails the suite.
  libFiles = [
    "default.nix"
    "errors.nix"
    "entity.nix"
    "fleet.nix"
    "build-roots.nix"
    "scope-adapter.nix"
    "declarations.nix"
    "concern-policies.nix"
    "concern-aspects.nix"
    "concern-quirks.nix"
    "concern-classes.nix"
    "linearization.nix"
    "settings.nix"
    "projects.nix"
    "demand.nix"
    "graph-escape.nix"
    "attributes/default.nix"
    "attributes/structural.nix"
    "attributes/resolved-aspects.nix"
    "attributes/collections.nix"
    "attributes/resolved-settings.nix"
    "attributes/class-modules.nix"
    "attributes/output-modules.nix"
    "output/terminal.nix"
    "output/class-share.nix"
  ];
  read = f: builtins.readFile "${denHoagSrc}/lib/${f}";
  isCommentLine = l: builtins.match "[[:space:]]*#.*" l != null;
  codeOf =
    text:
    lib.concatStringsSep "\n" (builtins.filter (l: !(isCommentLine l)) (lib.splitString "\n" text));
  occurrences = tok: text: builtins.length (lib.splitString tok text) - 1;
  circularPerFile = map (f: {
    file = f;
    n = occurrences "scope.circular" (codeOf (read f));
  }) libFiles;
  circularCallFiles = sort (map (x: x.file) (builtins.filter (x: x.n > 0) circularPerFile));
  totalCircular = lib.foldl' (a: x: a + x.n) 0 circularPerFile;
  totalDispatchStep = lib.foldl' (a: f: a + occurrences "dispatchStep" (codeOf (read f))) 0 libFiles;
in
{
  flake.tests.end-to-end = {
    # ══ mkDen output shape (the consumer-facing acceptance) ═════════════════════════════════════════
    # `mkDen fleetModules` returns exactly { den; graph; nixosConfigurations; }.
    test-mkden-return-shape = {
      expr = sort (builtins.attrNames result);
      expected = [
        "den"
        "graph"
        "nixosConfigurations"
      ];
    };
    # `den.graph.trace` is stable (invariant under the unrelated-policy permutation) and hashable (the
    # trace renders identity only — the demand edges' value sources contribute their key, never content).
    test-graph-trace-stable = {
      expr = traceIgloo == denPerm.graph.trace iglooId;
      expected = true;
    };
    test-graph-trace-hashable = {
      expr = edge.hashTrace (den.graph.edges iglooId) == edge.hashTrace (denPerm.graph.edges iglooId);
      expected = true;
    };
    # non-vacuous: the trace is a real (non-empty) topology.
    test-graph-trace-nonempty = {
      expr = builtins.length traceIgloo >= 1;
      expected = true;
    };

    # ══ r2 §Acceptance scenario checks ══════════════════════════════════════════════════════════════
    # fleet gather terminates structural-only: the sparse product enumerates to exactly the three cells
    # (tux@igloo, admin@igloo, tux@web-1) — cluster is NOT a product axis (a link/root kind).
    test-fleet-gather-terminates = {
      expr = builtins.length den.cells;
      expected = 3;
    };
    test-fleet-cells = {
      expr = sort (map (c: "${c.user.name}@${c.host.name}") den.cells);
      expected = [
        "admin@igloo"
        "tux@igloo"
        "tux@web-1"
      ];
    };
    # provides-to-users registration-scoped delivery: `app` (neededBy user, included at env:prod) radiates
    # to every USER cell under prod — and ONLY to users: it does not deliver to the host roots (the
    # selector is `kind user`), so the delivery is scoped to the provided-to kind within the registration
    # scope, not sprayed over the whole subtree.
    test-registration-scoped-delivery = {
      expr = [
        (hasAspectAt tuxIglooCell "app") # user cell — delivered
        (hasAspectAt "user:tux@host:web-1" "app") # user cell on the other host — delivered
        (hasAspectAt "user:admin@host:igloo" "app") # the second user on igloo — delivered
        (hasAspectAt iglooId "app") # host root — NOT a user, not delivered
      ];
      expected = [
        true
        true
        true
        false
      ];
    };
    # guard-activated neededBy fires: `guardG` activates where `system` is resolved (its guard reads the
    # path set only), and `needT` (neededBy [ guardG ]) then fires — at the hosts, not at env.
    test-guard-activated-neededby-fires = {
      expr = [
        (hasAspectAt iglooId "guardG")
        (hasAspectAt iglooId "needT")
        (hasAspectAt "env:prod" "guardG")
      ];
      expected = [
        true
        true
        false
      ];
    };
    # one instantiate per host via link: the cluster imports BOTH hosts (the link resolved), yet each host
    # instantiates exactly once — `systems.nixos` and `nixosConfigurations` carry one entry per host.
    test-cluster-link-resolves = {
      expr = sort (eval.get clusterId "imports");
      expected = [
        "host:igloo"
        "host:web-1"
      ];
    };
    test-one-instantiate-per-host = {
      expr = sort (builtins.attrNames den.output.systems.nixos);
      expected = [
        "host:igloo"
        "host:web-1"
      ];
    };
    # http-backends order stable under the unrelated-policy permutation (pinned by producer identity).
    test-http-backends-order-stable = {
      expr = httpOrderAt den == httpOrderAt denPerm;
      expected = true;
    };
    # …and it is a REAL two-producer order (non-vacuous), pinned by aspect id_hash, not include/policy order.
    test-http-backends-order-canonical = {
      expr = httpOrderAt den;
      expected = [
        "backendB"
        "backendA"
      ];
    };

    # ══ projects facet + specificity + policy slot (one settings fold) ══════════════════════════════
    # The fleet-root `gruvbox-theme` projects ONE fleet-scope layer (via, at env), a host-scoped direct
    # override wins by specificity (host after env), and the `configure` policy wins the terminal slot —
    # all three visible in one provenance golden at the igloo cell.
    test-settings-provenance-order = {
      expr = map (e: e.value) rs.app.provenance.colorScheme;
      expected = [
        "base" # schema default
        "fleet-gruvbox" # env-slice projection (via gruvbox-theme) — the fleet-root theme, ONE layer
        "igloo-host" # host-slice direct override — wins by specificity over the fleet projection
        "prod-policy" # configure policy — the terminal slot
      ];
    };
    test-settings-policy-wins-terminal = {
      expr = rs.app.value.colorScheme;
      expected = "prod-policy";
    };
    # the projection layer (and ONLY it) carries a `via` = the projecting aspect's identity.
    test-settings-projection-via = {
      expr = map (e: if e.via == null then null else e.via.name) rs.app.provenance.colorScheme;
      expected = [
        null
        "gruvbox-theme"
        null
        null
      ];
    };

    # ══ quirk gathers (fleet-wide) ══════════════════════════════════════════════════════════════════
    # ssh-peers gathered fleet-wide at the cluster (cross-member consumption via the link's imports).
    test-ssh-peers-gathered-at-cluster = {
      expr = sshAtCluster;
      expected = [
        "igloo-ip"
        "web1-ip"
      ];
    };

    # ══ demand-edge folding (A9 staging closed) ═════════════════════════════════════════════════════
    # the demand cascade produces provider + consumer edges that JOIN the fleet edge set (the trace)…
    test-demand-provider-edge-joins-trace = {
      expr = traceHasProviderEdge;
      expected = true;
    };
    test-demand-consumer-edge-joins-trace = {
      expr = traceHasConsumerEdge;
      expected = true;
    };
    # …and MATERIALIZE into config(root): the provider resource under `outputs.demands.database.*`…
    test-demand-provider-materializes = {
      expr = outIgloo.outputs.${dbArm};
      expected = [ { engine = "postgres"; } ];
    };
    # …and the consumer wiring under the subject's `wiring` root bucket.
    test-demand-consumer-materializes = {
      expr = builtins.attrNames (outIgloo.${iglooHash} or { });
      expected = [ "wiring" ];
    };

    # ══ the real nixpkgs crossing ═══════════════════════════════════════════════════════════════════
    # nixosConfigurations.<host> — host-name-keyed REAL NixOS systems that evaluate their hostName.
    test-nixos-configurations-hosts = {
      expr = sort (builtins.attrNames result.nixosConfigurations);
      expected = [
        "igloo"
        "web-1"
      ];
    };
    test-nixos-hostname-igloo = {
      expr = result.nixosConfigurations.igloo.config.networking.hostName;
      expected = "igloo";
    };
    test-nixos-hostname-web1 = {
      expr = result.nixosConfigurations.web-1.config.networking.hostName;
      expected = "web-1";
    };
    # deferred (config-demanding) channel resolution AT the real terminal (PR #623 parity): `deferredProbe`
    # emits `probe = { config, ... }: [ "host-is-${config.networking.hostName}" ]` at igloo and consumes it
    # in its nixos content; through crossNixos the config-thunk resolves against igloo's OWN nixos config,
    # so `networking.domain` carries the resolved hostName. This exercises the deferredToThunk /
    # channelBindingsAt true-branch end to end (not just a bare evalModules), asserting on the BUILT system.
    test-deferred-channel-resolves-at-terminal = {
      expr = resultDeferred.nixosConfigurations.igloo.config.networking.domain;
      expected = "host-is-igloo";
    };

    # ══ no-effect-runtime tripwires (owner directive) ═══════════════════════════════════════════════
    # (a) demand-laziness: forcing igloo's output-modules succeeds despite web-1's throwing sibling
    #     content (per-root laziness), and web-1's own output genuinely throws (the probe is non-vacuous).
    test-laziness-sibling-does-not-block = {
      expr = lazyIglooForces;
      expected = true;
    };
    test-laziness-throwing-sibling-is-real = {
      expr = lazyWeb1Throws;
      expected = true;
    };
    # (b) inert declarations: every field of every policy-constructed declaration is data (no lambdas).
    test-inert-declarations = {
      expr = builtins.length lambdaFields;
      expected = 0;
    };
    # non-vacuous: the fixture's policies did construct declarations (link ×2, demand ×1, configure ×3).
    test-inert-declarations-nonempty = {
      expr = builtins.length allPolicyDecls >= 6;
      expected = true;
    };
    # (c) fixpoint census: exactly the two declared circular fixpoints, zero dispatchStep.
    test-census-circular-files = {
      expr = circularCallFiles;
      expected = [
        "attributes/resolved-aspects.nix"
        "attributes/structural.nix"
      ];
    };
    test-census-circular-count = {
      expr = totalCircular;
      expected = 2;
    };
    test-census-no-dispatchstep = {
      expr = totalDispatchStep;
      expected = 0;
    };
  };
}
