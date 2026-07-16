# den-compat aspect-include POLICY-RECORD arm (the `den.default.includes` grain — the droid-policy rung).
# v1 routes a `{ __isPolicy }` record in an aspect's `.includes` to `register-aspect-policy` — the FIRST
# `processInclude` arm, never the aspect walk (den children.nix:70-72 @ 11866c16); the registered policy
# fires scope-locally where registered (policy/default.nix:96-97). The corpus manifestation: nix-config
# nix-on-droid.nix:104, `den.default.includes = [ den.policies.drop-user-to-host-on-droid ]`.
#
# `den.default` now DESUGARS into `den.aspects.defaults` (legacy/defaults.nix), so the record rides the
# `defaults` aspect's `.includes` and fires via its `__aspectInclude__<name>` arm (the general regular-aspect
# include grain), gated on the record fn's own formals. This suite pins the arm:
#   (1) PARTITION — the record compiles to `__aspectInclude__<name>`, NEVER `defaults` aspect content (no
#       `fn` leak, no `__isPolicy` element in the normalized includes);
#   (2) GATE — the compiled policy's `__condition` is the record fn's formals (`{ host = false; }`, the v1
#       required-coord presence gate); the `den.policies` registration's fleet-wide global is REMOVED
#       (`includeReferencedNames`), so the record fires SOLELY via its `__aspectInclude__<name>` arm;
#   (3) INERTNESS at class-A (the w3 declaration-level witness) — at a nixos-classed host ctx the
#       corpus-shaped body takes its false branch and the compiled fn emits `[ ]`;
#   (4) BEHAVIORAL — a nixos-only fleet carrying the record resolves crash-free (the corpus probe's
#       class-A advance in miniature), with `defaults` still reaching both cells;
#   (5) exclude-family routing — at a droid-classed host the record's exclude-of-policy emission ROUTES
#       through the staged pre-pass's exclude family (its corpus name ∈ the compat tag set), resolving
#       crash-free; the fixture's record is INLINE-ONLY (never under `den.policies`), so the firing is
#       attributable to THIS arm alone (fires solely via `__aspectInclude__<name>`).
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
  # The record carries the CORPUS name (∈ exclude-family-names.nix), so the staged pre-pass's
  # exclude family dispatches it with real ctx — the suppression ROUTES (the class-B stub retired).
  dropRec = {
    __isPolicy = true;
    name = "drop-user-to-host-on-droid";
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
  aspectIncludeName = "__aspectInclude__drop-user-to-host-on-droid";

  # The corpus shape in miniature: a battery-ish static ref + the policy record, BOTH in
  # `den.default.includes`; the record ALSO under `den.policies` (the scope-local case: its global is
  # REMOVED, so it fires solely via the `__aspectInclude__<name>` arm — includeReferencedNames).
  decls = {
    aspects.batteryish.nixos.marker = 1;
    policies.drop-user-to-host-on-droid = dropRec;
    default.includes = [
      { name = "batteryish"; }
      dropRec
    ];
    hosts.x86_64-linux.h1 = {
      class = "nixos";
      users.alice = { };
    };
  };
  c = denCompat.compileFull decls;
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
    # (1) PARTITION: the record becomes an `__aspectInclude__<name>` POLICY; the `defaults` aspect carries
    #     NO `fn` key and no `__isPolicy` element in its normalized includes (the record is not content).
    #     The includes retain the static `batteryish` ref (the coerced route records are diverted too).
    test-record-partitioned-out = {
      expr = {
        policy = c.policies ? ${aspectIncludeName};
        aspect = c.aspects ? defaults;
        noFnLeak = !(c.aspects.defaults ? fn);
        noPolicyInIncludes = builtins.all (i: !(builtins.isAttrs i && (i.__isPolicy or false))) (
          c.aspects.defaults.includes or [ ]
        );
      };
      expected = {
        policy = true;
        aspect = true;
        noFnLeak = true;
        noPolicyInIncludes = true;
      };
    };
    # (2) GATE + SCOPE-LOCAL FIRING: `__condition = { host = false; }` — the record fn's formals (the v1
    #     required-coord presence gate). The `den.policies.drop-on-droid` registration is ALSO
    #     include-referenced (it rides `default.includes`), so its fleet-wide global is REMOVED — the record
    #     fires SOLELY via this `__aspectInclude__<name>` arm (v1: a policy fires only where INCLUDED, not by
    #     `den.policies` presence).
    test-radiation-coord-and-scope-local = {
      expr = {
        cond = c.policies.${aspectIncludeName}.__condition;
        alsoCompiledFleetWide = c.policies ? drop-user-to-host-on-droid;
      };
      expected = {
        cond = {
          host = false;
        };
        alsoCompiledFleetWide = false;
      };
    };
    # (3) INERTNESS at class-A (w3, declaration-level): at a nixos-classed host ctx the compiled fn's
    #     corpus-shaped body takes the false branch → `[ ]` (no declarations — the extra firing is inert).
    test-inert-at-nixos-ctx = {
      expr = c.policies.${aspectIncludeName}.fn {
        host = {
          name = "h1";
          class = "nixos";
        };
      };
      expected = [ ];
    };
    # (4) BEHAVIORAL class-A advance: the nixos fleet carrying the record resolves crash-free at BOTH
    #     cells (no §2.2 abort, no excludeOfPolicy), and `defaults` still reaches both.
    test-nixos-fleet-resolves = {
      expr = {
        hostOk = raOkAt fleet "host:h1";
        userOk = raOkAt fleet "user:alice@host:h1";
        hostHasDefault = builtins.elem "defaults" (keysAt fleet "host:h1");
        userHasDefault = builtins.elem "defaults" (keysAt fleet "user:alice@host:h1");
      };
      expected = {
        hostOk = true;
        userOk = true;
        hostHasDefault = true;
        userHasDefault = true;
      };
    };
    # (5) exclude-family routing: the record's exclude-of-POLICY emission ROUTES through the staged
    #     pre-pass's exclude family (its corpus name is in the compat tag set), so the droid host RESOLVES
    #     crash-free — the suppression of `target-route` is consumed, never dropped (the untagged case stays
    #     LOUD — compat-exclude-family.test-untagged-excluder-aborts).
    test-droid-exclude-routes = {
      expr = raOkAt droidFleet "host:d1";
      expected = true;
    };
    # (6) the MIXED fleet: both cells resolve (the droid sibling no longer aborts via exclude-family
    #     routing; the nixos cell was already lazy past it).
    test-nixos-cell-lazy-past-droid-sibling = {
      expr = {
        nixosOk = raOkAt mixedFleet "host:h1";
        droidResolves = raOkAt mixedFleet "host:d1";
      };
      expected = {
        nixosOk = true;
        droidResolves = true;
      };
    };
  };
}
