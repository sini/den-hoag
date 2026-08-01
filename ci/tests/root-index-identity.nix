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
#
# ★★ THE DEMAND EMISSION TARGETED A CELL KIND, AND ITS BINDING WAS LOST AT EVERY NODE. This fixture
# used to aim its `containTo` at `rack` — the kind the membership tuple below makes a CELL kind — so the
# pre-pass keyed the binding at the bare `rack:r1` while the fold that injects it iterates root scope
# nodes only, and the node carrying that instance in the main run is `rack:r1@zone:z1` anyway. The
# emission was produced, keyed, and dropped: `authToken` read `<absent>` at every node in the fleet, and
# nothing here asked. A `containTo` target is required to be a membership-INDEPENDENT root — the target
# guard says so in its own words — so the tuple and the target were in conflict from the start and the
# target is the half that was wrong. `shelf` is the repair: a sibling kind under `zone` that no tuple
# names, so it is a root, and the emission's SHAPE is untouched (a single-coord source slice whose kind
# is the target's schema parent — the attachment case, exactly as before). The delivery row below is
# what makes the loss unrepeatable: a fixture that never reads its own emission cannot notice losing it.
{ denHoag, nixpkgsLib, ... }:
let
  inherit (denHoag) sel;
  inherit (denHoag) declare;

  # ── the topology: zone <- { rack, shelf }, plus a `tag` registry the pre-pass never fires at ──────
  # `tag` is parentless and carries no membership: it exists only to be a registry kind, which is
  # exactly the population the index spans and the pre-pass ignores.
  # `rack` and `shelf` are both childless kinds under `zone`, so both are cell-kind CANDIDATES; only
  # the membership tuple decides. It names `rack`, so `rack` is a cell and `shelf` stays a root — which
  # is what makes `shelf` a legal `containTo` target and `rack` an illegal one.
  schema = {
    config.den.schema = {
      zone.parent = null;
      rack.parent = "zone";
      shelf.parent = "zone";
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
      shelf.s1 = { };
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

  # THE containment emission — the demand that builds the index. The source slice is the single `zone`
  # coord, whose kind IS the target's schema parent, so this is the attachment case rather than the
  # bindings-only one; the target is a ROOT kind, so the binding it carries reaches a node.
  zoneRelateMod =
    { config, ... }:
    {
      config.den.policies.grant-token = {
        emits = [ "member" ];
        selects = sel.star;
        binds = [ "authToken" ];
        fn =
          { zone, ... }:
          [
            (declare.member {
              coords = {
                inherit zone;
                shelf = config.den.shelf.s1;
              };
              bindings.authToken = "tok-${zone.name}";
              containTo = "shelf";
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

  # WHAT THE EMISSION DELIVERED, read at the node rather than inferred from the fleet evaluating. Both
  # readings are needed and neither is redundant: the by-name read says the target holds the value, and
  # the census says NO OTHER node does — a binding that silently moved and a binding that silently
  # vanished are different regressions, and the census is the only one of the two that catches the
  # second by itself.
  bindingAt = den: id: (den.structural.eval.node id).decls.authToken or "<absent>";
  bindingCarriers =
    den:
    builtins.sort (a: b: a < b) (
      builtins.filter (id: (den.structural.eval.node id).decls ? authToken) (
        builtins.attrNames den.structural.eval.allNodes
      )
    );

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

    # THE DEMAND EMISSION ACTUALLY ARRIVES, which is the row this fixture never had. Every arm above
    # reads whether the fleet EVALUATES, and a lost binding evaluates perfectly — so for as long as the
    # emission aimed at a cell kind, `authToken` was absent at every node and all four arms stayed green
    # over a fleet whose only pre-pass product was being dropped. The demand that builds the index has
    # to be a demand that lands, or these arms are pinning the index of a fleet that never used it.
    test-the-containment-binding-arrives-at-its-target = {
      expr =
        let
          den = fleetWith distinct;
        in
        {
          atTarget = bindingAt den "shelf:s1";
          carriers = bindingCarriers den;
        };
      expected = {
        atTarget = "tok-z1";
        carriers = [ "shelf:s1" ];
      };
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
