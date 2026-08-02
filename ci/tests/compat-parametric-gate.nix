# The parametric-result gate (design §9.5). A parametric aspect's RESULT is materialized at RESOLUTION
# (resolved-aspects.nix `aspect ctx`), NOT run through the compile-time closed-gated typed tree — so a typo in
# a parametric body reaches content un-gated unless the resolver re-gates it. `grndDispatch`'s content
# terminals normalize the fired result to the static pre-gate shape via `translateAspect` (droppedAspectKeys
# drop + excludes→meta.drop fold + provides sentinel), THEN type it through the SAME closed gate the compile
# view uses (lib/compat/gated-aspects-type.nix), so gated-parametric-shape == gated-static-shape. The gate is a
# VALIDATION seq: a typo throws NAMED at the gate at resolution; a valid result rides through unchanged.
# Theory: scope-as-type (Néron/Tolmach/Visser/Wachsmuth 2015) — a name resolving to no declaration in the
# aspect scope is a type error at that scope; the parametric result is a fresh scope closed the same way.
{ denCompat, ... }:
let
  # A parametric aspect compiles to a `__isWrappedFn` functor; firing it with a coordinate ctx routes its
  # result through `grndDispatch` → `translateAspect` → the gate. The ctx carries the entity coords a
  # `{ host, ... }:` body binds (empty stand-ins suffice for the typo/lowering witnesses, which key on
  # class/typo keys rather than values; the identity witnesses below supply named coords instead).
  fireAt =
    ctx: body:
    let
      para =
        (denCompat.compile {
          aspects.p = body;
          hosts.x86_64-linux.h.class = "nixos";
        }).aspects.p;
    in
    para (
      {
        host = { };
        user = { };
        settings = { };
        aspects = { };
      }
      // ctx
    );
  fire = fireAt { };
  forced = body: builtins.tryEval (builtins.deepSeq (fire body) true);

  # ── IDENTITY TOTALITY at the gate, at the granularity the kernel reads ─────────────────────────────
  # A TOP-LEVEL parametric aspect is materialized by gen-aspects itself, so its fired result is already a
  # typed node carrying `id_hash`. A BARE-FN INCLUDE is not: `deferIncludeResolution` passes it through the
  # type opaquely and `normalize` wraps the raw closure, so its fired result is a raw attrset and the gate
  # is the only place it is ever typed. That is the corpus shape — one bare fn attached to the `user` kind,
  # fired once per user cell of a host — and the shape whose element reaches the kernel's A12 producer key.
  #
  # ONE authored include site, N cells: the resolved node's KEY is the site's, identical at every cell, so
  # it cannot discriminate the N producers. Only the instantiation's own name can.
  mkFleet =
    includes:
    denCompat.mkDen [
      {
        den = {
          hosts.x86_64-linux.h = {
            class = "nixos";
            users = {
              u1 = { };
              u2 = { };
            };
          };
          schema.user.parent = "host";
          schema.user.includes = includes;
        };
      }
    ];
  nodesAt = fleet: id: fleet.den.structural.eval.get id "resolved-aspects";
  # The nodes the kind-include ADDED, selected by difference against an otherwise identical fleet with no
  # kind-include — so the selection never depends on the internal wrap-name spelling.
  ctrlKeys = map (n: n.key) (nodesAt (mkFleet [ ]) "user:u1@host:h");
  addedAt = fleet: id: builtins.filter (n: !(builtins.elem n.key ctrlKeys)) (nodesAt fleet id);
  keysAddedAt = fleet: id: map (n: n.key) (addedAt fleet id);
  idsAddedAt = fleet: id: map (n: n.content.id_hash or "«absent»") (addedAt fleet id);

  # A self-naming per-cell body (the corpus shape: an identity aspect naming itself `<aspect>/<user>@<host>`).
  namedBody =
    { host, user, ... }:
    {
      name = "acct/${user.name}@${host.name}";
      nixos.tag = "t";
    };
  # The SAME body, naming nothing — the include-site fallback arm, and the control on the witness above.
  anonBody =
    { host, user, ... }:
    {
      nixos.tag = "t";
    };
  namedFleet = mkFleet [ namedBody ];
  anonFleet = mkFleet [ anonBody ];
  # An INDEPENDENTLY BUILT fleet of the same declarations — the identity is a content-address, so it must
  # reproduce across builds rather than vary per materialization.
  namedFleetAgain = mkFleet [ namedBody ];

  # The STATIC twin of the excludes witness — the same `excludes` on a non-parametric aspect, lowered by the
  # SAME `translateAspect`. The parametric drop must equal this by construction (one desugar path).
  staticDrop =
    ((denCompat.compile {
      aspects.s = {
        nixos.x = true;
        excludes = [ "sib" ];
      };
      hosts.x86_64-linux.h.class = "nixos";
    }).aspects.s
    ).meta.drop or "NONE";
  parametricDrop =
    (fire (
      { host, ... }:
      {
        nixos.x = true;
        excludes = [ "sib" ];
      }
    )).meta.drop or "NONE";
in
{
  flake.tests.compat-parametric-gate = {
    # A typo in a parametric body (an undeclared non-attrset leaf) throws NAMED at the gate at resolution —
    # the sole typo boundary for parametric content (the compile-time typed tree never sees the fired result).
    test-parametric-typo-throws-at-gate = {
      expr = (forced ({ host, ... }: { homeManagr = "x"; })).success;
      expected = false;
    };
    # A valid parametric result (declared class content) rides through the gate unchanged — byte-neutral.
    test-parametric-valid-admits = {
      expr = (forced ({ host, ... }: { nixos.networking.hostName = "h"; })).success;
      expected = true;
    };
    # A legit nested aspect inside a parametric result is admitted (recursive-closed: an undeclared attrset
    # child is a namespace that recurses, not a flat reject), not gate-rejected.
    test-legit-nested-in-parametric-admits = {
      expr =
        (forced (
          { host, ... }:
          {
            nixos.networking.hostName = "h";
            kid.nixos.x = 1;
          }
        )).success;
      expected = true;
    };
    # A parametric result carrying `excludes` lowers to `meta.drop` IDENTICALLY to the static path (both route
    # through the one `translateAspect` fold) — recognition ⟂ lowering, the §9.3 must-fix.
    test-parametric-excludes-lowers-to-meta-drop-identical-to-static = {
      expr = {
        inherit parametricDrop staticDrop;
        identical = parametricDrop == staticDrop;
      };
      expected = {
        parametricDrop = [ "sib" ];
        staticDrop = [ "sib" ];
        identical = true;
      };
    };
    # THE GATE SUPPLIES THE ELEMENT'S IDENTITY. Every aspect element the kernel reads must carry one: the
    # A12 producer key is `identity = a.content.id_hash` (`collections.nix`), read as TOTAL. A bare-fn
    # include's fired result is a raw attrset, so before the gate stamped it the kernel met an element with
    # the field ABSENT. Present because SUPPLIED, never because a reader defaults it — an `or`-defaulted
    # identity is a silent merge of distinct producers, a wrong answer rather than a failure.
    test-kind-include-element-carries-identity = {
      expr = {
        # the predicate is not vacuous: the kind-include really did add elements at this cell.
        someAdded = builtins.length (addedAt namedFleet "user:u1@host:h") > 0;
        present = builtins.all (i: builtins.isString i && i != "«absent»") (
          idsAddedAt namedFleet "user:u1@host:h"
        );
        reproducible =
          idsAddedAt namedFleet "user:u1@host:h" == idsAddedAt namedFleetAgain "user:u1@host:h";
      };
      expected = {
        someAdded = true;
        present = true;
        reproducible = true;
      };
    };
    # THE COLLISION PREMISE, stated as a fact rather than assumed: the two cells' elements come from ONE
    # authored include site and therefore share a key. Any identity derived from that key collapses them.
    test-kind-include-site-key-is-shared-across-cells = {
      expr = {
        shared = keysAddedAt namedFleet "user:u1@host:h" == keysAddedAt namedFleet "user:u2@host:h";
        nonEmpty = keysAddedAt namedFleet "user:u1@host:h" != [ ];
      };
      expected = {
        shared = true;
        nonEmpty = true;
      };
    };
    # THE COLLISION HALF. Under that shared key the two cells' identities are DISTINCT: a self-naming
    # instantiation keys each cell by its own name (v1's discipline — an aspect body's `name` IS its
    # identity), so two users' contributions are never merged into one producer.
    test-kind-include-per-cell-identities-do-not-collide = {
      expr = idsAddedAt namedFleet "user:u1@host:h" != idsAddedAt namedFleet "user:u2@host:h";
      expected = true;
    };
    # THE FALLBACK ARM, and the control on the witness above: a body that names nothing is keyed by its
    # include site, so the SAME two cells that discriminate under a name agree under none. Without this the
    # distinctness above could not be told from a per-cell-unstable identity.
    test-kind-include-anonymous-identity-is-the-include-site = {
      expr = idsAddedAt anonFleet "user:u1@host:h" == idsAddedAt anonFleet "user:u2@host:h";
      expected = true;
    };
  };
}
