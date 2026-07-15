# #8 WITNESS — a `den.quirks` CHANNEL key rides as CHANNEL content, NOT a freeform-absorbed nested aspect.
#
# THE BUG (#8, the compat-phase blocker): the compat compile + nav views typed the v1 aspect tree through a
# gen-aspects cnf that declared CLASSES but NOT the fleet's quirk channels. So a channel key (`firewall`) on
# an aspect body fell through the `aspectSubmodule` FREEFORM → typed as a NESTED ASPECT (an attrset value
# gets identity: its own `name`/`key`/`meta`), silently RESHAPING the channel content the collector reads.
#
# THE FIX (Shape B, Task 4): den-hoag declares its whole aspect vocabulary through ONE `keySemantics` map
# (`lib/key-semantics.nix`, shared by core `concern-aspects.nix` AND compat `flake-module.nix`). The compat
# compile view + nav view now declare each fleet `den.quirks` name as `{ category = "channel"; }` — gen-aspects
# builds a `raw` passthrough option for it, so the channel body rides VERBATIM (never nested). This witness
# pins BOTH views: `? name == false` (not a nested aspect) on the nav read-back AND the channel key SURVIVES
# on the compiled aspect record (not stripped as a nested key).
{ denCompat, ... }:
let
  decls = {
    quirks.firewall.description = "smoke firewall channel";
    aspects.svc = {
      nixos.networking.hostName = "h";
      firewall.networking.firewall.allowedTCPPorts = [ 22 ];
    };
    hosts.x86_64-linux.h.class = "nixos";
  };
  # COMPILE view — the tree `compile` consumes (the deferredModule class buckets + raw channel options).
  compiled = denCompat.compile decls;
  # NAV view — the `evalV1` read-back (what a `with den.aspects; …` reader / a ref navigates).
  navSvc = (denCompat.evalV1 [ { den = decls; } ]).aspects.svc;
in
{
  flake.tests.compat-channel-not-freeform = {
    # ── NAV VIEW: the channel key is NOT a nested aspect (`? name` false) and rides its raw value verbatim. ──
    test-nav-channel-not-nested = {
      expr = {
        # a freeform-absorbed channel would be a nested aspect carrying its own `name`; a `raw` channel is not.
        hasName = (navSvc.firewall or { }) ? name;
        # the raw channel body passes through byte-for-byte (transparent passthrough, no wrap).
        value = navSvc.firewall or "<absent>";
      };
      expected = {
        hasName = false;
        value = {
          networking.firewall.allowedTCPPorts = [ 22 ];
        };
      };
    };
    # ── COMPILE VIEW: the channel key SURVIVES on the compiled aspect record (classed as channel content,
    #    not stripped/nested). The compiled aspect carries BOTH its class key (`nixos`) and channel (`firewall`). ──
    test-compile-channel-survives = {
      expr = builtins.sort builtins.lessThan (builtins.attrNames compiled.aspects.svc);
      expected = [
        "firewall"
        "nixos"
      ];
    };
  };
}
