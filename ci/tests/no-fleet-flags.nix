# Class-share (A10) is PER-CLASS and PER-CELL lazy, NO global fleet switch (spec §2.10, Law
# A17). Three proofs:
#   per-class      — in ONE fleet eval a `share.core = true` class (nixos) is built through the gen-class
#                    tier-2 path while a sibling `share.core = false` class (home-manager) is not. The
#                    switch is `classCfg.share.core`, read per class — a fleet-wide toggle would be a
#                    spec violation.
#   per-cell lazy  — building ONE member forces no OTHER member's DELTA: a poisoned member delta is
#                    inert while a sibling member builds; forcing the poisoned member itself aborts (the
#                    probe is not vacuous). The shared core forces every member's cheap PROJECTION, never
#                    a delta.
#   no fleet flag  — a source tripwire over the WHOLE kernel (scan set DERIVED from the tree): no kernel
#                    file names a fleet-global share toggle; the decision reads `classCfg.share.core`
#                    (per class), asserted present at the one stratum that makes it.
{
  denHoag,
  denHoagSrc,
  nixpkgsLib,
  genPrelude,
  ...
}:
let
  # ── a fleet where hosts produce `nixos` (share.core = true) and a user cell `home-manager` (false) ──
  schema = {
    config.den.schema = {
      env.parent = null;
      host.parent = "env";
      user.parent = "host";
    };
  };
  instances = {
    config.den = {
      env.prod = { };
      host.axon = { };
      host.blade = { };
      user.alice = { };
    };
  };
  membership =
    { config, ... }:
    {
      config.den.membership = [
        {
          coords = {
            env = config.den.env.prod;
            host = config.den.host.axon;
          };
        }
        {
          coords = {
            env = config.den.env.prod;
            host = config.den.host.blade;
          };
        }
        {
          coords = {
            host = config.den.host.axon;
            user = config.den.user.alice;
          };
        }
      ];
    };
  classing.config.den.contentClass = {
    host = "nixos";
    user = "home-manager";
  };
  quirk.config.den.quirks.ports = { };

  # nixos content at both hosts: a shared class-invariant channel value + nixos class content.
  hostContent =
    { config, ... }:
    {
      config.den.aspects.svc = {
        ports = [
          22
          80
        ];
        nixos = {
          boot.isContainer = true;
        };
      };
      config.den.include = [
        {
          at = config.den.host.axon;
          aspects = [ config.den.aspects.svc ];
        }
        {
          at = config.den.host.blade;
          aspects = [ config.den.aspects.svc ];
        }
      ];
    };
  # home-manager content at the user cell (the sibling class, share.core = false).
  userContent =
    { config, ... }:
    {
      config.den.aspects.usr = {
        home-manager = {
          home.stateVersion = "24.05";
        };
      };
      config.den.include = [
        {
          at = config.den.user.alice;
          aspects = [ config.den.aspects.usr ];
        }
      ];
    };
  # ONLY nixos shares; home-manager is left at the default (share.core = false).
  shareNixos.config.den.classes.nixos.share.core = true;

  base = [
    schema
    instances
    membership
    classing
    quirk
    hostContent
    userContent
    shareNixos
  ];
  den = (denHoag.mkDen base).den;

  axonId = "host:axon";
  bladeId = "host:blade";
  cellId = "user:alice@host:axon";

  # ── per-cell laziness probe: a poisoned member DELTA at blade (a nixos class module that aborts when
  #    built). Building axon must NOT force it; building blade must. ──
  poison =
    { config, ... }:
    {
      config.den.aspects.boom = {
        # a poison in the DELTA (class content) — forced only when THIS member's output is built, never
        # by the shared core (which reads the cheap classInvariant PROJECTION, not class-modules).
        nixos = { ... }: builtins.throw "class-share: blade delta forced";
      };
      config.den.include = [
        {
          at = config.den.host.blade;
          aspects = [ config.den.aspects.boom ];
        }
      ];
    };
  denProbe = (denHoag.mkDen (base ++ [ poison ])).den;
  buildsAxon =
    (builtins.tryEval (builtins.deepSeq denProbe.output.systems.nixos.${axonId} true)).success;
  buildsBlade =
    (builtins.tryEval (builtins.deepSeq denProbe.output.systems.nixos.${bladeId} true)).success;

  # ── source tripwire: no fleet-global share toggle anywhere in the kernel ──
  # SCAN DOMAIN — this is a COVERAGE CLAIM, not a targeted probe, so the domain is TOTAL: every kernel
  # file, DERIVED from the tree by `_lib/core-files.nix` (the same set boundary.nix, zero-machinery.nix
  # and end-to-end.nix scan). The claim being made is an ABSENCE — "no fleet-global toggle exists" — and
  # a hand-listed domain cannot carry one: a toggle introduced in an unlisted file leaves this test GREEN,
  # because a scan set that omits a file is indistinguishable from a scan set over which that file is
  # clean. The two strata that actually read the decision are MEMBERS of this set, not the whole of it,
  # and their membership is asserted below rather than assumed.
  read = f: builtins.readFile "${denHoagSrc}/lib/${f}";
  scanned = import ./_lib/core-files.nix { inherit denHoagSrc nixpkgsLib; };
  decisionStrata = [
    "output/class-share.nix"
    "attributes/output-modules.nix"
  ];
  fleetFlagTokens = [
    "fleetShare"
    "shareAll"
    "globalShare"
    "globalCore"
    "fleetWideCore"
    "fleetCore"
  ];
  fleetFlagOffenders = builtins.concatMap (
    f:
    let
      t = read f;
    in
    map (tok: "${f}:${tok}") (builtins.filter (tok: genPrelude.hasInfix tok t) fleetFlagTokens)
  ) scanned;
  # By contrast this is a PRESENCE claim about ONE named stratum — the file that makes the per-class
  # decision — so naming it is the content of the assertion, not a coverage gap. Deriving this domain
  # would WEAKEN it to "some kernel file reads `classCfg.share.core`", which is a different proposition.
  perClassRead = genPrelude.hasInfix "classCfg.share.core" (read "attributes/output-modules.nix");
in
{
  flake.tests.no-fleet-flags = {
    # ── per-class (one eval, two classes, opposite share.core) ──
    # the share.core = true class (nixos) is built through the gen-class tier-2 path — its member output
    # carries the shared-core loc (the collect terminal never produces it).
    test-nixos-class-shares = {
      expr = builtins.hasAttr denHoag.internal.classShareCoreAttr den.output.systems.nixos.${axonId};
      expected = true;
    };
    test-nixos-both-members-share = {
      expr =
        builtins.all
          (id: builtins.hasAttr denHoag.internal.classShareCoreAttr den.output.systems.nixos.${id})
          [
            axonId
            bladeId
          ];
      expected = true;
    };
    # the sibling share.core = false class (home-manager) is NOT shared — it crosses the ordinary
    # `collect` terminal (no shared-core loc), in the SAME fleet eval.
    test-home-manager-not-shared = {
      expr = den.output.systems.home-manager.${cellId}.__terminal or null;
      expected = "collect";
    };
    test-home-manager-no-core-loc = {
      expr =
        builtins.hasAttr denHoag.internal.classShareCoreAttr
          den.output.systems.home-manager.${cellId};
      expected = false;
    };

    # ── per-cell lazy (building one member forces no other member's delta) ──
    # building axon succeeds DESPITE blade's poisoned delta ⇒ axon's build never forced blade's delta.
    test-sibling-delta-not-forced = {
      expr = buildsAxon;
      expected = true;
    };
    # …and the poison IS reachable (building blade forces its own delta and aborts) — probe not vacuous.
    test-own-delta-is-forced = {
      expr = buildsBlade;
      expected = false;
    };

    # ── no fleet flag (source tripwire) ──
    # NO kernel file names a fleet-global share toggle, over the tree-derived total scan set.
    test-no-fleet-global-toggle = {
      expr = fleetFlagOffenders;
      expected = [ ];
    };
    # …and that scan set is non-vacuous where it matters: the two strata that read the share decision are
    # IN the derived domain. An absence claim over an empty or drifted domain reads as success, so the
    # domain is pinned by the files it must contain rather than by the count it happens to have.
    test-scan-domain-covers-decision-strata = {
      expr = builtins.filter (f: !(builtins.elem f scanned)) decisionStrata;
      expected = [ ];
    };
    # the decision is read PER CLASS (`classCfg.share.core`), never a fleet switch.
    test-decision-is-per-class = {
      expr = perClassRead;
      expected = true;
    };
  };
}
