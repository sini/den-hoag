# #71 (the ledger u20 next-link) — the v1 `userType` TWIN on the registry `users` option. v1 types
# host-embedded users `attrsOf (userType config)` (pin 11866c16 entities/host.nix:75-80; the userType
# :145-177 — a non-strict USER kind instance eval + userName/classes/host option defaults +
# `_module.args.{user,host}`), so a bare `host.users.sini = { }` (corpus hosts/{patch,slab}.nix:10)
# carries `classes` — the field home-env's `host-has-user-with-class` (home-env.nix:47) maps over
# `attrValues host.users` (the u20 abort: the shim raw-held users, so `.classes` was missing).
#
# The twin runs as the users option's APPLY (registry.nix baseEntityModule `userInstanceOf`): the
# option TYPE stays `lazyAttrsOf raw`, so the field remains structurally EXCLUDED from the safe stamp
# and rides the #70 lazy raw side channel unchanged; instance evaluation is per-entry, forced only
# when a body reads a user.
#
# Witnesses:
#   (1) a BARE `{ }` user gains v1's instance defaults — name/userName (= the attr key), classes
#       (= `[ "user" ]`, v1 :157-162), host (= the host instance, v1 :169-172);
#   (2) the CORPUS kind-shorthand: a user kind module carrying `classes = mkDefault [ "homeManager" ]`
#       (the #68 belt's emitted shorthand — corpus users.nix:103) BEATS the option default, exactly
#       v1's def-over-default ladder — the value the hm gate reads;
#   (3) an EXPLICIT-fields user is unchanged (authored classes/userName win at def priority);
#   (4) the #70 raw-channel behavior unaffected — `users` stays a RAW-tree leaf (excluded from the
#       safe tree), and the u20 read shape (`any (u: elem c u.classes) (attrValues host.users)`)
#       resolves over the applied registry.
{ denCompat, nixpkgsLib, ... }:
let
  registryLib = denCompat.registry;
  inherit (nixpkgsLib) mkOption types;

  kindModule =
    { ... }:
    {
      options.role = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
    };
  # the corpus user-kind shape: the #68 belt emits the kind's shorthand config as a module def —
  # `den.schema.user.classes = lib.mkDefault [ "homeManager" ]` (corpus users.nix:103).
  userKindShorthand = {
    classes = nixpkgsLib.mkDefault [ "homeManager" ];
  };

  hostDecls.x86_64-linux.h1 = {
    class = "nixos";
    users.tux = { }; # the corpus patch/slab shape (hosts/patch.nix:10 `users.sini = { }`)
    users.amy = {
      classes = [ "custom" ];
      userName = "amy-alt";
    };
  };

  applyWith =
    userKindModule:
    (registryLib.mkHostsOption {
      lib = nixpkgsLib;
      inherit kindModule userKindModule;
    }).apply
      hostDecls;
  plain = (applyWith { }).x86_64-linux.h1;
  corpusShaped = (applyWith userKindShorthand).x86_64-linux.h1;

  instanceOpts = registryLib.hostInstanceOptions {
    lib = nixpkgsLib;
    inherit kindModule;
    userKindModule = userKindShorthand;
  };
in
{
  flake.tests.compat-user-type-twin = {
    # (1) the bare user gains v1's instance defaults.
    test-bare-user-gains-defaults = {
      expr = {
        name = plain.users.tux.name;
        userName = plain.users.tux.userName;
        classes = plain.users.tux.classes;
        hostIsParent = plain.users.tux.host.name == "h1";
      };
      expected = {
        name = "tux";
        userName = "tux";
        classes = [ "user" ];
        hostIsParent = true;
      };
    };

    # (2) the corpus kind-shorthand def beats the option default — the hm gate's value.
    test-kind-shorthand-classes-win = {
      expr = corpusShaped.users.tux.classes;
      expected = [ "homeManager" ];
    };

    # (3) explicit fields unchanged (authored defs win natively).
    test-explicit-user-unchanged = {
      expr = {
        classes = corpusShaped.users.amy.classes;
        userName = corpusShaped.users.amy.userName;
      };
      expected = {
        classes = [ "custom" ];
        userName = "amy-alt";
      };
    };

    # (4) the #70 split unaffected: `users` stays a RAW-tree leaf (safe tree excludes it)…
    test-users-stays-on-raw-channel = {
      expr = {
        raw = (registryLib.rawStampTreeOf instanceOpts).users or null;
        safe = registryLib.stampTreeOf instanceOpts ? users;
      };
      expected = {
        raw = true;
        safe = false;
      };
    };
    # …and the u20 read shape (v1 home-env.nix:47 `host-has-user-with-class`) resolves over the
    # applied registry — the exact read that aborted at host:patch.
    test-u20-read-shape-resolves = {
      expr = builtins.any (u: builtins.elem "homeManager" u.classes) (
        builtins.attrValues corpusShaped.users
      );
      expected = true;
    };
  };
}
