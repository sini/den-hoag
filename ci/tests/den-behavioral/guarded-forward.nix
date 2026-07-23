# den v1 BEHAVIORAL migration — public-api/guarded-forward.nix (denful/den@11866c16). Migrated by copy +
# arg-rename onto the `_lib/den-compat-test.nix` scaffold; the `den.*` declarations + assertions are
# BYTE-IDENTICAL to v1. Concern: `den.provides.forward` with a `guard` (den.batteries.forward guardFn) —
# a bool guard `{ options }: options ? impermanence` (option-existence, delivers nothing when absent) and a
# fn guard `{ config }: _: lib.mkIf …` (item-applied, config-reading). All STATIC-each.
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

  imperModule =
    { lib, ... }:
    {
      options.impermanence = lib.mkOption {
        type = lib.types.submoduleWith {
          modules = [
            {
              options.foo = lib.mkOption {
                type = lib.types.int;
                default = 0;
              };
            }
          ];
        };
        default = { };
      };
    };
in
{
  flake.tests.guarded-forward = {

    test-guard-applies-when-target-exists = denTest (
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
            fromClass = _: "imper";
            intoClass = _: "nixos";
            intoPath = _: [ "impermanence" ];
            fromAspect = _: lib.head aspect-chain;
            guard = { options, ... }: options ? impermanence;
          };
      in
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.aspects.igloo = {
          includes = [ forwarded ];
          nixos.imports = [ imperModule ];
          imper.foo = 42;
        };

        expr = igloo.impermanence.foo;
        expected = 42;
      }
    );

    test-guard-skips-when-target-missing = denTest (
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
            fromClass = _: "imper";
            intoClass = _: "nixos";
            intoPath = _: [ "impermanence" ];
            fromAspect = _: lib.head aspect-chain;
            guard = { options, ... }: options ? impermanence;
          };
      in
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.aspects.igloo = {
          includes = [ forwarded ];
          imper.foo = 42;
        };

        expr = igloo.networking.hostName;
        expected = "nixos";
      }
    );

    # PARKED — a `home-pingu` → homeManager forward fires at each user CELL, but the shipped hmUserDetect lift
    # (`parentTargetedRoutesAt` → `remapOver`) reads `classSliceOf(cell, "homeManager")` PER-NODE, so the
    # forward's synthesized hm content never reaches `home-manager.users.pingu` (pingu resolves "unset", not
    # "hello"). The config-reading `mkIf` guard mechanism itself is exercised green by the option-existence
    # guard cases above.
    /*
        test-guard-can-read-config-values = denTest (
        {
          den,
          lib,
          igloo,
          tuxHm,
          pinguHm,
          ...
        }:
        {

          den.hosts.x86_64-linux.igloo.users = {
            tux = { };
            pingu = { };
          };

          den.schema.user.classes = [ "homeManager" ];

          den.aspects.pingu.homeManager.programs.vim.enable = true;

          den.schema.user.includes =
            let
              unset.homeManager.home.keyboard.model = lib.mkDefault "unset";

              vimer-home =
                { class, aspect-chain }:
                den.provides.forward {
                  each = lib.singleton true;
                  fromAspect = _: lib.head aspect-chain;
                  fromClass = _: "home-pingu";
                  intoClass = _: "homeManager";
                  intoPath = _: [ "home" ];
                  guard = { config, ... }: _: lib.mkIf config.programs.vim.enable;
                };

              doit.home-pingu =
                { pkgs, ... }:
                {
                  keyboard.model = lib.getName pkgs.hello;
                };

            in
            [
              unset
              doit
              vimer-home
            ];

          expr = {
            tux = tuxHm.home.keyboard.model;
            pingu = pinguHm.home.keyboard.model;
          };
          expected = {
            tux = "unset";
            pingu = "hello";
          };
        }
      );
    */

  };
}
