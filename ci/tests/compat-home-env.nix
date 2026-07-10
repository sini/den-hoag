# den.lib.home-env + inline-aspect hoisting (ship-gate lib-surface rung). Two coupled mechanisms:
#
#   (1) den.lib.home-env — v1's OS-user home battery builder (nix/lib/home-env.nix), reproduced
#       compat-side (lib/compat/home-env.nix), {makeHomeEnv, mkDetectHost, mkIntoClassUsers}. The corpus
#       (modules/den/batteries/nix-on-droid.nix:61) calls makeHomeEnv and includes its `.battery` /
#       `.userDetect` in `den.schema.{host,user}.includes`.
#   (2) inline-aspect hoisting (compile.nix kindIncludePolicies) — the battery is an INLINE aspect
#       `{ policies; includes }`; the shim HOISTS its `.includes` (the `{ __isPolicy; fn }` record) into
#       the kind-include ref list (→ compilePolicy → concern-policies per-declaration expansion, the
#       8e2f8c8 machinery) and DROPS its `.policies` as a verified duplicate, with two loud guards.
#
# These pin the MECHANISM at the unit level; the corpus re-probe validates the end-to-end. The design
# rested on two empirical facts, both witnessed below: mkDetectHost's `isEnabled` short-circuits `&&`
# before the bare `host.class` (so the value-less probe never hard-fails), and the drop-.policies is a
# name-verified duplicate of the hoisted includes record (so v1's one-firing is preserved, not doubled).
{ denCompat, denHoag, ... }:
let
  he = denHoag."home-env";

  mk =
    schemaIncludes:
    he.makeHomeEnv {
      className = "homeManager";
      ctxName = "droidHm";
      supportedOses = [ "droid" ];
      optionPath = "nixOnDroidHome";
      getModule = { ... }: { };
      forwardPathFn = _: [
        "home-manager"
        "config"
      ];
      inherit schemaIncludes;
    };

  # Corpus-shape compile: battery in host.includes, userDetect in user.includes (both inline aspects).
  compiledWith =
    dh:
    denCompat.compile {
      schema.host.includes = [ dh.battery ];
      schema.user.includes = [ dh.userDetect ];
      hosts.h1 = {
        class = "nixos";
      };
    };

  # A resolved nixos host node (carries class + users, no nixOnDroidHome option) and a droid host node
  # with a homeManager user + the option enabled (the gate should OPEN there).
  nixosHost = {
    id_hash = "h";
    name = "h1";
    class = "nixos";
    users = { };
  };
  droidHost = {
    id_hash = "d";
    name = "slab";
    class = "droid";
    users.me = {
      classes = [ "homeManager" ];
    };
    nixOnDroidHome.enable = true;
  };

  c = compiledWith (mk [ ]);
  hostPolNames = builtins.filter (n: builtins.match "__kindInclude__host__policy__.*" n != null) (
    builtins.attrNames c.policies
  );
  hostPol = c.policies.${builtins.head hostPolNames};

  # Force a policy body at a host ctx: a compiled record `{ __condition; fn }`.
  forceThrows = e: !(builtins.tryEval (builtins.deepSeq e null)).success;
in
{
  flake.tests.compat-home-env = {
    # ── (1) the three v1 exports are present (surface totality). ──────────────────────────────────────
    test-three-exports = {
      expr = {
        makeHomeEnv = he ? makeHomeEnv;
        mkDetectHost = he ? mkDetectHost;
        mkIntoClassUsers = he ? mkIntoClassUsers;
      };
      expected = {
        makeHomeEnv = true;
        mkDetectHost = true;
        mkIntoClassUsers = true;
      };
    };

    # ── (2) HOIST: the inline battery compiles to a policy-ref sub-rule (NOT the identityLaw abort the
    #    outer `{ policies; includes }` attrset would hit as an aspect ref). ──────────────────────────────
    test-battery-hoisted-to-policy-ref = {
      expr = builtins.elem "__kindInclude__host__policy__0" (builtins.attrNames c.policies);
      expected = true;
    };

    # ── (3) NO DOUBLE-FIRE: exactly ONE host policy — the `.includes` record is hoisted, the same-named
    #    `.policies` entry is DROPPED (verified duplicate), so the policyFn fires once (v1's one-firing). ──
    test-no-double-fire = {
      expr = builtins.length hostPolNames;
      expected = 1;
    };

    # ── (4) NIXOS INERT: the hoisted policy fires at a real nixos host and produces ZERO declarations
    #    (supportedOses = [droid]; the gate is closed). No hard-fail — the probe-safety holds at a real node. ─
    test-nixos-battery-inert = {
      expr = builtins.length (hostPol.fn { host = nixosHost; });
      expected = 0;
    };

    # ── (5) DROID GATE OPENS → NAMED STUB: at a droid host with a homeManager user + the option enabled,
    #    the policyFn takes the droid path (resolve.withIncludes / batteries.forward) and reaches the
    #    #49/#50 named stubs — self-announcing (throws), never a silent no-op. ────────────────────────────
    test-droid-gate-opens-to-stub = {
      expr = forceThrows (hostPol.fn { host = droidHost; });
      expected = true;
    };

    # ── (6) FINDING-1 SENTINEL PROOF: the battery's policyFn at the EXACT concern-policies value-less
    #    sentinel `{ id_hash; name }` (no class/users/option) yields `[ ]` — `isEnabled` short-circuits `&&`
    #    before the bare `host.class`, so the reproduction is byte-faithful (no `or null` deviation). ──────
    test-finding1-sentinel-no-hard-fail = {
      expr =
        let
          r = builtins.tryEval (
            (mk [ ]).battery.policies."host-to-droidHm-users" {
              host = {
                id_hash = "«probe»";
                name = "«probe»";
              };
            }
          );
        in
        {
          ok = r.success;
          empty = r.success && r.value == [ ];
        };
      expected = {
        ok = true;
        empty = true;
      };
    };

    # ── (7) hm-host FORWARDING pair: makeHomeEnv threads `schemaIncludes` (the corpus forwards
    #    `config.den.schema.hm-host.includes or [ ]`) into the droid path; on class-A it stays inert whether
    #    the forwarded set is EMPTY (corpus shape) or NONEMPTY (synthetic) — no double-provision on nixos. ──
    test-hmhost-forward-empty-inert = {
      expr = builtins.length (hostPol.fn { host = nixosHost; });
      expected = 0;
    };
    test-hmhost-forward-nonempty-inert = {
      expr =
        let
          cNon = compiledWith (mk [ { name = "someHmHostAspect"; } ]);
          p =
            cNon.policies.${
              builtins.head (
                builtins.filter (n: builtins.match "__kindInclude__host__policy__.*" n != null) (
                  builtins.attrNames cNon.policies
                )
              )
            };
        in
        builtins.length (p.fn { host = nixosHost; });
      expected = 0;
    };

    # ── (8) the OTHER two exports fire correctly: mkDetectHost inert at nixos (short-circuit), and
    #    mkIntoClassUsers pairs each homeManager user on a host. ─────────────────────────────────────────
    test-mkDetectHost-nixos-false = {
      expr = he.mkDetectHost {
        className = "homeManager";
        supportedOses = [ "droid" ];
        optionPath = "nixOnDroidHome";
      } { host = nixosHost; };
      expected = false;
    };
    test-mkIntoClassUsers-pairs = {
      expr = builtins.length (he.mkIntoClassUsers "homeManager" { host = droidHost; });
      expected = 1;
    };

    # ── (9) hostConf is a constructible option module (the third makeHomeEnv output; its mkOption body
    #    pulls `lib` from module args, so constructing it forces no nixpkgs lib). ────────────────────────
    test-hostConf-is-module-fn = {
      expr = builtins.isFunction (mk [ ]).hostConf;
      expected = true;
    };

    # ── (10) GUARD A — an inline aspect whose `.policies.<name>` is NOT mirrored by a `.includes`
    #    `__isPolicy` record aborts (refusing to drop a policy silently), never a silent partition. ───────
    test-guardA-unmatched-policies-aborts = {
      expr =
        forceThrows
          (denCompat.compile {
            schema.host.includes = [
              {
                policies.orphan = _ctx: [ ];
                includes = [ ];
              }
            ];
            hosts.h1 = {
              class = "nixos";
            };
          }).policies;
      expected = true;
    };

    # ── (11) GUARD B — an inline aspect carrying a key beyond {includes, policies} (class content) aborts
    #    named (not hoisted), listing the offending key. ────────────────────────────────────────────────
    test-guardB-unknown-key-aborts = {
      expr =
        forceThrows
          (denCompat.compile {
            schema.host.includes = [
              {
                includes = [ ];
                someClassKey = { };
              }
            ];
            hosts.h1 = {
              class = "nixos";
            };
          }).policies;
      expected = true;
    };
  };
}
