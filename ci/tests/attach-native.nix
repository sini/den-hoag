# NATIVE ATTACHMENT (`den.attach`) — a kind attaches to its declared parent KIND's instance without a
# policy.
#
# THE GAP THIS FILLS. `den.schema.<kind>.parent = "<K>"` states the parent KIND and nothing more. Declaring
# it attaches NOTHING: measured before this surface existed, a fleet with `host.parent = "env"` and a real
# `env:e1` produced `host:a -> null` and `host:b -> null`. Attachment came only from policy-emitted
# containment, so a fleet with no policies had no parentage at all — and any rule of the form *materialise
# iff attached* was therefore either vacuous or emptied the fleet.
#
# A declared parent KIND does not determine a parent INSTANCE, so `den.attach.<kind>` supplies the two
# facts that do:
#   ref     the entity FIELD naming its parent instance — per-entity, so two hosts naming different
#           environments attach to different parents;
#   unless  an OPT-OUT field, tested by VALUE (present and empty ⇒ withheld), never by presence — the same
#           `entry ? f -> entry.f != [ ]` shape the output placement gate runs.
#
# ARMED AGAINST WRONG IMPLEMENTATIONS, not merely against the unfixed state. Each arm below fails for a
# DIFFERENT wrong implementation:
#   (a) attaches at all                  — fails if the emission never reaches `byTarget`;
#   (b) per-entity parent resolution     — fails an implementation that attaches every entity to the FIRST
#                                          instance of the parent kind, which arm (a) alone would pass;
#   (c) the opt-out withholds            — fails an implementation that ignores `unless`;
#   (d) absence is not opt-out           — fails an implementation that treats a missing `unless` field as
#                                          a withhold, which would empty every fleet not declaring one;
#   (e) no row ⇒ no attachment           — fails an implementation that attaches on `parent` alone, which
#                                          would change every existing fleet;
#   (f) an unresolvable ref ABORTS NAMED — fails an implementation that silently does not attach, which is
#                                          the silent-drop class this arc keeps finding.
{
  lib,
  denHoag,
  ...
}:
let
  # The kind declares its own options with the consumer's nixpkgs `lib`, as a consumer does.
  kindOpts = _: {
    options.environment = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
    options.intoAttr = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "nixosConfigurations" ];
    };
  };
  fleet =
    attach: hosts:
    (denHoag.mkDen [
      (
        { config, ... }:
        {
          config.den.schema.env.parent = null;
          config.den.schema.host = {
            parent = "env";
            imports = [ kindOpts ];
          };
          config.den.contentClass.host = "nixos";
          config.den.attach = attach;
          config.den.env = {
            e1 = { };
            e2 = { };
          };
          config.den.host = hosts;
          config.den.aspects.body.nixos.services.enable = true;
          config.den.include = map (n: {
            at = config.den.host.${n};
            aspects = [ config.den.aspects.body ];
          }) (builtins.attrNames hosts);
        }
      )
    ]).den;
  row = {
    host = {
      ref = "environment";
      unless = "intoAttr";
    };
  };
  parentsOf = d: builtins.mapAttrs (_: v: v.parent) d.scopeRoots;
  throws = e: !(builtins.tryEval (builtins.deepSeq e true)).success;

  twoEnvs = fleet row {
    a.environment = "e1";
    b.environment = "e2";
  };
  withOptOut = fleet row {
    a.environment = "e1";
    b = {
      environment = "e2";
      intoAttr = [ ];
    };
  };
  noRow = fleet { } { a.environment = "e1"; };
in
{
  flake.tests.attach-native = {
    # (a)+(b) THE PARENT INSTANCE IS PER-ENTITY. Two hosts naming different environments attach to
    # DIFFERENT parents. An implementation that resolved the parent KIND to a single instance would pass
    # "attaches at all" and fail here, which is why the two environments are not decoration.
    test-attaches-each-entity-to-its-own-parent = {
      expr = parentsOf twoEnvs;
      expected = {
        "env:e1" = null;
        "env:e2" = null;
        "host:a" = "env:e1";
        "host:b" = "env:e2";
      };
    };
    # (c)+(d) THE OPT-OUT, AND THAT ABSENCE IS NOT OPT-OUT — one pin, because they fail differently:
    # `b` declares the field EMPTY and is withheld; `a` never declares it and attaches. An implementation
    # treating absence as a withhold empties the fleet and fails on `a`.
    test-empty-optout-withholds-absence-does-not = {
      expr = parentsOf withOptOut;
      expected = {
        "env:e1" = null;
        "env:e2" = null;
        "host:a" = "env:e1";
        "host:b" = null;
      };
    };
    # (e) NO `den.attach` ROW ⇒ NO NATIVE ATTACHMENT, even though `parent` is declared and the parent
    # instance exists. This is what keeps every existing fleet byte-unchanged: attachment is opted INTO.
    test-no-row-means-no-attachment = {
      expr = parentsOf noRow;
      expected = {
        "env:e1" = null;
        "env:e2" = null;
        "host:a" = null;
      };
    };
    # (f) AN UNRESOLVABLE REF ABORTS NAMED rather than silently not attaching. A reference to an
    # unregistered parent is a typo; silent non-attachment would reproduce exactly the failure class this
    # surface exists to remove — a registry that never reaches the fleet, with no error.
    test-unresolvable-ref-aborts = {
      expr = throws (parentsOf (fleet row { a.environment = "nope"; }));
      expected = true;
    };
    # THE OUTPUT FACE follows attachment plus the placement gate: the opted-out entity has no parent AND
    # no named result, while its sibling keeps both. Pinned as CONTENTS so a fold that dropped every
    # member could not satisfy it.
    test-output-face-tracks-the-optout = {
      expr = builtins.attrNames (withOptOut.familyOutputs.nixosConfigurations or { });
      expected = [ "a" ];
    };
  };
}
