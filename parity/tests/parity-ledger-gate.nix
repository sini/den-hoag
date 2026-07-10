# P6 — the ship gate: corpus diffs ∖ ledger = ∅. Every cross-arm divergence the harness surfaces (the
# golden `missing` + `extra` key sets, parity/golden/traces.nix) must classify into a LEDGERED family
# (parity/ledger.md). An unledgered divergence key — a NEW parity shift a regression introduced, or a
# re-baselined golden without a matching ledger row — classifies into NO family and FAILS this gate. This is
# the mechanical form of the plan's P6 ship condition; the human-readable classifications + dispositions
# live in parity/ledger.md (the L3/L4/L5 rows + the residual-n / residual-o notes), which this gate mirrors.
#
# SHIP-GATE SCOPE (honest, per plan Task 8/9): this runs over the SYNTHETIC corpus (the golden). The
# full-fleet arm — the real nix-config corpus diff ∖ ledger — is the dev-time ship-gate (runbook.md), the
# one arm that cannot run in den-hoag's own CI (it evaluates the corpus flake + crosses nixpkgs/nix-darwin).
{
  harness,
  nixpkgsLib,
  ...
}:
let
  inherit (nixpkgsLib) hasPrefix hasInfix;
  inherit (harness) golden;

  fixtures = [
    "plainHostUser"
    "quirkChannel"
    "classFold"
    "multiHost"
  ];
  divergencesOf = fx: (golden.${fx}.missing or [ ]) ++ (golden.${fx}.extra or [ ]);
  allDivergences = builtins.concatMap divergencesOf fixtures;

  # The LEDGERED divergence families — every current cross-arm divergence key matches at least one. Ordered
  # so the user-scope family claims the user-rooted homeManager-synthesize edge (it is a scope-model
  # divergence, not an hm-battery one). A key matching NONE is an unledgered divergence → the gate fails.
  families = [
    {
      id = "residual-n: v1 user-as-root vs den-hoag user-as-cell (L3/L5 scope-model boundary)";
      match = hasPrefix "root:user:";
    }
    {
      id = "residual-o: unported v1 home-manager battery default fold (L3/L5)";
      match = k: hasInfix "collected:host:" k && hasInfix "/homeManager | merge" k;
    }
    {
      id = "L4: den-hoag quirk-channel fold has no v1 counterpart (disjoint-domain extra)";
      match = hasInfix "/feat | merge";
    }
    {
      id = "L4: v1 always folds host class content, den-hoag only with content (class-fold domain boundary)";
      match = k: hasInfix "collected:host:" k && hasInfix "/nixos | merge" k;
    }
  ];
  classifies = k: builtins.any (f: f.match k) families;
  unledgered = builtins.filter (k: !(classifies k)) allDivergences;

  # NEGATIVE CONTROL — a fabricated divergence key that matches no ledgered family (the gate's teeth).
  unledgeredProbe = "root:host:igloo/UNLEDGERED |  | collected:host:igloo/UNLEDGERED | merge";
in
{
  flake.tests.parity-ledger-gate = {
    # P6 SHIP GATE: every golden divergence key classifies into a ledgered family — corpus diffs ∖ ledger = ∅.
    test-no-unledgered-divergence = {
      expr = unledgered;
      expected = [ ];
    };
    # non-vacuous: the corpus HAS divergences (the gate is proving they are all classified, not that none exist).
    test-divergences-nonempty = {
      expr = builtins.length allDivergences >= 8;
      expected = true;
    };
    # TEETH: a fabricated unledgered key classifies into NO family — so a real new divergence would fail the gate.
    test-gate-has-teeth = {
      expr = classifies unledgeredProbe;
      expected = false;
    };
    # every ledgered family is actually EXERCISED by the current corpus (no dead classification rows).
    test-families-all-live = {
      expr = builtins.all (f: builtins.any f.match allDivergences) families;
      expected = true;
    };
  };
}
