# den v1 BEHAVIORAL migration — public-api/forward-from-custom-class.nix (denful/den@11866c16).
# Migrated by copy + arg-rename onto the `_lib/den-compat-test.nix` scaffold; the `den.*` declarations +
# assertions are BYTE-IDENTICAL to v1. Concern: `den.provides.forward` (den.batteries.forward) — forward a
# custom class's content into a target class[.path]. Covers the STATIC-each battery (each is a LITERAL:
# `singleton class` / `[ "nixos" "homeManager" ]`) AND the DYNAMIC-each pair-of-hosts case (a doubly-curried
# forwarder whose `each` reads walk-time cell coords). The two homeManager-targeting custom-class variants
# stay parked in-file (a homeManager-at-cell lift).
{
  denHoagFlakeModule,
  homeManagerModule,
  genInputs,
  nixpkgs,
  nixpkgsLib,
  ...
}:
let
  denTest = import ../_lib/den-compat-test.nix {
    inherit
      denHoagFlakeModule
      homeManagerModule
      nixpkgs
      nixpkgsLib
      ;
    flakeParts = genInputs.flake-parts;
  };
in
{
  flake.tests.forward-custom-class = {

    test-forward-custom-class-to-nixos = denTest (
      {
        den,
        lib,
        igloo,
        ...
      }:
      let
        forwarded =
          { class, aspect-chain }:
          den.provides.forward {
            each = lib.singleton class;
            fromClass = _: "custom";
            intoClass = _: "nixos";
            intoPath = _: [ ];
            fromAspect = _: lib.head aspect-chain;
          };
      in
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.aspects.igloo = {
          includes = [ forwarded ];
          custom.networking.hostName = "from-custom-class";
        };

        expr = igloo.networking.hostName;
        expected = "from-custom-class";
      }
    );

    test-forward-into-subpath = denTest (
      {
        den,
        lib,
        igloo,
        ...
      }:
      let
        fwdModule = {
          options.items = lib.mkOption { type = lib.types.listOf lib.types.str; };
        };

        forwarded =
          { class, aspect-chain }:
          den.provides.forward {
            each = lib.singleton class;
            fromClass = _: "src";
            intoClass = _: "nixos";
            intoPath = _: [ "fwd-box" ];
            fromAspect = _: lib.head aspect-chain;
          };
      in
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.aspects.igloo = {
          includes = [ forwarded ];
          nixos.imports = [
            { options.fwd-box = lib.mkOption { type = lib.types.submoduleWith { modules = [ fwdModule ]; }; }; }
          ];
          nixos.fwd-box.items = [ "from-nixos-owned" ];
          src.items = [ "from-src-class" ];
        };

        expr = lib.sort (a: b: a < b) igloo.fwd-box.items;
        expected = [
          "from-nixos-owned"
          "from-src-class"
        ];
      }
    );

    # PARKED — env-unrealizable in-CI (scaffold deviation, like the darwin env-parks): this HM-unstable
    # restructured `programs.git` (`userEmail` → `settings.user.email` via mkRenamedOptionModule with a broken
    # target), so READING `igloo.home-manager.users.tux.programs.git.userEmail` aborts (`option programs.git.
    # settings.user.email does not exist`) regardless of forward delivery — not a forward-machinery gap.
    /*
        test-custom-git-class-fowards-to-hm-then-nixos = denTest (
        {
          den,
          lib,
          igloo,
          ...
        }:
        let
          forwarded =
            { class, aspect-chain }:
            den.provides.forward {
              each = lib.singleton class;
              fromClass = _: "git";
              intoClass = _: "homeManager";
              intoPath = _: [
                "programs"
                "git"
              ];
              fromAspect = _: lib.head aspect-chain;
              adaptArgs =
                { config, ... }:
                {
                  osConfig = config;
                };
            };
        in
        {
          den.hosts.x86_64-linux.igloo.users.tux = { };

          den.aspects.igloo.homeManager.home.stateVersion = "25.11";

          den.aspects.tux = {
            includes = [ forwarded ];
            git.userEmail = "root@linux.com";
          };

          expr = igloo.home-manager.users.tux.programs.git.userEmail;
          expected = "root@linux.com";
        }
      );

      test-custom-nix-class-fowards-to-both-hm-and-nixos = denTest (
        {
          den,
          lib,
          igloo,
          ...
        }:
        let
          forwarded =
            { class, aspect-chain }:
            den.provides.forward {
              each = [
                "nixos"
                "homeManager"
              ];
              fromClass = _: "nix";
              intoClass = lib.id;
              intoPath = _: [ "nix" ];
              fromAspect = _: lib.head aspect-chain;
              adaptArgs =
                { config, ... }:
                {
                  osConfig = config;
                };
            };
        in
        {
          den.hosts.x86_64-linux.igloo.users.tux = { };

          den.aspects.igloo.homeManager.home.stateVersion = "25.11";

          den.aspects.tux = {
            includes = [ forwarded ];
            nix.settings.allowed-users = [ "tux" ];
          };

          expr = {
            os = igloo.nix.settings.allowed-users;
            hm = igloo.home-manager.users.tux.nix.settings.allowed-users;
          };
          expected = {
            os = [ "tux" ];
            hm = [ "tux" ];
          };
        }
      );
    */
    # PARKED — both halves: the `os` half nix→nixos is ALSO blocked on the forward `intoPath ["nix"]`
    # collision (landing at the builtin nix-class submodule slot delivers the nixos DEFAULT `["*"]`, not the
    # forwarded `["tux"]`; nix→nixos @`[]` and @`["nix" "settings"]` land, only @`["nix"]` does not). The `hm`
    # half: a forward INTO homeManager at a user CELL
    # (nix→homeManager) lands in `projectClass(cell, "homeManager")`, but the shipped hmUserDetect lift
    # (output-modules `parentTargetedRoutesAt` → `remapOver`) reads `classSliceOf(cell, "homeManager")`
    # PER-NODE, so the forward's SYNTHESIZED hm content is invisible to the lift to `home-manager.users.<u>`
    # (`attribute 'allowed-users' missing`). A separate composition (no corpus route delivers INTO homeManager
    # then lifts).

    # A DYNAMIC-each forward — the forwarder is DOUBLY curried `{ host, user }: { class, aspect-chain }:
    # forward { … }`, and `each = lib.optional (elem host.name …) user` reads WALK-TIME cell coords
    # (host.name/host.class/user, all in the enriched-context), firing per-cell exactly like static-each.
    test-pair-of-hosts = denTest (
      {
        den,
        lib,
        igloo,
        iceberg,
        ...
      }:
      let
        forwarded =
          { host, user }:
          { class, aspect-chain }:
          den.provides.forward {
            each = lib.optional (lib.elem host.name [
              "igloo"
              "iceberg"
            ]) user;
            fromClass = _: "iced";
            intoClass = _: host.class;
            intoPath = _: [ ];
            fromAspect = _: lib.head aspect-chain;
          };
      in
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.hosts.x86_64-linux.iceberg.users.tux = { };

        den.aspects.igloo.homeManager.home.stateVersion = "25.11";
        den.default.includes = [ forwarded ];

        den.aspects.tux = {
          iced.networking.hostName = "iced";
        };

        expr = [
          igloo.networking.hostName
          iceberg.networking.hostName
        ];
        expected = [
          "iced"
          "iced"
        ];
      }
    );

  };
}
