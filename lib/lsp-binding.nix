# The gen-lsp BINDING — the den-side adapter that feeds a BUILT den fleet's surface into gen-lsp's
# general LSP/MCP projection. gen-lsp reads gen value SHAPES (option trees, aspect instances, gen libs)
# with pure builtins and emits neutral-keyed views (`forNixd` in-process / `forNixdJSON` wire); den owns
# the mapping from its own surface onto gen-lsp's inputs. That mapping is exactly three passthroughs:
#
#   * `options`      = `den._options`      — the evaluated option-declaration tree (entity.build),
#                      reachable WITHOUT forcing `.config` (declaration-only laziness).
#   * `aspects`      = `den.aspects`       — the declared aspect instances (`config.den.aspects`).
#   * `keySemantics` = `den._keySemantics` — the construction-time key vocabulary (concern-aspects `cnf`),
#                      which classifies each aspect key (a `facet` key projects; `class`/`channel` content
#                      buckets do not). It is SCHEMA data, not on the resolved aspect instances, so gen-lsp's
#                      facet-generic `aspectsProjection` needs it threaded here.
#
# The gen-lib API surface is den's 19 SUBSTRATE libs. `internal` MIXES those 19 with ~30 den helper
# closures (buildRoots/runResolve/terminal/…); gen-lsp's `genLibProjection` is GENERAL (no allowlist), so
# membership is den's concern — this filters `internal` down to the 19-name allowlist via
# `intersectAttrs`, taking each lib's value from `internal` (one source of truth, no re-listing).
#
# `structuralKeys` is left to gen-lsp's default (the identity list `[name includes meta tags projects key
# description]`), which matches den's structural facets — so den's `settings`/`neededBy`/`artifact`/`id_hash`
# keySemantics facets project while the identity keys stay built-in submodule options.
#
# Pure builtins (no prelude/nixpkgs `lib`): the binding is nixpkgs-lib-free like the rest of `lib/`.
{ lsp }:
let
  # den's 19 substrate libraries — the allowlist gen-lsp's general `genLibProjection` is handed. These are
  # exactly the libs `internal` inherits under these names (`genGraph` = gen-graph, role-named to avoid the
  # bare-`graph` collision with den's own graph escape hatch); `intersectAttrs` keeps only these keys.
  genLibNames = [
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
  allowlist = builtins.listToAttrs (
    map (n: {
      name = n;
      value = null;
    }) genLibNames
  );

  # The three-passthrough + filtered-libs argument gen-lsp's composed views take. `structuralKeys` is
  # omitted so `aspectsProjection` applies its own (den-matching) default.
  argsOf =
    {
      den,
      internal,
    }:
    {
      options = den._options;
      aspects = den.aspects;
      keySemantics = den._keySemantics;
      libs = builtins.intersectAttrs allowlist internal;
    };
in
{
  # The IN-PROCESS view (`forNixd`): the three projections with functions intact (an option leaf's `.type`
  # keeps its `check`/`merge`/`getSubOptions`, an aspect node's `getSubOptions` is a live lambda) — for a
  # nixd worker's own evaluator. Neutral-keyed (`options`/`aspects`/`libs`) as gen-lsp emits them.
  forNixd = args: lsp.forNixd (argsOf args);
  # The WIRE view (`forNixdJSON`): the same three trees re-projected JSON-safe (functions dropped, submodule
  # aspect facets descended, derivation/cyclic defaults rendered as placeholders) — for an MCP server's
  # `nix eval --json`.
  forNixdJSON = args: lsp.forNixdJSON (argsOf args);
}
