# Slice R1 — the STAGED ROOT-RESOLUTION pre-pass (design note 2026-07-11 §2/§3(ii)). Fixture-driven over
# SYNTHETIC CUSTOM KINDS (the genericity pin — ZERO env/host/user names, zero corpus/v1 vocabulary): a
# three-level containment topology `zone <- rack <- blade` (blade the leaf/cell kind). The pass:
#
#   • routes a policy-emitted CELL membership into the fleet (the deferred Task 4 — A5's promised law);
#   • folds a CONTAINMENT tuple's bindings (source zone -> existing rack, `containTo = "rack"`) into the
#     target's ctx via a per-target transpose slice, demand-read where the consuming rack policy fires
#     (`authToken`) AND folded onto the target's decls for the main run;
#   • materializes the binding carrier as an order-INDEPENDENT per-target map (no parent-before-child phase
#     schedule): two sources to DISTINCT targets each deliver to their OWN target;
#   • holds the DOUBLE-FIRE / A5 discipline: a resolve-family emission at a membership-DERIVED node aborts
#     LOUD (never a silent drop);
#   • leaves a native fleet (no resolution emissions) BYTE-IDENTICAL to the static-membership fleet.
{ denHoag, ... }:
let
  inherit (denHoag) declare sel;

  sort = builtins.sort (a: b: a < b);

  # ── the synthetic topology + instances (shared) ──────────────────────────────────────────────────────
  schema = {
    config.den.schema = {
      zone.parent = null;
      rack.parent = "zone";
      blade.parent = "rack";
    };
  };
  instances = {
    config.den = {
      zone.z1 = { };
      rack.r1 = { };
      rack.r2 = { };
      blade.b1 = { };
    };
  };
  # The STATIC membership skeleton (real registry entries via `{ config, ... }`, never fabricated):
  #   • both racks sit in zone z1 (the containment upper half);
  #   • a (rack r2, blade b1) tuple — this CONSTRAINS the blade dimension globally (an otherwise-untupled
  #     leaf dim multiplies through gen-product's natural join, default.nix:434), so a rack with NO
  #     (rack, blade) tuple carries NO blade cell. r2 therefore has b1; r1 has NONE — until a policy
  #     routes a (r1, blade) membership, ADDING the cell.
  staticMembership =
    { config, ... }:
    {
      config.den.contentClass.blade = "nixos"; # collect terminal (den.nixpkgs = null) — no nixpkgs needed
      config.den.membership = [
        {
          coords = {
            zone = config.den.zone.z1;
            rack = config.den.rack.r1;
          };
        }
        {
          coords = {
            zone = config.den.zone.z1;
            rack = config.den.rack.r2;
          };
        }
        {
          coords = {
            rack = config.den.rack.r2;
            blade = config.den.blade.b1;
          };
        }
      ];
    };
  # The (r1, blade) tuple as STATIC config — the native-equivalent of the rack policy's emission.
  rackBladeStatic =
    { config, ... }:
    {
      config.den.membership = [
        {
          coords = {
            rack = config.den.rack.r1;
            blade = config.den.blade.b1;
          };
        }
      ];
    };

  # An aspect radiating to every blade cell (neededBy the blade kind), included at the zone — the content
  # whose arrival at the terminal witnesses "membership emission -> cell exists -> content delivers".
  tenantMod =
    { config, ... }:
    {
      config.den.aspects.tenant = {
        neededBy = sel.kind config.den.schema.blade;
        nixos.marker = "tenant-content";
      };
      config.den.include = [
        {
          at = config.den.zone.z1;
          aspects = [ config.den.aspects.tenant ];
        }
      ];
    };

  # ── the RESOLUTION policies (the two-phase corpus shape, synthetic) ──────────────────────────────────
  # zone phase: a CONTAINMENT member to an EXISTING rack (§3c-UNIFIED, `relate` dissolved), carrying
  # `authToken` (a tuple-carried binding) + recording zone as rack's containment ancestor. Fires at zone
  # roots only (the `zone` coord is absent at rack roots and — being a stripped `__coords` entry — at blade
  # cells). Single-group structural (the probe emits a `member`). `containTo = "rack"` marks the target coord.
  zoneRelateMod =
    { config, ... }:
    {
      config.den.policies.grant-token =
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
  # a SECOND containment source, to a DISTINCT target (rack r2), carrying its own token. Two sources fired
  # in one collection prove the carrier is per-TARGET keyed and order-independent: r2's slice never leaks
  # into r1's and vice versa, with no phase schedule between them.
  zoneRelateR2Mod =
    { config, ... }:
    {
      config.den.policies.grant-token-r2 =
        { zone, ... }:
        [
          (declare.member {
            coords = {
              inherit zone;
              rack = config.den.rack.r2;
            };
            bindings.authToken = "tok2-${zone.name}";
            containTo = "rack";
          })
        ];
    };
  # rack phase: reads the relation-carried `authToken` and emits a leaf-dim MEMBERSHIP (rack, blade) — the
  # blade cell. Value-conditional (emits nothing without the token → expansion). `__firesAtKinds = [rack]`
  # keeps it off the blade cell (which inherits `rack` + the injected `authToken`) — the resolve-policy
  # scope-restriction the double-fire discipline expects.
  rackMemberMod =
    { config, ... }:
    {
      config.den.policies.enroll-blade = {
        __condition = {
          rack = false;
        };
        __firesAtKinds = [ "rack" ];
        # value-conditional (empty probe) resolve policy → the emitting adapter DECLARES resolve-family
        # intent (its probe cannot reveal the member it emits only once `authToken` is present).
        __resolveFamily = true;
        fn =
          ctx:
          if (ctx.authToken or null) != null then
            [
              (declare.member {
                rack = ctx.rack;
                blade = config.den.blade.b1;
              })
            ]
          else
            [ ];
      };
    };

  baseFleet = [
    schema
    instances
    staticMembership
    tenantMod
  ];
  # (A) the RESOLUTION fleet: the two-phase policies route the blade cell + thread the token.
  viaPolicy =
    (denHoag.mkDen (
      baseFleet
      ++ [
        zoneRelateMod
        rackMemberMod
      ]
    )).den;
  # (B) the STATIC-equivalent fleet: the SAME (rack, blade) tuple declared statically, NO resolve policies
  #     — the native/identity path. viaPolicy's routing must produce a byte-identical fleet.
  staticEquiv = (denHoag.mkDen (baseFleet ++ [ rackBladeStatic ])).den;
  # two containment sources to DISTINCT targets in ONE fleet — the per-target / order-independence witness.
  twoSource =
    (denHoag.mkDen (
      baseFleet
      ++ [
        zoneRelateMod
        zoneRelateR2Mod
      ]
    )).den;

  # COLLISION: two SAME-KIND sources (zones z1, z2) both emit `containTo = "rack"` to the SAME target
  # rack:r1. The merge is deterministic and byte-faithful to the pre-transpose flat fold: same-kind roots
  # iterate alphabetically (`attrNames`) in BOTH, so the alphabetically-LAST source (z2) wins. This is the
  # ONLY reachable multi-source shape — a target of kind K has one parent KIND in the schema forest, so its
  # containment sources are all of kind parent(K); cross-kind emitters to one target (two parent kinds for
  # one node) are topology-unreachable. INVARIANT (not a deferred case): the corpus + every other fixture is
  # single-source per target (one env per host, `host.environment` scalar; on the real corpus the env→host
  # fan-out is stubbed entirely), so `containmentBindings.${id}` derives from exactly one source there.
  collisionInstances =
    { config, ... }:
    {
      config.den = {
        zone.z1 = { };
        zone.z2 = { };
        rack.r1 = { };
      };
    };
  collisionDen =
    (denHoag.mkDen [
      schema
      collisionInstances
      zoneRelateMod
    ]).den;

  cellId = "blade:b1@rack:r1";
  keysAt = den: id: map (n: n.key) (den.structural.eval.get id "resolved-aspects");
  hasAspectAt =
    den: id: k:
    builtins.elem k (keysAt den id);
  cellsOf = den: sort (map (c: "${c.blade.name}@${c.rack.name}/${c.zone.name}") den.cells);

  # relation binding visible in the MAIN run's rack node ctx (the injected-decls seam → enriched-context).
  rackCtx = viaPolicy.structural.eval.get "rack:r1" "enriched-context";

  # ── (C) the DISCIPLINE aborts: a resolve-family emission at a membership-DERIVED node (the blade cell) ─
  # `{ blade }` fires ONLY at the blade cell (the `blade` coord is absent at every root), so its emission
  # lands at a cell → the main run aborts LOUD (errors.memberAtCell), never a silent drop.
  memberAtCellMod =
    { config, ... }:
    {
      config.den.policies.bad-member =
        { blade, ... }:
        [
          (declare.member {
            rack = config.den.rack.r1;
            inherit blade;
          })
        ];
    };
  containAtCellMod =
    { config, ... }:
    {
      config.den.policies.bad-contain =
        { blade, ... }:
        [
          (declare.member {
            coords = {
              inherit blade;
              rack = config.den.rack.r1;
            };
            bindings.x = 1;
            containTo = "rack";
          })
        ];
    };
  abortFleet = baseFleet ++ [ rackBladeStatic ];
  memberAtCellDen = (denHoag.mkDen (abortFleet ++ [ memberAtCellMod ])).den;
  containAtCellDen = (denHoag.mkDen (abortFleet ++ [ containAtCellMod ])).den;
  forceCellDecls =
    den:
    (builtins.tryEval (builtins.deepSeq (den.structural.eval.get cellId "declarations") true)).success;
in
{
  flake.tests.staged-resolution = {
    # ── THE PER-TARGET CARRIER is order-INDEPENDENT: two containment sources fired in one collection each
    #    deliver to their OWN target's ctx (r1 gets its token, r2 gets its own), with no phase schedule and
    #    no cross-leak. This is the property that replaces the former parent-before-child phase sort. ──────
    test-per-target-binding-order-independent = {
      expr = {
        r1 = (twoSource.structural.eval.get "rack:r1" "enriched-context").authToken or null;
        r2 = (twoSource.structural.eval.get "rack:r2" "enriched-context").authToken or null;
      };
      expected = {
        r1 = "tok-z1";
        r2 = "tok2-z1";
      };
    };

    # ── MULTI-SOURCE COLLISION to ONE target is deterministic + byte-faithful to the pre-transpose fold:
    #    two same-kind sources (zones z1, z2) to rack:r1 merge last-wins in alphabetical (`attrNames`) source
    #    order, so z2's token wins — identical to the old kind-ordered fold's within-kind alphabetical
    #    last-wins. Corpus/fixtures are single-source per target (an invariant, stated above), so this path
    #    is corpus/fixture-zero; it is defined here, not deferred. ──────────────────────────────────────────
    test-same-kind-collision-last-wins = {
      expr = (collisionDen.structural.eval.get "rack:r1" "enriched-context").authToken or null;
      expected = "tok-z2";
    };

    # ── MEMBERSHIP ROUTING (Task 4): the rack policy's leaf-dim `member` emission (r1, b1) ROUTES into the
    #    fleet and ADDS the b1@r1 cell beside the static b1@r2 — the fleet gained a cell from a POLICY. ──
    test-membership-emission-routes-to-fleet = {
      expr = cellsOf viaPolicy;
      expected = [
        "b1@r1/z1"
        "b1@r2/z1"
      ];
    };
    # non-vacuous: WITHOUT the policy the b1@r1 cell does NOT exist — only the static b1@r2 (r1 carries no
    # (rack, blade) membership, and the blade dim is globally constrained by the r2 tuple).
    test-policy-adds-the-cell = {
      expr = cellsOf (denHoag.mkDen baseFleet).den;
      expected = [ "b1@r2/z1" ];
    };
    # …and the cell only materializes once the zone phase's token reached the rack phase: the rack policy
    # WITHOUT the zone relate (no `authToken`) enrolls nothing, so the fleet is the static baseline.
    test-no-cell-without-relation = {
      expr = cellsOf (denHoag.mkDen (baseFleet ++ [ rackMemberMod ])).den; # rack policy, but no zone relate
      expected = [ "b1@r2/z1" ];
    };

    # ── RELATION-CARRIED BINDINGS reach a LATER-phase policy's ctx (proven transitively: the rack member
    #    fired ⇒ the rack phase saw `authToken`) AND the main run's node ctx (the injected-decls seam). ──
    test-relation-binding-in-main-run-ctx = {
      expr = rackCtx.authToken or null;
      expected = "tok-z1";
    };
    # the relation only reaches its TARGET root (rack:r1), never rack:r2 (a distinct root, no relation).
    test-relation-binding-scoped-to-target = {
      expr = (viaPolicy.structural.eval.get "rack:r2" "enriched-context") ? authToken;
      expected = false;
    };

    # ── CONTENT DELIVERS: the radiating `tenant` aspect resolves AT the routed blade cell (the full flow
    #    S1 could not witness — a policy-membership cell carrying delivered content to the terminal). ────
    test-content-delivers-at-routed-cell = {
      expr = hasAspectAt viaPolicy cellId "tenant";
      expected = true;
    };

    # ── NATIVE BYTE-IDENTITY: the policy-routed fleet matches the static-membership fleet at the cell set
    #    AND the delivered content — the routing == a static declaration for those, and a fleet with no
    #    resolution emissions is unchanged by the pre-pass (the identity path). (The containment member DOES
    #    add zone as rack's settings-chain ancestor, a §3c difference the static tuple lacks — not asserted
    #    here; cells + resolved-aspect content are what this pins.) ─────────────────────────────────────────
    test-routed-fleet-identical-to-static = {
      expr = {
        cells = cellsOf viaPolicy == cellsOf staticEquiv;
        content = hasAspectAt viaPolicy cellId "tenant" == hasAspectAt staticEquiv cellId "tenant";
      };
      expected = {
        cells = true;
        content = true;
      };
    };
    # the static fleet emits NO member/relate, so its cells come purely from static membership (the pre-pass
    # is inert) — the un-changed native baseline the identity path preserves.
    test-static-fleet-native-cells = {
      expr = cellsOf staticEquiv;
      expected = [
        "b1@r1/z1"
        "b1@r2/z1"
      ];
    };

    # ── DOUBLE-FIRE / A5 DISCIPLINE: a resolve-family emission at the membership-DERIVED blade cell aborts
    #    LOUD (errors.memberAtCell) — never silently dropped. Both a CELL member and a CONTAINMENT member
    #    (the unified `member`) are guarded. ──────────────────────────────────────────────────────────────
    test-member-at-cell-aborts = {
      expr = forceCellDecls memberAtCellDen;
      expected = false;
    };
    test-containment-member-at-cell-aborts = {
      expr = forceCellDecls containAtCellDen;
      expected = false;
    };
    # non-vacuous: the SAME base fleet WITHOUT the over-firing policy forces the cell's declarations clean
    # (the abort is caused by the resolve-family emission, not the cell itself).
    test-cell-decls-clean-without-bad-policy = {
      expr =
        (builtins.tryEval (
          builtins.deepSeq ((denHoag.mkDen abortFleet).den.structural.eval.get cellId "declarations") true
        )).success;
      expected = true;
    };
  };
}
