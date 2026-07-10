# Per-host instantiation witness (ship-gate M2, D7 the per-entity grain) — v1's per-host
# `host.instantiate` (nix-config schema/host.nix: `resolvedChannel.nixosSystem`, each host's OWN
# channel-derived evaluator) is HONORED through the compat path, and WINS over the class-level terminal.
# The `hosts` sub-option is `raw`, so the evaluator function rides through `flatHosts` untouched; ingest
# keys it by id_hash (`instantiateFor`, the systemFor twin) and the compat nixos wrapper crosses each host
# through its declared evaluator (`crossVia instantiateFor`), falling to the class terminal when absent.
#
# THREE-GRAIN PRECEDENCE (per-entity > class N1 declaration > policy.instantiate capture > den.nixpkgs):
# this suite pins the top rung — the per-host evaluator beats the class terminal — with a distinct fake for
# each so the winner is unambiguous. `mkDenWith`'s `nixosTerminal` is the class terminal (grain 4 here); a
# host's `instantiate` is the per-entity grain. No nixpkgs is needed: both fakes just tag + reflect their
# argument, the same nixpkgs-free crossing the declared-instantiation suite uses.
{ denCompat, ... }:
let
  # The per-host evaluator (host.instantiate) — the `{ modules; specialArgs; } -> system` contract crossVia
  # hands to gen-flake's mkSystemTerminal. Tags the crossed system so the winning grain is observable.
  fakePerHostEval = args: { __perHostCrossed = true; } // args;
  # The class-level terminal (grain 4) — the `{ name; hostModules; bindings; classCfg; } -> artifact`
  # terminal contract mkDenWith threads as `nixosTerminal`. Distinct tag ⇒ an unambiguous loser.
  fakeClassTerminal = args: { __classTerminal = true; } // args;

  fixture = {
    den.hosts.x86_64-linux = {
      # per-entity grain: this host pins its own evaluator — builds through THAT, not the class terminal.
      pinned = {
        instantiate = fakePerHostEval;
      };
      # no per-host instantiate: falls to the class terminal (grain 4, the fake below).
      plain = { };
    };
    # Self-named aspects give each host real nixos content (the compat-bridge fixture pattern), so the
    # terminal has modules to wrap — the grain selection is what is under test, not the content.
    den.aspects.pinned.nixos.marker = "p";
    den.aspects.plain.nixos.marker = "q";
  };

  fleet = denCompat.mkDenWith [ fixture ] { nixosTerminal = fakeClassTerminal; };
  configs = fleet.nixosConfigurations;
in
{
  flake.tests.compat-per-host-instantiate = {
    # GRAIN 1 wins: the host with its own `instantiate` crosses through THAT evaluator (crossVia), NOT the
    # class terminal — proving per-host `host.instantiate` is preserved and takes precedence.
    test-per-host-evaluator-wins = {
      expr = {
        crossed = configs.pinned.__perHostCrossed or false;
        notClassTerminal = !(configs.pinned ? __classTerminal);
      };
      expected = {
        crossed = true;
        notClassTerminal = true;
      };
    };
    # GRAIN 4 fallback: the host with no per-host instantiate uses the class terminal, untouched by grain 1.
    test-no-per-host-uses-class-terminal = {
      expr = {
        classTerminal = configs.plain.__classTerminal or false;
        notPerHost = !(configs.plain ? __perHostCrossed);
      };
      expected = {
        classTerminal = true;
        notPerHost = true;
      };
    };
    # both hosts are present — honoring the per-host grain does not drop the fleet member that lacks it.
    test-both-hosts-present = {
      expr = builtins.sort (a: b: a < b) (builtins.attrNames configs);
      expected = [
        "pinned"
        "plain"
      ];
    };
    # the per-host crossing still receives the gen-flake terminal contract (wrapped modules + a specialArgs
    # carrying the cross-host `nodes` accessor) — the systemFor platform injection + wrapAll run as for any
    # crossing, so a real `resolvedChannel.nixosSystem` gets exactly what nixpkgs' `nixosSystem` expects.
    test-per-host-terminal-contract = {
      expr = {
        hasModules = configs.pinned ? modules;
        hasNodes = configs.pinned.specialArgs ? nodes;
      };
      expected = {
        hasModules = true;
        hasNodes = true;
      };
    };
  };
}
