# The (b) PAYLOAD-PROJECTING reverse-read witness (§5 productions substrate, the §9 transpose's payload
# variant). Where `claim-negation`/`claim-dedup` read the id-only reverse (`.query`/`.rel` = sort-by-lessThan
# ID-LISTS), a provider that needs the CLAIM PAYLOAD (not just the claimer id) reads the ADDITIVE
# `.queryEdges` handle — the reverse claimers as `{ from; data }` records. This suite pins BOTH: `queryEdges`
# PROJECTS the payload, AND the shipped-consumer `.query`/`.rel` KEEP their id-list shape (the §0 additive
# contract — an in-place change would break claim-negation.nix:107/109/196 + claim-dedup.nix:49). Corpus-zero
# (no fleet reads `queryEdges`), so a DIRECT synthetic pool is the witness. Header mirrors claim-dedup.nix's —
# ci specialArgs provides `denHoag`.
{
  denHoag,
  ...
}:
let
  # the payload fleet: two apps BOTH claiming `target` via `attaches` — each carrying a DISTINCT edge payload
  # (`data`), the thing `queryEdges` projects that `query` drops. The `attaches` leaf claim sits at `connect`
  # (strictly below `resolution`), so the reverse-read is in scope. from = ∅ EDB (pure ground facts).
  fleet = denHoag.mkDen [
    {
      config.den.schema.node.parent = null;
      config.den.strata.insert = denHoag.declare.strataChain {
        after = "structural";
        chain = [
          "connect"
          "secret"
          "database"
          "route"
        ];
      };
      config.den.node.appA = { };
      config.den.node.appB = { };
      config.den.node.target = { };
      config.den.node.lonely = { };

      # the `attaches` leaf claim (emit = edges, from = ∅ EDB): appA + appB both claim `target`, each with its
      # OWN `data` payload (the projected value). `claimEdgesOf` carries `data = fact.data or { }` into the pool.
      config.den.productions.attaches = {
        stratum = "connect";
        from = [ ];
        emit = "edges";
        mode = "all";
        readsAttrs = [ ];
        compute = _self: _id: [
          {
            from = "node:appA";
            to = "node:target";
            data = {
              role = "primary";
            };
          }
          {
            from = "node:appB";
            to = "node:target";
            data = {
              role = "backup";
            };
          }
        ];
      };
    }
  ];

  eval = fleet.den.structural.eval;
  handleAt = id: eval.get id "claim-accessor";
  byFrom = a: b: a.from < b.from;
in
{
  flake.tests.claim-payload-projection = {
    # ── (b) `queryEdges` PROJECTS the payload — the reverse claimers of `target` as `{ from; data }` records,
    #    each carrying its edge's `data` (role=primary/backup), not just the claimer id. ──
    test-queryedges-projects-payload = {
      expr = builtins.sort byFrom ((handleAt "node:target").queryEdges "attaches");
      expected = [
        {
          from = "node:appA";
          data = {
            role = "primary";
          };
        }
        {
          from = "node:appB";
          data = {
            role = "backup";
          };
        }
      ];
    };

    # ── the REGRESSION GUARD (§0): the shipped-consumer `.query` STILL returns the id-only list (shape
    #    unchanged — claim-negation/claim-dedup read it as a sort-by-lessThan id-list). ──
    test-query-still-id-only = {
      expr = builtins.sort builtins.lessThan ((handleAt "node:target").query "attaches");
      expected = [
        "node:appA"
        "node:appB"
      ];
    };

    # …and the throwing `.rel.<kind>` gate ALSO keeps its id-list shape (the negation consumer's contract).
    test-rel-still-id-only = {
      expr = builtins.sort builtins.lessThan (handleAt "node:target").rel.attaches;
      expected = [
        "node:appA"
        "node:appB"
      ];
    };

    # a node claimed by NOBODY projects an EMPTY edge list (never an attr-miss) — the empty-pool variant.
    test-queryedges-unclaimed-empty = {
      expr = (handleAt "node:lonely").queryEdges "attaches";
      expected = [ ];
    };
  };
}
