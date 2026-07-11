# den-compat aspect-include POLICY-RECORD arm (the `den.default.includes` grain — the droid-policy rung).
# v1 routes a `{ __isPolicy }` record in an aspect's `.includes` to `register-aspect-policy` — the FIRST
# `processInclude` arm, never the aspect walk (den children.nix:70-72 @ 11866c16); the registered policy
# fires scope-locally where registered (policy/default.nix:96-97). The corpus manifestation: nix-config
# nix-on-droid.nix:104, `den.default.includes = [ den.policies.drop-user-to-host-on-droid ]` — the
# bridge-coerced record fell to translateAspect's static-aspect groundRec branch, and its `fn` key
# aborted at the §2.2 three-branch key dispatch. This suite pins the arm:
#   (1) PARTITION — the record compiles to a `__default__policy__<i>` policy, NEVER `__default` aspect
#       content (no `fn` leak, no `__isPolicy` element in the normalized includes);
#   (2) GATE — the compiled policy's `__condition` is the `__default` radiation coord `{ host = false; }`
#       (fires at every host + user cell, never a custom-kind scope — the same firing set v1's
#       scope-local registration produces for the fleet-radiated default aspect; ledger u3, #57 unmoved);
#   (3) INERTNESS at class-A (the w3 declaration-level witness) — at a nixos-classed host ctx the
#       corpus-shaped body takes its false branch and the compiled fn emits `[ ]`;
#   (4) BEHAVIORAL — a nixos-only fleet carrying the record resolves crash-free (the corpus probe's
#       class-A advance in miniature), with `__default` still radiating;
#   (5) CLASS-B DEFERRAL PIN (negative) — at a droid-classed host the record's exclude-of-policy emission
#       still hits the named `excludeOfPolicy` abort (class-B / board #50, explicitly NOT this rung); the
#       fixture's record is INLINE-ONLY (never under `den.policies`), so the firing is attributable to
#       THIS arm alone — also pinning the inline-only coverage (fires solely via `__default__policy__<i>`).
{ denCompat, ... }:
let
  keysAt = den: id: map (n: n.key) (den.structural.eval.get id "resolved-aspects");
  raOkAt = den: id: (builtins.tryEval (builtins.deepSeq (keysAt den id) true)).success;

  # The exclude TARGET — a policy record (the corpus's `den.policies.user-to-host` stand-in).
  targetRec = {
    __isPolicy = true;
    name = "target-route";
    fn = _ctx: [ ];
  };
  # The corpus record shape (the bridge coercion of `den.policies.drop-user-to-host-on-droid`):
  # value-conditional on `host.class`, exclude-of-POLICY on the droid branch, `[ ]` otherwise. The
  # value-less stratum probe sees the enriched sentinel (`class = "«probe»"` ≠ "droid") → false branch.
  dropRec = {
    __isPolicy = true;
    name = "drop-on-droid";
    fn =
      { host, ... }:
      if host.class == "droid" then
        [
          {
            __policyEffect = "exclude";
            value = targetRec;
          }
        ]
      else
        [ ];
  };

  # The corpus shape in miniature: a battery-ish static ref + the policy record, BOTH in
  # `den.default.includes`; the record ALSO under `den.policies` (the double-fire precedent shape).
  decls = {
    aspects.batteryish.nixos.marker = 1;
    policies.drop-on-droid = dropRec;
    default.includes = [
      { name = "batteryish"; }
      dropRec
    ];
    hosts.x86_64-linux.h1 = {
      class = "nixos";
      users.alice = { };
    };
  };
  c = denCompat.compile decls;
  fleet = (denCompat.mkDen [ { config.den = decls; } ]).den;

  # Class-B pin fleet: a droid-classed host, the record INLINE-ONLY (not under `den.policies`).
  droidDecls = {
    classes.droid = { };
    default.includes = [ dropRec ];
    hosts.x86_64-linux.d1.class = "droid";
  };
  droidFleet = (denCompat.mkDen [ { config.den = droidDecls; } ]).den;

  # Mixed fleet: a nixos host ALONGSIDE the aborting droid host — pins PER-CELL laziness (the corpus
  # probe shape: `nixosConfigurations` forces only nixos-class cells; slab's droid-node abort must not
  # radiate into them).
  mixedDecls = droidDecls // {
    hosts.x86_64-linux = {
      h1.class = "nixos";
      d1.class = "droid";
    };
  };
  mixedFleet = (denCompat.mkDen [ { config.den = mixedDecls; } ]).den;
in
{
  flake.tests.compat-default-include-policy = {
    # (1) PARTITION: the record becomes a `__default__policy__0` POLICY; the `__default` aspect carries
    #     NO `fn` key and no `__isPolicy` element in its normalized includes (the record is not content).
    test-record-partitioned-out = {
      expr = {
        policy = c.policies ? __default__policy__0;
        aspect = c.aspects ? __default;
        noFnLeak = !(c.aspects.__default ? fn);
        noPolicyInIncludes = builtins.all (i: !(builtins.isAttrs i && (i.__isPolicy or false))) (
          c.aspects.__default.includes or [ ]
        );
        includeCount = builtins.length (c.aspects.__default.includes or [ ]);
      };
      expected = {
        policy = true;
        aspect = true;
        noFnLeak = true;
        noPolicyInIncludes = true;
        includeCount = 1;
      };
    };
    # (2) GATE: `__condition = { host = false; }` — the `__default` radiation coord (host + user cells,
    #     never a custom kind; the same mechanism compat-surface pins for `__denDefault`). The
    #     double-fire precedent holds: the `den.policies` registration ALSO compiles (both firings kept).
    test-radiation-coord-and-double-registration = {
      expr = {
        cond = c.policies.__default__policy__0.__condition;
        alsoCompiledFleetWide = c.policies ? drop-on-droid;
      };
      expected = {
        cond = {
          host = false;
        };
        alsoCompiledFleetWide = true;
      };
    };
    # (3) INERTNESS at class-A (w3, declaration-level): at a nixos-classed host ctx the compiled fn's
    #     corpus-shaped body takes the false branch → `[ ]` (no declarations — the extra firing is inert).
    test-inert-at-nixos-ctx = {
      expr = c.policies.__default__policy__0.fn {
        host = {
          name = "h1";
          class = "nixos";
        };
      };
      expected = [ ];
    };
    # (4) BEHAVIORAL class-A advance: the nixos fleet carrying the record resolves crash-free at BOTH
    #     cells (no §2.2 abort, no excludeOfPolicy), and `__default` still radiates to both.
    test-nixos-fleet-resolves = {
      expr = {
        hostOk = raOkAt fleet "host:h1";
        userOk = raOkAt fleet "user:alice@host:h1";
        hostHasDefault = builtins.elem "__default" (keysAt fleet "host:h1");
        userHasDefault = builtins.elem "__default" (keysAt fleet "user:alice@host:h1");
      };
      expected = {
        hostOk = true;
        userOk = true;
        hostHasDefault = true;
        userHasDefault = true;
      };
    };
    # (5) CLASS-B DEFERRAL PIN (negative): at the droid host the inline-only record fires via THIS arm
    #     alone and its exclude-of-POLICY emission hits the named `excludeOfPolicy` abort — class-B /
    #     board #50, explicitly not this rung (never a silent drop, never a §2.2 abort).
    test-droid-exclude-still-aborts = {
      expr = raOkAt droidFleet "host:d1";
      expected = false;
    };
    # (6) PER-CELL LAZINESS: in a MIXED fleet the nixos cell resolves even though its droid SIBLING's
    #     dispatch aborts — the corpus probe shape (`nixosConfigurations` never forces slab's droid cell).
    test-nixos-cell-lazy-past-droid-sibling = {
      expr = {
        nixosOk = raOkAt mixedFleet "host:h1";
        droidAborts = !(raOkAt mixedFleet "host:d1");
      };
      expected = {
        nixosOk = true;
        droidAborts = true;
      };
    };
  };
}
