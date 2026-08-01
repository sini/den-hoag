# class-bucket-query — the DIRECT per-node class-slice QUERY ATOM ([[project_class_bucket_holdover]]). The
# eager per-class content bucket (the v1 state-accumulator VALUE-shape — the whole-map base-accumulation) is
# retired for a direct per-(node,class) keyed class-slice sourced from `rawSliceOf` (THE per-element
# extraction), with inject/reroute kept as a whole-map post-transform. The REACHABLE descendant-closure
# (`classSubtreeAt`) is re-sourced over this direct atom (via the memoized `class-modules-keyed`).
#
# Witnesses over the raw class-modules producer (`internal.classModulesBuilder`) against a synthetic `self`
# (so a corpus-inert reroute has a direct witness):
#   (1) CHAINED REROUTE (the whole-map faithfulness) — `[ {A→B}, {B→C} ]` lands A's content in C via B; a
#       per-class-INDEPENDENT fold would see only `{B→C}` for C and miss A.
#   (2) INJECT — a resolution `inject { class; module }` appends to the class bucket (non-vacuous).
#   (3) BASE COLLECTION — each aspect's class content lands in its own bucket (the direct-query base).
{ denHoag, denHoagSrc, ... }:
let
  inherit (denHoag.internal) prelude aspects merge;
  cmb = denHoag.internal.classModulesBuilder;
  classNames = [
    "A"
    "B"
    "C"
    "D"
  ];
  # THE CLASSIFICATION AUTHORITY IS A REAL SCHEMA INSTANCE over this fixture's own class names, not a
  # hand-written dispatch — both functions the producer classifies with come from it, so the fixture holds
  # ONE authority about its own channels and the suite tests the kernel's classification rather than a copy
  # of it. A registered class key still classifies as `class`, so both bucket producers key ONLY over
  # `classNames`.
  inherit
    (import "${denHoagSrc}/lib/concern-aspects.nix" {
      inherit
        prelude
        aspects
        merge
        classNames
        ;
      errors = import "${denHoagSrc}/lib/errors.nix";
      kindNames = [ ];
    })
    classifyKey
    aspectSchema
    ;

  # a non-empty deferredModule leaf (a real content wrap; `isEmptyDeferredModule` false), tag-marked so the
  # buckets read as plain data (no functions ⇒ `==` comparable for the parity rows).
  mod = tag: {
    imports = [ { inherit tag; } ];
  };
  # the channel → [ tag ] projection of a `class-seeds` value.
  bareTags = v: builtins.mapAttrs (_: ss: map (e: (builtins.head e.module.imports).tag) ss) v;

  # two resolved-aspect nodes: aspect `aspA` carries class-A content, aspect `aspD` carries class-D content.
  # `scope` and `assertedClasses` are STAMPED: a content element is produced COMPLETE, and the totality
  # assertion projects `assertedClasses` with a named throw rather than reading an absence as a default.
  # `{ }` is the value every produced aspect element carries — "this element asserts nothing" — so these
  # fixtures stay semantically identical to what the assembly feeds the equation.
  resolvedAspects = [
    {
      content = {
        name = "aspA";
        A = mod "cA";
      };
      sharedFoldKey = null;
      scope = "n";
      assertedClasses = { };
    }
    {
      content = {
        name = "aspD";
        D = mod "cD";
      };
      sharedFoldKey = null;
      scope = "n";
      assertedClasses = { };
    }
  ];
  # synthetic resolver: `resolved-aspects` = the two nodes; `declarations.actions.resolution` = `acts`;
  # `content-key-totality` = the real §2.2 classification driver over those same nodes; `class-relocation`
  # = the real per-scope relocation memo, whose `injections` field `class-seeds` reads for its element list
  # and whose `sourceOrder` the extraction reads a channel's preimage through. Both are driven from the
  # KERNEL's own equation against this same `self`, so the instrument supplies DATA (the acts at the scope)
  # and never a second copy of the relation — a hand-written memo would replicate the algorithm and any
  # divergence from the kernel's would be silent.
  mkSelf =
    acts:
    let
      self = {
        get =
          id: attr:
          if attr == "resolved-aspects" then
            resolvedAspects
          else if attr == "declarations" then
            { actions.resolution = acts; }
          else if attr == "content-key-totality" then
            cm.content-key-totality.compute self id
          else if attr == "class-relocation" then
            cm.class-relocation.compute self id
          else
            throw "class-bucket-query: unexpected attr ${attr}";
      };
    in
    self;
  selfPlain = mkSelf [ ];
  selfReroute = mkSelf [
    {
      __action = "reroute";
      from = "A";
      to = "B";
    }
    {
      __action = "reroute";
      from = "B";
      to = "C";
    }
  ];
  selfInject = mkSelf [
    {
      __action = "inject";
      class = "D";
      module = mod "inj";
    }
  ];

  cm = cmb {
    inherit classNames classifyKey;
    inherit (aspectSchema) keyCategory;
  };
  bare = self: cm.class-seeds.compute self "n";
in
{
  flake.tests.class-bucket-query = {
    # (3) base collection (non-vacuous): each aspect's class content lands in its own bucket.
    test-base-content-collected = {
      expr = bareTags (bare selfPlain);
      expected = {
        A = [ "cA" ];
        B = [ ];
        C = [ ];
        D = [ "cD" ];
      };
    };

    # (1) chained reroute A→B→C — A's content rides through B into C (the whole-map fold); a per-class fold
    #     would see only `{B→C}` for C and miss A.
    test-chained-reroute-lands-in-C = {
      expr = bareTags (bare selfReroute);
      expected = {
        A = [ ];
        B = [ ];
        C = [ "cA" ];
        D = [ "cD" ];
      };
    };

    # (2) inject appends to the class bucket (§2.3 resolution).
    test-inject-applied = {
      expr = (bareTags (bare selfInject)).D;
      expected = [
        "cD"
        "inj"
      ];
    };
  };
}
