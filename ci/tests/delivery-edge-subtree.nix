# #62c — the DELIVERY-EDGE SUBTREE (the flagged Task 5): a host-fired forward/route delivery's collected
# source gathers the firing scope's class content AND its descendant cells' — `members = [ id ] ++
# scope.descendants result id` (output-modules.nix `deliveryEdgesAt`). This is the home-manager.users half:
# a user cell (home-manager, an isolated edge-root) delivers its class content up to its host terminal.
# gen-edge isolates each cell as its own edge-root, so the collected source reaches ACROSS those roots via
# the explicit member list — the members are NAMED, not walked by the per-root subtree fold.
#
# Two witnesses over one fixture (a host firing a `deliver { from; to }` route), with and without child
# cells. `descendants` is self-EXCLUDING, so a childless firing node yields `[ id ]` — byte-identical to the
# pre-#62c own-scope collection (the second witness pins that identity).
{ denCompat, ... }:
let
  inherit (denCompat) deliver;

  # host:igloo firing a class-source route `src -> dst`; `withCells` toggles two home-manager user cells
  # under it (the corpus `host.users` shape; `user.parent = host` so they materialise as CELLS).
  mk =
    withCells:
    denCompat.mkDen [
      {
        den.hosts.x86_64-linux.igloo = {
          class = "nixos";
        }
        // (
          if withCells then
            {
              users.tux = { };
              users.pol = { };
            }
          else
            { }
        );
        den.schema.user.parent = "host";
        den.quirks.src = { };
        den.quirks.dst = { };
        den.aspects.seed.src = [ "hello" ];
        den.schema.host.includes = [ "seed" ];
        den.aspects.hostc.nixos.networking.hostName = "igloo";
        # the host-fired route (a class-source delivery: collected(src) -> root(dst)).
        den.policies.route1 = _ctx: [
          (deliver {
            from = "src";
            to = "dst";
          })
        ];
      }
    ];

  # the collected-source member list of the `src -> dst` delivery edge fired at the host.
  routeMembers =
    fleet:
    let
      edges = builtins.filter (
        e:
        e.source.arm == "collected"
        && (e.source.class or null) == "src"
        && (e.target.class or null) == "dst"
      ) (fleet.den.graph.trace "host:igloo");
    in
    (builtins.head edges).source.members;
in
{
  flake.tests.delivery-edge-subtree = {
    # (1) with cells: the host-fired route gathers the host PLUS its two descendant user cells (self first,
    #     then the lazy id-spine descendants in lexicographic order).
    test-route-gathers-subtree-cells = {
      expr = routeMembers (mk true);
      expected = [
        "host:igloo"
        "user:pol@host:igloo"
        "user:tux@host:igloo"
      ];
    };
    # (2) no cells: an empty descendant set ⇒ own-scope collection `[ id ]` — byte-identical to pre-#62c.
    test-no-cell-host-own-scope-unchanged = {
      expr = routeMembers (mk false);
      expected = [ "host:igloo" ];
    };
  };
}
