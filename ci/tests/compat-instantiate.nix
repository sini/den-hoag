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
  # host-modules-capture is include-referenced (`schema.host.includes`), so SCOPE-LOCAL FIRING (board #57,
  # ledger u3) removes its fleet-wide global — it fires SOLELY via its `__kindInclude__host__policy__0` arm
  # (index 0: the direct compile carries no built-in host includes). The arm's `.fn` is the SAME compiled
  # body; forcing its produce at a REAL host ctx yields the spawn declaration carrying the spec.
  fired = builtins.head (
    compiled.policies."__kindInclude__host__policy__0".fn {
      host = {
        id_hash = "h";
        name = "h1";
        class = "nixos";
      };
    }
  );

  # SYNTHETIC intoAttr witness (tool-name-free): a policy parking an instantiate spec whose evaluator WRAPS the
  # collected class content, targeting a den-native family "artifactsA" (NOT colmenaModules/nixidyEnvs). The 4th
  # familyOutputs arm recovers the parked spawn from the host node's structural action group, runs the spec's OWN
  # evaluator over the node's class slice, and places the built value at `intoAttr = [ family key ]`. Mirrors the
  # corpus host-modules-capture shape but with a distinct evaluator (`{ built = modules; }`) so the placement +
  # the run-over-collected-content are both observable — family/key/evaluator/class are ALL data on the spec.
  artRec = {
    __isPolicy = true;
    name = "artifacts-capture";
    fn =
      { host, ... }:
      [
        (denHoag.policy.instantiate {
          name = "${host.name}-art";
          inherit (host) class;
          instantiate = { modules, ... }: { built = modules; };
          intoAttr = [
            "artifactsA"
            host.name
          ];
        })
      ];
  };
  withArt = mkFleet {
    policies.artifacts-capture = artRec;
    schema.host.includes = [ artRec ];
  };
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
    # (6) THE intoAttr OUTPUT FAMILY (board #50 materialization rung): the parked instantiate spec is recovered
    #     from the host node's STRUCTURAL action group and its evaluator run over the collected class content,
    #     placed at `outputs.<family>.<key>`. GENERIC — family/key/evaluator/class are DATA on the spec, so a
    #     den-native "artifactsA" family materializes through the SAME kernel arm the class-C/D families ride.
    test-instantiate-materializes-family = {
      expr = {
        hasFamily = withArt.outputs ? artifactsA;
        hasKey = (withArt.outputs.artifactsA or { }) ? h1;
        # the evaluator ran over the node's collected class slice — the built `.built` IS that slice.
        builtIsClassSlice =
          withArt.outputs.artifactsA.h1.built == withArt.den.output.classSubtreeAt "host:h1" "nixos";
      };
      expected = {
        hasFamily = true;
        hasKey = true;
        builtIsClassSlice = true;
      };
    };
    # (7) BYTE-NEUTRAL on a no-instantiate fleet: the baseline recovers NO spec → the 4th arm contributes nothing
    #     → the family is absent and the built-in nixos face is untouched (the additive-arm invariant).
    test-no-instantiate-no-family = {
      expr = {
        noFamily = !(baseline.outputs ? artifactsA);
        nixosUnchanged =
          builtins.attrNames (withArt.nixosConfigurations or { })
          == builtins.attrNames (baseline.nixosConfigurations or { });
      };
      expected = {
        noFamily = true;
        nixosUnchanged = true;
      };
    };
  };
}
