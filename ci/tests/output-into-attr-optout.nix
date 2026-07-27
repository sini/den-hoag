# `intoAttr = [ ]` — the DECLARED standalone-output opt-out, honoured at the family placement.
#
# THE SHAPE THIS FIXES. An entity materialises into its class family by REGISTRY ENUMERATION → scope
# root → class terminal. Nothing along that path asks whether the entity wanted a named result: it is
# emitted because it EXISTS. So an entity that exists only INSIDE another one — a microvm guest
# delivered into its host is the corpus case — is emitted standalone anyway, and a standalone guest is
# built without the context its host would have given it.
#
# `intoAttr` is the entity's own declaration of where its named result lands (`flake.<intoAttr>.<name>`),
# class-derived by default (`[ "nixosConfigurations" <name> ]` for a nixos host). The empty path says
# there is nowhere for it to land. The gate reads that declaration and nothing else — not a name, not a
# kind, not a list of known-embedded entities.
#
# WHAT IS DELIBERATELY NOT GATED: the BUILD. The artifact still exists in the fleet's systems, because
# the entity embedding it needs exactly that artifact. `intoAttr` says where a result is PLACED, not
# whether it is produced, so gating the terminal instead of the placement would remove the thing the
# opt-out exists to keep.
#
# ARMED BOTH WAYS, and the contents are pinned rather than the absence: a family that lost every member
# would satisfy "the opted-out entity is gone", so each arm pins the full member set.
{
  lib,
  denHoag,
  ...
}:
let
  # A two-host fleet where the hosts differ ONLY in what they declare for `intoAttr`. The kind declares
  # the option the way a consumer does (its own nixpkgs `lib`), with the class-derived non-empty default.
  fleetWith =
    guestDecl:
    (denHoag.mkDen [
      {
        config.den.schema.host.parent = null;
        config.den.schema.host.options.intoAttr = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "nixosConfigurations"
          ];
        };
        config.den.contentClass.host = "nixos";
        config.den.host.keeper = { };
        config.den.host.guest = guestDecl;
      }
      (
        { config, ... }:
        {
          config.den.aspects.body.nixos.services.enable = true;
          config.den.include = [
            {
              at = config.den.host.keeper;
              aspects = [ config.den.aspects.body ];
            }
            {
              at = config.den.host.guest;
              aspects = [ config.den.aspects.body ];
            }
          ];
        }
      )
    ]);
  membersOf = f: builtins.attrNames (f.nixosConfigurations or { });

  optedOut = fleetWith { intoAttr = [ ]; };
  undeclared = fleetWith { };
  explicitPath = fleetWith {
    intoAttr = [
      "nixosConfigurations"
      "guest"
    ];
  };
in
{
  flake.tests.output-into-attr-optout = {
    # THE GATE: the entity declaring the empty path is absent, and the family still carries everything
    # else. Both halves in one pin — absence alone is satisfiable by a fold that dropped every member.
    test-empty-into-attr-omits-the-named-result = {
      expr = membersOf optedOut;
      expected = [ "keeper" ];
    };
    # ARMED THE OTHER WAY, two arms, because "absent" and "present" fail for different reasons:
    # a kind whose entity says nothing about `intoAttr` keeps its output (absence is not opt-out), and
    # an entity declaring a non-empty path keeps it too (the gate reads emptiness, not presence).
    test-non-optout-entities-still-emit = {
      expr = {
        undeclared = membersOf undeclared;
        explicitPath = membersOf explicitPath;
      };
      expected = {
        undeclared = [
          "guest"
          "keeper"
        ];
        explicitPath = [
          "guest"
          "keeper"
        ];
      };
    };
    # THE ARTIFACT SURVIVES. The opted-out entity is still built and still reachable as a system — that
    # is what the embedding entity delivers. A fix that gated the terminal would empty this too, and
    # would look correct from the family face alone.
    test-opted-out-entity-is-still-built = {
      expr = {
        systems = builtins.attrNames (optedOut.den.output.systems.nixos or { });
        registryEntry = builtins.attrNames (optedOut.den.registries.host or { });
      };
      expected = {
        systems = [
          "host:guest"
          "host:keeper"
        ];
        registryEntry = [
          "guest"
          "keeper"
        ];
      };
    };
  };
}
