# #63 — the WITHIN-CLASS SUBTREE FOLD (task #53a, the class-fold twin of delivery-edge-subtree.nix):
# a node's within-class content assembly gathers the SAME class bucket from `[ id ] ++ scope.descendants
# result id` (output-modules.nix `classSubtreeAt`, consumed at the TERMINAL reads hostModules/deltaOf/
# contentIdsOf — the byte-compare path — AND the default-fold edge classBucketsOf/contentsOf). This is
# v1's non-isolated NESTING fold (defaultFoldEdges, edges/default.nix Corollary 1) rendered where a
# no-isolated-KIND corpus collapses the isolation-aware subtree to the blind descendants walk: a user cell
# (home-manager, an isolated edge-root) emits HOST-CLASS (nixos) content — the corpus define-user
# `users.users.<n>` shape — which folds UP into its host's nixos assembly (the terminal that builds the
# host system) and the host's nixos default-fold edge. gen-edge isolates each cell as its own edge-root,
# so the gather crosses those roots via the explicit descendants walk, never the per-root subtree fold.
#
# Four witnesses over one fixture (a nixos host with home-manager user cells, each cell emitting nixos +
# home-manager content), with and without cells:
#   (1) fold gathers subtree — the host's nixos assembly carries the host's OWN content AND each cell's
#       nixos content, at BOTH the default-fold edge and the terminal (the byte-compare path).
#   (2) identity companion — a cell-less host's assembly is its own content alone: `descendants` is
#       self-EXCLUDING, so an empty descendant set ⇒ `[ id ]`, byte-identical to the pre-#63 own-scope read.
#   (3) per-class no-leak — a cell's OTHER-class (home-manager) bucket does NOT enter the host's nixos
#       assembly (the gather is gated to the class in question); the host's home-manager assembly gathers
#       the cells' home-manager content instead.
#   (4) A12 order — own-first ++ lexicographic-DFS descendants, no dedup (three cells pin the sort).
{ denCompat, ... }:
let
  # a nixos host `igloo`; `withCells` toggles three home-manager user cells under it (the corpus host.users
  # shape; `user.parent = host` so they materialise as CELLS with producing class home-manager).
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
              users.amy = { };
            }
          else
            { }
        );
        den.schema.user.parent = "host";
        # the host's OWN nixos content (a host-kind include — resolves at the host only).
        den.aspects.hostc.nixos.tag = "nixos-host";
        den.schema.host.includes = [ "hostc" ];
        # each user cell's content: nixos (HOST-class, folds up — the define-user shape) tagged per-user,
        # AND home-manager (the cell's OWN producing class). A user-kind include ⇒ resolves at each cell.
        den.aspects.acct =
          { user, ... }:
          {
            nixos.tag = "nixos-${user.name}";
            # hm class content authored the v1-SURFACE way (`homeManager`) — v1 keys the hm class camelCase; kebab
            # `home-manager` is den-hoag's GROUNDED name, not v1-surface. A parametric aspect's RESULT has no
            # raw-splice, so a kebab class key freeform-mangles; the v1 spelling grounds to `home-manager` at
            # compile. (Static kebab class content stays accepted via mkRawTotality's raw-splice.)
            homeManager.tag = "hm-${user.name}";
          };
        den.schema.user.includes = [ "acct" ];
      }
    ];

  # every `tag` string reachable in a wrapped deferredModule (the gen-aspects `{ imports = [ … ]; }` form).
  tags =
    m:
    if builtins.isAttrs m then
      (if m ? tag then [ m.tag ] else [ ])
      ++ (if m ? imports then builtins.concatMap tags m.imports else [ ])
    else
      [ ];

  # the host's within-class assembly at a class, read two ways: the DEFAULT-FOLD edge content
  # (graphAccessor.contentsOf — the classBucketsOf/contentsOf sites) and the TERMINAL hostModules
  # (systems.<class>.<host>.modules — the byte-compare path, the hostModules/deltaOf/contentIdsOf sites).
  foldTags =
    fleet: id: class:
    builtins.concatMap tags (map (c: c.content) (fleet.den.output.graphAccessor.contentsOf id class));
  termTags =
    fleet: id: class:
    builtins.concatMap tags (fleet.den.output.systems.${class}.${id}.modules or [ ]);

  withCells = mk true;
  noCells = mk false;
  igloo = "host:igloo";
  subtreeNixos = [
    "nixos-host" # own (self first)
    "nixos-amy" # descendant cells, lexicographic-DFS
    "nixos-pol"
    "nixos-tux"
  ];
in
{
  flake.tests.class-fold-subtree = {
    # (1) the host's nixos assembly gathers own + all three cells' nixos content, at the default-fold edge
    #     AND the terminal (the drv the byte-compare oracle hashes) — the account content v1 folds up.
    test-fold-gathers-subtree-nixos = {
      expr = foldTags withCells igloo "nixos";
      expected = subtreeNixos;
    };
    test-terminal-gathers-subtree-nixos = {
      expr = termTags withCells igloo "nixos";
      expected = subtreeNixos;
    };

    # (2) identity companion: a cell-less host's nixos assembly is its own content alone (`[ id ]`),
    #     byte-identical to the pre-#63 own-scope read — at both the fold edge and the terminal.
    test-no-cell-fold-own-scope-unchanged = {
      expr = foldTags noCells igloo "nixos";
      expected = [ "nixos-host" ];
    };
    test-no-cell-terminal-own-scope-unchanged = {
      expr = termTags noCells igloo "nixos";
      expected = [ "nixos-host" ];
    };

    # (3) per-class no-leak: the cells' HOME-MANAGER (other-class) content does NOT enter the host's NIXOS
    #     assembly (no `hm-*` tag) — the gather is gated to the class in question.
    test-per-class-no-leak-hm-into-nixos = {
      expr = builtins.filter (t: builtins.match "hm-.*" t != null) (termTags withCells igloo "nixos");
      expected = [ ];
    };
    # …and the host's HOME-MANAGER assembly gathers the cells' home-manager content (the same subtree fold,
    # a different class), lexicographic — the per-class companion to the no-leak pin.
    test-host-hm-assembly-gathers-cells = {
      expr = foldTags withCells igloo "home-manager";
      expected = [
        "hm-amy"
        "hm-pol"
        "hm-tux"
      ];
    };
    # …and only the host (producing class nixos) builds a nixos system — the cells (home-manager producing)
    # do not, so `contentIdsOf` keys the nixos output map on the host alone even though it gathered the
    # cells' nixos content (the memberClassName gate: subtree content ≠ own producing class).
    test-only-host-builds-nixos-system = {
      expr = builtins.attrNames withCells.den.output.systems.nixos;
      expected = [ igloo ];
    };

    # (4) A12 order — own-first ++ lexicographic-DFS descendants, no dedup. `nixos-host` (own) precedes the
    #     cells; `amy` < `pol` < `tux` (the three-cell sort makes the lexicographic order non-trivial).
    test-a12-own-first-lexicographic = {
      expr =
        builtins.head (termTags withCells igloo "nixos") == "nixos-host"
        && termTags withCells igloo "nixos" == subtreeNixos;
      expected = true;
    };
  };
}
