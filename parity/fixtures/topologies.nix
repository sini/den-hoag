# Promoted synthetic parity topologies — each a den v1 declaration set the harness renders through BOTH
# arms (`crossArm = true`) or, for the v1-internal negative control, through the v1 arm alone
# (`crossArm = false`). A fixture is `{ name; module; crossArm; hostRoots ? true; flakeRoot ? false; }`:
#
#   module    — the v1 declaration module. A plain attrset (`{ den.hosts…; }`) runs on both arms; a
#               FUNCTION module (`{ den, lib, … }: …`) reaches den v1's `den.lib.policy.*`/`den.batteries.*`
#               and is therefore v1-ONLY (the negative control uses this to build a spawn topology).
#   crossArm  — true: diffed v1-vs-hoag (P1). false: v1-internal only (the P7 negative control).
#   hostRoots — trace every `den.hosts` root (default). flakeRoot — also/only trace the flake root.
#
# CROSS-ARM SCOPE (C7 findings, edge-schema.md + ledger). den v1's `edgeTrace` and den-hoag's
# `graph.edges` are LARGELY DISJOINT edge domains: v1 folds CLASS content (nixos/homeManager/os/user) as
# edges; den-hoag folds QUIRK CHANNELS (+ demand + the explicit deliver surface) as edges and delivers
# class content through the class-module path instead. So the cross-arm fixtures here do NOT yet reach
# byte-parity — they SURFACE that boundary as classified ledger findings (the plan's "a divergence enters
# the ledger, never papered over"). The shared delivery vocabulary (`deliver`/`route`/`provide`) is called
# via DIFFERENT lib handles on each arm (`denCompat.deliver` vs `den.lib.policy.deliver`), so a single
# static decl set cannot witness it on both arms; that reconciliation + the deliver-materialization
# completion (#44) is C8/C9 territory. The fixtures kept here are the ones that produce STABLE, classifiable
# diffs today.
{ }:
{
  # Plain host + single user. v1 renders the 6 class-fold/route/forward edges; hoag renders none (no quirk
  # channel present). The whole v1 trace is `missingFromActual` — the class-fold-domain boundary (F-domain).
  plainHostUser = {
    name = "plain-host-user";
    crossArm = true;
    module = {
      den.hosts.x86_64-linux.igloo.users.tux = { };
      den.aspects.igloo.nixos.networking.hostName = "igloo";
    };
  };

  # A quirk channel (`feat`) radiated to every host via a kind-attached include. hoag folds it into a
  # `collected:host/feat` default-fold edge; v1 does NOT surface a per-channel edge (it consumes quirk
  # content into the class folds). So the arms diverge in BOTH directions: the `feat` edge is `extra` on
  # hoag, the 6 class-fold edges are `missing` — the clearest witness of the disjoint-domain finding.
  quirkChannel = {
    name = "quirk-channel";
    crossArm = true;
    module = {
      den.hosts.x86_64-linux.igloo.users.tux = { };
      den.quirks.feat = { };
      den.aspects.seed.feat = [ "hello" ];
      den.schema.host.includes = [ { name = "seed"; } ];
    };
  };

  # Two hosts across two systems (the multi-system `@system` shape) — exercises root enumeration + per-root
  # trace concatenation on both arms. Each host's class folds are independent; the diff is the union of two
  # single-host boundaries.
  multiHost = {
    name = "multi-host";
    crossArm = true;
    module = {
      den.hosts.x86_64-linux.igloo.users.tux = { };
      den.hosts.aarch64-linux.iceberg.users.pingu = { };
      den.aspects.igloo.nixos.networking.hostName = "igloo";
      den.aspects.iceberg.nixos.networking.hostName = "iceberg";
    };
  };

  # The P7 NEGATIVE CONTROL — a v1-ONLY flake-root spawn topology (verbatim from den v1's own
  # fx-edge-parity `test-negative-control-spawn`). Diffing its production `edgeTrace` against
  # `legacyEdgeTrace` MUST diverge (the legacy rewalk arm undercounts the spawn + carries suppressed
  # twins), proving `assertEdgeParity` has teeth. Never runs on the hoag arm (function module).
  spawnNegControl = {
    name = "spawn-negcontrol";
    crossArm = false;
    hostRoots = false;
    flakeRoot = true;
    module =
      { den, lib, ... }:
      {
        den.policies.to-fleet = _: [
          (den.lib.policy.resolve.to "fleet" {
            fleet = {
              name = "fleet";
            };
          })
        ];
        den.policies.fleet-to-hosts =
          { fleet, ... }:
          lib.concatMap (
            system:
            lib.concatMap (
              hostName:
              let
                host = den.hosts.${system}.${hostName};
              in
              [
                (den.lib.policy.resolve.to "host" { inherit host; })
                (den.lib.policy.instantiate host)
              ]
            ) (builtins.attrNames (den.hosts.${system} or { }))
          ) (builtins.attrNames (den.hosts or { }));
        den.schema.flake.includes = [ den.policies.to-fleet ];
        den.schema.fleet.includes = [ den.policies.fleet-to-hosts ];
        den.schema.flake-system.excludes = [
          den.policies.system-to-os-outputs
          den.policies.system-to-hm-outputs
        ];
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.aspects.igloo.homeManager.home.sessionVariables.X = "y";
        den.aspects.tux.includes = [ den.batteries.host-aspects ];
        den.aspects.igloo.nixos.networking.hostName = "igloo";
      };
  };
}
