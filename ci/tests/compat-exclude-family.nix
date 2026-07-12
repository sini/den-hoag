# #72 (candidate A, owner-ratified — ledger u21) — the EXCLUDE FAMILY: v1's `policy.exclude <policy>`
# scope-local suppression (pin 11866c16 fx/handlers/dispatch-policies.nix:15-33 — a name-keyed
# `type="exclude"` constraint at the emitting scope, consulted scope+ancestors ⇒ descendants inherit,
# siblings isolated per #613), rendered as the SECOND staged pre-pass family (the R1 pattern reused):
#   • compile.nix's exclude arm → `declare.suppress { name }` for a NAMED policy target (the class-B
#     stub RETIRED; a NAMELESS target keeps a named abort — excludeOfPolicyNameless);
#   • the exclude-family feed (concern-policies `__excludeFamily` — detected by probe or declared via
#     `den.excludeFamilyNames`, compat/exclude-family-names.nix) dispatched by the pre-pass with real
#     ctx (staged-resolution.nix), producing per-root SUPPRESSION SETS;
#   • the sets ride the emitting root's decls (`__denSuppressedPolicies`, default.nix scopeRoots) —
#     inherited-context threads them to descendants;
#   • every compiled rule with a known v1 NAME consults the key before producing (compile.nix
#     `gateSuppression`) — a suppressed policy fires as `[ ]`, exactly v1's dispatch filter.
#
# Witnesses:
#   (1) the CORPUS SHAPE — a value-conditional excluder (the drop-user-to-host-on-droid name, gated on
#       `host.class == "droid"`) suppresses the named `user-to-host` route at the droid host's CELL
#       (descendant inheritance): no user-class delivery edge at that cell;
#   (2) SIBLING ISOLATION — the same fleet's nixos host cell keeps its user-to-host edge;
#   (3) the NON-VACUOUS companion — withOUT the exclude, the droid cell's edge IS present (the
#       suppression, not the fixture shape, removes it);
#   (4) the DETECTED (unconditional) path — an excluder emitting unconditionally is probe-DETECTED into
#       the feed without any name-set entry, suppressing fleet-wide;
#   (5) the DOUBLE-FIRE guard — a value-conditional excluder NOT in the family aborts LOUD
#       (excludeFamilyUntagged) when its main-run `suppress` is forced;
#   (6) NAMELESS target — a policy-record exclude without a name aborts NAMED.
{ denCompat, ... }:
let
  inherit (denCompat) exclude;

  # the coerced registry shape a corpus exclude targets (bridge policy-type coercion; the v1 name is
  # what the suppression keys on).
  userToHostRef = {
    __isPolicy = true;
    name = "user-to-host";
    fn = _: [ ];
  };

  base = {
    hosts.x86_64-linux.d1 = {
      class = "droid";
      users.tux = { };
    };
    hosts.x86_64-linux.n1 = {
      class = "nixos";
      users.pol = { };
    };
    classes.droid = { };
    schema.user.parent = "host";
    aspects.hostc.nixos.tag = "nixos-host";
    schema.host.includes = [ "hostc" ];
    # user-CLASS content at each cell — what the os-user `user-to-host` route collects.
    aspects.uacct =
      { user, ... }:
      {
        user = [ "u-${user.name}" ];
      };
    schema.user.includes = [ "uacct" ];
  };

  mk =
    extraPolicies:
    denCompat.mkDen [
      {
        den = base // {
          policies = extraPolicies;
        };
      }
    ];

  # (1)-(3): the corpus-shaped value-conditional excluder — IN the compat exclude-family name set
  # (exclude-family-names.nix), so the pre-pass dispatches it with real ctx.
  excluded = mk {
    drop-user-to-host-on-droid =
      { host, ... }:
      if (host.class or null) == "droid" then [ (exclude userToHostRef) ] else [ ];
  };
  plain = mk { };

  # (4): the DETECTED path — an unconditional excluder (probe emits `suppress` → joins the feed with no
  # name-set entry) suppresses fleet-wide.
  detected = mk {
    always-exclude = _ctx: [ (exclude userToHostRef) ];
  };

  # (5): the double-fire guard — value-conditional AND not in the family ⇒ its main-run suppress aborts.
  rogue = mk {
    rogue-excluder =
      { host, ... }:
      if (host.class or null) == "droid" then [ (exclude userToHostRef) ] else [ ];
  };

  dCell = "user:tux@host:d1";
  nCell = "user:pol@host:n1";
  # the user-to-host route's delivery edges at a cell root (source class `user`).
  userEdgesAt =
    fleet: root:
    builtins.length (
      builtins.filter (e: (e.source.class or null) == "user") (fleet.den.graph.trace root)
    );
  ok = e: (builtins.tryEval (builtins.deepSeq e true)).success;
in
{
  flake.tests.compat-exclude-family = {
    # (1) suppression at the droid cell (descendant inheritance from the d1 root's suppression set).
    test-excluded-at-droid-cell = {
      expr = userEdgesAt excluded dCell;
      expected = 0;
    };
    # (2) sibling isolation: the nixos host's cell keeps its route (v1 #613).
    test-sibling-nixos-cell-unaffected = {
      expr = userEdgesAt excluded nCell;
      expected = 1;
    };
    # (3) non-vacuous: without the exclude the droid cell's route fires.
    test-without-exclude-droid-cell-fires = {
      expr = userEdgesAt plain dCell;
      expected = 1;
    };
    # (4) the DETECTED (unconditional) path suppresses fleet-wide with no name-set entry.
    test-detected-excluder-suppresses-fleet-wide = {
      expr = {
        d = userEdgesAt detected dCell;
        n = userEdgesAt detected nCell;
      };
      expected = {
        d = 0;
        n = 0;
      };
    };
    # (5) the double-fire guard: a non-family value-conditional excluder's main-run suppress is LOUD.
    test-untagged-excluder-aborts = {
      expr = ok (rogue.den.structural.eval.get "host:d1" "declarations");
      expected = false;
    };
    # (6) a NAMELESS policy target aborts NAMED at translation (v1's suppression is name-keyed).
    test-nameless-target-aborts = {
      expr = ok (
        (denCompat.compile {
          policies.bad = _ctx: [
            (exclude {
              __denCanTake = "user-host";
              fn = _: [ ];
            })
          ];
        }).policies.bad.fn
          { }
      );
      expected = false;
    };
  };
}
