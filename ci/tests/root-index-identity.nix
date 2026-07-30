# The containment-target index's IDENTITY PRECONDITION (lib/staged-resolution.nix `rootNodeIndex`).
#
# The index maps a registry entry's `id_hash` to the `"<kind>:<name>"` scope node it denotes, and it
# spans EVERY registry kind — including kinds the pre-pass never fires at. That map is well-defined
# only while `id_hash` is injective over the indexed entries, and the index is built by a traversal
# that must pick ONE binding per repeated key. Whichever it picked, a repeated key would hand one
# entry the other's node id: a containment target silently resolving to a node that is not its own.
# So the index refuses a repeated key by name rather than resolving it by traversal order.
#
# WHY THE REFUSAL IS NOT VACUOUS, and why the shape below is the one that reaches it. gen-schema
# content-addresses an instance as `sha256("<kind>|<k>=<v>|…")` over its sorted identity keys
# (`hashIdentity`, gen-schema/lib/identity.nix), so:
#   • ACROSS KINDS the hash cannot repeat — the kind name is the preimage's FIRST field. Pinned below
#     as a property of the minting, since no fleet can witness its absence.
#   • WITHIN a kind it normally cannot repeat either — gen-schema injects `name` per instance and it
#     reflects as an identity key. But `_identity.keys` REPLACES reflection wholesale, so an instance
#     pinning it to a key set that omits `name` is content-identical to any sibling agreeing on those
#     keys. That is the construction here, and it is the only one that reaches the refusal.
#
# ★ THE INDEX IS DEMAND-BUILT: it is forced only once the pre-pass sees a `containTo`-marked emission.
# A fixture without one never builds the index at all, so it would evaluate clean no matter what its
# registries collide on — a false pass. Every arm below carries the containment emission, and
# `test-collision-free-fleet-is-clean` is the control proving the abort is attributable to the
# collision rather than to the fixture.
{ denHoag, nixpkgsLib, ... }:
let
  inherit (denHoag) declare;

  # ── the topology: zone <- rack, plus a `tag` registry the pre-pass never fires at ────────────────
  # `tag` is parentless and carries no membership: it exists only to be a registry kind, which is
  # exactly the population the index spans and the pre-pass ignores.
  schema = {
    config.den.schema = {
      zone.parent = null;
      rack.parent = "zone";
      tag = {
        parent = null;
        imports = [
          {
            options.tier = nixpkgsLib.mkOption {
              type = nixpkgsLib.types.str;
              default = "t";
            };
          }
        ];
      };
    };
  };

  instances = tags: {
    config.den = {
      zone.z1 = { };
      rack.r1 = { };
      tag = tags;
    };
  };

  staticMembership =
    { config, ... }:
    {
      config.den.membership = [
        {
          coords = {
            zone = config.den.zone.z1;
            rack = config.den.rack.r1;
          };
        }
      ];
    };

  # THE containment emission — the demand that builds the index.
  zoneRelateMod =
    { config, ... }:
    {
      config.den.policies.grant-token = {
        emits = [ "member" ];
        binds = [ "authToken" ];
        fn =
          { zone, ... }:
          [
            (declare.member {
              coords = {
                inherit zone;
                rack = config.den.rack.r1;
              };
              bindings.authToken = "tok-${zone.name}";
              containTo = "rack";
            })
          ];
      };
    };

  fleetWith =
    tags:
    (denHoag.mkDen [
      schema
      (instances tags)
      staticMembership
      zoneRelateMod
    ]).den;

  # Forcing the same pair the pre-pass produces; the index is on the demand path of both.
  forces =
    den:
    (builtins.tryEval (
      builtins.deepSeq [
        den.scopeRoots
        den.membershipTuples
      ] true
    )).success;

  # Two `tag` entries pinning identity to `tier` alone — `name` drops out of the preimage, so both
  # hash to the same content address.
  colliding = {
    one = {
      _identity.keys = [ "tier" ];
      tier = "shared";
    };
    two = {
      _identity.keys = [ "tier" ];
      tier = "shared";
    };
  };
  # The SAME pin, but disagreeing on the pinned key — identity is still `tier`-only, so this proves
  # the abort tracks the hash rather than the presence of `_identity.keys`.
  distinct = {
    one = {
      _identity.keys = [ "tier" ];
      tier = "a";
    };
    two = {
      _identity.keys = [ "tier" ];
      tier = "b";
    };
  };

  # ── the cross-kind pin: one instance NAME under two kinds ────────────────────────────────────────
  crossKind =
    (denHoag.mkDen [
      {
        config.den.schema = {
          alpha.parent = null;
          beta.parent = null;
        };
      }
      {
        config.den = {
          alpha.same = { };
          beta.same = { };
        };
      }
    ]).den;
in
{
  flake.tests.root-index-identity = {
    # A repeated `id_hash` ABORTS instead of silently giving one entry the other's node id.
    test-duplicate-identity-aborts = {
      expr = forces (fleetWith colliding);
      expected = false;
    };

    # CONTROL — the identical fleet whose two entries pin the same key to DIFFERENT values evaluates
    # clean. Without this, the arm above could be passing because the fixture is broken.
    test-collision-free-fleet-is-clean = {
      expr = forces (fleetWith distinct);
      expected = true;
    };

    # CONTROL — an unpinned fleet is clean, so the pin itself is not what aborts.
    test-unpinned-fleet-is-clean = {
      expr = forces (fleetWith {
        one = { };
        two = { };
      });
      expected = true;
    };

    # The ACROSS-KIND half of the precondition, pinned at the minting rather than by census: the kind
    # name is part of the content address, so one instance name under two kinds is two identities.
    # No fleet can witness this failing, so the property is asserted directly.
    test-kind-participates-in-identity = {
      expr = crossKind.registries.alpha.same.id_hash == crossKind.registries.beta.same.id_hash;
      expected = false;
    };
  };
}
