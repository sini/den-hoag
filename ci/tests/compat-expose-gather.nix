# #62b — the v1 `pipe.expose` ASCENT twin (approved slice U9.3): the `den.channelGather` supplier that
# fills the core #62a channel-augmentation seam with den v1's cross-scope gather (`collectAllExposed`,
# pin 11866c16 assemble-pipes.nix:701-782). Two arms:
#
#   (A) FLEET — the exact ship-gate corpus shape end-to-end through `denCompat.mkDen`: home-manager-class
#       user cells expose `resolved-users`; the different-class (nixos) host root receives the cells'
#       contributions at its terminal binding (CROSS-CLASS delivery). A sibling channel emitted at the
#       cells but NEVER exposed is NOT gathered (no-mark channels unaffected).
#   (B) UNIT — the DEPTH semantics over the gather algorithm (`denCompat.gather.gatheredAt`) on a
#       synthetic three-level `result` stub (root <- mid <- leaf). v1 is GATED-TRANSITIVE: a value bubbles
#       up only through nodes that RE-EXPOSE. A non-re-exposing middle TRAPS its child's exposed data — the
#       grandparent receives NOTHING (the non-vacuous negative that a blind subtree gather would violate).
#       When the middle DOES re-expose, the leaf's value reaches the grandparent (own ++ child order).
{ denHoag, denCompat, ... }:
let
  inherit (denHoag) sel;
  inherit (denCompat) gather;

  # ── (A) FLEET — cross-class expose delivery + no-mark isolation ────────────────────────────────────
  fleet = denCompat.mkDen [
    {
      # two home-manager user cells under one nixos host (the corpus `host.users` shape).
      den.hosts.x86_64-linux.igloo.users.tux = { };
      den.hosts.x86_64-linux.igloo.users.pol = { };
      # the host schema declares user.parent = host (topology.nix:7, the corpus's own declaration) so the
      # users materialise as CELLS under the host rather than parentless roots.
      den.schema.user = {
        parent = "host";
        includes = [
          "emit-ru"
          "expose-ru"
          "emit-secret"
        ];
      };
      # a host aspect included at every host — makes igloo a nixos content member.
      den.aspects.hostc.nixos.networking.hostName = "igloo";
      den.schema.host.includes = [ "hostc" ];

      den.quirks.resolved-users = { };
      den.quirks.secret = { };
      # per-user emit to resolved-users (parametric, resolved at the emitting cell) + to `secret`.
      den.aspects.emit-ru.resolved-users = { user, ... }: [ { name = user.name or "?"; } ];
      den.aspects.emit-secret.secret = { user, ... }: [ "s-${user.name or "?"}" ];
      # EXPOSE resolved-users (the bottom-up bubble); `secret` is emitted but NEVER exposed.
      # A v1-shaped record (`__isPolicy`) carrying its declarations. `selects = sel.star` is DECLARED because
      # this fixture registers the policy and includes it nowhere: an undeclared selection is derived from
      # the schema, where "in no includes list" means "selects nothing" — the 241-firings correction doing
      # its job, and the right answer to a question this suite is not asking.
      den.policies.expose-ru = {
        __isPolicy = true;
        selects = sel.star;
        emits = [ "pipeMark" ];
        fn = { user, ... }: [
          (denCompat.pipe.from "resolved-users" [ denCompat.pipe.expose ])
        ];
      };
    }
  ];
  hostBindings = fleet.den.output.systems.nixos."host:igloo".bindings;
  # the gathered resolved-users at the host, names sorted (source order is children-lexicographic; the
  # value SET is what matters — the consuming host aspects key by user name).
  gatheredNames = builtins.sort (a: b: a < b) (map (u: u.name) hostBindings.resolved-users);

  # ── (B) UNIT — gated-transitive depth over a synthetic three-level stub (root <- mid <- leaf) ───────
  exposeMark = channel: {
    __action = "pipeMark";
    inherit channel;
    marks = [ { __pipeMark = "expose"; } ];
  };
  contrib = v: {
    deferred = false;
    value = v;
  };
  # stub `result`: `get nid attr` over hand-built children / declarations / local-collection-data maps.
  mkStub =
    {
      children,
      decls,
      local,
    }:
    {
      get =
        nid: attr:
        if attr == "children" then
          children.${nid} or { }
        else if attr == "declarations" then
          { actions.collection = decls.${nid} or [ ]; }
        else if attr == "local-collection-data" then
          local.${nid} or { }
        else
          throw "unexpected attr ${attr}";
      # the re-layered expose arm enumerates nodes over `allNodes` to build the flat gated-edge list (the
      # gen-graph query source); a plain literal over the three stub ids (no `prelude` in this test header).
      allNodes = {
        root = true;
        mid = true;
        leaf = true;
      };
    };
  # topology root <- mid <- leaf; leaf ALWAYS exposes `ch` and emits "leaf". `midExposes` toggles whether
  # the middle re-exposes `ch` (and, when it does, contributes its own "mid").
  stub =
    midExposes:
    mkStub {
      children = {
        root.mid = { };
        mid.leaf = { };
        leaf = { };
      };
      decls = {
        leaf = [ (exposeMark "ch") ];
        mid = if midExposes then [ (exposeMark "ch") ] else [ ];
      };
      local = {
        leaf.ch = [ (contrib "leaf") ];
        mid.ch = [ (contrib "mid") ];
      };
    };
  valuesAt = s: nid: map (c: c.value) ((gather.gatheredAt s nid).ch or [ ]);
in
{
  flake.tests.compat-expose-gather = {
    # (A1) CROSS-CLASS delivery: the nixos host root receives BOTH home-manager cells' resolved-users.
    test-fleet-cross-class-gather = {
      expr = gatheredNames;
      expected = [
        "pol"
        "tux"
      ];
    };
    # (A2) no-mark channel: `secret` is emitted at the cells but never exposed, so the host gathers NONE
    #      (its own `secret` binding is empty — the host does not emit it locally).
    test-fleet-unexposed-channel-not-gathered = {
      expr = hostBindings.secret;
      expected = [ ];
    };

    # (B1) direct parent RECEIVES: the middle gathers the leaf's exposed value regardless of re-exposing.
    test-depth-direct-parent-receives = {
      expr = valuesAt (stub false) "mid";
      expected = [ "leaf" ];
    };
    # (B2) GATED negative (non-vacuous): the middle does NOT re-expose `ch`, so the grandparent (root)
    #      receives NOTHING — the leaf's value traps at the middle. A blind subtree gather would wrongly
    #      surface "leaf" at the root.
    test-depth-gated-grandparent-empty = {
      expr = valuesAt (stub false) "root";
      expected = [ ];
    };
    # (B3) transitive when the middle RE-EXPOSES: the leaf's value reaches the grandparent, after the
    #      middle's own emission (own ++ child order — v1 `resolvedBase ++ exposedValues`).
    test-depth-transitive-through-reexposing-middle = {
      expr = valuesAt (stub true) "root";
      expected = [
        "mid"
        "leaf"
      ];
    };
  };
}
