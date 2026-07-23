# CONFIG-WIRED den.lib.* witness (#49 sub-rung B) — the four surfaces (`nh`, `policyInspect`, `__findFile`,
# `schemaUtil`) that v1 loads `{ lib, den }:` / `{ lib, config }:` reading the FLEET config, so they cannot
# live on the config-less migrationLib and are bound at the bridge seam (lib/compat/bridge.nix `configWiredLib`
# → `config._module.args.den.lib`). Corpus-unreferenced (API-completeness rows, not drvPath rows), so the
# witness is a STRICT flake-parts bridge eval over a SYNTHETIC fleet, reading the applied surface off the
# `den` module arg — the migrationLib-direct test cannot reach these (they need `config.den`).
#
# NIT-1: `bridge` is threaded ALONE (no builtinsModule) so no builtin flake-system schema kinds pollute the
# schemaUtil kind list; the fixture schema kinds are declared parent-less (all roots), topologically valid.
{
  lib,
  denCompat,
  denHoag,
  denHoagSrc,
  nixpkgs,
  ...
}:
let
  # Reconstruct the bridge with the SAME deps flake.nix threads (mirrors compat-bridge.nix).
  mkCrossNixos =
    npkgs:
    (import "${denHoagSrc}/lib/output/terminal.nix" {
      inherit (denHoag.internal) bind flake;
    } { nixpkgs = npkgs; }).crossNixos;
  bridge = import "${denHoagSrc}/lib/compat/bridge.nix" {
    compat = denCompat;
    inherit mkCrossNixos;
    schema = denHoag.internal.schema;
    denLib = denHoag;
  };

  flakeStub = {
    options.flake = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.raw;
      default = { };
    };
  };
  # The APPLIED config-wired lib surface off the `den` module arg — read exactly as a corpus module does
  # (`{ den, ... }: den.lib.*`), stashed through the stub `flake` option so the witness reaches it.
  denLibOf =
    extra:
    (lib.evalModules {
      modules = [
        flakeStub
        bridge
        extra
        ({ den, ... }: { flake.__denLib = den.lib; })
      ];
    }).config.flake.__denLib;

  # ── schemaUtil fixture: parent-less kinds (all roots), a couple entity + the non-entity `conf`/`aspect`. ──
  schemaLib = denLibOf {
    den.schema = {
      host.isEntity = true;
      cluster.isEntity = true;
      conf.isEntity = false;
      aspect.isEntity = false;
    };
  };

  # ── nh fixture: a synthetic 2-level hosts registry (system → name); each host materializes name/class/
  #    intoAttr (nixos ⇒ ["nixosConfigurations" name]). Stub `pkgs` keeps the witness nixpkgs-free — the
  #    writeShellApplication builder is read only for `.name`, so the `text`/`intoAttr` thunks stay lazy. ──
  nhLib = denLibOf {
    den.hosts.x86_64-linux = {
      igloo = { };
      hut = { };
    };
  };
  fakePkgs = {
    writeShellApplication = a: { inherit (a) name; };
    mkShell = a: a;
    nh = null;
  };

  # ── policyInspect fixture: a resolve policy `{ host, ... }: [ resolve → user ]` over a schema with host +
  #    user entity kinds; inspect drives the shipped resolveArgsSatisfied (canTake.atLeast) AND the new
  #    schemaUtil (the targetKey findFirst reads schemaEntityKinds). ──
  policyLib = denLibOf {
    den.schema = {
      host.isEntity = true;
      user.isEntity = true;
    };
    den.policies.env-to-host =
      { host, ... }:
      [
        {
          __policyEffect = "resolve";
          value = {
            user = { };
          };
        }
      ];
  };
  policyReport = policyLib.policyInspect.inspect {
    kind = "host";
    context = {
      host = { };
    };
  };

  # ── __findFile fixture: a synthetic aspect + the ful-absent ceiling (throws "Aspect not found"). ──
  findLib = denLibOf {
    den.aspects.myaspect = {
      name = "myaspect";
      foo = 42;
    };
  };
  fulLookup = builtins.tryEval (findLib.__findFile null "ful.x");

  # ── resolve-verbs fixture (#49 sub-rung C): a PLAIN hosts-only fleet (NO custom kinds ⇒ the field-less host
  #    stamp is empty ⇒ the bridge's shared `built.den` == an INDEPENDENT `denCompat.mkDen [fixture].den`
  #    byte-identical). The adapter (lib/compat/resolve-verbs.nix, off the `den` module arg) reads the SAME
  #    native `outputFor`/`traceFor` the DIRECT `mkDen` read does — so the comparison is a NON-TAUTOLOGY
  #    (adapter-through-bridge vs direct native), mirroring the oracle's hoag arm (oracle.nix:439-458). ──
  resolveFixture = {
    den.hosts.x86_64-linux.iceberg = { };
  };
  resolveLib = denLibOf resolveFixture;
  # INDEPENDENT direct native read (the oracle's `hoagBuilt`, oracle.nix:439-442) — NOT the bridge path.
  nativeDen = (denCompat.mkDen [ resolveFixture ]).den;
  rootId = "host:iceberg";
  rootClass = "nixos";
  # v1's seed shape `{ ${kind} = <entity record>; }`; the adapter reads only `record.name` → the node id.
  resolveHandle = resolveLib.resolveEntity "host" {
    host = {
      name = "iceberg";
    };
  };
  nativeImports = (nativeDen.output.outputFor rootId).${rootId}.${rootClass} or [ ];

  # ── hasAspect accessors (#49 Option B): the config-wired collectPathSet/hasAspectIn/mkEntityHasAspect over
  #    the built den's native `reach`, + the PURE mkProjectedHasAspect. Fixture = R5 self-named-aspect
  #    (witness-map R5): a top-level aspect NAMED after the host auto-includes at that host (legacy/
  #    self-provide.nix), so its key MUST deliver into the host's reach closure. The POSITIVE is asserted
  #    from the DECLARATION (`aspects.igloo` → key "igloo"), NOT pulled from `reach` (non-tautology, R5). ──
  hasAspectFixture = {
    den.hosts.x86_64-linux.igloo.users.tux = { };
    den.aspects.igloo.nixos.networking.hostName = "igloo";
  };
  hasAspectLib = denLibOf hasAspectFixture;
  hasHandle = hasAspectLib.resolveEntity "host" {
    host = {
      name = "igloo";
    };
  };
  hasPathSet = hasAspectLib.aspects.collectPathSet hasHandle;
  hasEntity = hasAspectLib.aspects.mkEntityHasAspect hasHandle;
  # The self-named node in the augmented `.aspects` list (identityKey = the gen-aspects.key "igloo").
  iglooNode = builtins.head (builtins.filter (n: n.identityKey == "igloo") hasEntity.aspects);
  hasRef = {
    key = "igloo";
  };

  # PURE mkProjectedHasAspect (migrationLib, config-less): a lookup over a caller-supplied pathSet bucket.
  proj = denCompat.mkProjectedHasAspect {
    pathSetByScope = {
      h = {
        "core/network/manager" = true;
      };
    };
    key = "h";
  };
  projKeyless = builtins.tryEval (proj { });
in
{
  flake.tests.compat-config-wired-lib = {
    # schemaUtil: the kind-registry map (attrNames minus `_`-prefixed) + per-kind isEntity. conf excluded,
    # non-entity (aspect) excluded; schemaArgKinds drops conf+aspect; the set indexes entity kinds.
    test-schema-entity-kinds = {
      expr = schemaLib.schemaUtil.schemaEntityKinds;
      expected = [
        "cluster"
        "host"
      ];
    };
    test-schema-arg-kinds = {
      expr = schemaLib.schemaUtil.schemaArgKinds;
      expected = [
        "cluster"
        "host"
      ];
    };
    test-schema-entity-kinds-set = {
      expr = {
        host = schemaLib.schemaUtil.schemaEntityKindsSet.host or false;
        conf = schemaLib.schemaUtil.schemaEntityKindsSet.conf or false;
      };
      expected = {
        host = true;
        conf = false;
      };
    };

    # nh.denPackages: host-keyed app set over the 2-level registry; den.homes absent → homeApps == [] (the
    # ceiling); denApps flattens to the two hosts.
    test-nh-denpackages-host-keyed = {
      expr = builtins.attrNames (nhLib.nh.denPackages { } fakePkgs);
      expected = [
        "hut"
        "igloo"
      ];
    };
    test-nh-homes-empty-ceiling = {
      expr = nhLib.nh.homeApps { } fakePkgs;
      expected = [ ];
    };
    test-nh-denapps-count = {
      expr = builtins.length (nhLib.nh.denApps { } fakePkgs);
      expected = 2;
    };

    # policyInspect.inspect: the resolve policy matches (resolveArgsSatisfied) and its report routes host→user
    # (targetKey via schemaUtil's schemaEntityKinds), routing = "child".
    test-policy-inspect-report = {
      expr = policyReport.env-to-host or "<no-match>";
      expected = {
        targetKey = "user";
        targets = [ { user = { }; } ];
        from = "host";
        to = "user";
        as = "";
        routing = "child";
      };
    };

    # __findFile: bracket resolution of a synthetic aspect (whole aspect + a sub-key), and the ful-absent
    # ceiling — a `<ful/…>` lookup falls to the else-throw exactly as v1 with an empty `ful`.
    test-findfile-aspect = {
      expr = findLib.__findFile null "myaspect";
      expected = {
        name = "myaspect";
        foo = 42;
      };
    };
    test-findfile-subkey = {
      expr = findLib.__findFile null "myaspect.foo";
      expected = 42;
    };
    test-findfile-ful-ceiling-throws = {
      expr = fulLookup.success;
      expected = false;
    };

    # ── resolve verbs (#49 sub-rung C): the config-wired adapter over the built den's native output. ──
    # resolveEntity → the node HANDLE (readable coord path "${kind}:${name}", the outputFor/traceFor key).
    test-resolve-entity-handle = {
      expr = resolveHandle.__denNode;
      expected = "host:iceberg";
    };
    # resolve class handle → `{ imports }` == the INDEPENDENT direct-native `outputFor.<id>.<class>` read
    # (oracle.nix:442 twin). Bare host ⇒ [] both sides; the equality confirms the adapter reads the same fold.
    test-resolve-imports-match-native = {
      expr = (resolveLib.aspects.resolve rootClass resolveHandle).imports == nativeImports;
      expected = true;
    };
    # resolveWithPaths.edgeTrace == the INDEPENDENT direct-native `traceFor` — the STRONG non-tautology: the
    # trace is hashable/comparable by design (output-modules.nix:871) and oracle-proven `hoag traceFor == v1
    # edgeTrace`. Equality here pins the bridge's shared `built.den` == direct `mkDen [fixture].den`.
    test-resolve-with-paths-trace-match-native = {
      expr =
        (resolveLib.aspects.resolveWithPaths rootClass resolveHandle).edgeTrace
        == nativeDen.output.traceFor rootId;
      expected = true;
    };
    # resolveWithPaths.pathSetByScope — the native `reach` closure keyed by id (v1 projected-hasAspect
    # `{ scopeId → { pathKey → true } }`); a bare host reaches the `defaults` aspect alone.
    test-resolve-with-paths-pathset = {
      expr = (resolveLib.aspects.resolveWithPaths rootClass resolveHandle).pathSetByScope;
      expected = {
        "host:iceberg" = {
          defaults = true;
        };
      };
    };
    # resolveImports (phases 1-3; den-hoag collapses phase4 natively) == resolve's imports.
    test-resolve-imports-verb-equals-resolve = {
      expr =
        (resolveLib.aspects.resolveImports rootClass resolveHandle).imports
        == (resolveLib.aspects.resolve rootClass resolveHandle).imports;
      expected = true;
    };

    # ── hasAspect accessors (#49 Option B) ────────────────────────────────────────────────────────────
    # PURE mkProjectedHasAspect (migrationLib): membership TRUE for the present key, FALSE for an absent one
    # (the negative → non-tautological), + a keyless ref aborts NAMED (refKey throw, never a silent false).
    test-projected-hasaspect-pure = {
      expr = {
        present = proj { key = "core/network/manager"; };
        absent = proj { key = "not/delivered"; };
        keylessThrows = projKeyless.success;
      };
      expected = {
        present = true;
        absent = false;
        keylessThrows = false;
      };
    };
    # collectPathSet: the flat membership set from the host's native reach. The self-named `igloo` aspect
    # (R5 declaration) delivers ⇒ its key is present; an undeclared key is absent (the negative).
    test-collect-pathset-membership = {
      expr = {
        selfNamed = hasPathSet ? "igloo";
        absent = hasPathSet ? "not/delivered";
      };
      expected = {
        selfNamed = true;
        absent = false;
      };
    };
    # hasAspectIn handle ref → the same membership via a ref (native `.key`): the declared self-named aspect
    # is delivered; an absent-key ref is false.
    test-has-aspect-in = {
      expr = {
        delivered = hasAspectLib.aspects.hasAspectIn hasHandle { key = "igloo"; };
        absent = hasAspectLib.aspects.hasAspectIn hasHandle { key = "not/delivered"; };
      };
      expected = {
        delivered = true;
        absent = false;
      };
    };
    # mkEntityHasAspect: `.aspects` is the AUGMENTED resolved-aspects node list (non-empty, every node carries
    # `.identity`/`.identityKey`/`.isNamed`), and the self-named node's identity accessors are grounded.
    test-entity-hasaspect-augmented = {
      expr = {
        nonEmpty = hasEntity.aspects != [ ];
        allAugmented = builtins.all (
          n: (n ? identity) && (n ? identityKey) && (n ? isNamed)
        ) hasEntity.aspects;
        iglooIdentity = iglooNode.identity;
        iglooIsNamed = iglooNode.isNamed;
      };
      expected = {
        nonEmpty = true;
        allAugmented = true;
        iglooIdentity = "igloo";
        iglooIsNamed = true;
      };
    };
    # mkEntityHasAspect membership arms COLLAPSE to class-invariant (v1 unified model): `__functor`, `forClass`
    # <any>, and `forAnyClass` all agree over the same `check` — the delivered self-named aspect reads true on
    # all three (faithfulness of the collapse).
    test-entity-hasaspect-collapse = {
      expr = {
        functor = hasEntity hasRef;
        forClass = hasEntity.forClass "nixos" hasRef;
        forAnyClass = hasEntity.forAnyClass hasRef;
      };
      expected = {
        functor = true;
        forClass = true;
        forAnyClass = true;
      };
    };
  };
}
