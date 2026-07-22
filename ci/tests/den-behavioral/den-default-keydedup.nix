# den.default cross-scope KEY-DEDUP regression witness. den v1 dual-wires `den.default` into the host AND
# user schema (modules/aspects/defaults.nix), then KEY-DEDUPS the shared class modules across scopes
# (wrapPerScope `dedupByKey (m: m.key or null)`, resolve.nix:43-66 @ pin 11866c16). den-hoag fans the
# desugared `defaults` aspect to host+user includes (legacy/defaults.nix `wireSchemaInclude`) but resolves
# it at BOTH the host scope and its user cell with NO cross-scope dedup, so a `den.default` class module
# lands TWICE in the host's assembly. A `types.str` equal-merge hides an identical scalar; it manifests on a
# byte-identical double that is NOT equal-mergeable — a UNIQUE option (double def throws) and a mergeable
# LIST (silent doubling `[ "server" "server" ]`).
#
# The double requires the user to be a CELL under the host (its content folds up the containment subtree),
# so the fleet declares `den.schema.user.parent = "host"` explicitly (a root user would not fold into the
# host's assembly and no double would arise).
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
  flake.tests.den-default-keydedup = {

    # (A) DOUBLE OPTION-DECLARATION — the headline crash. `den.default` carries a module that DECLARES an
    #     option; folded at the host + its tux cell it declares the option TWICE ⇒ "The option `tags' … is
    #     already declared" abort pre-fix (a throw = test failure = RED). The fix folds it once ⇒ the single
    #     declaration + definition resolve ⇒ `[ "server" ]`.
    test-double-declaration-collapses = denTest (
      {
        den,
        lib,
        igloo,
        ...
      }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.schema.user.parent = "host";

        den.default.nixos.imports = [
          {
            options.tags = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
            };
          }
        ];
        den.default.nixos.tags = [ "server" ];

        expr = igloo.tags;
        expected = [ "server" ];
      }
    );

    # (C-isolated) SILENT list-double, no option-decl crash. The list option is DECLARED once (a host-only
    #     include, not fanned to the cell) and DEFINED by `den.default` (fanned to host + cell). Pre-fix the
    #     definition folds twice ⇒ `[ "server" "server" ]` with NO abort (the pure silent divergence); the
    #     fix ⇒ `[ "server" ]`.
    test-list-double-silent = denTest (
      {
        den,
        lib,
        igloo,
        ...
      }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.schema.user.parent = "host";

        den.aspects.decl.nixos.options.den-kd-silent = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };
        den.schema.host.includes = [ den.aspects.decl ];

        den.default.includes = [ den.aspects.dd ];
        den.aspects.dd.nixos.den-kd-silent = [ "server" ];

        expr = igloo.den-kd-silent;
        expected = [ "server" ];
      }
    );

    # (C) MERGEABLE LIST — the silent latent double. `den.default`'s aspect emits a list-option value; the
    #     host folds it once (own) + once (the tux cell's copy) ⇒ `[ "server" "server" ]` pre-fix. The fix
    #     dedups the byte-identical copy ⇒ `[ "server" ]`.
    test-list-not-doubled = denTest (
      {
        den,
        lib,
        igloo,
        ...
      }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.schema.user.parent = "host";

        den.default.includes = [ den.aspects.dd ];
        den.aspects.dd.nixos = {
          options.den-keydedup-list = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
          };
          config.den-keydedup-list = [ "server" ];
        };

        expr = igloo.den-keydedup-list;
        expected = [ "server" ];
      }
    );

    # (B) UNIQUE option — the crash. `types.uniq` throws "defined multiple times, expected unique" on a
    #     DOUBLE def even when byte-identical. Pre-fix the host's fold defines it twice ⇒ forcing it throws
    #     (RED — a throw is a test failure); the fix folds it once ⇒ the single def resolves (GREEN).
    test-unique-option-survives = denTest (
      {
        den,
        lib,
        igloo,
        ...
      }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.schema.user.parent = "host";

        den.default.includes = [ den.aspects.dd ];
        den.aspects.dd.nixos = {
          options.den-keydedup-uniq = lib.mkOption {
            type = lib.types.uniq lib.types.str;
            default = "unset";
          };
          config.den-keydedup-uniq = "once";
        };

        expr = igloo.den-keydedup-uniq;
        expected = "once";
      }
    );

  };
}
