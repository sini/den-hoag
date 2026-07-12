# Membership-derived CELL-KIND classification (design note 2026-07-11 §3b, user-delivery R3-core) — the
# permanent witness that core classifies cell vs root kinds from the MEMBERSHIP TUPLES, not from a single
# `head cellKinds` pick. Fixture-driven over SYNTHETIC CUSTOM KINDS (zero corpus/v1 vocabulary), shaped
# like the corpus topology that surfaced the gap: TWO childless-with-a-parent kinds under DIFFERENT
# parents — `seat <- box` and `svc <- env` (box <- env) — where only ONE is targeted by membership.
#
#   • CLASSIFICATION: a candidate (childless + parented) targeted by a tuple's DIM SIGNATURE is a CELL
#     kind; an UNtargeted candidate is an ordinary ROOT (its entities stay readable as root scope nodes —
#     the corpus's cluster analog `svc`). The pre-R3 `head cellKinds` would have picked `seat` OR `svc`
#     alphabetically and zeroed the other's cells; here `seat` becomes the leaf exactly where membership
#     says so and `svc` stays a root, with zero kind-name literals.
#   • CELLS MATERIALIZE + CONTENT DELIVERS at the targeted family (`seat<-box`); the untargeted candidate
#     `svc` delivers its content at the ROOT scope node.
#   • NATIVE IDENTITY: with NO membership, NO candidate is targeted, so BOTH childless kinds are roots and
#     no cells materialize (byte-identical to a fleet that never declared them as cells).
#   • DERIVED-TUPLE FLIP: a pre-pass `member` emission ALONE (no static membership) flips `seat` to a cell
#     — the classification reads static ∪ pre-pass-derived tuples, and the routed fleet == the static one.
{ denHoag, ... }:
let
  inherit (denHoag) declare sel;
  sort = builtins.sort (a: b: a < b);

  # ── the synthetic corpus-shaped topology (two childless candidates under different parents) ───────────
  schema = {
    config.den.schema = {
      env.parent = null; # root
      box.parent = "env"; # the "host" analog (a parent kind → non-candidate root)
      svc.parent = "env"; # the "cluster" analog — childless + parented → a CANDIDATE
      seat.parent = "box"; # the "user" analog  — childless + parented → a CANDIDATE
    };
  };
  instances = {
    config.den = {
      env.e1 = { };
      box.b1 = { };
      svc.s1 = { };
      seat.st1 = { };
    };
  };
  # A `svc` root aspect (the untargeted candidate delivers content at its ROOT node) and a `seat` cell
  # aspect (radiates to every seat cell, included at env → witnesses "cell exists → content delivers").
  aspectsMod =
    { config, ... }:
    {
      config.den.aspects = {
        tenant = {
          neededBy = sel.kind config.den.schema.seat;
          nixos.marker = "seat-content";
        };
        svcTag.nixos.marker = "svc-content";
      };
      config.den.contentClass = {
        seat = "nixos";
        svc = "nixos";
      };
      config.den.include = [
        {
          at = config.den.box.b1; # the parent — in the seat cell's containment, so `tenant` radiates down
          aspects = [ config.den.aspects.tenant ];
        }
        {
          at = config.den.svc.s1;
          aspects = [ config.den.aspects.svcTag ];
        }
      ];
    };
  # STATIC membership: a single `{ box; seat }` tuple — targets `seat` ONLY (NO `svc` tuple; `svc` content
  # is read off its ROOT entity, exactly as the corpus reads its cluster root entities).
  staticMembership =
    { config, ... }:
    {
      config.den.membership = [
        {
          coords = {
            box = config.den.box.b1;
            seat = config.den.seat.st1;
          };
        }
      ];
    };
  # The DERIVED equivalent: a resolve-family policy emitting the SAME `{ box; seat }` membership at the box
  # root (a non-candidate — the pre-pass fires it). `__firesAtKinds = [ box ]` keeps it off the seat cell
  # (which also carries a `box` coord) so the main run's A5 guard is not tripped.
  derivedMembership =
    { config, ... }:
    {
      config.den.policies.enroll-seat = {
        __condition = {
          box = false;
        };
        __firesAtKinds = [ "box" ];
        __resolveFamily = true;
        fn =
          { box, ... }:
          [
            (declare.member {
              inherit box;
              seat = config.den.seat.st1;
            })
          ];
      };
    };

  baseFleet = [
    schema
    instances
    aspectsMod
  ];
  # (A) the corpus-shaped fleet: static membership targets seat; svc is an untargeted candidate.
  corpusShaped = (denHoag.mkDen (baseFleet ++ [ staticMembership ])).den;
  # (B) the NATIVE-IDENTITY fleet: no membership at all → no candidate targeted.
  noMembership = (denHoag.mkDen baseFleet).den;
  # (C) the DERIVED-tuple fleet: the seat membership arrives from the pre-pass alone.
  derived = (denHoag.mkDen (baseFleet ++ [ derivedMembership ])).den;

  seatCell = "seat:st1@box:b1";
  keysAt = den: id: map (n: n.key) (den.structural.eval.get id "resolved-aspects");
  hasAspectAt =
    den: id: k:
    builtins.elem k (keysAt den id);
  cellsOf = den: sort (map (c: "${c.seat.name}@${c.box.name}") den.cells);
  rootsOf = den: sort (builtins.attrNames den.scopeRoots);
  # The scope children a `box` root SPAWNS (the fleet NTA arm) — a seat cell iff seat is a cell kind.
  boxChildren = den: sort (builtins.attrNames (den.structural.eval.get "box:b1" "children"));
in
{
  flake.tests.cell-classification = {
    # ── the untargeted candidate `svc` is a ROOT (not a cell); the targeted `seat` is NOT a root (it is a
    #    cell under box). `env`/`box` (non-candidates) are roots; `svc` (untargeted candidate) is a root. ──
    test-untargeted-candidate-is-root = {
      expr = rootsOf corpusShaped;
      expected = [
        "box:b1"
        "env:e1"
        "svc:s1"
      ];
    };
    # seat never appears as a root scope node (it is the cell leaf).
    test-targeted-candidate-not-a-root = {
      expr = builtins.any (id: (builtins.match "seat:.*" id) != null) (rootsOf corpusShaped);
      expected = false;
    };

    # ── the untargeted candidate's ENTITY is readable at its root node (the corpus's cluster-root read). ──
    test-untargeted-candidate-entity-readable = {
      expr = (corpusShaped.structural.eval.node "svc:s1").decls.__entry.name;
      expected = "s1";
    };
    # …and it delivers its own content at the ROOT scope node.
    test-untargeted-candidate-delivers-at-root = {
      expr = hasAspectAt corpusShaped "svc:s1" "svcTag";
      expected = true;
    };

    # ── the TARGETED family materializes a cell, and the radiating `tenant` aspect resolves AT that cell ──
    test-targeted-family-cell-materializes = {
      expr = cellsOf corpusShaped;
      expected = [ "st1@b1" ];
    };
    test-content-delivers-at-targeted-cell = {
      expr = hasAspectAt corpusShaped seatCell "tenant";
      expected = true;
    };

    # ── NATIVE IDENTITY: no membership → NO candidate targeted → BOTH childless kinds are ROOTS, NO cells.
    #    (The pre-R3 `head cellKinds` would have made one of them a leaf regardless; here both stay roots.) ─
    test-no-membership-both-candidates-are-roots = {
      expr = rootsOf noMembership;
      expected = [
        "box:b1"
        "env:e1"
        "seat:st1" # the would-be leaf is a ROOT when nothing targets it
        "svc:s1"
      ];
    };
    # …and the box root spawns NO seat cell (the fleet NTA arm has no cell family) — vs the corpus-shaped
    # fleet, where the same box root spawns the seat cell. (The raw membership-restricted product is a
    # degenerate FULL product with no tuples; the SCOPE TREE is the classification's observable surface.)
    test-no-membership-box-spawns-no-cell = {
      expr = {
        native = boxChildren noMembership;
        targeted = boxChildren corpusShaped;
      };
      expected = {
        native = [ ];
        targeted = [ "seat:st1@box:b1" ];
      };
    };

    # ── DERIVED-TUPLE FLIP: a pre-pass `member` emission ALONE flips `seat` from a root to a cell — the
    #    classification reads static ∪ derived tuples. The routed fleet == the static one (cells + content).
    test-derived-tuple-flips-candidate-to-cell = {
      expr = {
        cells = cellsOf derived == cellsOf corpusShaped;
        content = hasAspectAt derived seatCell "tenant";
        seatNotARoot = builtins.any (id: (builtins.match "seat:.*" id) != null) (rootsOf derived);
        svcStillRoot = builtins.elem "svc:s1" (rootsOf derived);
      };
      expected = {
        cells = true;
        content = true;
        seatNotARoot = false;
        svcStillRoot = true;
      };
    };
  };
}
