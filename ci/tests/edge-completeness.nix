# Task 9 (A9) — edge materialization + class-modules + the terminal crossing (spec §2.10, Law A15).
# Over an env/host/user fleet where hosts produce the `nixos` class and user cells `home-manager`:
#
#   A15 output completeness — `config(root) = materialize (toposort (edgesFor { graph, root }))` with
#     `project { graph, root, dials }` reproduces the collected channel values EXACTLY (no side
#     channel); the frozen trace E is stable and equal for equal topologies (invariant under
#     order-significant membership permutation).
#   three-branch key dispatch — an aspect content key that is neither a facet, a registered class, nor
#     a quirk channel (a typo) aborts named at `class-modules` (§2.2).
#   one instantiate per host — `systems.<class>` is class-major + content-driven: exactly one terminal
#     instantiation per member carrying that class's content (r2 check 4).
#   deferred resolve-at-producing-class (§27) — a config-reading channel emission from a user-scoped
#     aspect resolves against the home-manager config at the terminal, a host-scoped one against nixos.
{ denHoag, nixpkgsLib, ... }:
let
  I = denHoag.internal;
  edge = I.edge;
  declare = denHoag.declare;

  # ── base fleet ───────────────────────────────────────────────────────────────────────────────────
  schema = {
    config.den.schema = {
      env.parent = null;
      host.parent = "env";
      user.parent = "host";
    };
  };
  instances = {
    config.den = {
      env.prod = { };
      host.axon = { };
      host.blade = { };
      user.alice = { };
    };
  };
  membershipOf =
    order:
    { config, ... }:
    let
      axonEnv = {
        coords = {
          env = config.den.env.prod;
          host = config.den.host.axon;
        };
      };
      bladeEnv = {
        coords = {
          env = config.den.env.prod;
          host = config.den.host.blade;
        };
      };
      aliceAxon = {
        coords = {
          host = config.den.host.axon;
          user = config.den.user.alice;
        };
      };
    in
    {
      config.den.membership =
        if order then
          [
            axonEnv
            bladeEnv
            aliceAxon
          ]
        else
          [
            aliceAxon
            bladeEnv
            axonEnv
          ];
    };
  classing.config.den.contentClass = {
    host = "nixos";
    user = "home-manager";
  };
  quirk.config.den.quirks.ports = { };
  baseOf = order: [
    schema
    instances
    (membershipOf order)
    classing
    quirk
  ];

  axonId = "host:axon";
  bladeId = "host:blade";
  cellId = "user:alice@host:axon";

  # ── A15: quirk-data completeness + trace ───────────────────────────────────────────────────────────
  # one aspect emitting a plain-data channel contribution at host axon.
  dataMod =
    { config, ... }:
    {
      config.den.aspects.p.ports = [
        22
        80
      ];
      config.den.include = [
        {
          at = config.den.host.axon;
          aspects = [ config.den.aspects.p ];
        }
      ];
    };
  denA = (denHoag.mkDen (baseOf true ++ [ dataMod ])).den;
  denARev = (denHoag.mkDen (baseOf false ++ [ dataMod ])).den;

  outAxon = denA.output.outputFor axonId;
  # the direct gen-pipe read of the channel at the same root — what the edge fold must reproduce.
  directAxon = map (c: c.value) ((denA.receivedOutputs.at axonId).ports.contributions or [ ]);

  traceAxon = denA.graph.trace axonId;
  traceAxonRev = denARev.graph.trace axonId;

  # ── three-branch key dispatch (§2.2) ───────────────────────────────────────────────────────────────
  typoMod =
    { config, ... }:
    {
      # `nixxos` is neither a facet, a registered class, nor a quirk channel — a typo.
      config.den.aspects.bad.nixxos = {
        foo = 1;
      };
      config.den.include = [
        {
          at = config.den.host.axon;
          aspects = [ config.den.aspects.bad ];
        }
      ];
    };
  denTypo = (denHoag.mkDen (baseOf true ++ [ typoMod ])).den;

  # ── one instantiate per host (r2 check 4) ──────────────────────────────────────────────────────────
  sysMod =
    { config, ... }:
    {
      config.den.aspects.sys.nixos =
        { config, ... }:
        {
          boot.isContainer = true;
        };
      config.den.include = [
        {
          at = config.den.host.axon;
          aspects = [ config.den.aspects.sys ];
        }
        {
          at = config.den.host.blade;
          aspects = [ config.den.aspects.sys ];
        }
      ];
    };
  denB = (denHoag.mkDen (baseOf true ++ [ sysMod ])).den;
  nixosMembers = builtins.sort (a: b: a < b) (builtins.attrNames denB.output.systems.nixos);

  # ── deferred resolve-at-producing-class (§27) ──────────────────────────────────────────────────────
  # dp emits a config-reading channel contribution AND consumes it in its per-class content. Included at
  # a host (nixos) and a user (home-manager), so each producing scope binds the emission to its class.
  defMod =
    { config, ... }:
    {
      config.den.aspects.dp = {
        ports =
          { config, ... }:
          [ config.marker ];
        nixos =
          { config, ports, ... }:
          {
            result = builtins.head ports;
          };
        home-manager =
          { config, ports, ... }:
          {
            result = builtins.head ports;
          };
      };
      config.den.include = [
        {
          at = config.den.host.axon;
          aspects = [ config.den.aspects.dp ];
        }
        {
          at = config.den.user.alice;
          aspects = [ config.den.aspects.dp ];
        }
      ];
    };
  denC = (denHoag.mkDen (baseOf true ++ [ defMod ])).den;

  # ── inject applied (§2.3 resolution) ───────────────────────────────────────────────────────────────
  # a resolution-phase policy injects a nixos module at the host; class-modules collects it into the
  # nixos bucket alongside any aspect content.
  injectMod =
    { config, ... }:
    {
      config.den.policies.injector =
        { host, ... }:
        [
          (declare.inject {
            class = denHoag.classes.nixos;
            module = {
              boot.tmp.cleanOnBoot = true;
            };
          })
        ];
    };
  denInject = (denHoag.mkDen (baseOf true ++ [ injectMod ])).den;
  injectedNixos = builtins.length (denInject.structural.eval.get axonId "class-modules").nixos;

  # force a member's deferred channel thunk at a terminal that supplies the PRODUCING class's config
  # (nixpkgs evalModules = the same module system gen-flake's terminal crosses into).
  evalMember =
    sys: markerVal:
    (nixpkgsLib.evalModules {
      modules = sys.modules ++ [
        (
          { lib, ... }:
          {
            options.result = lib.mkOption { type = lib.types.raw; };
            options.marker = lib.mkOption {
              type = lib.types.str;
              default = markerVal;
            };
            # gen-bind's split-return `validators` emit `config.warnings` (collision diagnostics); a bare
            # evalModules (not a full NixOS eval) does not declare it, so provide it — the same option the
            # nixpkgs assertions module would.
            options.warnings = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
            };
          }
        )
      ];
    }).config.result;
  nixosResult = evalMember denC.output.systems.nixos.${axonId} "nixos-cfg";
  hmResult = evalMember denC.output.systems.home-manager.${cellId} "hm-cfg";
in
{
  flake.tests.edge-completeness = {
    # ── A15 output completeness ──
    # the edge fold reproduces the collected channel values exactly — no content path outside it.
    test-materialize-equals-direct = {
      expr = outAxon.${axonId}.ports or null;
      expected = directAxon;
    };
    # a leaf root's channel content is non-empty (the aspect emission survives the fold).
    test-materialize-nonempty = {
      expr = outAxon.${axonId}.ports;
      expected = [
        [
          22
          80
        ]
      ];
    };
    # exactly one default-fold merge edge per present channel at the root (the ports channel).
    test-trace-one-edge-per-channel = {
      expr = builtins.length traceAxon;
      expected = 1;
    };
    # the trace is a collected → root merge edge (the corollary-1 default fold).
    test-trace-is-collected-merge = {
      expr =
        let
          e = builtins.head traceAxon;
        in
        {
          inherit (e) mode;
          source = e.source.arm;
          target = e.target.arm;
        };
      expected = {
        mode = "merge";
        source = "collected";
        target = "root";
      };
    };
    # equal topology ⇒ byte-equal trace: permuting the order-significant membership list changes nothing.
    # (Equality alone would pass vacuously on two empty traces — non-emptiness is established by
    # test-trace-one-edge-per-channel, so this pair together pins stability of a REAL trace.)
    test-trace-stable-under-permutation = {
      expr = traceAxon == traceAxonRev;
      expected = true;
    };
    test-trace-hash-stable-under-permutation = {
      expr = edge.hashTrace (denA.graph.edges axonId) == edge.hashTrace (denARev.graph.edges axonId);
      expected = true;
    };

    # ── three-branch key dispatch (§2.2) ──
    # an unregistered aspect content key (a typo) aborts named at class-modules.
    test-unregistered-key-aborts = {
      expr =
        (builtins.tryEval (builtins.deepSeq (builtins.attrNames denTypo.output.systems.nixos) true))
        .success;
      expected = false;
    };

    # ── one instantiate per host (r2 check 4) ──
    # systems.nixos is class-major + content-driven: one member per host carrying nixos content.
    test-one-instantiate-per-host = {
      expr = nixosMembers;
      expected = [
        axonId
        bladeId
      ];
    };
    # a class with no member content produces no instantiations (home-manager here).
    test-empty-class-no-instantiate = {
      expr = builtins.attrNames denB.output.systems.home-manager;
      expected = [ ];
    };
    # the crossing is the terminal (den-hoag's nixpkgs-free default `collect` here).
    test-terminal-crosses = {
      expr = denB.output.systems.nixos.${axonId}.__terminal;
      expected = "collect";
    };

    # ── inject applied (§2.3) ──
    # a resolution-phase `inject` lands in the class bucket at class-modules.
    test-inject-applied = {
      expr = injectedNixos;
      expected = 1;
    };

    # ── deferred resolve-at-producing-class (§27) ──
    # a host-scoped config-reading emission resolves against the nixos config at the terminal…
    test-deferred-host-resolves-nixos = {
      expr = nixosResult;
      expected = "nixos-cfg";
    };
    # …and a user-scoped one against the home-manager config.
    test-deferred-user-resolves-homemanager = {
      expr = hmResult;
      expected = "hm-cfg";
    };
  };
}
