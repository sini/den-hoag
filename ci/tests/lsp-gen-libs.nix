# The gen-lib API-surface PROJECTION (§ options-projection): `den.lib.lsp.genLibProjection { internal }`
# projects the 19 gen substrate libraries as an option-tree of members (member NAMES + `functionArgs`
# formals), so an LSP completes/hovers a gen-lib member. THIN BY DESIGN (den-map finding): the gen libs are
# flat function attrsets carrying NO type/signature metadata, so this projects names + PARTIAL formals, never
# typed signatures. `internal` MIXES the 19 libs with ~30 den helper closures (buildRoots/runResolve/…), so
# the projection filters by an explicit 19-name allowlist — only the libs surface. Reading a lib's `attrNames`
# + a member's `functionArgs` is config-free: the projection never enters the fx pipeline (the laziness seam).
{
  denHoag,
  ...
}:
let
  projected = denHoag.lsp.genLibProjection { internal = denHoag.internal; };
in
{
  flake.tests.lsp-gen-libs = {
    # (a) A known lib surfaces as a node keyed by member name; each member is an `_type == "option"` leaf
    # with an (empty, doc-deferred) description.
    test-lib-members-projected = {
      expr = {
        hasSelect = projected ? select;
        entryType = projected.select.entity._type;
        entryDesc = projected.select.entity.description;
        hasKindMember = projected.select ? kind;
      };
      expected = {
        hasSelect = true;
        entryType = "option";
        entryDesc = "";
        hasKindMember = true;
      };
    };

    # (b) A lambda member carries `formals = functionArgs fn`: an attrset-argument function surfaces its
    # formal names; a positional-argument function surfaces `{ }`.
    test-lambda-member-carries-formals = {
      expr = {
        mkGraphFormals = builtins.sort (a: b: a < b) (
          builtins.attrNames projected.genGraph.mkGraph.formals
        );
        resolveFormals = builtins.sort (a: b: a < b) (builtins.attrNames projected.resolve.resolve.formals);
        positionalFormals = projected.select.entity.formals;
      };
      expected = {
        mkGraphFormals = [
          "edges"
          "nodeData"
          "parents"
        ];
        resolveFormals = [
          "declaredEdges"
          "equations"
          "parseParent"
          "roots"
          "settings"
          "strataOrder"
        ];
        positionalFormals = { };
      };
    };

    # (c) The allowlist works: only the 19 libs surface — the ~30 den helper closures (buildRoots/runResolve/
    # settingsLib/…) that share `internal` are ABSENT.
    test-den-helpers-excluded = {
      expr = {
        keyCount = builtins.length (builtins.attrNames projected);
        buildRootsAbsent = !(projected ? buildRoots);
        runResolveAbsent = !(projected ? runResolve);
        settingsLibAbsent = !(projected ? settingsLib);
        allLibs = builtins.sort (a: b: a < b) (builtins.attrNames projected);
      };
      expected = {
        keyCount = 19;
        buildRootsAbsent = true;
        runResolveAbsent = true;
        settingsLibAbsent = true;
        allLibs = builtins.sort (a: b: a < b) [
          "prelude"
          "dispatch"
          "resolve"
          "scope"
          "select"
          "product"
          "aspects"
          "pipe"
          "settings"
          "algebra"
          "demand"
          "edge"
          "bind"
          "class"
          "merge"
          "flake"
          "schema"
          "identity"
          "genGraph"
        ];
      };
    };

    # THE LAZINESS SEAM: fully forcing the projection (every member node + its formals) resolves — reading a
    # lib's member names + `functionArgs` is config-free, so the projection never enters the fx pipeline.
    test-projection-is-config-free = {
      expr = builtins.deepSeq projected "OK";
      expected = "OK";
    };
  };
}
