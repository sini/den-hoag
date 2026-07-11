# den-compat `den.lib.policy.instantiate` — the declarable-instantiation surface (board #50, D7's third
# grain), CLASS-A-MINIMAL landing. v1 `instantiate spec` (den nix/lib/policy-effects.nix:243) requests
# post-pipeline instantiation of an entity's CLASS content into a flake output. The constructor (un-stubbed,
# flake.nix) emits `{ __policyEffect = "instantiate"; value = spec }`; compile's `translateEffect`
# (`kind == "instantiate"`) routes it to `declare.spawn { instantiate = spec }` — a CHILDLESS-INERT
# resolution declaration (fleetChildren is membership-driven, so a spawn with no `{ host; user }` binding
# adds NO scope node), which PARKS the spec for the future intoAttr output family.
#
# CORPUS CONSUMERS: fleet.nix:74 `instantiate hostCfg` (CLASS-A host → nixosConfigurations, subsumed by the
# native nixos class terminal → inert), colmena.nix:96 host-modules-capture (CLASS-C colmenaHive, intoAttr
# = ["colmenaModules" <host>]), clusters.nix:104 cluster-to-nixidy (CLASS-D nixidyEnvs, u2). The class-C/D
# intoAttr OUTPUT FAMILIES are den-hoag-native-ABSENT → LATENT (ledger rows; the intoAttr family is its own
# board-#50 rung when the class-C/D arms come up).
{ denCompat, denHoag, ... }:
let
  nodesOf =
    den: builtins.sort (a: b: a < b) (builtins.attrNames (den.structural.eval.allNodes or { }));
  keysAt = den: id: map (n: n.key) (den.structural.eval.get id "resolved-aspects");
  raOkAt = den: id: (builtins.tryEval (builtins.deepSeq (keysAt den id) true)).success;

  # host-modules-capture shape (colmena.nix:96): UNCONDITIONAL instantiate at every host, class-C.
  hmcRec = {
    __isPolicy = true;
    name = "host-modules-capture";
    fn =
      { host, ... }:
      [
        (denHoag.policy.instantiate {
          name = "${host.name}-modules";
          inherit (host) class;
          instantiate = { modules, ... }: modules;
          intoAttr = [
            "colmenaModules"
            host.name
          ];
        })
      ];
  };
  mkFleet =
    extra:
    (denCompat.mkDen [
      {
        config.den = {
          hosts.x86_64-linux.h1 = {
            class = "nixos";
          };
          aspects.h1.nixos.marker = "M";
        }
        // extra;
      }
    ]);
  baseline = mkFleet { };
  withInst = mkFleet {
    policies.host-modules-capture = hmcRec;
    schema.host.includes = [ hmcRec ];
  };
  compiled = denCompat.compile {
    policies.host-modules-capture = hmcRec;
    schema.host.includes = [ hmcRec ];
    hosts.x86_64-linux.h1.class = "nixos";
  };
  # the compiled standalone policy's produce at a REAL host ctx — the spawn declaration carrying the spec.
  fired = builtins.head (
    compiled.policies.host-modules-capture.fn {
      host = {
        id_hash = "h";
        name = "h1";
        class = "nixos";
      };
    }
  );
in
{
  flake.tests.compat-instantiate = {
    # (1) The un-stubbed constructor takes BOTH v1 call shapes → the same effect record.
    test-constructor-both-shapes = {
      expr = {
        recordEffect =
          (denHoag.policy.instantiate {
            name = "n";
            class = "nixos";
          }).__policyEffect;
        entityRoundtrips =
          (denHoag.policy.instantiate {
            id_hash = "h";
            name = "host";
          }).value.id_hash;
      };
      expected = {
        recordEffect = "instantiate";
        entityRoundtrips = "h";
      };
    };
    # (2) translateEffect routes the effect to a `spawn` declaration that PARKS the spec (recoverable data —
    #     the intoAttr output family reads it; never discarded).
    test-compiles-to-spawn-parking-spec = {
      expr = {
        action = fired.__action;
        intoAttr = fired.instantiate.intoAttr;
      };
      expected = {
        action = "spawn";
        intoAttr = [
          "colmenaModules"
          "h1"
        ];
      };
    };
    # (3) host-modules-capture fires at a REAL host WITHOUT throwing (the #50 stub is gone; the emission
    #     compiles single-group and resolves).
    test-fires-clean-at-real-host = {
      expr = raOkAt withInst.den "host:h1";
      expected = true;
    };
    # (4) NO SPURIOUS FLEET CHILD (binding-1 mini-stop-gate resolved): the `spawn { instantiate }` is
    #     childless-inert — the scope-node set is IDENTICAL with and without the instantiate policy.
    test-no-spurious-fleet-child = {
      expr = nodesOf baseline.den == nodesOf withInst.den;
      expected = true;
    };
    # (5) CLASS-A from the NATIVE terminal: nixosConfigurations members are the hosts, produced by the nixos
    #     class terminal — the (raw-entity) instantiate does NOT double-register or add members.
    test-nixos-from-native-terminal = {
      expr =
        builtins.attrNames (withInst.nixosConfigurations or { })
        == builtins.attrNames (baseline.nixosConfigurations or { });
      expected = true;
    };
  };
}
