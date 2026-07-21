# The shared position-attribution layer (§ options-projection): a projected option leaf carries
# `declarationPositions` — a list of nixd goto records `{ file; line; column; }` locating the leaf's
# source declaration site. Positions come from `builtins.unsafeGetAttrPos` over the MERGED option leaf,
# which preserves its `mkOption { … }` field source positions (the gen-merge option merge threads the
# declared attrset through), so the DECLARATION site is recovered WITHOUT hoisting the raw decl modules.
# The logic is a GENERIC `raw → positions` layer (`den.lib.lsp.positions`) a later graph/nav feature can
# reuse. Reading a position is STRUCTURAL: it never forces resolved fleet `.config` (the laziness seam).
{
  denHoag,
  ...
}:
let
  den =
    (denHoag.mkDen [
      {
        config.den.schema.host.parent = null;
        config.den.host.h0 = { };
      }
    ]).den;

  # Independence fixture: identical fleet EXCEPT its RESOLVED fleet config carries a live `throw` thunk
  # (`h0.outputs.fam`). Forcing `.config` throws; attaching positions (a structural leaf read) must not.
  poisonDen =
    (denHoag.mkDen [
      {
        config.den.schema.host.parent = null;
        config.den.host.h0 = {
          outputs.fam = throw "CONFIG-FORCED";
        };
      }
    ]).den;

  projected = denHoag.lsp.optionsProjection { options = den._options; };

  # `den.membership` is a real mkOption decl (lib/default.nix) — its projected leaf must carry a real
  # source position (line/col path taken ⇒ line > 0).
  membershipPos = projected.den.membership.declarationPositions;
  firstMembership = builtins.head membershipPos;

  # Genericity: a raw literal that is NOT an option leaf, run through the generic layer, recovers ITS
  # OWN field's source position — proving the layer is reusable beyond option leaves (a graph node's
  # `label`/`id` field would be probed the same way).
  rawNode = {
    label = "n";
  };
  genericPos = denHoag.lsp.positions.positionsOf { fields = [ "label" ]; } rawNode;

  # The full-projection force under a poison fleet: attaching positions to every option leaf must not
  # enter the fx pipeline (mirrors the Task-1/3 independence guard). `walkPositions` gathers every
  # leaf's `declarationPositions` (the added channel) so `deepSeq` forces the `unsafeGetAttrPos` reads
  # WITHOUT forcing each leaf's `.type`/`.default` (structural position read only).
  poisonProjected = denHoag.lsp.optionsProjection { options = poisonDen._options; };
  walkPositions =
    node:
    if builtins.isAttrs node && (node._type or null) == "option" then
      node.declarationPositions
    else if builtins.isAttrs node then
      builtins.map walkPositions (builtins.attrValues node)
    else
      null;
in
{
  flake.tests.lsp-positions = {
    # A real declared option leaf carries a non-empty `declarationPositions` list of nixd goto records
    # (`{ file; line; column; }`), and — the line/col path taken — line > 0 at a real source file.
    test-leaf-carries-positions = {
      expr = {
        isList = builtins.isList membershipPos;
        nonEmpty = membershipPos != [ ];
        recordKeys = builtins.sort (a: b: a < b) (builtins.attrNames firstMembership);
        lineIsPositive = firstMembership.line > 0;
        columnIsPositive = firstMembership.column > 0;
        fileIsString = builtins.isString firstMembership.file;
        # the recovered site IS the membership declaration file (lib/default.nix), not merge machinery.
        fileIsDeclSite = builtins.match ".*/lib/default\\.nix" firstMembership.file != null;
      };
      expected = {
        isList = true;
        nonEmpty = true;
        recordKeys = [
          "column"
          "file"
          "line"
        ];
        lineIsPositive = true;
        columnIsPositive = true;
        fileIsString = true;
        fileIsDeclSite = true;
      };
    };

    # THE GENERIC LAYER: `positions.positionsOf { fields } raw` is not options-specific — a bare raw
    # literal yields a singleton position at its probed field's source site.
    test-generic-layer-reusable = {
      expr = {
        isSingleton = builtins.length genericPos == 1;
        lineIsPositive = (builtins.head genericPos).line > 0;
        # the probe landed in THIS test file (the literal's real source).
        fileIsThisFile = builtins.match ".*/lsp-positions\\.nix" (builtins.head genericPos).file != null;
        # a field absent from the raw yields NO position (honest — never a faked location).
        absentFieldEmpty = denHoag.lsp.positions.positionsOf { fields = [ "nope" ]; } rawNode == [ ];
      };
      expected = {
        isSingleton = true;
        lineIsPositive = true;
        fileIsThisFile = true;
        absentFieldEmpty = true;
      };
    };

    # THE LAZINESS SEAM: deep-forcing the WHOLE projected tree's positions succeeds even when the
    # RESOLVED fleet config carries a live `throw` (`positionsOk`), while forcing that config throws
    # (`configThrows`). Pins "attaching positions never forces `.config`" as a regression guard.
    test-positions-independent-of-resolved-config = {
      expr = {
        positionsOk = builtins.deepSeq (walkPositions poisonProjected) "OK";
        configThrows =
          !(builtins.tryEval (builtins.deepSeq poisonDen.registries.host.h0.outputs "forced")).success;
      };
      expected = {
        positionsOk = "OK";
        configThrows = true;
      };
    };
  };
}
