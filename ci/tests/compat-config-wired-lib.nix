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
  };
}
